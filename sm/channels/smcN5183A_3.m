function val = smcN5183A_2(ico, val, rate)
%
% in use currently
%
% function val = smcN5183A(ico, val, rate) val in Hz(dBm), rate in Hz/s(dBm/s) 
% driver for Agilent N8183A MXG Analog signal generator
% GUIDE TO ico(2) COMMANDS
% Pos    Name(Alt func)         additional information
%  1     FREQ                   100kHz - 20GHz FREQ:STOP in STEP mode, 
%                               for CW:MODE set FREQ:STAR = FREQ:STOP
%                               -val: FREQ:STARt +val: FREQ:STOP
%  2     POW                    -20dBm - 15dBm 
%                               -rate: POW:Start, +rate: POW:stop 
%                               [NOTE: NON-STANDARD USE OF -ve RATE!]
%                               To indicate a self ramped power-only 
%                               sweep use Freq rate with fixed frequency.
%  3     OUTPut:STATe           1/0 

% Instrument permits simultaneous freq and pow sweeps but not implemented in this
% driver. Pulsing (UNW) also not implemented.
% written by mcneil@physik.rwth... & stefanie.tenberg@rwth...

global smdata;  % make the struct smdata available
% warning('ToDO: +/- selectrion in ico(3) = 0 FREQ:readout \n interputed sweeeps')

% ic/ico[1:3] = instrument control. 
%           ic(1) = inst number (eg physical inst 1, 2, 3 not channel num)
%           ic(2) = inst 'sub channel' eg 1 = Freq, 2= POW. See full list below.
%           ic(3) = read/write/?/trig/reset/other. 
%           0 = read value(s) from channel, 1 = write value(s)to channel, 
%           2 = ?, 3 = trigger channel to start (eg a freq sweep), 
%           4 = reset buffer ready to read new data, 5 = 'other'
%           instrument specific operations, (a general 'extras' option.)
% val = value to be assigned to inst 'sub channel' [ignore if read operation]
% rate = rate of change to/from 'val' [optional?]

% :LIST:SWE:TIME 1e-6 s
%Option Narrow Pulse Modulation (UNW)
%  14  :PULM:INTernal:PERiod    Pulse Period
%  15  :PULM:INTernal:FREQuency ??? (used for internallzý generated square wave)
%  16  :PULM:INT:PWIDth         Pulse Width   (used for doublet and adoublet pulses)
%  17  :PULM:SOURce             source of the pulse modulation, INTernal or EXTernal
%  18  :PULM:Source:INTernal    internal inputs: SQUare|FRUN|TRIGgered|ADOublet|DOUBlet|GATEd
%  19  :PULM:STATe              Modulation ON 1 or OFF 0
%TRIGGER MISSING!
%Pulse mode??

% cmds = {'FREQ:MODE', 'LIST:TYPE', 'FREQ:STAR', 'FREQ:STOP',...
%         'SWE:POIN', ':POW:LEV', 'LIST:FREQ', 'FREQ:CW',...
%         'SWE:DWEL', 'INIT:CONT', 'INIT', 'OUTP:STAT'};

inst = smdata.inst(ico(1)).data.inst;
if nargin<3 && ~exist('rate') % if not rate specified use default rate drate 
%   for i=1:length(smdata.channels)
%      if find(smdata.channels(i).instchan(1),ico(1))==1
%        
%   end
  switch ico(2)
    case {1}
      rate=smdata.inst(ico(1)).data.drateFreq; 
    case {2}
      rate=smdata.inst(ico(1)).data.dratePow;   
  end
end

switch ico(3)   % which driver function to perform 
    case 0      % read from an inst 'sub channel'
        switch ico(2) 
            case {1} % FREQ 
                if strcmp(sscanf(query(inst,'LIST:TYPE?'),'%s*'),'STEP')
                        str = sscanf(query(inst,'LIST:RETR?'),'%s*');
                    if strcmp(str,'1')
                        val=sscanf(query(inst,'FREQ:STAR?'),'%f'); % FREQ:STARt
                    elseif strcmp(str,'0')
                        val=sscanf(query(inst,'FREQ:STOP?'),'%f'); % FREQ:STOP
                    else
                        error('error reading LIST:RETR, "%s"',str);
                    end
%   FUTURE CW USE    elseif strcmp(sscanf(query(inst,'FREQ:MODE?'),'%s*'),'CW')
%   FUTURE CW USE    val=sscanf(query(inst,'FREQ:CW?'),'%f'); %CW
                 else
                     error('only :STEP mode allowed (CW|LIST not supported) check initialisation options');
                 end
            case {2} % POW
                 strmode = sscanf(query(inst,'POW:MODE?'),'%s*');
                 if strcmp(strmode,'LIST')
                     str = sscanf(query(inst,'LIST:RETR?'),'%s*');
                     if strcmp(str,'1')
                         val=sscanf(query(inst,'POW:STAR?'),'%f'); % FREQ:STARt
                     elseif strcmp(str,'0')
                         val=sscanf(query(inst,'POW:STOP?'),'%f'); % FREQ:STOP
                     else
                         error('error reading LIST:RETR "%s"',str);
                     end
                     % insert CW friendly POW: code here.
                 elseif strcmp(strmode,'FIX')
                     val=sscanf(query(inst,'POW?'),'%f');
                 else
                     error('unsupported POW mode, "%s"',strmode);
                 end
            case {3}
                val=sscanf(query(inst,'OUTPUT?'),'%i'); % OUTPUT ON/OFF
            otherwise
                error('read options are 1-3 only')
        end
        
    case 1      % write to an inst 'sub channel'
%         dwellTime = smdata.inst(ico(1)).data.dwelltime;
        switch ico(2) 
            case {1} % FREQ dwell [100us min], set in smdata.inst.data.dwelltime,
                PntTime = smdata.inst(ico(1)).data.pnttime;
                Fstop = sscanf(query(inst,'FREQ:STOP?'),'%f');

                if val>0 % setting FREQ:STOP
                    Fstart = smdata.inst(ico(1)).cntrlfn([ico(1) 1 0]); % read expected current freq value
                    fprintf(inst,'FREQ:STARt %f',Fstart);
                    fprintf(inst,'FREQ:STOP %f',abs(val));
                    Fstop=sscanf(query(inst,'FREQ:STOP?'),'%f');
                else % val<=0 setting FREQ:START
                    fprintf(inst,'FREQ:STARt %f',abs(val));
                    Fstart=sscanf(query(inst,'FREQ:STARt?'),'%f');
                end
                
                if smdata.inst(ico(1)).data.sweepdir == 0
                  fprintf(inst,'LIST:DIR UP');
                else
                  fprintf(inst,'LIST:DIR DOWN');
                end
                        
                Frng = range([Fstart Fstop]); % a zero range will give a sweep of 2 points, should be fine
                FswpTime = Frng/abs(rate);
                Fpnts = floor(FswpTime/PntTime);
                
                if abs(smdata.inst(ico(1)).data.npnts) > 0
                  Fpnts = smdata.inst(ico(1)).data.npnts;
                else
                  Fpnts = min(max(Fpnts,2),2^16-1);
                end
                
                PntDwell = FswpTime/Fpnts;
                fprintf(inst,'TRIG:TIMer %f',PntTime); % hack: Tim
%                 fprintf(inst,'TRIG:TIMer %f',PntDwell);
                fprintf(inst,'SWEep:POINts %i',Fpnts);
                val = PntTime*Fpnts; % return total SweepTime
                
                if rate > 0
                  fprintf(inst,'TRIG:SOURCE IMM'); 
                  fprintf(inst,'INIT:CONT 1'); % cont swp
                  smdata.inst(ico(1)).cntrlfn([ico(1) 1 3],0,0); % immediately sweep
                else
                  fprintf(inst,'TRIG:SOURCE EXT'); 
                  fprintf(inst,'INIT:CONT 0'); % one swp 
                  fprintf(inst,'TSWeep');
                  fprintf(inst,'INIT'); % arm
                end
                
            case {2} % POW max ramp rate 2ms settle time, res 0.01dBm
                if rate>0 % immediate setting of POW in LIST:FIX mode
                    fprintf(inst,sprintf('POW %f DBM',val)); % CW code
                    val=sscanf(query(inst,'POW?'),'%f');
                elseif rate <= 0
                    Fstop = sscanf(query(inst,'FREQ:STOP?'),'%f');
                    Fstart = sscanf(query(inst,'FREQ:STAR?'),'%f');
                    AmpList = sscanf(query(inst,'LIST:POW?'),'%f');
                    if range(Fstart,Fstop) ~= 0
                        warning(sprintf(['driver does not support simultaneous freq and amp swps\n',...
                            'amp set to %fdBm,\n',...
                            'freq swp is %f - %f GHz\n',...
                            'set a zero freq range and retry amp swp(*).'],min(AmpList,val),Fstart,Fstop))
                        fprintf(inst,sprintf('POW %f DBM',val)); % CW code
                        val=sscanf(query(inst,'POW?'),'%f');
                    else % clever power sweep
                       
                warning(sprintf(['(*)Amp sweeps not yet implemented.','\n',...
                                'Please supply Steffi or Rob with lots of \n',...
                                'coffee and/or biscuits and smile sweetly.']))
                val = nan;
                    end
                    
                    
                end
            case {3} % OUTPut:STATe
                if val == 1 || val == 0
                    
                    fprintf(inst,sprintf('OUTP:STATE %i',val));
                    val=sscanf(query(inst,'OUTPUT?'),'%i');
                else
                    error('OUTPut:STATe values are [0|1]');
                end
            otherwise
                error('write options are 1-3')
        end
        
    case 3   %trigger
            fprintf(inst,'TSWeep'); % (aborts any running sweeps) and rearms
            fprintf(inst,'INIT');    
            fprintf(inst,'TRIG'); % forces an immediate trigger
            val = 0;
%            in BUS|EXT|KEY 'INIT' only arms the source


    
    case 4     %Arm (Trigger Modes)
%              fprintf(inst,'INIT'); % arm         
%           if val==1
            fprintf(inst,'TRIG:SOURCE EXT');
            fprintf(inst,'INIT'); 
            val =0;
%           else
%                error('unknown mode for the sweep trigger [0 auto|1ext]');
%           end        
    case 6 % most of these are defult settings but collected here for edification or in case they need changing
        PntTime = smdata.inst(ico(1)).data.pnttime;
        fprintf(inst,'OUTP:MOD OFF');
        fprintf(inst,'UNIT:POW DBM'); % ensures dBm power units
        fprintf(inst,'OUTPut:BLANKing:AUTO 1'); % blanks output during freq band changes, (avoids spikes)
        fprintf(inst,'OUTPut:BLANKing:STATe 0'); % if possible does not blank output during freq changes
        fprintf(inst,'FREQ:MODE LIST'); % [not default] 
%         fprintf(inst,'POW:MODE LIST'); % [not default]
        fprintf(inst,'LIST:TYPE STEP'); % [not default] 
        fprintf(inst,'INIT:CONT 1'); % one swp per trigger pulse
        fprintf(inst,'LIST:RETR %i',smdata.inst(ico(1)).data.retrace); 
        fprintf(inst,'TRIG:FSW:SOUR SING'); % single trace per trig event
        fprintf(inst,'TRIG:SLOPe NEG'); % trig on falling edge
        fprintf(inst,'TRIG:TIM %f',PntTime'); % fixes npnts/s
         fprintf(inst,'TRIG:SOURCE EXT'); 
         fprintf(inst,'LIST:TRIG:SOURCE TIM'); 
        display('Init complete');
        val = 0;
        
    otherwise
        error('Operation not supported');
end

%%
% useful commands
% function out = issweeping
%     out = 1;
% if ...
% bitand(query(smdata.inst(7).data.inst, sprintf('STAT:OPER:COND?'),'%s\n', '%i'),2^3) ~= 0 &&... % sweeping
% bitand(query(smdata.inst(7).data.inst, sprintf('STAT:OPER:COND?'),'%s\n', '%i'),2^5) ~= 0; % waiting for trigger
% out = 0;
% end
% 
% 
% % query
% strcmp(sscanf(query(inst,'FREQ:MODE?'),'%s*'),'CW')
% % write
% fprintf(inst,'FREQ:MODE CW');
% 
% [:SOURce]:SWEep:SPACing LINear|LOGarithmic
% % TRIG:SOUR IMM|EXT
% % The  maximum  number  of  list  sweep  points  is  3,201.
