function val = sminstset(inst, chan, val, varargin)
% val = sminstset(inst, chan, val)
% Directly write to instrument channel without requiring user channel. 
% No limit check or default rate!

global smdata;
inst = sminstlookup(inst);
if ~isnumeric(chan)
    chan = strmatch(chan, smdata.inst(inst).channels);
end

val = smdata.inst(inst).cntrlfn([inst, chan, 1], val, varargin{:});


