function [val, rate] = smcANC250(ico, val, rate, varargin)
% virtual instrument driver for scanning
global smdata

switch ico(3)
    case 0
        switch ico(2)
            case {1,2,3} % setZ/setY/setX
                val = smdata.inst(ico(1)).data.currentOutput(ico(2));
                
            case {4,5,6} % setZ/setY/setX
                val = smdata.inst(ico(1)).data.currentOutput(ico(2)-3);
        end

    case 1
        switch ico(2)
            case {1,2,3} % linrampZ/linrampY/linrampX
                if nargin < 3
                    rate = 7.5;
%                     session = smdata.inst(ico(1)).data.travel;
                else
%                     session = smdata.inst(ico(1)).data.linramp;
                end
                session = smdata.inst(ico(1)).data.linramp;
                
                if rate > 0
                    queue = repmat(smdata.inst(ico(1)).data.currentOutput,...
                        smdata.inst(ico(1)).data.npoints,...
                        1);
                    queue(:,ico(2)) = linspace(...
                        smdata.inst(ico(1)).data.currentOutput(ico(2)),...
                        val,...
                        smdata.inst(ico(1)).data.npoints);
                    session.wait();
                    session.queueOutputData(queue);
                    smdata.inst(ico(1)).data.queue = queue;
                    
                    if max(abs(queue(end,:) - queue(1,:))) > 0
                        samprate = rate / ...
                            max(abs(queue(end,:) - queue(1,:))) * ...
                            smdata.inst(ico(1)).data.travelRatio * ...
                            smdata.inst(ico(1)).data.npoints;
                        if samprate > session.RateLimit(2)
                            samprate = session.RateLimit(2);
                        end                            
                        session.Rate = samprate;
                        session.prepare();
                        if ~isempty(session.Connections)
                            session.startBackground()
                            fcnGenerateDigitalTrigger();
                            while ~session.IsDone && session.IsRunning
                                session.wait();
                            end
                        else
                            session.startForeground();
                        end
                    end
                    smdata.inst(ico(1)).data.currentOutput = queue(end, :);
                elseif rate < 0
                    smdata.inst(ico(1)).data.queue(:,ico(2)) = linspace(...
                        smdata.inst(ico(1)).data.currentOutput(ico(2)),...
                        val,...
                        smdata.inst(ico(1)).data.npoints);
                    warning('off','all');
                    session.release();
                    warning('on','all');
                    queue = smdata.inst(ico(1)).data.queue;
                    session.queueOutputData(queue);
%                     samprate = abs(rate) / ...
%                         max(abs(queue(end,:) - queue(1,:))) * ...
%                         smdata.inst(ico(1)).data.npoints;
%                     if samprate > session.RateLimit(2)
%                         samprate = session.RateLimit(2);
%                     end
%                     session.Rate = samprate;
                end
                
            case {4,5,6} % setZ/setY/setX
                out = smdata.inst(ico(1)).data.currentOutput;
                out(ico(2)-3) = val;
                smdata.inst(ico(1)).data.linramp.outputSingleScan(out);
                smdata.inst(ico(1)).data.currentOutput = out;
        end
        
    case 3
        switch ico(2)
            case {1,2,3}
                smdata.inst(ico(1)).data.linramp.startBackground();
                smdata.inst(ico(1)).data.currentOutput = ...
                    smdata.inst(ico(1)).data.queue(end, :);
        end
            
    case 4
        switch ico(2)
            case {1,2,3}
                smdata.inst(ico(1)).data.linramp.startBackground();
                smdata.inst(ico(1)).data.currentOutput = ...
                    smdata.inst(ico(1)).data.queue(end, :);
        end
    case 6
        % this configures a NIDAQ Session with the NI PCIe-6363 to control
        % the scanners
        for dev = daq.getDevices
            if strcmp (dev.Description, 'National Instruments PCIe-6363')
                smdata.inst(ico(1)).data.id = dev.ID;
            end
        end
        
        % create default session for linear ramping of scanners
        smdata.inst(ico(1)).data.linramp = daq.createSession('ni');
        smdata.inst(ico(1)).data.linramp.addAnalogOutputChannel( ...
            smdata.inst(ico(1)).data.id,...
            0:2,...
            'Voltage'...
            );
        smdata.inst(ico(1)).data.linramp.outputSingleScan([0 0 0]);
        smdata.inst(ico(1)).data.currentOutput = [0 0 0];
        
        % helper session to quickly fix some behaviour of sm
        % should be replaced by a better concept at some point
        smdata.inst(ico(1)).data.travel = daq.createSession('ni');
        smdata.inst(ico(1)).data.travel.addAnalogOutputChannel( ...
            smdata.inst(ico(1)).data.id,...
            0:2,...
            'Voltage'...
            );
                        
    otherwise
        error('Operation not supported!')
end