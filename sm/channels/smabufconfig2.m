function scan = smabufconfig2(scan, cntrl, getrng, setrng, loop, varargin)
% scan = smabufconfig2(scan, cntrl, getrng, setrng, loop)
% Configure buffered acquisition for fastest loop using drivers. 
% Supersedes smarampconfig/smabufconfig if driver provides this
% functionality.
%
% cntrl: trig : use smatrigfn for triggering
%         arm : use smatrigfn to arm insts in loops(2).prefn(1)
%         fast: change behavior to not use rate and time of first loop.
%               Instead, setrng = [npts, rate, varargin], loop = loop to be used (default = 1)
%               Without fast setrng is only the varargin for the driver
%               call
% getrng: indices to loops(2).getchan to be programmed (and armed/triggered).
%   
% Possible extensions (not implemented): 
% - configure decimation (see smarampconfig for code)

global smdata;


if nargin < 2 
    cntrl = '';
end

if strfind(cntrl, 'fast')
    if nargin < 5
        loop = 1;
    end
else
    if ~exist('loop', 'var')
        loop = 2;
    end
    
    setic = smchaninst(scan.loops(1).setchan);
    if nargin >= 4
        setic = setic(setrng, :);
    end
end

getic = smchaninst(scan.loops(loop).getchan);
if nargin >= 3
   getic = getic(getrng, :);
end

if strfind(cntrl, 'fast')
    args = num2cell(setrng);  
    for i = 1:size(getic, 1)
        smdata.inst(getic(i, 1)).cntrlfn([getic(i, :), 5], args{:});
        % mol: do not know what this line is for, I guess debugging
        %[setrng(1), setrng(2)] = smdata.inst(getic(i, 1)).cntrlfn([getic(i, :), 5], setrng(1), setrng(2));
    end
else
    for i = 1:size(getic, 1)
        if nargin > 5
          args = varargin;
        else
          args = {};
        end
        [scan.loops(1).npoints, rate] = smdata.inst(getic(i, 1)).cntrlfn([getic(i, :), 5], scan.loops(1).npoints, ...
            1/abs(scan.loops(1).ramptime), args{:});
        scan.loops(1).ramptime = sign(scan.loops(1).ramptime)/abs(rate);
    end
end

if strfind(cntrl, 'trig')
  if ~exist('setic', 'var')
    setic = [];
  end
  
  if ~exist('getic', 'var')
    getic = [];
  end
  
  scan.loops(1).trigfn.fn = @smatrigfn;
        scan.loops(1).trigfn.args = {[setic; getic]};
end

if strfind(cntrl, 'arm')
    if strfind(cntrl,'end') % bad hack, need to fix this
      scan.loops(loop).prefn(end+1).fn = @smatrigfn;
      scan.loops(loop).prefn(end).args = {getic, 4};  
    else
      scan.loops(loop).prefn(1).fn = @smatrigfn;
      scan.loops(loop).prefn(1).args = {getic, 4};
    end
end
