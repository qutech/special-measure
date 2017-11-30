function [val, rate] = smcMFLI(ico, val, rate)

% 1: X, 2: Y, 3: R, 4: Theta, 5: freq, 6: ref amplitude
% 7: Buffered Read out R
% 8: buffered Read Out phase
%10: Buffered Read Out x
%11: Time constant
%12: Offset on Vref
%
global smdata;



switch ico(3) % mode
    case 6 % single out case 6 for init mainly -> seems hacked
        switch ico(2) %channel
            case 1 %init
                clear ziDAQ;
                
                if isfield(smdata.inst(ico(1)).data,'device_name')
                    device_id=smdata.inst(ico(1)).data.device_name;
                else
                    disp('Please create field <device_name> in inst.data')
                    %device_id='dev3331';
                    return
                end
                apilevel=5;               
                
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
                [smdata.inst(ico(1)).data.inst.device, props] = ziCreateAPISession(device_id, apilevel);
                
                smdata.inst(ico(1)).data.inst.props = props;
                 smdata.inst(ico(1)).data.inst.Status='open';
               
                smdata.inst(ico(1)).data.inst.out_mixer_c = ...
                    num2str(ziGetDefaultSigoutMixerChannel(props, 0));
                
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
                
                [smdata.inst(ico(1)).data.inst.trigger.last_result,...
                    smdata.inst(ico(1)).data.inst.trigger.checkout]=get_buffered_data(smdata,ico);
                
                val = sqrt(smdata.inst(ico(1)).data.inst.trigger.last_result.x.^2+...
                    smdata.inst(ico(1)).data.inst.trigger.last_result.y.^2);
%                 val=val(1:npts);

                nptsAdd = 2*max(floor(numel(val)/10), 100);
								nptsAddDownsampled = floor(nptsAdd*smdata.inst(ico(1)).data.inst.trigger.final_rate/smdata.inst(ico(1)).data.inst.trigger.demod_rate);
								val = horzcat(zeros(1, nptsAdd/2), ones(1, nptsAdd/2)*val(1), val, ones(1, nptsAdd/2)*val(end), zeros(1, nptsAdd/2));
                val = resample(val, fix(smdata.inst(ico(1)).data.inst.trigger.final_rate), fix(smdata.inst(ico(1)).data.inst.trigger.demod_rate));
								val = val(nptsAddDownsampled+1:nptsAddDownsampled+npts);
%                 ratio = floor(smdata.inst(ico(1)).data.inst.trigger.demod_rate/smdata.inst(ico(1)).data.inst.trigger.final_rate);
% 								val = val(1:floor(length(val)/ratio)*ratio);
% 								val = reshape(val(:), ratio, []);
% 								val = mean(val, 1).';
                
								% val = val(1:npts);
                smdata.inst(ico(1)).data.currsamp(1) =  smdata.inst(ico(1)).data.currsamp(1) + npts;
            case 8 % buff phase
                npts = smdata.inst(ico(1)).datadim(ico(2), 1);
                
                [smdata.inst(ico(1)).data.inst.trigger.last_result,...
                    smdata.inst(ico(1)).data.inst.trigger.checkout]=get_buffered_data(smdata,ico);
                % This is a neat hack for debugging! use auxin for
                % monitoring!
%                 val = smdata.inst(ico(1)).data.inst.trigger.last_result.auxin0;
                val = smdata.inst(ico(1)).data.inst.trigger.last_result.phase;
                val=val(1:npts);
                smdata.inst(ico(1)).data.currsamp(2) =  smdata.inst(ico(1)).data.currsamp(2) + npts;
            case 9 % buff x
                npts = smdata.inst(ico(1)).datadim(ico(2), 1);
                
                [smdata.inst(ico(1)).data.inst.trigger.last_result,...
                    smdata.inst(ico(1)).data.inst.trigger.checkout]=get_buffered_data(smdata,ico);
                
                val = smdata.inst(ico(1)).data.inst.trigger.last_result.x;
                val=val(1:npts);
                smdata.inst(ico(1)).data.currsamp(1) =  smdata.inst(ico(1)).data.currsamp(1) + npts;
            case 10 % buff y
                npts = smdata.inst(ico(1)).datadim(ico(2), 1);
                
                [smdata.inst(ico(1)).data.inst.trigger.last_result,...
                    smdata.inst(ico(1)).data.inst.trigger.checkout]=get_buffered_data(smdata,ico);
                
                val = smdata.inst(ico(1)).data.inst.trigger.last_result.y;
                val=val(1:npts);
                smdata.inst(ico(1)).data.currsamp(2) =  smdata.inst(ico(1)).data.currsamp(2) + npts;
            case 11
                val = ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/timeconstant']);
            case 12
                val = ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/sigouts/0/offset']);
        end
        
    case 1 % write
        switch ico(2) %channel
            
            case 5 %frequency
                ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/oscs/0/freq'], val); % [Hz]
                val=ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/oscs/0/freq']);
            case 6 %amplitude
                ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/sigouts/0/amplitudes/'...
                    smdata.inst(ico(1)).data.inst.out_mixer_c], sqrt(2)*val);
                val=ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/sigouts/0/amplitudes/'...
                    smdata.inst(ico(1)).data.inst.out_mixer_c]);
            case 11
                ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/timeconstant'],val)
                val = ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/timeconstant']);
            case 12
                ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/sigouts/0/offset'],val)
                val = ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/sigouts/0/offset']);
            otherwise
                error('Operation not supported.');
        end
        
    case 3 % trigger
        
        if ~logical(smdata.inst(ico(1)).data.inst.trigger.triggered)||smdata.inst(ico(1)).data.inst.trigger.checkout
            ziDAQ('trigger',smdata.inst(ico(1)).data.inst.trigger.handle);
            smdata.inst(ico(1)).data.inst.trigger.checkout=0;
            smdata.inst(ico(1)).data.inst.trigger.triggered=1;
        end
        
    case 4 % arm
        
        smdata.inst(ico(1)).data.inst.trigger.armed=0;
        smdata.inst(ico(1)).data.inst.trigger.triggered=0;
        smdata.inst(ico(1)).data.inst.trigger.checkout=0;
        
        
        
    case 5 % config
        
        if ~isfield(smdata.inst(ico(1)).data.inst,'trigger')||~logical(smdata.inst(ico(1)).data.inst.trigger.armed)
            smdata.inst(ico(1)).data.inst.trigger.demod_rate= 26.79e3; % 53571.4296875;
						smdata.inst(ico(1)).data.inst.trigger.final_rate = rate;
            smdata.inst(ico(1)).data.inst.trigger.trigger_count=1;
            smdata.inst(ico(1)).data.inst.trigger.trigger_delay=0;
            smdata.inst(ico(1)).data.inst.trigger.armed=0;
            
            %remove old trigger
            if isfield(smdata.inst(ico(1)).data.inst.trigger,'handle')
                if ~isempty(smdata.inst(ico(1)).data.inst.trigger.handle)
									  ziDAQ('finish',smdata.inst(ico(1)).data.inst.trigger.handle); %new
                    ziDAQ('clear',smdata.inst(ico(1)).data.inst.trigger.handle);
                    smdata.inst(ico(1)).data.inst.trigger.handle=[];
                end
            end
            
            %set rate
            ziDAQ('setDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/rate'], ...
                smdata.inst(ico(1)).data.inst.trigger.demod_rate);
            
            % get closeset possible rate back
            smdata.inst(ico(1)).data.inst.trigger.demod_rate=ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/rate'], ...
                smdata.inst(ico(1)).data.inst.trigger.demod_rate);
%             smdata.inst(ico(1)).data.inst.trigger.demod_rate=rate;
            
            
            smdata.inst(ico(1)).data.inst.trigger.trigger_duration=val/rate;
            
            ziDAQ('unsubscribe','*');
            
            smdata.inst(ico(1)).data.inst.trigger.time_constant = ...
                ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/timeconstant']);
            
            pause(10*smdata.inst(ico(1)).data.inst.trigger.time_constant);
            
            h=ziDAQ('record');
            
            smdata.inst(ico(1)).data.inst.trigger.handle=h;
            
            ziDAQ('set', h, 'trigger/device', smdata.inst(ico(1)).data.inst.device);
            ziDAQ('set', h, 'trigger/endless', 1);
						ziDAQ('set',h,'trigger/historylength',10) % 100000
            ziDAQ('set', h, 'trigger/0/count', ...
                smdata.inst(ico(1)).data.inst.trigger.trigger_count);
            %   type:
            %     NO_TRIGGER = 0
            %     EDGE_TRIGGER = 1
            %     DIGITAL_TRIGGER = 2
            %     PULSE_TRIGGER = 3
            %     TRACKING_TRIGGER = 4
            ziDAQ('set', h, 'trigger/0/type', 1); %seems like a hack, check for potential misfires
            %   triggernode, specify the triggernode to trigger on.
            %     SAMPLE.X = Demodulator X value
            %     SAMPLE.Y = Demodulator Y value
            %     SAMPLE.R = Demodulator Magnitude
            %     SAMPLE.THETA = Demodulator Phase
            %     SAMPLE.AUXIN0 = Auxilliary input 1 value
            %     SAMPLE.AUXIN1 = Auxilliary input 2 value
            %     SAMPLE.DIO = Digital I/O value
            %   Here we use the device's DIO value which is included in a demodulator sample:
            
            triggernode = ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample.' smdata.inst(ico(1)).data.trigchannel];
            ziDAQ('set', h, 'trigger/0/triggernode', triggernode);
            %   edge:
            %     POS_EDGE = 1
            %     NEG_EDGE = 2
            %     BOTH_EDGE = 3
            ziDAQ('set', h, 'trigger/0/edge', 1)
            ziDAQ('set', h, 'trigger/0/level', .2)
            % The size of the internal buffer used to store data, this should be larger
            % than trigger_duration.
            ziDAQ('set', h, 'trigger/buffersize', ...
                2*smdata.inst(ico(1)).data.inst.trigger.trigger_duration);
            ziDAQ('set', h, 'trigger/0/duration', ...
                smdata.inst(ico(1)).data.inst.trigger.trigger_duration);
            
         
            ziDAQ('set', h, 'trigger/0/delay', ...
                smdata.inst(ico(1)).data.inst.trigger.trigger_delay)
            ziDAQ('set', h, 'trigger/0/retrigger', 0) % check if these are neccesary
            ziDAQ('set', h, 'trigger/0/holdoff/time', 0.)
            ziDAQ('set', h, 'trigger/0/holdoff/count', 0)
            
						try
							ziDAQ('subscribe',h,['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
						catch err
              warning(err.getReport());
							util.keyboard_control();
							pause(2);
							ziDAQ('subscribe',h,['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample']);
						end
            
            ziDAQ('execute',h);  %arm
            smdata.inst(ico(1)).data.inst.trigger.armed=1;
        else
%             rate=ziDAQ('getDouble', ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/rate'], ...
%                 smdata.inst(ico(1)).data.inst.trigger.demod_rate);
        end
        
        %copie from SR830 driver
        smdata.inst(ico(1)).data.currsamp = [0 0 0 0];
        
        smdata.inst(ico(1)).data.sampint = 1/rate;
        
        smdata.inst(ico(1)).datadim(7:10, 1) = val;
        
    otherwise
        error('Operation not supported.');
        
end
end

function [last_result, checkout]=get_buffered_data(smdata,ico)

if ~smdata.inst(ico(1)).data.inst.trigger.checkout
	  tic
		
    res=ziDAQ('read',smdata.inst(ico(1)).data.inst.trigger.handle);
    while ~ziCheckPathInData(res, ['/' smdata.inst(ico(1)).data.inst.device '/demods/0/sample'])
        pause(.1);
        temp=ziDAQ('read',smdata.inst(ico(1)).data.inst.trigger.handle);
        res.(smdata.inst(ico(1)).data.inst.device).demods.sample=...
            temp.(smdata.inst(ico(1)).data.inst.device).demods.sample;
		end		
		
    last_result=...
        res.(smdata.inst(ico(1)).data.inst.device).demods.sample{end};
    checkout=1;
		
		toc
else
    checkout=smdata.inst(ico(1)).data.inst.trigger.checkout;
    last_result=smdata.inst(ico(1)).data.inst.trigger.last_result;
end

end



