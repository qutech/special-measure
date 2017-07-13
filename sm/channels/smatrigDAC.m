function smatrigDAC(daqs)

smcDecaDAC4([daqs 1], 0); % trigger reset 
smcDecaDAC4([daqs 1], 1); % default trigger level in sm_setups.common.AlazarDefaultSettings 0.75V

%fprintf(smdata.inst(tds).data.inst, 'TRIG FORCE');
