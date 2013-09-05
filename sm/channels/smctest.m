function val = smctest(ic, val, rate)
% ico(3) = 5 sets number of channels to val
global smdata;

switch ic(3)
    case 1
        smdata.inst(ic(1)).data.val(ic(:, 2)) = val;
        if nargin >= 3
            %fprintf('%d %f %f\n',ic(:, 2), val, rate);
        else
            %fprintf('%d %f\n',ic(:, 2), val);
        end
    case 0
        val = smdata.inst(ic(1)).data.val(ic(:, 2));
        
    case 5 % change channel number
        smdata.inst(ic(1)).channels(val+1:end, :) = [];
        for i = val:-1:size(smdata.inst(ic(1)).channels, 1)
            smdata.inst(ic(1)).channels(i, :) =  sprintf('CH%02i', i);
        end
        smdata.inst(ic(1)).type = zeros(val, 1);
        smdata.inst(ic(1)).datadim = zeros(val, 0);
        
    otherwise
        error('Operation not supported');
end
