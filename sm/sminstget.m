function val = sminstget(inst, chan)
% val = sminstget(inst, chan)
% Directly read instrument channel without requiring user channel.

global smdata;
inst = sminstlookup(inst);
if ~isnumeric(chan)
    chan = strmatch(chan, smdata.inst(inst).channels);
end
val = smdata.inst(inst).cntrlfn([inst, chan, 0]);


