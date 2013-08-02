function smasimconfig(sim, outdim, outchan, inchan)

global smdata;
if isempty(sim)
    sim = 'Sim';
    prefix = '';
    inst = sminstlookup(sim);
else
    inst = sminstlookup(sim);
    prefix = [smdata.inst(inst).name, ':'];
end


if nargin <= 2
    smdata.inst(inst).datadim(1:size(outdim, 1), :) = outdim;
else
    if size(outdim, 1) ~= length(outchan)
        error('Number of dimensions given must equal number of output channels.');
    end
    smdata.inst(inst).datadim = [outdim; zeros(length(inchan), size(outdim, 2))];
    smdata.inst(inst).data.noutchan = length(outchan);
    
    oldchan = vertcat(smdata.channels.instchan);
    if ~isempty(oldchan)
        oldchan = find(oldchan(:, 1) == inst);
    end
    
    [smdata.channels(oldchan).instchan] = deal([0, 0]);
    [smdata.channels(oldchan).name] = deal('');
   
    channels = [outchan, inchan];
    smdata.inst(inst).channels = char(channels);
    smdata.inst(inst).type = zeros(length(channels), 1);
   
    
    for i = 1:min(length(smdata.inst(inst).channels), length(oldchan))
        smdata.channels(oldchan(i)).name = [prefix, channels{i}];
        smdata.channels(oldchan(i)).instchan = [inst, i];
        smdata.channels(oldchan(i)).rangeramp = [-Inf, Inf, Inf, 1];
    end

    for i = length(oldchan)+1:length(smdata.inst(inst).channels)
        smaddchannel(inst, channels{i}, [prefix, channels{i}]); 
        %smdata.channels(i).name = [prefix, channels{i}];
        %smdata.channels(oldchan(i)).instchan = [inst, i];
        %smdata.channels(oldchan(i)).rangeramp = [-Inf, Inf, Inf, 1];
    end

end

