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
ip = inputParser;
ip.FunctionName = 'smaNIDAQmx';
ip.addRequired('scan');
ip.addOptional('trig', {});
ip.addOptional('sngl', false);
ip.addOptional('rate', 1e6, @isnumeric);
ip.addOptional('rng', []);
ip.parse(scan,varargin{:});

global smdata
inst = sminstlookup('NIDAQmx');
devID = smdata.inst(inst).data.id;

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
		if isfield(scan.loops(1), 'trigfn')
			scan.loops(1).trigfn(end+1).fn   = @smatrigfn;
			scan.loops(1).trigfn(end).args = ip.Results.trig(1);
		else
			scan.loops(1).trigfn.fn   = @smatrigfn;
			scan.loops(1).trigfn.args = ip.Results.trig(1);
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
    smdata.inst(inst).datadim(:) = 1;
    smdata.inst(inst).data.downsamp = 1;
end

% set rate
smdata.inst(inst).data.input.Rate = ip.Results.rate;

% set range of input
if ~isempty(ip.Results.rng)
    smdata.inst(inst).data.input.Channels.Range = [ip.Results.rng(1) ip.Results.rng(2)];
end