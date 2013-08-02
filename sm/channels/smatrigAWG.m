function smatrigAWG(inst)

global smdata;

%fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:HIGH 2');
fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:LOW 0.1');
% fprintf(smdata.inst(inst).data.inst, 'SOUR3:MARK1:VOLT:LOW 2.6');
pause(0.5)
fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:LOW -0.5');
% fprintf(smdata.inst(inst).data.inst, 'SOUR3:MARK1`:VOLT:LOW 0');