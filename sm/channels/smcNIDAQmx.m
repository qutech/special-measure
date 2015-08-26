function [val, rate] = smcNIDAQmx(ico, val, rate)
global smdata
% little workaround because of the session interface
wrapper = @(varargin) varargin;

% workaround; better ideas are always welcome
COLLCHANS = smdata.inst(ico(1)).type == 2;
if length(ico) > 3
    COLLCHANS  = ico(2:end-1);
    ico(2)     = 0;
    ico(3)     = ico(end);
    ico(4:end) = [];
    rate       = rate ( find (abs(rate) == min (abs (rate)), 1) );
end

switch ico(3)
    case 0 %Read
        ch = strtrim (smdata.inst(ico(1)).channels(ico(2),:) );
        
        %Add channel DEPRECATED
%         try smdata.inst(ico(1)).data.input.addAnalogInputChannel(...
%                 smdata.inst(ico(1)).data.id,...
%                 ch,...
%                 'Voltage'...
%                 );
%         catch err
%             errStr = 'NI: The channel ''ai([0-9]|([1-2][0-9])|(3[01]))'' cannot be added to the session because it has been added previously.';
%             if ~regexp (err.message, errStr, 'ONCE')
%                 rethrow(err);
%             end
%         end
        
        switch ico(2)
            case num2cell(1:32) %analog inputs
                chanlist = wrapper (smdata.inst(ico(1)).data.input.Channels.ID);
                ind      = strcmp (ch, chanlist);
                downsamp = smdata.inst(ico(1)).data.downsamp;
                nsamp = smdata.inst(ico(1)).datadim(ico(2), 1);
                
                while (smdata.inst(ico(1)).data.input.IsRunning && ...
                        ~smdata.inst(ico(1)).data.input.IsDone)
                    smdata.inst(ico(1)).data.input.wait;
%                     fprintf('running...\n');
                end
                
                if (nsamp > 1 || downsamp > 1) %buffered readout
                    if smdata.inst(ico(1)).data.input.IsDone
                        val = smdata.inst(ico(1)).data.buf(:, ind);
                        if downsamp > 1
                            val = mean(reshape(val(1:downsamp*nsamp), downsamp, nsamp));
                        end
                    else
                        error('Wait for DataAvailable failed!')
                    end
                else %just read current value
                    val = smdata.inst(ico(1)).data.input.inputSingleScan();
                    val = val(ind);
                end
                
            case num2cell(33:36) %analog outputs
                chanlist = wrapper (smdata.inst(ico(1)).data.output.Channels.ID);
                ind = strcmp (ch, chanlist);
                val = smdata.inst(ico(1)).data.currentOutput(ind);
            
            case num2cell(37:51) %pfi0-pfi14
                chanlist = wrapper (smdata.inst(ico(1)).data.digital.Channels.ID);
                ind = strcmp (ch, chanlist);
                val = smdata.inst(ico(1)).data.currentDigitalOutput(ind);
                
            otherwise
                error('Channel not (yet?) configured for readout!')            
        end
    
    case 1 %Set/Ramp
        switch ico(2)
            case {0, 33, 34, 35, 36} %{collective, ao0, ao1, ao2, ao3}
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
%                 while(smdata.inst(ico(1)).data.output.IsRunning)
%                     drawnow()
%                 end

                % in case you just want to step
                if nargin < 3
                   rate = Inf;
                end
                
                rate = sign(rate) * smdata.inst(ico(1)).data.output.Rate;
                
                if rate > 0
                    %fprintf ([mat2str(queue) '\n']);
                    smdata.inst(ico(1)).data.output.outputSingleScan (queue);
                    smdata.inst(ico(1)).data.currentOutput = queue;
                    val = 0;
                elseif rate < 0
%                     npoints = smdata.inst(ico(1)).data.output.Rate / abs(rate) *...
%                         max(abs(smdata.inst(ico(1)).data.currentOutput - queue));
                    % dirty workaround
                    if ~isempty(smdata.inst(ico(1)).data.sync)
                        inst = smdata.inst(ico(1)).data.sync;
                    else
                        inst  = ico(1);
                    end
                        
                    npoints = smdata.inst(inst).data.input.NumberOfScans / ...
                        smdata.inst(inst).data.downsamp;
            
                    fun = @(x) linspace (smdata.inst(ico(1)).data.currentOutput(x),...
                                         queue(x),...
                                         npoints)';
                    % not very generic, to be changed
                    ramp = [fun(1) fun(2) fun(3) fun(4)]; 
%                     smdata.inst(ico(1)).data.output.release;
                    smdata.inst(ico(1)).data.output.queueOutputData (ramp);
                    %smdata.inst(ico(1)).data.output.prepare();
                    smdata.inst(ico(1)).data.currentlyQueuedOutput = queue;
                    val = size(queue, 1) / abs(smdata.inst(ico(1)).data.output.Rate);
                else
                    error('Cannot ramp at zero ramprate!')
                end
                
            case num2cell(37:51) %pfi0-pfi14
                setDigitalChannel (ico, val);
                
        end
    case 3 %Trigger, has to be 'collectivelized' as well;
        switch ico(2)
            case num2cell(1:32) %analog inputs
                if ~smdata.inst(ico(1)).data.input.IsRunning
                    %Start background job
                    smdata.inst(ico(1)).data.input.startBackground;
                end
                            
            case num2cell(33:36) %analog outputs
                %Start background job
                smdata.inst(ico(1)).data.output.startBackground;
                %not safe when measurement fails
                smdata.inst(ico(1)).data.currentOutput = ...
                    smdata.inst(ico(1)).data.currentlyQueuedOutput;

% UNSUPPORTED! See auxiliary function smaNIDAQmx for further details                
% do not like this way of triggering any longer; inconvenient to work with                
%             case num2cell(1:51) %pfi0-pfi14
%                 %trigger on rising edge
%                 smdata.inst(ico(1)).data.input.startBackground();
%                 setDigitalChannel (ico, 0);
%                 setDigitalChannel (ico, 1);
%                 setDigitalChannel (ico, 0);
                
            otherwise
                error('No trigger available for selected channel!')
        end
        
    case 4 %Arm
        switch ico(2)
            case num2cell(1:32) %analog inputs
                if ~smdata.inst(ico(1)).data.input.IsRunning
                    %Start background job
                    smdata.inst(ico(1)).data.input.startBackground;
                end
                
            otherwise
                error('No arming procedure available for selected channel!')
        end
           
    case 5 %configure
        ch = strtrim (smdata.inst(ico(1)).channels(ico(2),:) );
        %Add channel
        try smdata.inst(ico(1)).data.input.addAnalogInputChannel(...
                smdata.inst(ico(1)).data.id,...
                ch,...
                'Voltage'...
                );
        catch err
            errStr = 'NI: The channel ''ai([0-9]|([1-2][0-9])|(3[01]))'' cannot be added to the session because it has been added previously.';
            if ~regexp (err.message, errStr, 'ONCE')
                rethrow(err);
            end
        end
        
        smdata.inst(ico(1)).data.downsamp = ...
            floor(smdata.inst(ico(1)).data.input.Rate / rate);
        rate = smdata.inst(ico(1)).data.input.Rate / smdata.inst(ico(1)).data.downsamp;
        
        if smdata.inst(ico(1)).data.downsamp == 0
            error('Input rate too large.');
        end
        
        % could add some error checks here
        if smdata.inst(ico(1)).data.downsamp > 1
            npt = val * smdata.inst(ico(1)).data.downsamp;
        else
            npt = val;
        end
        
        smdata.inst(ico(1)).data.input.NumberOfScans = npt;
        smdata.inst(ico(1)).data.input.NotifyWhenDataAvailableExceeds = npt;
        
        %Create listener for acquisition
        smdata.inst(ico(1)).data.lh = ...
            smdata.inst(ico(1)).data.input.addlistener(...
                'DataAvailable',...
                @(src, event) outputData(ico(1), event.Data)...
                );
        
        %smdata.inst(ico(1)).data.input.prepare();
        smdata.inst(ico(1)).datadim(ico(2), 1) = val;
        %fprintf('CHECK!\n')
        
    case 6 %Initialize card
        %TODO: Needs to be improved, if more than one NI daq-device is installed
        %dev = daq.getDevices;
        
        % ---------------------------------------------------------------
        % THIS SECTION CAN VERY EASILY BE MIGRATED TO THE RESPECTIVE SMA
        % FUNCTION TO ADD VARIABILITY AND BETTER ERROR HANDLING
        % ---------------------------------------------------------------
%         daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);
        
        for dev = daq.getDevices
            if strcmp (dev.Description, 'National Instruments PCIe-6363')
                smdata.inst(ico(1)).data.id      = dev.ID;
                smdata.inst(ico(1)).data.output  = daq.createSession('ni');
                smdata.inst(ico(1)).data.input   = daq.createSession('ni');
                smdata.inst(ico(1)).data.digital = daq.createSession('ni');
                disp('Found NI PCIe-6363!')
            end
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
        
        %Digital channels (PFI1-13)
        smdata.inst(ico(1)).data.digital.addDigitalChannel(...
                smdata.inst(ico(1)).data.id,...
                'port1/line1:7',...
                'OutputOnly'...
                );
        smdata.inst(ico(1)).data.digital.addDigitalChannel(...
                smdata.inst(ico(1)).data.id,...
                'port2/line0:5',...
                'OutputOnly'...
                );
        queue = zeros (1, length(smdata.inst(ico(1)).data.digital.Channels));    
        smdata.inst(ico(1)).data.digital.outputSingleScan (queue);
        smdata.inst(ico(1)).data.currentDigitalOutput = queue;
        
        %Maybe add configuration for analog outputs here, e.g. range, triggers etc.
        smdata.inst(ico(1)).data.digital.prepare();
        
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

function val = setDigitalChannel (ico, val)
    global smdata
    wrapper = @(varargin) varargin;
    
    ch       = strtrim (smdata.inst(ico(1)).channels(ico(2),:) );
    chanlist = wrapper (smdata.inst(ico(1)).data.digital.Channels.ID);
    ind      = strcmp (ch, chanlist);
               
    queue = smdata.inst(ico(1)).data.currentDigitalOutput;
    queue(ind) = val;
                
    smdata.inst(ico(1)).data.digital.outputSingleScan (queue);
    smdata.inst(ico(1)).data.currentDigitalOutput = queue;
end


% function waitRunning (inst, session, timeout)
% %wait implemented manually
%     global smdata
% %     t = now;
% %     while smdata.inst(inst).data.(session).IsRunning
% %         if 24*3600*(now-t) > timeout % in seconds
% %             error ('Wait timeout!');
% %         end
% %     end
% 
% % MODIFIED VERSION OF doWait in Session.m
%     obj = smdata.inst(inst).data.(session);
%     % Validate timeout
%     if ~isscalar(timeout) || ~isnumeric(timeout) || isnan(timeout) || timeout <= 0
%         error('Invalid timeout!')
%     end
%     if obj.IsContinuous && isinf(timeout)
%         error('No inf wait in continuous mode allowed!')
%     end
%             
%     % Wait for up to timeout seconds for obj to reach IsRunning state.
%     localTimer = tic;
%     while obj.IsRunning == true &&...
%             (isinf(timeout) || toc(localTimer) < timeout)
%         drawnow();
%     end
%     if obj.IsRunning == true
%         error('Wait timeout!')
%     end
% end