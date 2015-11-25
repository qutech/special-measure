function scan = smaNIDAQmx(scan, device, varargin)
% This function is generally deprecated and will likely already not work
% with the current control functions
ip = inputParser;
ip.FunctionName = 'smaNIDAQmx';
ip.addRequired('scan');
ip.addRequired('device');
ip.addOptional('trig', {});
ip.addOptional('sngl', false);
ip.addOptional('orate', [], @isnumeric);
ip.addOptional('irate', [], @isnumeric);
ip.addOptional('npoints', [], @isnumeric);
ip.addOptional('rng', []);
ip.addOptional('addInput', []);
ip.parse(scan,device,varargin{:});

global smdata
inst = sminstlookup(ip.Results.device);
devID = smdata.inst(inst).data.id;

try smdata.inst(inst).data.input.stop; catch err; end
try smdata.inst(inst).data.output.stop; catch err; end
try smdata.inst(inst).data.digital.stop; catch err; end

% add input channel manually (add channel should always be placed here!)
if ~isempty(ip.Results.addInput)
    for ch = ip.Results.addInput
        try smdata.inst(inst).data.input.addAnalogInputChannel(...
                    smdata.inst(inst).data.id,...
                    ch,...
                    'Voltage'...
                 );
            catch err
                errStr = 'NI: The channel ''ai([0-9]|([1-2][0-9])|(3[01]))'' cannot be added to the session because it has been added previously.';
                if ~regexp (err.message, errStr, 'ONCE')
                    rethrow(err);
                end
        end
    end
end

% determine number of input channels
try
    numInputs =  numel(smdata.inst(inst).data.input.Channels);
catch err
    doThrow = any(~strfind(err.message,...
        'Attempt to reference field of non-structure array.'));
    if doThrow
        rethrow(err);
    end
    numInputs = 0;
end

% configure triggers
if ~isempty(ip.Results.trig)
    if isempty(ip.Results.trig{1}) %bad hack, but extremely useful
        try
            smdata.inst(inst).data.input.addTriggerConnection(...
                'external', [devID '/' ip.Results.trig{2}] , 'StartTrigger');
        catch err
            doThrow = any( [ ~strfind(err.message, 'A StartTrigger connection already exists between'),...
                ~strfind(err.message, 'Attempt to reference field of non-structure array.') ] );
            if doThrow
                rethrow(err);
            end 
        end
        
        try
            smdata.inst(inst).data.output.addTriggerConnection(...
                'external', [devID '/' ip.Results.trig{2}] , 'StartTrigger');
        catch err
            if ~strfind (err.message, 'A StartTrigger connection already exists between')
                rethrow(err);
            end
        end
    else % output triggers input
        try
            smdata.inst(inst).data.input.addTriggerConnection(...
                'external', [devID '/' ip.Results.trig{2}] , 'StartTrigger');
        catch err
            doThrow = any( [ ~strfind(err.message, 'A StartTrigger connection already exists between'),...
                ~strfind(err.message, 'Attempt to reference field of non-structure array.') ] );
            if doThrow
                rethrow(err);
            end
        end
        
        try
            smdata.inst(inst).data.output.addTriggerConnection(...
                [devID '/' ip.Results.trig{1}], 'external', 'StartTrigger');
        catch err
            if ~strfind (err.message, 'A StartTrigger connection already exists between')
                rethrow(err);
            end
        end
    end
% UNSUPPORTED!
% mol: I do not like this any longer; use marker trigger instead 	
% 	if numel(ip.Results.trig{1}) == 2 %external trigger
%         if (~isfield(scan.loops(1).trigfn(1), 'fn') || ...
%                 isempty(scan.loops(1).trigfn(1).fn)) && ~scan.loops(1).trigfn.autoset
% 			scan.loops(1).trigfn.fn = @smatrigfn;
% 			scan.loops(1).trigfn.args = ip.Results.trig(1);
%         elseif isfield(scan.loops(1), 'trigfn')
%  			scan.loops(1).trigfn(end+1).fn = @smatrigfn;
% 			scan.loops(1).trigfn(end).args = ip.Results.trig(1);
%         end
% 	end
else
    % TODO: add `try catch` here for the case of no channel being added to 
    % the session object yet
    for iter = 1:numel(smdata.inst(inst).data.output.Connections)
        smdata.inst(inst).data.output.removeConnection(iter);
    end
    
    try
        for iter = 1:numel(smdata.inst(inst).data.input.Connections)
            smdata.inst(inst).data.input.removeConnection(iter);
        end
    catch
    end
    
    try
        for iter = 1:numel(smdata.inst(inst).data.digital.Connections)
            smdata.inst(inst).data.digital.removeConnection(iter);
        end
    catch
    end
end

if ip.Results.sngl %just read single points
    smdata.inst(inst).datadim(1:numInputs,:) = deal(1);
    smdata.inst(inst).data.downsamp = 1;
end

% set rate
if ip.Results.orate
    smdata.inst(inst).data.output.Rate = ip.Results.orate;
end

if ip.Results.irate
    smdata.inst(inst).data.input.Rate = ip.Results.irate;
end

if ip.Results.npoints
    if strcmp(smdata.inst(inst).device, 'NIPCI6713')
        smdata.inst(inst).data.nout = ip.Results.npoints;
    else
        smdata.inst(inst).data.input.NumberOfScans = ip.Results.npoints;
    end
end

% set range of input
if ~isempty(ip.Results.rng)
    % better implementation would be setting a range for each channel
    % individually; can also be done manually if really needed
    for iter = 1:numInputs
    smdata.inst(inst).data.input.Channels(iter).Range = ...
        [ip.Results.rng(1) ip.Results.rng(2)];
    end
end   