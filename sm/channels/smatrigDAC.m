function smatrigDAC(ic) %set trigger for ramp channels

smcDecaDAC4([ic 1], 0, Inf); % trigger reset 
smcDecaDAC4([ic 1], 5, Inf); % default trigger level in sm_setups.common.AlazarDefaultSettings 0.75*5V

%fprintf(smdata.inst(tds).data.inst, 'TRIG FORCE');
