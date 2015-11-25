function [val, rate] = smcStepAttenuator (ico, val, rate, varargin)
% function val = smcStepAttenuator (ico, val)
% This driver is tailored for usage with the NIDAQmx PCIe-6363. It uses
% PFI1-PFI6 as outputs with PFI6 being the control/latch bit.
global smdata

switch ico(3)
    case 0
        switch ico(2)
            case 1
                % little endian
                val = bin2dec(num2str(...
                    fliplr(smdata.inst(ico(1)).data.currentDigitalOutput(1:5))))/2;
                
            otherwise
                error('Channel not available!')
        end
        
    case 1
        switch ico(2)
            case 1
                % set queue
                val = dec2bin(val*2, 5);
                queue = [];
                queue(5) = str2num(val(1));
                queue(4) = str2num(val(2));
                queue(3) = str2num(val(3));
                queue(2) = str2num(val(4));
                queue(1) = str2num(val(5));
    
                % latch low-high-low
                smdata.inst(ico(1)).data.digital.outputSingleScan(...
                    [queue 0]);
                smdata.inst(ico(1)).data.digital.outputSingleScan(...
                    [queue 1]);
                smdata.inst(ico(1)).data.digital.outputSingleScan(...
                    [queue 0]);
                
                smdata.inst(ico(1)).data.currentDigitalOutput = [queue 0];
                                
                val = 2 * bin2dec(num2str(val));
                
            otherwise
                error('Channel not available!')
        end
        
    case 6
        % this configures a NIDAQ Session with the NI PCIe-6363 to control
        % the digital step attenuator
        for dev = daq.getDevices
            if strcmp (dev.Description, 'National Instruments PCIe-6363')
                smdata.inst(ico(1)).data.id = dev.ID;
            end
        end
        
        % create default session for linear ramping of scanners
        smdata.inst(ico(1)).data.digital = daq.createSession('ni');
        
        % digital channels (PFI1-6)
        smdata.inst(ico(1)).data.digital.addDigitalChannel(...
            smdata.inst(ico(1)).data.id,...
            'port1/line1:6',...
            'OutputOnly'...
            );
        queue = zeros(1, length(smdata.inst(ico(1)).data.digital.Channels));
        smdata.inst(ico(1)).data.digital.outputSingleScan (queue);
        smdata.inst(ico(1)).data.currentDigitalOutput = queue;
end
end