function [val, rate] = smcDummy(ico, val, rate)

% [VAL, RATE] = SMCDUMMY(ICO, VAL, RATE) Summary
%   Driver for a dummy instruments which just returns the set value
%
% --- Outputs -------------------------------------------------------------
% val           : Text
% rate          : Text
%
% --- Inputs --------------------------------------------------------------
% ico           : ico(1): instrument number in rack
% 		            ico(2): channel on instrument, CH1 = set value
% 		            ico(3): 0=read, 1=write (3=trig, 4=bufferreset, 5=sweepsetup)
% val           : Text
% rate          : Text
%
% -------------------------------------------------------------------------
% (c) 2016/10 Pascal Cerfontaine (cerfontaine@physik.rwth-aachen.de)

global smdata;

switch ico(3)
	case 0
		val = smdata.inst(ico(1)).data.inst.val(ico(2));
	case 1
		smdata.inst(ico(1)).data.inst.val(ico(2)) = val;
	otherwise
		error('Operation not supported');
end
