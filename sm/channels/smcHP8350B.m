function val = smcHP8350B(ic, val, rate, varargin)
% 1: freq, 2: power
% units are Hz and dBm

global smdata;

% 1  CW  CWFreqency 
% 2  PL  PowerLevel 
% 3  FA  FreqStart
% 4  FB  FreqStop
% 5  RF  RFon/off
% 6  TS  TakeSweep
% 7  T3  External Sweep Trigger
% 8  T4  Single Sweep
% 9  ST  Sweep Time
% 10 SX  External Sweep (via front or back BNC connection)
cmds = {'CW', 'PL', 'FA', 'FB', 'RF', 'TS', 'T3', 'T4', 'ST', 'SX'};
units = {'HZ', 'DM', 'HZ', 'HZ', '', '', '', '', 'SC', ''};

switch ic(3)
    case 0
        val = query(smdata.inst(ic(1)).data.inst,...
            sprintf('OP %s', cmds{ic(2)}), '%s\n', '%f');
    
    case 1
        switch ic(2)
            case 5 %check for on/off operation
                fprintf(smdata.inst(ic(1)).data.inst,...
                    sprintf('%s%i', cmds{ic(2)}, val));
            
            otherwise
                fprintf(smdata.inst(ic(1)).data.inst,...
                    sprintf('%s %f %s', cmds{ic(2)}, val, units{ic(2)}));
        
        end
        
    case 3
        % do software triggering for now; switch to hardware later (Manual
        % 3-22); done (NIDAQmx)
        fprintf(smdata.inst(ic(1)).data.inst, sprintf('TS'));
        
    %case 5
    
    otherwise
        error('Operation not supported');
end

