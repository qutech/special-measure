function [val, rate] = smcNIDAQmx(ico, val, rate)
global smdata
%little workaround because of the stupid session interface
wrapper = @(varargin) varargin;
% TODO cleanupfn which removes the channels after a measurement

% workaround for now
COLLCHANS = smdata.inst(ico(1)).type == 2;
if length(ico) > 3
    COLLCHANS  = ico(2:end-1);
    ico(2)     = 0;
    ico(3)     = ico(end);
    ico(4:end) = [];
    rate       = rate ( find (abs(rate) == max (abs (rate)), 1) );
end

switch ico(3)
    case 0 %Read
        ch       = strtrim (smdata.inst(ico(1)).channels(ico(2),:) );
        chanlist = wrapper (smdata.inst(ico(1)).data.input.Channels.ID);
        ind      = strcmp (ch, chanlist);
        
        if regexp (ch, '^ai([0-9]|([1-2][0-9])|(3[01]))$', 'ONCE')
            if smdata.inst(ico(1)).datadim(ico(2), 1) > 1 %buffered readout
                smdata.inst(ico(1)).data.input.wait();
                if smdata.inst(ico(1)).data.input.IsDone
                    val = smdata.inst(ico(1)).data.buf(:, ind);
                else
                    error('Wait for DataAvailable failed!')
                end
            else %just read current value
                val = smdata.inst(ico(1)).data.input.inputSingleScan();
                val = val(ind);
            end
        elseif regexp (ch, '^ao[0123]$', 'ONCE')
            chanlist = wrapper (smdata.inst(ico(1)).data.output.Channels.ID);
            ind = strcmp (ch, chanlist);
            val = smdata.inst(ico(1)).data.currentOutput(ind);
        else
            error('Channel not (yet?) configured for readout!')
        end
    
    case 1 %Set/Ramp
        % if not all outputs are set, just set specified outputs and leave
        % the rest as is
        chans = smdata.inst(ico(1)).channels(COLLCHANS, :);
        chans = arrayfun (@(x) strtrim(chans(x, 1:end)),...
                            1:size(chans, 1),...
                            'UniformOutput', false...
                            );
        if ico(2) == 0
            for ch = 1:length(smdata.inst(ico(1)).data.currentOutput)
                tmp = val(...
                    strcmp (chans, smdata.inst(ico(1)).data.output.Channels(ch).ID)...
                    );
                if isempty(tmp)
                    queue(ch) = smdata.inst(ico(1)).data.currentOutput(ch);
                else
                    queue(ch) = tmp;
                end
            end
        else
            queue = smdata.inst(ico(1)).data.currentOutput;
            ch  = strtrim (smdata.inst(ico(1)).channels(ico(2),:) );
            ind = strcmp (ch, chans);
            queue(ind) = val;
        end
        
        smdata.inst(ico(1)).data.output.wait; %safety wait
        
        % in case you just want to step
        if nargin < 3
            rate = Inf;
        end
        
        if rate > 0
            smdata.inst(ico(1)).data.output.queueOutputData (queue);
            smdata.inst(ico(1)).data.output.startBackground;
            smdata.inst(ico(1)).data.currentOutput = queue;
            val = size(queue, 1) / abs(smdata.inst(ico(1)).data.output.Rate);
        elseif rate < 0
            npoints = smdata.inst(ico(1)).data.output.Rate / abs(rate) * ...
                max(abs(smdata.inst(ico(1)).data.currentOutput - queue));
            
            fun = @(x) linspace (smdata.inst(ico(1)).data.currentOutput(x),...
                                 queue(x),...
                                 npoints)';
            ramp = [fun(1) fun(2) fun(3) fun(4)]; %not very generic, to be changed
            smdata.inst(ico(1)).data.output.queueOutputData (ramp);
            smdata.inst(ico(1)).data.currentlyQueuedOutput = queue;
            val = 1 / abs(rate);
        else
            error('Cannot ramp at zero ramprate!')
        end
        
    case 3 %Trigger, has to be 'collectivelized' as well
        ch = strtrim (smdata.inst(ico(1)).channels(ico(2),:) );
        if regexp (ch, '^ai([0-9]|([1-2][0-9])|(3[01]))$', 'ONCE')
            if ~smdata.inst(ico(1)).data.input.IsRunning
                %Start background job
                smdata.inst(ico(1)).data.input.startBackground;
            end
        elseif regexp (ch, '^ao[0123]$', 'ONCE')
            if ~smdata.inst(ico(1)).data.output.IsRunning
                %Start background job
                smdata.inst(ico(1)).data.output.startBackground;
                smdata.inst(ico(1)).data.currentOutput = ...
                    smdata.inst(ico(1)).data.currentlyQueuedOutput;
            end
        else
            error('No trigger available for selected channel!')
        end
           
    case 5
        ch = strtrim (smdata.inst(ico(1)).channels(ico(2),:) );
        %Add channel
        try smdata.inst(ico(1)).data.input.addAnalogInputChannel(...
                smdata.inst(ico(1)).data.id,...
                ch,...
                'Voltage'...
                );
        catch err
            errStr = 'NI: The channel ''ai([0-9]|([1-2][0-9])|(3[01]))'' cannot be added to the session because it has been added previously.';
            if regexp (err.message, errStr, 'ONCE')
                    warning (['Channel already added to session. Consider'...
                        ' adding a cleanupfn if scan results in errors!']);
            else
                rethrow(err);
            end
        end
        
        rateLimit = smdata.inst(ico(1)).data.input.RateLimit;
        smdata.inst(ico(1)).data.input.Rate = min (rateLimit(2),... 
            max (rate, rateLimit(1)) );
        
        if val > 1
            smdata.inst(1).data.input.NumberOfScans = val;
            smdata.inst(ico(1)).data.input.NotifyWhenDataAvailableExceeds = ...
                val;
        
            %Create listener for acquisition
            smdata.inst(ico(1)).data.lh = ...
                smdata.inst(ico(1)).data.input.addlistener(...
                    'DataAvailable',...
                    @(src, event) outputData(ico(1), event.Data)...
                    );
        end
        
        smdata.inst(ico(1)).datadim(ico(2), 1) = val;
        %fprintf('CHECK!\n')
        
    case 6 %Initialize card
        %TODO: Needs to be improved, if more than one NI daq-device is installed
        dev = daq.getDevices;
        if strcmp (dev.Description, 'National Instruments PCIe-6363')
            smdata.inst(ico(1)).data.id = dev.ID;
            smdata.inst(ico(1)).data.output = daq.createSession('ni');
            smdata.inst(ico(1)).data.input = daq.createSession('ni');
        else
            error ('Device not found!')
        end
        
        %Add all analog channels
        smdata.inst(ico(1)).data.output.addAnalogOutputChannel(...
                smdata.inst(ico(1)).data.id,...
                0:3,...
                'Voltage'...
                );
        smdata.inst(ico(1)).data.output.queueOutputData([0 0 0 0]);
        smdata.inst(ico(1)).data.output.startForeground;
        smdata.inst(ico(1)).data.currentOutput = [0 0 0 0];
        %Maybe add configuration for analog outputs here, e.g. range, triggers etc.
                
    otherwise
        error('Operation not supported!')
end
end

%callback function for 'DataAvailable'-listener
function outputData (inst, data)
    global smdata
    smdata.inst(inst).data.buf = [];
    smdata.inst(inst).data.buf = data;
end