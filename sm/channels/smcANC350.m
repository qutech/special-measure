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
        loadParamFile(smdata.inst(ico(1)).data.devHandle,...
            smdata.inst(ico(1)).data.paramFile);
    end
end

switch ico(3)
    case 0
        switch ico(2)
            case 1
                val = getANC350(smdata.inst(ico(1)).data.devHandle,...
                    'Position','x');
                val = double(val);
            case 2
                val = getANC350(smdata.inst(ico(1)).data.devHandle,...
                    'Position','y');
                val = double(val);
            case 3
                val = getANC350(smdata.inst(ico(1)).data.devHandle,...
                    'Position','z');
                val = double(val);
        end
        
    case 1
        switch ico(2)
            case 1
                moveANC350(smdata.inst(ico(1)).data.devHandle,'x',...
                    'abs', val);
            case 2
                moveANC350(smdata.inst(ico(1)).data.devHandle,'y',...
                    'abs', val);
            case 3
                moveANC350(smdata.inst(ico(1)).data.devHandle,'z',...
                    'abs', val);
            otherwise
                error('Operation not supported!')
        end
end
end

function retCode = callANC350(cmd,varargin)
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
elseif retCode <= length(codes)
    error('Call to library returned with error code %s', codes{retCode})
else
    error('Call to library returned with error code NCB_Error')
end
end

function moveANC350(handle,axis,ref,pos)
% @param_in axis: specify either 'x', 'y', 'z'
% @param_in ref: either 'abs' for absolute or 'rel' for relative
% positioning
% @param_in: position or distance, depending on argument ref,
% specified in microns (native unit of the ANP101)
axis = (...
    1 * strcmpi(axis,'z')...
    + 2 * strcmpi(axis,'y')...
    + 3 * strcmpi(axis,'x')...
    ) - 1;

if strcmp(ref,'abs')
    cmd = 'PositionerMoveAbsolute';
elseif strcmp(ref,'rel')
    cmd = 'PositionerMoveRelative';
else
    error('Invalid argument for input argument ''ref''')
end

pos = int32(pos*1000);
callANC350(cmd,handle,axis,pos);
end

function val = getANC350(handle,cmd,varargin)
if strcmpi(cmd,'Position')
    axis = (...
        1 * strcmpi(varargin{1},'z')...
        + 2 * strcmpi(varargin{1},'y')...
        + 3 * strcmpi(varargin{1},'x')...
        ) - 1;
    val = libpointer('int32Ptr', -2^16);
    callANC350('PositionerGetPosition',handle,axis,val);
    val = val.Value / 1000;
    return;
end
end

function loadParamFile(handle,path)
% load file for each axis, preconfigured such that 0==z, 1==y,
% 2==x
callANC350('PositionerLoad',handle,0,...
    [path 'ANPz101res.aps']);
callANC350('PositionerLoad',handle,1,...
    [path 'ANPx101res.aps']);
callANC350('PositionerLoad',handle,2,...
    [path 'ANPx101res.aps']);
end