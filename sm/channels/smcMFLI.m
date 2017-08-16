function val = smcMFLI(ico, val, rate)

% 1: X, 2: Y, 3: R, 4: Theta, 5: freq, 6: ref amplitude
% 7: Buffered Read out V
% 8: buffered Read Out I

global smdata;

% Define some other helpful parameters.
% This Driver will for now only support one output (0), oscillator (0) and
% one demodulator (0)
device_id='dev3338';
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
            case 7 % buff V
                npts = smdata.inst(ic(1)).datadim(ico(2), 1);
                val = smdata.inst(ico(1)).data.inst.device.trigger.last_result;
                smdata.inst(ic(1)).data.currsamp(1) =  smdata.inst(ic(1)).data.currsamp(1) + npts;
            case 8 % buff I
                npts = smdata.inst(ic(1)).datadim(ico(2), 1);
                val = smdata.inst(ico(1)).data.inst.device.trigger.last_result;
                smdata.inst(ic(1)).data.currsamp(2) =  smdata.inst(ic(1)).data.currsamp(2) + npts;
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
        assert(smdata.inst(ico(1)).data.inst.device.trigger.armed);
        ziDAQ('trigger',smdata.inst(ico(1)).data.inst.device.trigger.handle);
        pause(5); % use query here?
        
        res=ziDAQ('read',smdata.inst(ico(1)).data.inst.device.trigger.handle);
        
        smdata.inst(ico(1)).data.inst.device.trigger.last_result=...
            eval(['res.' smdata.inst(ico(1)).data.inst.device '.demods.sample{1}']);
        ziDAQ('unsubscribe', smdata.inst(ico(1)).data.inst.device.trigger.handle,...
            ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
        ziDAQ('clear',smdata.inst(ico(1)).data.inst.device.trigger.handle);
        smdata.inst(ico(1)).data.inst.device.trigger.armed=0;
        
    case 5 % arm
        smdata.inst(ico(1)).data.inst.device.trigger.demod_rate=rate; %check for possible rates supported by Lock-In 100 -> 104.6  
        smdata.inst(ico(1)).data.inst.device.trigger.trigger_count=1;
        smdata.inst(ico(1)).data.inst.device.trigger.trigger_delay=0;
        smdata.inst(ico(1)).data.inst.device.trigger.trigger_duration=1;
        
        ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/rate'], ...
            smdata.inst(ico(1)).data.inst.device.trigger.demod_rate);
        
        
        ziDAQ('unsubscribe','*');
        
        time_constant = ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/timeconstant']);
        
        pause(10*time_constant);
        h=ziDAQ('record');
        ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/rate'], ...
            smdata.inst(ico(1)).data.inst.device.trigger.demod_rate);
        
        ziDAQ('set', h, 'trigger/device', smdata.inst(ico(1)).data.inst.device);
        ziDAQ('set', h, 'trigger/0/count', ...
            smdata.inst(ico(1)).data.inst.device.trigger.trigger_count);
        
        ziDAQ('set', h, 'trigger/0/type', 6); %seems like a hack, check for potential misfires
        
        %triggernode = '/dev3338/demods/0/sample.dio';
        %ziDAQ('set', h, 'trigger/0/triggernode', triggernode);
        %ziDAQ('set', h, 'trigger/0/edge', 1)
        ziDAQ('set', h, 'trigger/buffersize', ...
            2*smdata.inst(ico(1)).data.inst.device.trigger.trigger_duration);
        ziDAQ('set', h, 'trigger/0/duration', ...
            smdata.inst(ico(1)).data.inst.device.trigger.trigger_duration);
        ziDAQ('set', h, 'trigger/0/bitmask', 1)
        ziDAQ('set', h, 'trigger/0/bits', 1)
        ziDAQ('set', h, 'trigger/0/delay', ...
            smdata.inst(ico(1)).data.inst.device.trigger.trigger_delay)
        ziDAQ('set', h, 'trigger/0/retrigger', 0) % check if these are neccesary
        ziDAQ('set', h, 'trigger/0/holdoff/time', 0.1)
        ziDAQ('set', h, 'trigger/0/holdoff/count', 0)
        
        ziDAQ('subscribe',h,['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
        
        ziDAQ('execute',h);  %arm
        smdata.inst(ico(1)).data.inst.device.trigger.armed=1;
        
        %copie from SR830 driver 
        smdata.inst(ic(1)).data.currsamp = [0 0];
        
        smdata.inst(ic(1)).data.sampint = 1/rate;
        smdata.inst(ic(1)).datadim(7:8, 1) = val;
        
    otherwise
        error('Operation not supported.');
        
end
end


