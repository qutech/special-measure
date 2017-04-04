function smopen(inst)
% smopen(inst)
% Opens smdata.inst(i).data.inst for all i in inst, if defined.
% Default is to try to open all instruments.

global smdata;
if nargin < 1
    inst = 1:length(smdata.inst);
end

inst = sminstlookup(inst);

for i = inst
    if isfield(smdata.inst(i), 'data') && isfield(smdata.inst(i).data, 'inst')
        if strmatch('closed',smdata.inst(i).data.inst.Status)
            fopen(smdata.inst(i).data.inst);
						fprintf('Instrument opened successfully\n');
        end
    end
    
    % Operation 6 to initialize device
    if isfield(smdata.inst(i), 'cntrlfn')
        if ~isempty(smdata.inst(i).cntrlfn)
            try
                smdata.inst(i).cntrlfn([inst 1 6], 0, 0); % use channel 1 as this is used as a subscript index by some drivers e.g. decaDAC
            catch err
                if strfind (upper (err.message), 'OPERATION NOT SUPPORTED')
                    % warning (['Instrument ' smdata.inst(i).device ...
                    % ' does not support operation 6 for initialization!'...
                    % ]);
                    continue
                else
                    rethrow(err);
                end
            end
        end
    end
end