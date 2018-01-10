function [val, rate] = smcTabor2184C(ico, val, rate)
% [val, rate] = smcTabor2184C(ico, val, rate)
% Set/get offsets of 4 channels of Tabor AWG
% Operation 0 = get, 1 = set

% |offset*2 + amplitude| value can not exceed the 4 Vpp if in HV mode

global smdata;
tawg = smdata.inst(ico(1)).data.tawg;
py.pytabor.send_cmd(tawg.visa_inst, sprintf(':inst:sel %i', ico(2)), 2);
py.pytabor.send_cmd(tawg.visa_inst,':voltage:level:hv 2',2); % 2 Vpp so can set offset from -1 to 1

switch ico(3)
	
	case 0 % get
		val = sscanf(char(tawg.visa_inst.ask(':voltage:offset?')), '%f');

	case 1 % set
		py.pytabor.send_cmd(tawg.visa_inst, sprintf(':voltage:offset %f', val), 2);
	
	otherwise
		error('Operation not supported');
		
end


