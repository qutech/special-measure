function [val, rate] = smcANC250(ico, val, rate, varargin)
% virtual instrument driver for scanning
global smdata

switch ico(3)
    case 0
        switch ico(2)
            case {1,2,3} % setZ/setY/setX
                val = subsref(smdata.inst(ico(1)).data.inst.getCurrentOutput(), ...
                    struct('type','()','subs',{{ico(2)}}));
                
        end

    case 1
        switch ico(2)
            case {1,2,3} % linrampZ/linrampY/linrampX
                curr = smdata.inst(ico(1)).data.inst.getCurrentOutput();
                curr(ico(2)) = val;
                if nargin > 3
                    smdata.inst(ico(1)).data.inst.travelXYZ(curr,rate,varargin{1});
                else
                    smdata.inst(ico(1)).data.inst.travelXYZ(curr,rate);
                end
                val = 0;
        end
        
    case 6
        smdata.inst(ico(1)).data.inst = myattoscanner();
        smdata.inst(ico(1)).data.inst.initNiSession();
                        
    otherwise
        error('Operation not supported!')
end