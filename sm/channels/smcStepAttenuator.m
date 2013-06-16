function val = smcStepAttenuator (ico, val)
% function val = smcStepAttenuator (ico, val)
% This driver is tailored for usage with the NIDAQmx PCIe-6363. It uses
% PFI1-PFI6 as outputs with PFI6 being the control/latch bit.
global smdata
INST = sminstlookup('NIDAQmx');
CHANS = 38:43; %PFI1-PFI6

switch ico(3)
    case 1
        switch ico(2)
            case 1
                setBit([INST CHANS(6) 1], 0);
                
                val = dec2bin(val*2, 5);
                setBit([INST CHANS(5) 1], str2num(val(1)));
                setBit([INST CHANS(4) 1], str2num(val(2)));
                setBit([INST CHANS(3) 1], str2num(val(3)));
                setBit([INST CHANS(2) 1], str2num(val(4)));
                setBit([INST CHANS(1) 1], str2num(val(5)));
                
                setBit([INST CHANS(6) 1], 1);
                setBit([INST CHANS(6) 1], 0);
                
                val = 2 * bin2dec(num2str(val));
                
            otherwise
                error('Channel not available!')
        end
    case 0
        switch ico(2)
            case 1
                val(1) = getBit([INST, CHANS(5)]);
                val(2) = getBit([INST, CHANS(4)]);
                val(3) = getBit([INST, CHANS(3)]);
                val(4) = getBit([INST, CHANS(2)]);
                val(5) = getBit([INST, CHANS(1)]);
                
                val = bin2dec(num2str(val))/2;
                
            otherwise
                error('Channel not available!')
        end
end
end

function val = setBit(ic, val)
   retVal =  smcNIDAQmx([ic(1) ic(2) 1], val);
   
   if retVal ~= val
    error ('Error setting bit!')
   end
   
   val = retVal;
end

function val = getBit(ic)
    val = smcNIDAQmx([ic(1) ic(2) 0]);
end