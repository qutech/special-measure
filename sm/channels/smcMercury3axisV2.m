function val = smcMercury3axisV2(ico, val, rate)
%function val = smcMercury3axis(ico, val, rate)
% Driver for new 3 axis mercury power supply from oxford
% Warning! It is possible to remotely quench the magnet. The power supply
% does not know about the field limits of the magnet.
% It is therefore important to make sure the sub-function below isFieldSafe
% is properly populated
% We assume that only cartesian coordinates are used [X Y Z]
% channels are [Bx By Bz]
% here are the old comments from the IPS supply:
%ico: vector with instruemnt(index to smdata.inst), channel number for that instrument, operation
% operation: 0 - read, 1 - set , 2 - unused usually,  3 - trigger
% rate overrides default

%Might need in setup:
%channel 1: FIELD

% TODO:  max ramprate
%persistent mode after scan


if ico(3)==6
  warning('init not supported')
  return
end

global smdata;
mag = smdata.inst(ico(1)).data.inst;
% ico(2)
fclose(mag); fopen(mag); % this seems to make things less crappy

maxrate = .2; %.5 Tesla/min HARD CODED!!!!!

%set the coordinate system. always uses cartesian
%magwrite(mag,'SET:SYS:VRM:COO:CART');
%checkmag(mag);

% read current persistent field value
curr = getMagField(mag,'magnet'); %here, should be same as 'leads'
oldfieldval= curr;
persistentsetpoint = curr;

if ~exist('rate','var')
	rate = maxrate/60;
end

if ico(3)==1
	rateperminute = rate*60;
end

chan = ico(2);
if chan ~=1 && chan ~=2 && chan~=3 && chan~=4
	error('channel not programmed into Mercury');
end

switch ico(3) %operation
	case 0 %read
		switch ico(2)
			case {1,2,3}
				val = oldfieldval(ico(2));
			case 4
				val = ismagpersist(mag);
		end
	case 1 % standard magnet go to setpoint and holding there
		switch ico(2)
			case {1,2,3}
				%figure out the new setpoint
				newsp = getMagField(mag,'setpoint');
				newsp(ico(2)) = val;
				
				if ~isFieldSafe(newsp) %check that we are setting to a good value
					error('Unsafe field requested. Are you trying to kill me?');
				end
				
				% check that the path is ok
				if ~ispathsafe(oldfieldval,newsp)
					error('Path from current to final B goes outside of allowed range');
				end
				
				heateron = ~ismagpersist(mag);
				if ~heateron %magnet persistent at field or persistent at 0
					% any way to delay trigger
					if abs(rateperminute) > maxrate;
						error('Magnet ramp rate of %f too high. Must be less than %f T/min',rateperminute,maxrate)
					end
					
					if rateperminute<0
						% set to hold
						holdthemagnet(mag);
					end
					
					magwrite(mag,'SET:SYS:VRM:POC:ON'); %make it persistent on completion
					checkmag(mag);
					
					if ~all(curr==newsp) %only go through trouble if we're not at the target field
						
						if rateperminute > 0
							
							% switch on heater
							goNormal(mag); %has pauses and checks built in
							
							% set the field target
							%this command sets the mode to "rate," sets the
							%rate and sets the setpoint
							cmd = sprintf('SET:SYS:VRM:RVST:MODE:RATE:RATE:%f:VSET:[%f %f %f]',[rateperminute, newsp(:)']);
							magwrite(mag,cmd);
							checkmag(mag);
							% go to target field
							magwrite(mag,'SET:SYS:VRM:ACTN:RTOS');
							fscanf(mag,'%s');
							
							waittime = abs(norm(oldfieldval-newsp))/abs(rate);
							
							pause(waittime);
							waitforidle(mag);
							if ~ismagpersist(mag);
								goPers(mag);  % turn off switch heater
							end
							
							waitforidle(mag);
							val = 0;
						else
							% set the field target
							%this command sets the mode to "rate," sets the
							%rate and sets the setpoint
							cmd = sprintf('SET:SYS:VRM:RVST:MODE:RATE:RATE:%f:VSET:[%f %f %f]',[rateperminute, newsp(:)']);
							magwrite(mag,cmd);
							checkmag(mag);
							val = abs(norm(oldfieldval-newsp))/abs(rate);
						end
					end
					
				else % magnet not persistent
					
					magwrite(mag,'SET:SYS:VRM:POC:OFF'); %turn off persistent on completion
					checkmag(mag);
					
					% any way to delay trigger
					if abs(rateperminute) > maxrate
						error('Magnet ramp rate too high')
					end
					
					if rateperminute<0
						% set to hold
						holdthemagnet(mag);
					end
					
					% read the current field value
					curr = getMagField(mag,'leads'); %here it shouldnt matter if we pass 'magnet'
					
					% set the mode to "RATE", set rate, set field target
					cmd = sprintf('SET:SYS:VRM:RVST:MODE:RATE:RATE:%f:VSET:[%f %f %f]',[rateperminute, newsp(:)']);
					%                     fprintf('%s\n',cmd);
					magwrite(mag,cmd);
					checkmag(mag);
					
					val = abs(norm(oldfieldval-newsp))/abs(rate);
					
					if rateperminute>0
						
						% go to target field
						magwrite(mag,'SET:SYS:VRM:ACTN:RTOS');
						checkmag(mag);
						waitforidle(mag);
            val =0;  % added TB
					end
				end
			case 4 % Heater
				switch val
					% go normal
					case 0
						goNormal(mag);
						% go persistent
					case 1
						goPers(mag);
					otherwise
						display('Only 0/1 allowed');
				end
				
		end
		
	case 3 % trigger
		% go to target field FIXME
		magwrite(mag,'SET:SYS:VRM:ACTN:RTOS'); % new code
		checkmag(mag);
		
	otherwise
		error('operation not supported by mercury');
end
end

function bool=isFieldSafe(B)
% return 1 if inside 1T sphere, 2 if inside cyl, 0 if unsafe
bool=0;
if norm(B)<=1
	bool=1;
end
if (abs(B(3))<=1 && norm(B(1:2))<=.262)
	bool=bool+2;
end

end

function out =ismagpersist(mag)
magwrite(mag,'READ:SYS:VRM:SWHT');
state = fscanf(mag,'%s');
%   sh=sscanf(state,'STAT:SYS:VRM:SWHT:%s');
sh=sscanf(state,'STAT:SYS:VRM:SWHT:[NOSWNOSW%s');  %ST: WTF?!  


if isempty(sh)
	error('garbled communication: %s',state);
end

offs = strfind(sh,'OFF');
ons = strfind(sh,'ON');

%   if length(offs)==3 && isempty(ons)
if length(offs)==1 && isempty(ons)
	out = 1;
	%   elseif length(ons)==3 && isempty(offs)
elseif length(ons)==1 && isempty(offs)
	out = 0;
else
	error('switch heaters state confused. consider manual intervention. Heater state: %s',state);
	
end

end

function out = getMagField(mag, opts)
% read the current field value:
% returns [X Y Z];
% opts can be 'magnet' or 'leads' or 'setpoint'
% 'magnet' will be magnet field whether or not magnet is persistent
if strcmp(opts,'magnet')
	magwrite(mag,'READ:SYS:VRM:VECT');
	Btemp=fscanf(mag,'%s');
	B= sscanf(Btemp,'STAT:SYS:VRM:VECT:[%fT%fT%fT]');
	
elseif strcmp(opts,'leads')
	magwrite(mag,'READ:SYS:VRM:OVEC');
	Btemp=fscanf(mag,'%s');
	B= sscanf(Btemp,'STAT:SYS:VRM:OVEC:[%fT%fT%fT]');
	
elseif strcmp(opts,'setpoint')
	magwrite(mag,'READ:SYS:VRM:VSET');
	Btemp=fscanf(mag,'%s');
	B= sscanf(Btemp,'STAT:SYS:VRM:VSET:[%fT%fT%fT]');
else
	error('can only read magnet or lead fields');
end

if length(B)==3
	out = B;
else
	error('garbled comunications from mercury: %s', Btemp);
end
end


function goNormal(mag)
magwrite(mag,'SET:SYS:VRM:ACTN:NPERS');
checkmag(mag);
while ismagpersist(mag)
	pause(5);
end
waitforidle(mag);
end

function goPers(mag)
magwrite(mag,'SET:SYS:VRM:ACTN:PERS');
checkmag(mag);
while ~ismagpersist(mag)
	pause(5);
end
waitforidle(mag);
end


function out = ispathsafe(a,b)
% see if the path from a to b will quench magnet
% if they are both contained in the same allowed volume then is is safe

fa = isFieldSafe(a);
fb = isFieldSafe(b);

if fb==0 || fb ==0
	error('magnet fields unsafe');
end
out = bitand(uint8(fa),uint8(fb))>0;
end

function holdthemagnet(mag)
magwrite(mag,'SET:SYS:VRM:HOLD');
checkmag(mag);
end

function magwrite(mag,msg)
fprintf(mag,'%s\r\n',msg);
end

function checkmag(mag) % checks that communications were valid
outp=fscanf(mag,'%s');
%fprintf('%s\n',outp);
if isempty(strfind(outp,'VALID')) && isempty(strfind(outp,'BUSY'))
	fprintf('%s\n',outp);
	error('garbled magnet power communications: %s',outp);
end
end

function waitforidle(mag)
magwrite(mag,'READ:SYS:VRM:ACTN');
a=fscanf(mag,'%s');
a=sscanf(a,'STAT:SYS:VRM:ACTN:%s');
while ~strcmp(a,'IDLE')
	pause(1);
	magwrite(mag,'READ:SYS:VRM:ACTN');
	tmp=fscanf(mag,'%s');
	a=sscanf(tmp,'STAT:SYS:VRM:ACTN:%s');
end

end

function out =isZpersist(mag)
magwrite(mag,'READ:SYS:VRM:SWHT');
state = fscanf(mag,'%s');
sh=sscanf(state,'STAT:SYS:VRM:SWHT:[NOSWNOSW%s');


if isempty(sh)
	error('garbled communication: %s',state);
end

offs = strfind(sh,'OFF');
ons = strfind(sh,'ON');

if length(offs)==1 && isempty(ons)
	out = 1;
elseif length(ons)==1 && isempty(offs)
	out = 0;
else
	error('switch heaters not all the same. consider manual intervention. Heater state: %s',state);
	
end

end
