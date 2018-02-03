function [val, rate] = smcANC350(ico, val, rate, varargin)
global smdata

if ~libisloaded('hvpositionerv2')
    if strcmpi(computer('arch'), 'win64')
        libname='hvpositionerv2_ia64';
    else
        libname='hvpositionerv2';
    end
    loadlibrary([libname '.dll'],[libname '.h'],'alias','hvpositionerv2');
    
    posInfo = libstruct('PositionerInfo');
    numDevices = calllib('hvpositionerv2','PositionerCheck',posInfo);
    if numDevices < 1
        error('No device detected!')
    end
    
    devHandle = libpointer('int32Ptr', 0);
    devNo = int32(0);
    % connect to device
    callANC350('PositionerConnect',devNo,devHandle);
    smdata.inst(ico(1)).data.devHandle = devHandle.Value;
    
    if ~isempty(smdata.inst(ico(1)).data.paramFile)
        % load file for each axis, preconfigured such that 0==z, 1==y,
        % 2==x
        callANC350('PositionerLoad',devHandle.Value,0,...
            [path 'ANPz101res.aps']);
        callANC350('PositionerLoad',devHandle.Value,1,...
            [path 'ANPx101res.aps']);
        callANC350('PositionerLoad',devHandle.Value,2,...
            [path 'ANPx101res.aps']);
    end
end

switch ico(3)
    case 0
        switch ico(2)
            case [{1},{2},{3}] % anc350 axis index starts at 0
                val = libpointer('int32Ptr', -2^16);
                callANC350('PositionerGetPosition',...
                    smdata.inst(ico(1)).data.devHandle,ico(2)-1,val);
                val = double(val.Value / 1000);
           
            case 4
                val = smdata.inst(ico(1)).data.staticAmplitude/1000;
                
        end
        
    case 1
        switch ico(2)
            case [{1},{2},{3}] % anc350 axis index starts at 0
                pos = int32(val*1000);
                callANC350('PositionerMoveAbsolute',...
                    smdata.inst(ico(1)).data.devHandle,ico(2)-1,pos);
                
            case 4
                callANC350('PositionerStaticAmplitude',...
                    smdata.inst(ico(1)).data.devHandle,...
                    int32(val*1000));
                smdata.inst(ico(1)).data.staticAmplitude = int32(val);
                
            otherwise
                error('Operation not supported!')
        end
end
end

function retCode = callANC350(cmd,varargin)
% return codes for ANC350, copied from hvpositionerv2.h
% Rückgabewerte der Funktionen
% #define NCB_Ok               0      Kein Fehler
% #define NCB_Error            (-1)   Unbekannter/sonstiger Fehler
% #define NCB_Timeout          1      Timeout bei Datenabruf
% #define NCB_NotConnected     2      Kein Kontakt zum Positioner über USB
% #define NCB_DriverError      3      Fehler bei der Treiberansprache
% #define NCB_BootIgnored      4      Booten ignoriert, Gerät lief schon
% #define NCB_FileNotFound     5      Boot-Image nicht gefunden
% #define NCB_InvalidParam     6      Übergebener Parameter ungültig
% #define NCB_DeviceLocked     7      Ein Verbindungsversuch schlug fehl, da das Device schon verwendet wird
% #define NCB_NotSpecifiedParam 8     Übergebener Parameter ist außerhalb der Spezifikation
retCode = calllib('hvpositionerv2',cmd,varargin{:});

codes = {'NCB_TimeOut','NCB_NotConnected','NCB_DriverError','NCB_BootIgnored',...
    'NCB_FileNotFound','NCB_InvalidParam','NCB_DeviceLocked','NCB_NotSpecifiedParam'};
if retCode == 0
    return;
elseif retCode <= length(codes) && retCode > 0
    error('Call to library returned with error code %s', codes{retCode})
elseif retCode == -1
    error('Call to library returned with error code NCB_Error')
else
    error('Unknown return code')
end
end