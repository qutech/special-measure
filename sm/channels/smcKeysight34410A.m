function [val, rate] = smcdmm(ico, val, rate)
% driver for Agilent DMMs with support for buffered readout.
% mainly configured for voltage readings; needs small additions here and
% there for other modes
global smdata;

switch ico(2) % channel
    case 1
        switch ico(3)
            case 0 %get
                val = query(smdata.inst(ico(1)).data.inst, 'READ?', '%s\n', '%f');

            otherwise
                error('Operation not supported');
        end
        
    case 2
        switch ico(3)
            case 0
                % this blocks until all values are available
                val = sscanf(query(smdata.inst(ico(1)).data.inst,  'FETCH?'), '%f,')';

            case 3 %trigger
                pause(smdata.inst(ico(1)).data.trigDelay);
                trigger(smdata.inst(ico(1)).data.inst);
                
            case 4 % arm instrument
                fprintf(smdata.inst(ico(1)).data.inst, 'INIT');
                
            case 5 % configure instrument                    
                % set range
                fprintf(smdata.inst(ico(1)).data.inst, 'SENS:VOLT:RANG:AUTO 0');
                fprintf(smdata.inst(ico(1)).data.inst, 'SENS:VOLT:RANG %i',...
                    smdata.inst(ico(1)).data.vrng);

                % possible nplc with the 34410A
                % {0.006|0.02|0.06|0.2|1|2|10|100}
                % MIN = 0.006 PLC, 
                % MAX = 100 PLC
                bNplc = isfield(smdata.inst(ico(1)).data, 'nplc') && ...
                     ~isempty(smdata.inst(ico(1)).data.nplc);
                if bNplc
                    nplc = smdata.inst(ico(1)).data.nplc;
                    fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:NPLC %f', nplc);
                    fprintf(smdata.inst(ico(1)).data.inst, 'CURR:NPLC %f', nplc);
                    maxrate = ...
                        50*str2double(query(smdata.inst(ico(1)).data.inst, 'VOLT:NPLC?'));
                end
                
                % possible apertures with the 34410A
                % ~100 µs to ~1 s (with ~20 µs resolution).
                % MIN = ~100 µs, MAX = ~1 s
                bAper = isfield(smdata.inst(ico(1)).data, 'aper') && ...
                     ~isempty(smdata.inst(ico(1)).data.aper);
                if bAper
                    aper = smdata.inst(ico(1)).data.aper;
                    fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:APER:ENAB ON');
                    fprintf(smdata.inst(ico(1)).data.inst, 'CURR:APER:ENAB ON');
                    fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:APER %f', aper);
                    fprintf(smdata.inst(ico(1)).data.inst, 'CURR:APER %f', aper);
                    maxrate = ...
                        1/str2double(query(smdata.inst(ico(1)).data.inst, 'VOLT:APER?'));
                end
                
                if bAper && bNplc
                    warning('Both aperture and nplc are set. Took aperture for determination of integration time.')
                end
                
                fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:SOUR IMM');
                if rate > maxrate
                    rate = maxrate;
                    warning('Rate set to maxrate.')
                end
                
                delay = 1/rate - 1/maxrate;
                fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:DEL %f', delay);
                
                % hardcoded for 34410A
                if val > 50000
                    error('More than allowed number of samples requested. Correct and try again!\n');
                end
                fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:SOUR BUS');
                fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:COUN %i', 1);
                fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:COUN %d', val);
                smdata.inst(ico(1)).datadim(2,1) = val;
                                
            otherwise
                error('Operation not supported');
        end
end