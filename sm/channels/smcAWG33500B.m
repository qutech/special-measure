function [val, rate] = smcAWG33500B(ic, val, rate, ctrl)
% [val, rate] = smcAWG33500B(ic, val, rate, ctrl)
% Functions: 0 -> sin, 1 -> square, 2 -> triangle, -1 -> unknown (can do more but not
% implemented)

global smdata;


switch ic(2) % Channel
    case 1
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'SOUR1:FUNC?', '%s\n', '%s');
                if(strcmp(val, 'SIN'))
                    val = 0;
                elseif(strcmp(val, 'SQU'))
                    val = 1;
                elseif(strcmp(val, 'TRI'))
                    val = 2;
                else
                    val = -1;
                end
            case 1 % set
                if(val == 0)
                    val = 'SIN';
                elseif(val == 1)
                    val = 'SQU';
                elseif(val == 2)
                    val = 'TRI';
                else
                    error('Function not known!');
                    return;
                end
                fprintf(smdata.inst(ic(1)).data.inst, 'SOUR1:FUNC %s', val);
            case 6
                error('Operation not supported');
        end     
    case 2
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'SOUR2:FUNC?', '%s\n', '%s');
                if(strcmp(val, 'SIN'))
                    val = 0;
                elseif(strcmp(val, 'SQU'))
                    val = 1;
                elseif(strcmp(val, 'TRI'))
                    val = 2;
                else
                    val = -1;
                end
            case 1 % set
                if(val == 0)
                    val = 'SIN';
                elseif(val == 1)
                    val = 'SQU';
                elseif(val == 2)
                    val = 'TRI';
                else
                    error('Function not known!');
                    return;
                end
                fprintf(smdata.inst(ic(1)).data.inst, 'SOUR2:FUNC %s', val);
        end  
    case 3
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'SOUR1:VOLT?', '%s\n', '%f');
            case 1 % set
                fprintf(smdata.inst(ic(1)).data.inst, 'SOUR1:VOLT %f', val);
        end
    case 4
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'SOUR2:VOLT?', '%s\n', '%f');
            case 1 % set
                fprintf(smdata.inst(ic(1)).data.inst, 'SOUR2:VOLT %f', val);
        end
    case 5
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'SOUR1:FREQ?', '%s\n', '%f');
            case 1 % set
                fprintf(smdata.inst(ic(1)).data.inst, 'SOUR1:FREQ %f', val);
        end
    case 6
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'SOUR2:FREQ?', '%s\n', '%f');
            case 1 % set
                fprintf(smdata.inst(ic(1)).data.inst, 'SOUR2:FREQ %f', val);
        end
    case 7
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'SOUR1:PHAS?', '%s\n', '%f');
            case 1 % set
                fprintf(smdata.inst(ic(1)).data.inst, 'SOUR1:PHAS %f', val);
        end   
    case 8
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'SOUR2:PHAS?', '%s\n', '%f');
            case 1 % set
                fprintf(smdata.inst(ic(1)).data.inst, 'SOUR2:PHAS %f', val);
        end
    case 9
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'OUTP1:LOAD?', '%s\n', '%f');
            case 1 % set
                
        end
    case 10
        switch ic(3)
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, 'OUTP2:LOAD?', '%s\n', '%f');
            case 1 % set
                
        end
        
    otherwise 
        error('Operation not supported');
end