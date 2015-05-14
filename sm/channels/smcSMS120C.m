function val = smcSMS120C (ico, val, rate)
% driver for Cryogenics SMS120C 
% smcSMS120C([ico(1) ico(2) ico(3)] val, rate) val and rate are T and A/s
% "measurement points/second"
%           ico(1): instrument number (eg physical inst 1, 2, 3...)
%           ico(2): channel on instrument ignored as only one channel
%           available, could become 1:3 for x..z
%           ico(3):  0=read/1=write/2=NA/3=NA/4=N/5=NA. 
% written by mcneil@physik.rwth-aachen.de

% WARNING: The instrument has ***NO HEATER INTERLOCK*** to ensure the leads and magnet are at the same field. 

% This instrument replies to all commands (except (R)AMP and (D)IRECTION) so use query (printf)
% Ramp rate is rounded to nearest available rate. 
%   available rates are:
% 
% HEATER CURRENT:
%  heater current should be 53.6mA but this is controlled by voltage so need
%  to measure the "normal" heater resistance at 4K. Current room
%  temperature calculation gives HEATER DRIVE VOLTAGE of 3.8V 
% query(inst,'SH 3.8') 
% FUTURE DRIVER
% ico(2) 1,2,3 could become x,y,z field in future driver currently ico(2)
% is ignored


global smdata

% MAGNET PARAMETERS SHOULD BE SUITABLE FOR: AMI 7T Zfield coil
% NOTE: ramprate is ALWAYS interpreted as A/s even if using Tesla mode
Max_Zramp_rate = smdata.inst(ico(1)).data.maxrate;% Max is 0.3858A/s [or 0.03275T/s (117.9T/hr) for AMI 7T coil]
Max_Zfield = max(smdata.inst(ico(1)).data.rng); % some field ranges are asymmetric
Min_Zfield = min(smdata.inst(ico(1)).data.rng); % some field ranges are asymmetric
Zfieldconst= smdata.inst(ico(1)).data.TperA; % Amps/Telsa
% x- y- limits

% Defaults
default_Zramp_rate = Max_Zramp_rate/4;
lead_ramp_rate = smdata.inst(ico(1)).data.leadramprate; % fast rate for rmping leads 12A/s
heater_wait_time = smdata.inst(ico(1)).data.heaterwaittime; % time (in secs) for switch to go normal/SC
% warning('heater wait time is set to 2s for testing, revert to ~10s for operation');
% x- y-defaults


% set default ramp rate and check for safe ramp rates
if nargin<3
     rate= default_Zramp_rate; % default is to sweep rapidly at 50% of max  
end
if rate > Max_Zramp_rate
  warning('ramp rate too large, default value in use')
  rate = Max_Zramp_rate;
end

inst = smdata.inst(ico(1)).data.inst;

% front panel operation may leave data in the buffer, flush it first
flushinput(smdata.inst(ico(1)).data.inst);

% WARNING:The SMC forgets the [Tesla|Amp] state when power cycled. Without
% this next line Tesla values will be taken as Amp values, units are always ignored. 
% NOTE: Rate is always A/s

query(inst,'T1');  % could move this to an ico(3)=6 command takes 150ms to run but this is small compared to switch wait times and ramp times.

switch ico(3)
  case 1 % ramp to 'val' at 'rate'
%     keyboard    %    'breakpoint here'
    % catch point in case magnet is still sweping/quenched/etc
    if strcmp(sscanf(query(inst,'RS'),'%*s%*s%*s%s*'),'HOLDING') ~= 1
      warning(sprintf([query(inst,'RS'),'\nNote: if above message includes  ...0.000 TESLA... you may have interupted a "trough zero" sweep.']));
      return
    end
        
    % CHECK HEATER STATE 
    if strcmp(sscanf(query(inst,'H'),'%*s%*s%*s%s*'),'ON')
    initial_heater_state = 1;
    else
    initial_heater_state = 0;  
    end

    switch initial_heater_state(1)
      % %
      case 1 % DIRECT RAMPING
        'direct ramping';
            % ensure ramp will follow MID(%) after R0 command
            if sscanf(query(inst,'GO'),'%*s%*s%f*') == 0
            query(inst,'S% 0');  
            fprintf(inst,'R%') ;  
            end
        query(inst,'P1');    % PAUSE sweeping else setting new MID(%) will initiate sweep
        query(inst,['SR ',num2str(rate)]); % (S)ET (R)ATE
        query(inst,['S% ',num2str(val)]); % (S)ET (%)MID  +/- will be ignored by inst
        flushinput(smdata.inst(ico(1)).data.inst); % precautionary
        dir_positive_flag = strcmp(sscanf(query(inst,'GS'),'%*s%*s%*s%s*'),'POSITIVE');
        val_positive_flag = sign(val) >= 0;
        if dir_positive_flag ~= val_positive_flag
          if dir_positive_flag
            sgn_str = '-';
          else
            sgn_str ='+';
          end
          fprintf(inst,['D',sgn_str]);
        end
        query(inst,'P0');
% reading from instrument before it has passed zero will prevent further sweeping to the target.        
% %         % check status, if not 'RAMPING' issue ramp command.
% %         if strcmp(sscanf(query(inst,'RS'),'%*s%*s%*s%s*'),'RAMPING') ~= 1
% %           fprintf(inst,'R%')
% %         end
      % %
      case 0 % RAMPING WITH SWITCH ON/OFF
        'persistant field ramping';
%         keyboard
            % ensure ramp will follow MID(%) after R0 command
            if sscanf(query(inst,'GO'),'%*s%*s%f*') == 0
            query(inst,'S% 0');
            fprintf(inst,'R%'); 
            end
        persistant_field = sscanf(query(inst,'GP'),'%*s%f'); % GET PERSISTANT FIELD
        query(inst,'P1');    % PAUSE sweeping else setting new MID(%) will initiate sweep
        query(inst,['S% ',num2str(persistant_field)]);   % SET TARGET
        query(inst,['SR ',num2str(lead_ramp_rate)]);          % SET LEAD_RATE
        % start some direction checking here
        flushinput(smdata.inst(ico(1)).data.inst); % precautionary
        dir_positive_flag = strcmp(sscanf(query(inst,'GS'),'%*s%*s%*s%s*'),'POSITIVE');
        persist_positive_flag = sign(persistant_field) >= 0;
        if dir_positive_flag ~= persist_positive_flag
          if dir_positive_flag
            sgn_str = '-';
          else
            sgn_str ='+';
          end
          fprintf(inst,['D',sgn_str]);
        end
        % end some direction checking here
        query(inst,'P0'); % UNPAUSE to trigger sweep
        while ~(strcmp(sscanf(query(inst,'RS'),'%*s%*s%*s%s*'), 'HOLDING')) % WAIT FOR RAMP TO FINISH
          pause(0.1);
          ramp_status=sscanf(query(inst,'RS'),'%*s%*s%*s%s*');
          if strcmp(ramp_status,'QUENCH')
            error(query(inst,'RS'))
          end
        end
        if sscanf(query(inst,'GO'),'%*s%*s%f*') ~= persistant_field
        flushinput(smdata.inst(ico(1)).data.inst); % precautionary
        dir_positive_flag = strcmp(sscanf(query(inst,'GS'),'%*s%*s%*s%s*'),'POSITIVE');
        persist_positive_flag = sign(persistant_field) >= 0;
        if dir_positive_flag ~= persist_positive_flag
          if dir_positiveflag
            sgn_str = '-';
          else
            sgn_str ='+';
          end
          fprintf(inst,['D',sgn_str]);
        end
          query(inst,['S% ',num2str(persistant_field)]);   % RESET LEADTARGET
          fprintf(inst,['R% ',num2str(val)]);                 % SWEEP 
        end
        while ~(strcmp(sscanf(query(inst,'RS'),'%*s%*s%*s%s*'), 'HOLDING')) % WAIT FOR RAMP TO FINISH
          pause(0.1);
          ramp_status=sscanf(query(inst,'RS'),'%*s%*s%*s%s*'); 
          if strcmp(ramp_status,'QUENCH') 
            error(query(inst,'RS')) 
          end
        end
        % check I_lead =I_magnet
        if abs(sscanf(query(inst,'GO'),'%*s%*s%f*') - sscanf(query(inst,'GP'),'%*s%f*')) >= 0.01 % check leadsare within 1mT of magnet
          warning(sprintf(['Lead and Magnet currents not equal: HUMAN HELP REQUIRED']))
          return
        end
        query(inst,'H1');                                % HEATER ON
        pause(heater_wait_time);                          % WAIT FOR SWITCH TO GO NORMAL
               
        query(inst,'P1');    % PAUSE sweeping else setting new MID(%) will initiate sweep
        query(inst,['S% ',num2str(val)]);                 % SET NEW TARGET
        query(inst,['SR ',num2str(rate)]);                % SET RAMP RATE
        % start some direction checking here
        flushinput(smdata.inst(ico(1)).data.inst); % precautionary
        dir_positive_flag = strcmp(sscanf(query(inst,'GS'),'%*s%*s%*s%s*'),'POSITIVE');
        val_positive_flag = sign(val) >= 0;
        if dir_positive_flag ~= val_positive_flag
          if dir_positive_flag
            sgn_str = '-';
          else
            sgn_str ='+';
          end
          fprintf(inst,['D',sgn_str]);
        end
        % end some direction checking here
        query(inst,'P0');  % UNPAUSE to trigger sweep
        while ~(strcmp(sscanf(query(inst,'RS'),'%*s%*s%*s%s*'), 'HOLDING')) % WAIT FOR RAMP TO FINISH
          pause(0.1);
          ramp_status=sscanf(query(inst,'RS'),'%*s%*s%*s%s*'); 
          if strcmp(ramp_status,'QUENCH') 
            error(query(inst,'RS')); 
          end
        end
        if sscanf(query(inst,'GO'),'%*s%*s%f*') ~= val
         flushinput(smdata.inst(ico(1)).data.inst); % precautionary
        dir_positive_flag = strcmp(sscanf(query(inst,'GS'),'%*s%*s%*s%s*'),'POSITIVE');
        val_positive_flag = sign(val) >= 0;
        if dir_positive_flag ~= val_positive_flag
          if dir_positive_flag
            sgn_str = '-';
          else
            sgn_str ='+';
          end
          fprintf(inst,['D',sgn_str]);
        end
          query(inst,['S% ',num2str(val)]);                 % RESET TARGET
          fprintf(inst,['R% ',num2str(val)]);                 % SWEEP 
        end
        while ~(strcmp(sscanf(query(inst,'RS'),'%*s%*s%*s%s*'), 'HOLDING')) % WAIT FOR RAMP TO FINISH
          pause(0.1);
          ramp_status=sscanf(query(inst,'RS'),'%*s%*s%*s%s*'); 
          if strcmp(ramp_status,'QUENCH') 
            error(query(inst,'RS')) 
          end
        end
        query(inst,'H0');                                 % HEATER OFF
        pause(heater_wait_time);                         % WAIT FOR SWITCH TO GO NORMAL
        query(inst,['SR ',num2str(lead_ramp_rate)]);           % SET LEAD_RATE
        fprintf(inst,'R0%%');                              % RAMP LEADS BACK TO ZERO
        ramp_status = sscanf(query(inst,'RS'),'%*s%*s%*s%s*');  % WAIT FOR RAMP TO FINISH
        while ~(strcmp(ramp_status, 'HOLDING')) 
          pause(0.1);
          ramp_status=sscanf(query(inst,'RS'),'%*s%*s%*s%s*'); 
          if strcmp(ramp_status,'QUENCH') 
            error(query(inst,'RS')) 
          end
        end
%         %       These two lines are not necessary but mean the display shows
%         %       the last sweep rates and values
%         query(inst,['S% ',num2str(val)])                 % SET NEW TARGET
%         query(inst,['SR ',num2str(rate)])                % SET RAMP RATE
%         %
    end

  case 0 % read B field
    % read output directly or from persisted field record
    if strcmp(sscanf(query(inst,'H'),'%*s%*s%*s%s*'),'ON')
      val = sscanf(query(inst,'GO'),'%*s%*s%f*'); % (G)ET (O)UTPUT 
    else
     val = sscanf(query(inst,'GP'),'%*s%f'); % GET PERSISTANT FIELD
    end
    
  otherwise
    error('Operation not supported');
  
end
