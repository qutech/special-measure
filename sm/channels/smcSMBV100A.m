function [val, rate] = smcSMB100A(ico, val, rate, varargin)
global smdata

switch ico(3)
    case 0
        switch ico(2)
            case 1
                val = query(smdata.inst(ico(1)).data.inst, 'FREQ?');
                val = str2double(val);
            case 2
                val = query(smdata.inst(ico(1)).data.inst, 'POW?');
                val = str2double(val);
            case 3
                val = query(smdata.inst(ico(1)).data.inst, ':OUTP:STAT?');
                val = str2double(val);
        end
        
    case 1
        switch ico(2)
            case 1
                fprintf(smdata.inst(ico(1)).data.inst, 'FREQ:MODE CW');
                fprintf(smdata.inst(ico(1)).data.inst, 'FREQ %f', val);
            case 2
                fprintf(smdata.inst(ico(1)).data.inst, 'POW %.1f', val);
            case 3
                if val
                    fprintf(smdata.inst(ico(1)).data.inst, ':OUTP:STAT ON');
                else
                    fprintf(smdata.inst(ico(1)).data.inst, ':OUTP:STAT OFF');
                end
        end
    otherwise
        error('Operation not supported')
        
end

