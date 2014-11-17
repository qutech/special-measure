function sm_val = smcsim(sm_ico, sm_val)

% special measure driver for simulation
% The simulation to be run is in smdata.inst(ico(3).data.sim) and can 
% either be a script or a function handle. If smdata.inst(ico(1)).data.varlist 
% exists and is a channel index list or cell array,
% the corresponding channels are used as input for the simulation.
% Otherwise, smdata.configch are used.

% ico(3) = 0: ret simulation results
% ico(3) = 3: "trigger" simulation run

global smdata;

switch sm_ico(3)
    case 0
        sm_val = smdata.inst(sm_ico(1)).data.chanvals{sm_ico(2)};

    case 1
        smdata.inst(sm_ico(1)).data.chanvals{sm_ico(2)} = sm_val;

    case 3

%         if isfield(smdata.inst(sm_ico(1)).data, 'varlist') && ...
%                 ~ischar(smdata.inst(sm_ico(1)).data.varlist)
%             sm_varlist = smdata.inst(sm_ico(1)).data.varlist;
%         else 
%             sm_varlist = smdata.configch;
%         end

        %sm_vars = smget(inst, smdata.inst(inst).data.noutchan+1:sm_varlist);


        if isa(smdata.inst(sm_ico(1)).data.sim, 'function_handle') % function
            smdata.inst(sm_ico(1)).data.chanvals(1:smdata.inst(sm_ico(1)).data.noutchan) = ...
                smdata.inst(sm_ico(1)).data.sim(smdata.inst(sm_ico(1)).data.chanvals{smdata.inst(sm_ico(1)).data.noutchan+1:end});
            %smdata.inst(sm_ico(1)).data.chanvals(1) = smdata.inst(sm_ico(1)).data.chanvals(sm_vars{:});
        else % script
            %sm_varlist = smchanlookup(sm_varlist);
           
            
            for sm_i = smdata.inst(sm_ico(1)).data.noutchan+1:size(smdata.inst(sm_ico(1)).channels, 1)
                eval([smdata.inst(sm_ico(1)).channels(sm_i, :), ' = smdata.inst(sm_ico(1)).data.chanvals{sm_i};']);
            end
           
%             for sm_i = 1:length(sm_varlist)
%                 eval([smdata.channels(sm_varlist(sm_i)).name, ' = sm_vars{sm_i};']);
%             end
            eval(smdata.inst(sm_ico(1)).data.sim);
            
            for sm_i = 1:smdata.inst(sm_ico(1)).data.noutchan
                smdata.inst(sm_ico(1)).data.chanvals{sm_i} = eval(smdata.inst(sm_ico(1)).channels(sm_i, :));
            end            
        end
        
    otherwise
        error('Operation not implemented.')
end        
        
        
        



