function [val, rate] = smcNIPCI6713(ico, val, rate)
global smdata
%little workaround because of the session interface
wrapper = @(varargin) varargin;

% workaround; better ideas are always welcome
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
        ch = strtrim (smdata.inst(ico(1)).channels(ico(2),:));
       
        switch ico(2)
            case {0,1,2,3,4,5,6,7,8} %{collective, ao0, ao1, ...}
                chanlist = wrapper (smdata.inst(ico(1)).data.output.Channels.ID);
                ind = strcmp (ch, chanlist);
                val = smdata.inst(ico(1)).data.currentOutput(ind);
                
            otherwise
                error('Channel not (yet?) configured for readout!')            
        end
    
    case 1 %Set/Ramp
        switch ico(2)
            case {0,1,2,3,4,5,6,7,8} %{collective, ao0, ao1, ...}
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
                
                rate = sign(rate) * smdata.inst(ico(1)).data.output.Rate;
                
                if rate > 0
                    smdata.inst(ico(1)).data.output.outputSingleScan(queue);
                    smdata.inst(ico(1)).data.currentOutput = queue;
%                     disp('setStartRamp')
                    val = 0;
                elseif rate < 0
                    npoints = smdata.inst(ico(1)).data.npoints;
            
                    fun = @(x) linspace (smdata.inst(ico(1)).data.currentOutput(x),...
                                         queue(x),...
                                         npoints)';
                    ramp = [fun(1) fun(2) fun(3) fun(4)...
                        fun(5) fun(6) fun(7) fun(8)];
%                     smdata.inst(ico(1)).data.output.release;
                    smdata.inst(ico(1)).data.output.queueOutputData (ramp);
%                     smdata.inst(ico(1)).data.output.prepare();
                    smdata.inst(ico(1)).data.currentlyQueuedOutput = queue;
                    smdata.inst(ico(1)).data.output.startBackground();
%                     disp('setStopRamp')
                    val = size(queue, 1) / abs(smdata.inst(ico(1)).data.output.Rate);
                else
                    error('Cannot ramp at zero ramprate!')
                end
                
            case num2cell(37:51) %pfi0-pfi14
                setDigitalChannel (ico, val);
                
        end
    case 3 % Trigger, has to be 'collectivelized' as well;
        switch(ico(2))
            case {0,1,2,3,4,5,6,7,8} %{collective, ao0, ao1, ...}
                smdata.inst(ico(1)).data.output.startBackground();
                % not safe when measurement fails
                smdata.inst(ico(1)).data.currentOutput = ...
                    smdata.inst(ico(1)).data.currentlyQueuedOutput;
                
            otherwise
                error('No trigger available for selected channel!')
        end
        
    case 4 %Arm
        switch ico(2)
            case {0,1,2,3,4,5,6,7,8} %{collective, ao0, ao1, ...}
%                 This is generally not a good idea; do this in configfn
%                 if isfield(smdata.inst(ico(1)).data,'trigIn') && ...
%                         ~isempty(smdata.inst(ico(1)).data.trigIn)
%                     try
%                         smdata.inst(ico(1)).data.output.addTriggerConnection(...
%                             'external',...
%                             [smdata.inst(ico(1)).data.id '/' smdata.inst(ico(1)).data.trigIn],...
%                             'StartTrigger');
%                     catch err
%                         doThrow = any( [ ~strfind(err.message, 'A StartTrigger connection already exists between'),...
%                             ~strfind(err.message, 'Attempt to reference field of non-structure array.') ] );
%                         if doThrow
%                             rethrow(err);
%                         end
%                     end
%                 end
%                 disp('armOutput')
                                
            otherwise
                error('No arming procedure available for selected channel!')
        end
           
    case 5 %configure
                
    case 6 %Initialize card
        % See further details in smcNIDAQmx.m
%         daq.HardwareInfo.getInstance('DisableReferenceClockSynchronization',true);
        
        for dev = daq.getDevices
            if strcmp (dev.Description, 'National Instruments PCI-6713')
                smdata.inst(ico(1)).data.id      = dev.ID;
                smdata.inst(ico(1)).data.output  = daq.createSession('ni');
%                 disp('Found NI PCI-6713!')
            end
        end
        
        %Add all analog channels
        smdata.inst(ico(1)).data.output.addAnalogOutputChannel(...
                smdata.inst(ico(1)).data.id,...
                0:7,...
                'Voltage'...
                );
        smdata.inst(ico(1)).data.output.queueOutputData(zeros(1,8));
        smdata.inst(ico(1)).data.output.startForeground;
        smdata.inst(ico(1)).data.currentOutput = zeros(1,8);
        
        %Digital channels
%         smdata.inst(ico(1)).data.digital.addDigitalChannel(...
%                 smdata.inst(ico(1)).data.id,...
%                 'port0/line0:7',...
%                 'OutputOnly'...
%                 );
        
%         queue = zeros (1, length(smdata.inst(ico(1)).data.digital.Channels));    
%         smdata.inst(ico(1)).data.digital.outputSingleScan (queue);
%         smdata.inst(ico(1)).data.currentDigitalOutput = queue;
        
        %Maybe add configuration for analog outputs here, e.g. range, triggers etc.
%         smdata.inst(ico(1)).data.digital.prepare();
        
    otherwise
        error('Operation not supported!')
end
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