function [val, rate] = smcSR830(ic, val, rate)
% [val, rate] = smcSR830(ic, val, rate, ctrl)
% ctrl: sync (each sample triggered)
%       trig external trigger starts acq.
% 1: X, 2: Y, 3: R, 4: Theta, 5: freq, 6: ref amplitude
% 7:10: AUX input 1-4, 11:14: Aux output 1:4
% 15,16: stored data, length determined by datadim
% 17: sensitivity
% 18: time constant
% 19: sync filter on/off

global smdata;


switch ic(2) % Channel
    case 1
        switch ic(3) % action
            case 1 % set
                
                fprintf(smdata.inst(ic(1)).data.inst, sprintf('%s %f', cmds{ic(2)}, val));
            case 0 % get
                val = query(smdata.inst(ic(1)).data.inst, sprintf('%s? %s',...
                    cmds{ic(2)}(1:4), cmds{ic(2)}(5:end)), '%s\n', '%f');
                if ic(2)==17
                    val = SR830sensvalue(val);
                elseif ic(2)==18
                    val = SR830tauvalue(val);
                end

            otherwise
                error('Operation not supported');
        end
end

