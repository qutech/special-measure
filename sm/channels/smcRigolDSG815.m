function [val, rate] = smcRigolDSG815(ic, val, rate)
% [val, rate] = smcRigolDSG815(ic, val, rate)
% 1: Frequency in Hz
% 2: Amplitude in dBm

global smdata;

switch ic(2) % Channel
    case 1 % frequency
        switch ic(3) % action
            case 1 % set
								fprintf(smdata.inst(ic(1)).data.inst, sprintf(':FREQ %f', val));
            case 0 % get
							  val = query(smdata.inst(ic(1)).data.inst, ':FREQ?');
            otherwise
                error('Operation not supported');
        end
    case 2 % amplitude (level)
        switch ic(3) % action
            case 1 % set
								fprintf(smdata.inst(ic(1)).data.inst, sprintf(':LEV %f', val));
            case 0 % get
							  val = query(smdata.inst(ic(1)).data.inst, ':LEV?');
            otherwise
                error('Operation not supported');
        end
    otherwise
        error('Operation not supported');
end