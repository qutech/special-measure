function [val, rate] = smcKeithley2400(ico, val, rate)
% driver for Keithley 2400 SourceMeter
% currently just to supply and monitor components, experimental & incomlete
% 	SMCKEITHLEY2400([ico(1) ico(2) ico(3)] val, rate)
% 		ico(1): instrument number in rack
% 		ico(2): channel on instrument 1 =VOLT
%                                     2 =CURRENT, 
%									  3 =COMPLIANCE
%                                     4 =ISSOURCEVOLT
%                                     5 =OUTPUTON
% 		ico(3): 0=read, 1=write(, 3=trig, 4=bufferreset, 5=sweepsetup)

% measurement range is determined by instrument, presumebly slow
% no ramps/triggering implimented, consult smcdmm.m
% no ...
% only dc voltage/current measure/source
% written by eugen.kammerloher@rwth-aachen.de

global smdata;

switch ico(2)
	case 1	% measure voltage or set constant voltage source
		switch ico(3)
			case 0
				% slow but simple
				fprintf(smdata.inst(ico(1)).data.inst, ':SENS:VOLT:RANG:AUTO ON');
				% set remote output format to voltage only
				fprintf(smdata.inst(ico(1)).data.inst, ':FORM:ELEM VOLT');
				val = query(smdata.inst(ico(1)).data.inst,  ':READ?', '%s\n', '%f');

			case 1
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:FUNC VOLT');
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:VOLT:MODE FIXED');
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:VOLT:LEV %f', val);

			otherwise
				error('Operation not supported');
		end

	case 2	% measure current or set constant current on source
		switch ico(3)
			case 0
				% slow but simple
				fprintf(smdata.inst(ico(1)).data.inst, ':SENS:CURR:RANG:AUTO ON');
				% set remote output format to current only
				fprintf(smdata.inst(ico(1)).data.inst, ':FORM:ELEM CURR');
				val = query(smdata.inst(ico(1)).data.inst,  'READ?', '%s\n', '%f');

			case 1
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:FUNC CURR');
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:CURR:MODE FIXED');
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:CURR:LEV %f', val);

			otherwise
				error('Operation not supported');
		end

	case 3 % get real compliance as minimum of measuring range and compliance value. Set compliance
		switch ico(3)
			case 0
				source = query(smdata.inst(ico(1)).data.inst,  ':SOUR:FUNC?', '%s\n', '%s');
                if strcmp(source, 'VOLT')
					sense = 'CURR';
				else
					sense = 'VOLT';
                end
                
				% Query measurement range, compliance limit
				range = query(smdata.inst(ico(1)).data.inst,  [':' sense ':RANGE?'], '%s\n', '%f');
				prot = query(smdata.inst(ico(1)).data.inst,  [':' sense ':PROT?'], '%s\n', '%f');

				% Take the smaller one as compliance readback
				val = min(range, prot);

			case 1 % does not work for ohm
				source = query(smdata.inst(ico(1)).data.inst,  ':SOUR:FUNC?', '%s\n', '%s');
                if strcmp(source, 'VOLT')
					sense = 'CURR';
				else
					sense = 'VOLT';
                end

                % sometimes too small for sense range error, reason unknown
                % range auto on should set compliance independently from
                % sense range
                fprintf(smdata.inst(ico(1)).data.inst, [':SOUR:' source ':RANG:AUTO ON']);
				fprintf(smdata.inst(ico(1)).data.inst, [':' sense ':PROT %f'], val);

			otherwise
				error('Operation not supported');
		end

	case 4 % get 1 if sourcing voltage. Set 1 to source voltage (0 for current)
		switch ico(3)
			case 0 % instrument outputs VOLT, CURR
				val = query(smdata.inst(ico(1)).data.inst,  ':SOUR:FUNC?', '%s\n', '%s');
                if strcmp(val, 'VOLT')
					val = 1;
				else
					val = 0;
                end

			case 1
                if val == 1
					cmd = 'VOLT';
				else
					cmd = 'CURR';
                end
				fprintf(smdata.inst(ico(1)).data.inst, ':SOUR:FUNC %s', cmd);

			otherwise
				error('Operation not supported');
		end

	case 5 % get 1 if output is on. Set 1 to set output on (0 for off)
		switch ico(3)
			case 0 % instruments outputs 1 for ON, 0 for OFF
				val = query(smdata.inst(ico(1)).data.inst,  ':OUTP:STAT?', '%s\n', '%d');
                
			case 1
                if (val == 1)
					cmd = 'ON';
				else
					cmd = 'OFF';
                end
				fprintf(smdata.inst(ico(1)).data.inst, ':OUTP:STAT %s', cmd);

			otherwise
				error('Operation not supported');
		end

	otherwise
		%error('Operation not supported');
		error(['Channel ', num2str(ico(2)) ,' is not available']);
end
