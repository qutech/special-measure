function [val, rate] = smcDMM34410A(ico, val, rate)
	% Driver for Agilent/Keysight DMMs with support for buffered readout,
	% software and hardware trigger.
	% Mainly configured for voltage readings; needs small additions here and
	% there for other modes
	% For use with the 34401A the commands need to be changed slightly. Some
	% for the 34410A optional
	% parameters are necessary.
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
					
					if ~isempty(smdata.inst(ico(1)).data.vrng)
						fprintf(smdata.inst(ico(1)).data.inst, 'SENS:VOLT:RANG %i',...
							smdata.inst(ico(1)).data.vrng);
					end
					
					% possible nplc with the 34410A
					% {0.006|0.02|0.06|0.2|1|2|10|100}
					% the 34401A cannot measure as fast, only 0.02
					% MIN = 0.006 PLC,
					% MAX = 100 PLC
					bNplc = ~isempty(smdata.inst(ico(1)).data.nplc);
					if bNplc
						nplc = smdata.inst(ico(1)).data.nplc;
						fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:NPLC %f', nplc);
						fprintf(smdata.inst(ico(1)).data.inst, 'CURR:NPLC %f', nplc);
					end
					
					% possible apertures with the 34410A
					% ~100 µs to ~1 s (with ~20 µs resolution).
					% MIN = ~100 µs, MAX = ~1 s
					bAper = ~isempty(smdata.inst(ico(1)).data.aper);
					if bAper
						aper = smdata.inst(ico(1)).data.aper;
						fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:APER:ENAB ON');
						fprintf(smdata.inst(ico(1)).data.inst, 'CURR:APER:ENAB ON');
						fprintf(smdata.inst(ico(1)).data.inst, 'VOLT:APER %f', aper);
						fprintf(smdata.inst(ico(1)).data.inst, 'CURR:APER %f', aper);
					end
					
					if bAper && bNplc
						warning('Both aperture and nplc are set. Took aperture for determination of integration time.')
					end
					
					% Automatically get minimum sampling interval after nplc
					% (number per line cycle) or aper (integration time) has
					% been set. From this, the maximum sampling rate is
					% determined.
					maxrate = 1/query(smdata.inst(ico(1)).data.inst, 'SAMP:TIM? MIN', '%s', '%f');
					
					% set measurement type to be with timed intervals
					fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:SOUR TIM');
					% the theoretical maxrate is not the actual maxrate. the
					% actual maxrate is approx. a factor 2 slower.
					if rate > maxrate
						rate = maxrate;
						warning('Rate set to maxrate = %g Hz', rate);
					end
					
					rmptime = 1/rate;
					
					% sets the timer interval.
					fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:TIM %f', rmptime);
					
					
					%trigger
					fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:COUN %i', 1);
					if ~isempty(smdata.inst(ico(1)).data.htrig) && smdata.inst(ico(1)).data.htrig == 1
						fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:SOUR EXT') %hardwartrigger
						fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:DEL:AUTO ON');
						fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:SLOP POS');
					else
						fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:SOUR BUS'); %softwaretrigger
						fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:DEL 0.0');
					end
					
					% Buffersize (# of readings) hardcoded for 34410A
					% for 34401A this value would be 500
					if val > 50000
						error('More than allowed number of samples = 50000 requested. Correct and try again!\n');
					end
					fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:SOUR BUS');
					fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:COUN %i', 1);
					fprintf(smdata.inst(ico(1)).data.inst, 'SAMP:COUN %d', val);
					smdata.inst(ico(1)).datadim(2,1) = val;
					
				otherwise
					error('Operation not supported');
			end
	end
	