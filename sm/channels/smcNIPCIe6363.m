function [val, rate] = smcNIPCIe6363(ico, val, rate)
% general note: outputs will be deprecated by this driver; it works best
% to implement outputs as virtual instruments for the respective task
% you want to accomplish; this gets rid of a lot of headaches when
% configuring, updating and syncing the nidaq's state; as of now this
% control function will be used as a pure acquisition instrument
global smdata
% little workaround because of the session interface
wrapper = @(varargin) varargin;

switch ico(3)
    case 0 %Read
        ch = strtrim (smdata.inst(ico(1)).channels(ico(2),:) );
        
        switch ico(2)
            case num2cell(1:32) %analog inputs
                chanlist = wrapper (smdata.inst(ico(1)).data.input.Channels.ID);
                ind      = find(strcmp (ch, chanlist));
                downsamp = smdata.inst(ico(1)).data.downsamp;
                nsamp = smdata.inst(ico(1)).datadim(ico(2), 1);
                
                while (smdata.inst(ico(1)).data.input.IsRunning && ...
                        ~smdata.inst(ico(1)).data.input.IsDone)
                    smdata.inst(ico(1)).data.input.wait;
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
%                 disp('fetchBuffer')
                
                %  release resources to avoid clashing of different session
                smdata.inst(ico(1)).data.input.release();
                
            otherwise
                error('Channel not (yet?) configured for readout!')            
        end
    
    case 3 %Trigger, has to be 'collectivelized' as well;
        switch ico(2)
            case num2cell(1:32) %analog inputs
                if ~smdata.inst(ico(1)).data.input.IsRunning
                    smdata.inst(ico(1)).data.input.startBackground;
                end
                
            otherwise
                error('No trigger available for selected channel!')
        end
        
    case 4 %Arm
        switch ico(2)
            case num2cell(1:32) %analog inputs
                if ~smdata.inst(ico(1)).data.input.IsRunning
                    smdata.inst(ico(1)).data.input.prepare();
                    smdata.inst(ico(1)).data.input.startBackground();
%                     disp('armInput')
                end
                
            otherwise
                error('No arming procedure available for selected channel!')
        end
           
    case 5 %configure
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
        
        smdata.inst(ico(1)).datadim(:, 1) = val;
        
    case 6 % initialize
       for dev = daq.getDevices
            if strcmp (dev.Description, 'National Instruments PCIe-6363')
                smdata.inst(ico(1)).data.id      = dev.ID;
                smdata.inst(ico(1)).data.input   = daq.createSession('ni');
%                 disp('Found NI PCIe-6363!')
            end
       end
        
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