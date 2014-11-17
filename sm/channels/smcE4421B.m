function [val, rate] = smcE4421B(ico, val, rate)
% function [val, rate] = smcE4421B(ico, val, rate)
global smdata
obj = smdata.inst(ico(1)).data.inst;
fprintf(obj, ':OUTP ON');
MIN_FREQ = 250e3;
MAX_FREQ = 3e9;
NUM_POINTS = 401;

switch ico(3)
    case 0
        switch ico(2)
            case 1
                val = str2double(query(obj, ':FREQ?'));
            case 2
                val = str2double(query(obj, ':POW?'));
        end
        
    case 1
        switch ico(2)
            case 1
                fprintf(obj, ':FREQ:MODE CW');
                fprintf(obj, [':FREQ ',...
                    sprintf('%i', max( min(val, MAX_FREQ), MIN_FREQ)),'HZ']);
            case 2
                fprintf(obj, [':POW ', sprintf('%i', val),'DBM']);
            case 3 %program sweep
                if rate >= 0
                    fprintf(obj,...
                        [':FREQ:STAR ', sprintf('%i', max(val, MIN_FREQ)), 'HZ']);
                    val = 0;
                elseif rate < 0
                    fprintf(obj,...
                        [':FREQ:STOP ', sprintf('%i', min(val, MAX_FREQ)), 'HZ']);
                    fprintf(obj, ':FREQ:MODE LIST');
                    fprintf(obj, ':LIST:MODE AUTO');
                    fprintf(obj, ':LIST:TYPE STEP');
                    fprintf(obj, ':LIST:DIR UP');
                    fprintf(obj, ':LIST:TRIG:SOUR IMM'); % IMM|EXT|KEY
                    fprintf(obj, [':SWE:POIN ', sprintf('%i', NUM_POINTS)]);
                    rate = rate / (str2double(query(obj, ':FREQ:STOP?')) - ...
                        str2double(query(obj, ':FREQ:STAR?')))*NUM_POINTS;
                    fprintf(obj, [':SWE:DWEL ', sprintf('%f', abs(1/rate))]);
                    val = 1/rate;
                end
                                               
            case 4 %do sweep inversely
                fprintf(obj, ':LIST:DIR DOWN');
            
        end
        
    case 3
        switch ico(2)
            case 3 %trigger programmed sweep
                %fprintf(obj, ':TRIG:SOUR BUS'); % IMM|EXT|KEY
                fprintf(obj, ':INIT');
                pause(3)
                fprintf(obj, ':TRIG');
        end
        
    otherwise
        error('Operation not supported')
end