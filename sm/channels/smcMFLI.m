function [val, rate] = smcMFLI(ico, val, rate)

% 1: X, 2: Y, 3: R, 4: Theta, 5: freq, 6: ref amplitude
% 7: Buffered Read out V
% 8: buffered Read Out I

global smdata;

% Define some other helpful parameters.
% This Driver will for now only support one output (0), oscillator (0) and
% one demodulator (0)
device_id='dev3331';
apilevel=5;


switch ico(3) % mode
    case 6 % single out case 6 for init mainly -> seems hacked
        switch ico(2) %channel
            case 1 %init
                clear ziDAQ;
                
                if ~exist('device_id', 'var')
                    error(['No value for device_id specified. The first argument to the ' ...
                        'example should be the device ID on which to run the example, ' ...
                        'e.g. ''dev2006'' or ''uhf-dev2006''.'])
                end
                
                % Check the ziDAQ MEX (DLL) and Utility functions can be found in Matlab's path.
                if ~(exist('ziDAQ') == 3) && ~(exist('ziCreateAPISession', 'file') == 2)
                    fprintf('Failed to either find the ziDAQ mex file or ziDevices() utility.\n')
                    fprintf('Please configure your path using the ziDAQ function ziAddPath().\n')
                    fprintf('This can be found in the API subfolder of your LabOne installation.\n');
                    fprintf('On Windows this is typically:\n');
                    fprintf('C:\\Program Files\\Zurich Instruments\\LabOne\\API\\MATLAB2012\\\n');
                    return
                end
                
                % Create an API session; connect to the correct Data Server for the device.
                [device, props] = ziCreateAPISession(device_id, apilevel);
                smdata.inst(ico(1)).data.inst.device = device; %????
                smdata.inst(ico(1)).data.inst.props = props;
                out_c = '0'; % signal output channel
                % Get the value of the instrument's default Signal Output mixer channel.
                smdata.inst(ico(1)).data.inst.out_mixer_c = ...
                    num2str(ziGetDefaultSigoutMixerChannel(props, str2num(out_c)));
                ziDAQ('sync');
                
                %Make all other important settings on device!
                %END init
                
            otherwise
                error('Operation not supported');
        end
        
    case 0 % read
        switch ico(2) %channel
            
            case 1 %x
                sample = ziDAQ('getSample', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
                val=sample.x;
            case 2 %y
                sample = ziDAQ('getSample', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
                val=sample.y;
            case 3%r
                sample = ziDAQ('getSample', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
                val=abs(sample.x+1i*sample.y);
            case 4%theta
                sample = ziDAQ('getSample', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
                val=sample.phase;
            case 5%freq
                sample = ziDAQ('getSample', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
                val=sample.frequency;
            case 6%ref amp
                val=ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/sigouts/0/amplitudes/' smdata.inst(ico(1)).data.inst.out_mixer_c]);
            case 7 % buff R
                npts = smdata.inst(ico(1)).datadim(ico(2), 1);
                val = sqrt(smdata.inst(ico(1)).data.inst.trigger.last_result.x.^2+...
                    smdata.inst(ico(1)).data.inst.trigger.last_result.y.^2);
                val=val(1:npts);
                smdata.inst(ico(1)).data.currsamp(1) =  smdata.inst(ico(1)).data.currsamp(1) + npts;
            case 8 % buff phase
                npts = smdata.inst(ico(1)).datadim(ico(2), 1);
                val = smdata.inst(ico(1)).data.inst.trigger.last_result.phase;
                val=val(1:npts);
                smdata.inst(ico(1)).data.currsamp(2) =  smdata.inst(ico(1)).data.currsamp(2) + npts;
        end
        
    case 1 % write
        switch ico(2) %channel
            
            case 5 %frequency
                ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/oscs/0/freq'], val); % [Hz]
                
            case 6 %amplitude
                ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/sigouts/0/amplitudes/'...
                    smdata.inst(ico(1)).data.inst.out_mixer_c], val);
            otherwise
                error('Operation not supported.');
        end
        
    case 3 % query
        
    case 4 % trigger programmed handle
        assert(logical(smdata.inst(ico(1)).data.inst.trigger.armed));
        ziDAQ('trigger',smdata.inst(ico(1)).data.inst.trigger.handle);
        pause(4*smdata.inst(ico(1)).data.inst.trigger.trigger_duration);
        
        res=ziDAQ('read',smdata.inst(ico(1)).data.inst.trigger.handle);
                     
        smdata.inst(ico(1)).data.inst.trigger.last_result=...
            eval(['res.' smdata.inst(ico(1)).data.inst.device '.demods.sample{end}']);
        
             
        
    case 5 % arm
        smdata.inst(ico(1)).data.inst.trigger.demod_rate=rate;
        smdata.inst(ico(1)).data.inst.trigger.trigger_count=1;
        smdata.inst(ico(1)).data.inst.trigger.trigger_delay=0;
        smdata.inst(ico(1)).data.inst.trigger.armed=0;
        
        %remove old trigger
        if isfield(smdata.inst(ico(1)).data.inst.trigger,'handle')
            if ~isempty(smdata.inst(ico(1)).data.inst.trigger.handle)            
            ziDAQ('clear',smdata.inst(ico(1)).data.inst.trigger.handle);
            smdata.inst(ico(1)).data.inst.trigger.handle=[];
            end
        end

        %set rate      
        ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/rate'], ...
            smdata.inst(ico(1)).data.inst.trigger.demod_rate);
        
        % get closeset possible rate back
        rate=ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/rate'], ...
            smdata.inst(ico(1)).data.inst.trigger.demod_rate);
        
        
        smdata.inst(ico(1)).data.inst.trigger.trigger_duration=val/rate;
        
        ziDAQ('unsubscribe','*');
        
        smdata.inst(ico(1)).data.inst.trigger.time_constant = ...
            ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/timeconstant']);
        
        pause(10*smdata.inst(ico(1)).data.inst.trigger.time_constant);
        h=ziDAQ('record');
        smdata.inst(ico(1)).data.inst.trigger.handle=h;
        
        ziDAQ('set', h, 'trigger/device', smdata.inst(ico(1)).data.inst.device);
        ziDAQ('set', h, 'trigger/endless', 1);
        ziDAQ('set', h, 'trigger/0/count', ...
            smdata.inst(ico(1)).data.inst.trigger.trigger_count);
        %   type:
        %     NO_TRIGGER = 0
        %     EDGE_TRIGGER = 1
        %     DIGITAL_TRIGGER = 2
        %     PULSE_TRIGGER = 3
        %     TRACKING_TRIGGER = 4
        ziDAQ('set', h, 'trigger/0/type', 2); %seems like a hack, check for potential misfires
        %   triggernode, specify the triggernode to trigger on.
        %     SAMPLE.X = Demodulator X value
        %     SAMPLE.Y = Demodulator Y value
        %     SAMPLE.R = Demodulator Magnitude
        %     SAMPLE.THETA = Demodulator Phase
        %     SAMPLE.AUXIN0 = Auxilliary input 1 value
        %     SAMPLE.AUXIN1 = Auxilliary input 2 value
        %     SAMPLE.DIO = Digital I/O value
        %   Here we use the device's DIO value which is included in a demodulator sample:
        triggernode = ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample.dio'];
        ziDAQ('set', h, 'trigger/0/triggernode', triggernode);
        %   edge:
        %     POS_EDGE = 1
        %     NEG_EDGE = 2
        %     BOTH_EDGE = 3
        ziDAQ('set', h, 'trigger/0/edge', 1)
        % The size of the internal buffer used to store data, this should be larger
        % than trigger_duration.
        ziDAQ('set', h, 'trigger/buffersize', ...
            2*smdata.inst(ico(1)).data.inst.trigger.trigger_duration);
        ziDAQ('set', h, 'trigger/0/duration', ...
            smdata.inst(ico(1)).data.inst.trigger.trigger_duration);
        ziDAQ('set', h, 'trigger/0/bitmask', 1)
        ziDAQ('set', h, 'trigger/0/bits', 1)
        ziDAQ('set', h, 'trigger/0/delay', ...
            smdata.inst(ico(1)).data.inst.trigger.trigger_delay)
        ziDAQ('set', h, 'trigger/0/retrigger', 0) % check if these are neccesary
        ziDAQ('set', h, 'trigger/0/holdoff/time', 0.1)
        ziDAQ('set', h, 'trigger/0/holdoff/count', 0)
        
        ziDAQ('subscribe',h,['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
        
        ziDAQ('execute',h);  %arm
        smdata.inst(ico(1)).data.inst.trigger.armed=1;
        
        %copie from SR830 driver
        smdata.inst(ico(1)).data.currsamp = [0 0];
        
        smdata.inst(ico(1)).data.sampint = 1/rate;
        smdata.inst(ico(1)).datadim(7:8, 1) = val;
               
    otherwise
        error('Operation not supported.');
        
end
end


