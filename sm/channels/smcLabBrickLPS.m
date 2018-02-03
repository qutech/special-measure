function [val, rate] = smcLabBrickLPS(ico,val,rate,varargin)
%function val = smcLabBrickLPS(ic, val, rate)
% Control function for the LabBrick Phase Shifter from Vaunix.
% Only minimal functionality is supported.
% 1: freq, 2: phase
global smdata;
% only works for one phase shifter in the setup. Extend if needed.
DEVICE = 1;

% Open the library if needed.
if ~libisloaded('VNX_dps64')
    loadlibrary('VNX_dps64.dll', 'vnx_lps_api.h')
    if ~libisloaded('VNX_dps64')
        error('Unable to load VNX_dps64');
    end
    calllib('VNX_dps64', 'fnLPS_GetNumDevices');
    calllib('VNX_dps64', 'fnLPS_InitDevice',uint32(DEVICE));
end

switch ico(3)
    case 0 %Get
        switch ico(2)
            case 1 %working frequency
                % returns in units of 100 kHz
                val = calllib('VNX_dps64', 'fnLPS_GetWorkingFrequency',uint32(DEVICE));
                val = 100e3*double(val);
            case 2 %phase angle
                val = calllib('VNX_dps64', 'fnLPS_GetPhaseAngle',uint32(DEVICE));
                val = double(val);
        end
        
    case 1 %Set
        switch ico(2)
            case 1 %working frequency
                % set in units of 100 kHz
                calllib('VNX_dps64', 'fnLPS_SetWorkingFrequency',...
                    uint32(DEVICE),int32(val/100e3));
            case 2 %phase angle
                calllib('VNX_dps64', 'fnLPS_SetPhaseAngle',...
                    uint32(DEVICE),int32(val));
        end
    otherwise
        error('Operation not supported!')
end
