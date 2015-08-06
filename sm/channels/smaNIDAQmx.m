function scan = smaNIDAQmx(scan, varargin)
% function scan = smaNIDAQmx(scan, varargin)
% provides helpers for the NIDAQmx
% 
% optional
% ----------------------------------------------------
%
% 'inst' name
%   name of NI instrument to configure; e.g. 'NIPCIe6363' or 'NIPCI6713'
%   default: 'NIPCIe6363'
%
% 'trig' [source destination]
%   source is optional; if not specified source = external; if both are
%   empty, all remaining trigger connections are removed
% 
% 'sngl' boolean
%   if true, just read single points (inputSingleScan); defaults to `false`
%
% 'orate' double
%   sets sampling rate of output; if sampling rate > ramprate -> set downsampling in
%   smcNIDAQmx
%
% 'irate' double
%   sets sampling rate of input; if sampling rate > ramprate -> set downsampling in
%   smcNIDAQmx
%
% 'npoints' integer
%   sets the NumberOfScans property of input and output session
%
% 'rng' [lower upper]
%   sets range of input
%
% 'addInput' channels as cell
%   manually adds input channels to the session; TODO: add feature to
%   remove existing channels
%
ip = inputParser;
ip.FunctionName = 'smaNIDAQmx';
ip.addRequired('scan');
% changing the default for 'inst' will result in many scans breaking!
ip.addOptional('inst', 'NIPCIe6363');
ip.addOptional('trig', {});
ip.addOptional('sngl', false);
ip.addOptional('orate', [], @isnumeric);
ip.addOptional('irate', [], @isnumeric);
ip.addOptional('npoints', [], @isnumeric);
ip.addOptional('rng', []);
ip.addOptional('addInput', []);
ip.parse(scan,varargin{:});

global smdata
inst = sminstlookup(ip.Results.inst);
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
numInputs =  numel(smdata.inst(inst).data.input.Channels);

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
    smdata.inst(inst).data.input.NumberOfScans = ip.Results.npoints;
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