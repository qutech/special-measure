 function [val, rate] = smcE5071C(ico, val, rate)
% driver for AgilentE5071C 
% usage smcE5071C([ico(1) ico(2) ico(3)] val, rate) rate is just a +/- flag
% Inst response to FreqStop is sweeptime in seconds.
%           ico(1): instrument number (eg physical inst 1, 2, 3...)
%           ico(2): channel on instrument eg 1 = FreqSweep, 2= POWSweep. See below(GUIDE TO ioc(2) COMMANDS).
%           ico(3):  0=read/1=write/2=?/3=trig/4=bufferreset/5=sweepsetup. 
% written by mcneil@physik.rwth-aachen.de
% GUIDE TO ico(2) COMMANDS
% Case   Name(Alt func)         Permissible values
%  1     FREQSWEEP      % ramped freq sweep (+ve rate  = start freq, -ve rate = stop freq at given rate.)
%  2     POWSWEEP       % ramped power sweep
%  3     CW FREQ                   For power sweeps  300kHz-20GHz                  
%  4     POW                    For freq sweeps -85 to 10dBm (out of range values are followed but clip at limits)
%  5     DATA                   Read a scan from Inst, this driver only allows reading data from instrument (though Inst does support writing data)
%  6     SPARAM -parameters       1:4 = 'S11', 'S12', 'S21', 'S22' (NOTE: string values)
%  7     IFBW Bandwidth           (1|1.5|2|3|4|5|7)*1,10,100,1k,10k to 500kHz 
%  8     IDATA                  Imaginary part of S parameters. Must be read after REAL part!    
%  9     Num swp points         2-20001 (default is 2-1601) see: http://ena.tm.agilent.com/e5071c/manuals/webhelp/eng/measurement/setting_measurement_conditions/setting_channels_and_traces.htm 
%  10    STARTF
%  11    STOPF
%  12    SWPTYPE            1:4 =  'LIN', 'LOG', 'SEGM', 'POW' (Note no attempt (yet) to support LOG and SEGM)
%  13    CNTRFREQ
%  14    SPANFREQ
% NOTE: if rate (ico,val,rate) is positive val = StartFreq, if rate is negative val = StopFreq.

global smdata;  % make the struct smdata available 
persistent tmp; % will hold imaginay data.

% TO DO/CHECK LIST
% Sensible behaviour for negative sweep rates (i.e. just take modulus of sweep rate as all sweeps are under instrument control.)
% Case 9 expand Num points to full range
% confirm all input-output is numeric only
% consider 'other plots' i.e. polar
% ico(3) case 5 only sets one set of parameters (the most useful ones) but
% Should accept other options with missing values being default 


% List of commands kept for reference 
%  ':SENS:FREQ:STAR', ':SENS:FREQ:STOP', ':SENS:FREQ:SPAN',...
%  ':SOUR:POW', ':CALC:PAR:DEF', ':SENS:SWE:TYPE',...
%  ':SENS:SWE:POIN', ':SENS:BAND', ':CALC:DATA:FDAT',  ':SENS:FREQ:CENT';

if nargin<3
    rate=1000;
end
    

% SWEEP TYPE list for str/num conversion
SWEEP_TYPE = {'LIN', 'LOG', 'SEGM', 'POW'};
switch ico(3)   % which driver function to perform,...
%                  0 read val, 1 write val, 2 ?, 3 trigger sweep, 4 clear buffer, 5 setup buffered acquisition
    case 0      % read from an inst 'sub channel'
        switch ico(2) 
            case {1,2}
                error('not a read-back channel, use channel 5 to read DATA.');
            
            case 3 % read CW Freq (for POW sweep)
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ?');
                val = str2double(val);
            case 4 % read POW (for Freq sweep)
                val = query(smdata.inst(ico(1)).data.inst, ':SOUR:POW?');
                val = str2double(val);
               
            case 5  %reading Re(x) data DATA (i.e Re(x) +Im(y))
                %freq_range = [query(smdata.inst(ico(1)).data.inst, sprintf('%s?', cmds{1}),'%s\n', '%f') query(smdata.inst(ico(1)).data.inst, sprintf('%s?', cmds{2}),'%s\n', '%f')];
               
                %x_freq = (0:n_points-1)*((freq_range(2)-freq_range(1))/n_points)+freq_range(1);
                %val = query(smdata.inst(ico(1)).data.inst, ':CALC:DATA:FDAT?'); % Request formatted data
                %val = sscanf(val, '%f,', [2 smdata.inst(ico(1)).datadim(5)]);    % read data as float into 2x2n_points array
                %val(2, :) = [];
                % use fread, !!
                % avoid reading zeros?
                pause(smdata.inst(ico(1)).data.WaitBeforeRead); % seems to be needed to get fresh data. Experimentally/empirically determined.
                fprintf(smdata.inst(ico(1)).data.inst, ':CALC:DATA:FDAT?'); 
                
                nbyte = sscanf(char(fread(smdata.inst(ico(1)).data.inst, ...
                    sscanf(char(fread(smdata.inst(ico(1)).data.inst, 2, 'char'))','%*c%d'), 'char')), ...
                    '%d');
                
                % instrument data format - binary largest sig byte. LittleEndian
                
                %val = fread(smdata.inst(ico(1)).data.inst, 2 * smdata.inst(ico(1)).datadim(5), 'single'); 
                val = fread(smdata.inst(ico(1)).data.inst, nbyte/4, 'single'); 
                fread(smdata.inst(ico(1)).data.inst, 1);  % clear the \n character
                
                
                
                tmp = val(2:2:end);
                val(2:2:end) = []; % clears the imaginary zeros
                
            case 8
                if size(tmp) == 0
                    warning('real DATA (case 5) must be requested before each call for imaginary DATA (case 8)')
                end
                val = tmp;
                tmp = []; % tidying up to prevent recall of old data. 
                
            case {6} %Reading the S-parameter setting
               val = query(smdata.inst(ico(1)).data.inst, ':CALC:PAR:DEF?');
               val = str2double(val(2:3)); 
%               can also use find(strcmp(str to match, str to look through))  

            case 7
               val = query(smdata.inst(ico(1)).data.inst, ':SENS:BAND?');
               val = str2double(val);
            
            case 12
%                 SENSe(Ch).SWEep.TYPE

               val = query(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TYPE?');
               val = find(strcmp(val(1:end-1), SWEEP_TYPE));
          
            case 9 % set #points
               val = query(smdata.inst(ico(1)).data.inst, ':SENS:SWE:POIN?');
               val = str2double(val);
            
            case 10 % Read back start freq (full version of a query command)
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STAR?');
                val = str2double(val);
            case {11} % Read back stop freq (minimal version of query command)
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STOP?');
                val = str2double(val);
            case {13}
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:CENT?');
                val = str2double(val);
            case {14}
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:SPAN?');
                val = str2double(val);
            otherwise
               error('Read options are 3-11.')
        end
     
    case 1      % write to instrument [ico(3)]
        switch ico(2)   % channel that will be written to
            case 1  % frequency sweep
                if rate > 0 % set start freq
                        fstop = query(smdata.inst(ico(1)).data.inst, sprintf(':SENS:FREQ:STOP?'),'%s', '%f');
                        % sanity check for order of freq sweep endpoints
                        if fstop <= val
%                            set FREQ:STOP to new FREQ:START - to suppress
%                            error however FREQ:STOP will probably get over
%                            written immediately.
                             fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STOP %f',val);
                        end
                   fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STAR %f', val);
                   % return value is fstart
%                    val = val;
                    %STARTFREQ has been set                    
%                 elseif rate == 0
%                     error('please specify a non-zero rate')
                   val = 0;
                   
                else    % rate <=0, set stop freq and sweep rate
                    % start freq will be what it was before, unless stopfreq < starfreq.
                    fstart = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STAR?', '%s', '%f');
                    %    if fstart >= val
                    %       error('Stop freq (%s Hz) must be greater than %s Hz. Value not set.',num2str(val),num2str(fstop))
                    %    end
                    fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STOP %f', val);
                    
                    % Alternative: Set sweep time here
                    %swp_time = (val-fstart)/abs(rate)
                    %fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TIME:AUTO 0');    
                    %fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TIME %f', swp_time);
                    
                    % return value is sweep time        
                    val = query(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TIME?', '%s\n', '%f');
                end
                
                
            case 2
                %same for power
%               if rate positive set start pow = val
            fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TYPE POW');
            if rate > 0
                    % insert possible sanity check here
                    fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:POW:STAR %f', val);
            else % rate is negative set stop freq and rate 
                    fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:POW:STOP %f', val);
                    % set rate querying POW start
%                     pstop = val; pstart = query(smdata.inst(ico(1)).data.inst, ':SOUR:POW:STAR?','%s\n', '%f');
                    %swp_time = smdata.inst(ico(1)).datadim(5)/abs(rate);
                    %fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TIME %f', swp_time);
                    %val = swp_time;
    % return value is sweep time        
                    val = query(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TIME?', '%s\n', '%f');                  
                    
            end
                
            case 3 % set CW Freq (for POW sweep)
                fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FREQ %f', val);
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ?');
                val = str2double(val);                
            case 4 % set POW (for Freq sweep)
                fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:POW %f', val);
                val = query(smdata.inst(ico(1)).data.inst, ':SOUR:POW?');
                val = str2double(val);        
            case 5 %Writing data to instrument
                error('Driver does not permit writing on this instrument, please use paper instead.');

            case 6 % setting In/Out ports
                if any(val == [11, 12, 21, 22])
                fprintf(smdata.inst(ico(1)).data.inst, ':CALC:PAR:DEF S%02d\n', val);
                else
                    error('specify 11, 12, 21 or 22 only (with no "S")')
                end
              
            case 7 % set IF bandwidth
               fprintf(smdata.inst(ico(1)).data.inst, ':SENS:BAND %f', val); 
               val = query(smdata.inst(ico(1)).data.inst, ':SENS:BAND?'); 
               
            case 8 % Sweep type
%                 Add check for LOG freq range, 2octave span minimum 
%                 to permit sweeping. give user error msg and abort if not so.
            switch val
                case 3
                    error('driver does not (yet) support SEGM sweeps')
                case {1, 2, 4}
               fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TYPE %s', SWEEP_TYPE{val});
               val = query(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TYPE?');
               val = find(strcmp(val(1:end-1), SWEEP_TYPE))             ;               
            end
            case 9 % set #points
                fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:POIN %d', val); 
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:SWE:POIN?');
                smdata.inst(ico(1)).datadim(5) = str2double(val);

             case {10} % set start freq 
                fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STAR %f', val);
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STAR?');
             case {11} % set stop freq 
                fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STOP %f', val);
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STOP?');
            case {13}
                fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:CENT %f', val);
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:CENT?');
            case {14}
                fprintf(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:SPAN %f', val);
                val = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:SPAN?');
            otherwise
                error('write options are currently 1:4, 6, 7, 9-11')
        end
    case 2 % unused
        % no function performed
    case 3
        %trigger
        
        fprintf(smdata.inst(ico(1)).data.inst, ':TRIG:SEQ:IMM');
        
        % This needs testing to ensure desired operation, calling ico
        % operation 3 should set an immediate trigger but leave the
        % instrument in a "waiting, non measuring state"

    case 4 % can be used to clear buffer and reset state if needed
        % not implemented as instrument does not appear to need it. 
                
    case 5

        if ico(2) ~= 5
            error('Can only configure channel DATA.')
        end
        
        % 32 bits enough? !!
        % set binary transfer {ASCii|REAL|REAL32}={ASCII|binary-64|binary-32}
        fprintf(smdata.inst(ico(1)).data.inst, ':FORM:DATA REAL32'); 
%       Alternative version of above line
%       fprintf(smdata.inst(ico(1)).data.inst, ':FORM:DATA ASC'); 

%       set single sweep on BUS trigger
%         fprintf(smdata.inst(ico(1)).data.inst, ':TRIG:SEQ:SOUR BUS');
%       fprintf(smdata.inst(ico(1)).data.inst, ':TRIG::EXT:DEL');        % can set a trig delay
        
        %set lin sweep
        fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TYPE LIN');
        
        fprintf(smdata.inst(ico(1)).data.inst, ':FORM:BORD SWAP');
        % switch off averaging


        % set sweep time
        %        fstart = query(smdata.inst(ico(1)).data.inst, ':SENS:FREQ:STAR?', '%s', '%f');  % read start freq then...
        %        if (fstart >= val)      % check for freq start/stop order
        %            error('check your target freq, should be > than start freq')
        %        end
        fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TIME:AUTO 0');
        %fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TIME %f', (val-fstart)/rate);
        fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:TIME %f', val/rate);
        
        fprintf(smdata.inst(ico(1)).data.inst, ':SENS:SWE:POIN %d', val);             
        smdata.inst(ico(1)).datadim(5,:) = val;
        smdata.inst(ico(1)).datadim(8,:) = val;
        
    otherwise
        error('Operation not supported');
end


%% SCPI GPIB commands
% display commands :DISP:SPLit d1; d1 = full display d12 = vertical split screen etc

