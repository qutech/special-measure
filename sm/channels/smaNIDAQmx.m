function scan = smaNIDAQmx(scan, varargin)
% function scan = smaNIDAQmx(scan, varargin)
% provides helpers for the NIDAQmx
% 
% optional
% ----------------------------------------------------
% 'trig' [source destination]
%   source is optional; if not specified source = external; if both are
%   empty, all remaining trigger connections are removed
% 
% 'sngl' boolean
%   if true, just read single points (inputSingleScan); defaults to `false`
%
% 'rate' double
%   sets sampling rate; if sampling rate > ramprate -> set downsampling in
%   smcNIDAQmx
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
ip.addOptional('trig', {});
ip.addOptional('sngl', false);
ip.addOptional('rate', 1e3, @isnumeric);
ip.addOptional('rng', []);
ip.addOptional('addInput', []);
ip.parse(scan,varargin{:});

global smdata
inst = sminstlookup('NIDAQmx');
devID = smdata.inst(inst).data.id;

smdata.inst(inst).data.input.stop;
smdata.inst(inst).data.output.stop;
smdata.inst(inst).data.digital.stop;

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
    try
        smdata.inst(inst).data.input.addTriggerConnection(...
            'external', [devID '/' ip.Results.trig{2}] , 'StartTrigger'); 
    catch err
        if ~strfind (err.message, 'A StartTrigger connection already exists between')
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
	
	if numel(ip.Results.trig{1}) == 2 %external trigger
        if (~isfield(scan.loops(1).trigfn(1), 'fn') || ...
                isempty(scan.loops(1).trigfn(1).fn)) && ~scan.loops(1).trigfn.autoset
			scan.loops(1).trigfn.fn = @smatrigfn;
			scan.loops(1).trigfn.args = ip.Results.trig(1);
        elseif isfield(scan.loops(1), 'trigfn')
 			scan.loops(1).trigfn(end+1).fn = @smatrigfn;
			scan.loops(1).trigfn(end).args = ip.Results.trig(1);
        end
	end
else
    % TODO: add `try catch` here for the case of no channel being added to 
    % the session object yet
    for iter = 1:numel(smdata.inst(inst).data.output.Connections)
        smdata.inst(inst).data.output.removeConnection(iter);
    end
    for iter = 1:numel(smdata.inst(inst).data.input.Connections)
        smdata.inst(inst).data.input.removeConnection(iter);
    end
    for iter = 1:numel(smdata.inst(inst).data.digital.Connections)
        smdata.inst(inst).data.digital.removeConnection(iter);
    end
end

if ip.Results.sngl %just read single points
    smdata.inst(inst).datadim(1:numInputs,:) = deal(1);
    smdata.inst(inst).data.downsamp = 1;
end

% set rate
smdata.inst(inst).data.input.Rate = ip.Results.rate;
smdata.inst(inst).data.output.Rate = ip.Results.rate;

% set range of input
if ~isempty(ip.Results.rng)
    % better implementation would be setting a range for each channel
    % individually; can also be done manually if really needed
    for iter = 1:numInputs
    smdata.inst(inst).data.input.Channels(iter).Range = ...
        [ip.Results.rng(1) ip.Results.rng(2)];
    end
end   