function [val, rate] = smcAtsPython(ico, val, rate, varargin)
global smdata;

% python class AlazarCard
device = smdata.inst(ico(1)).data.python_card_wrapper;

%config field
%smdata.inst(ico(1)).data.config


% OPERATION SWITCH
switch ico(3)
  
  %--------------------------------%
  % OPERATION 0: Get channel value %
  %--------------------------------%
  case 0
      val = python_to_MATLAB( device.MATLAB_getOperationResult( uint32(ico(2)) ) );

  %---------------------------------------%
  % OPERATION 1: Set channel value to val %
  %---------------------------------------%
  case 1
      error('Set channel capabilities have been removed.');
    
  %---------------------------------------------------%  
  % OPERATION 3: force trigger if not externally done %
  %---------------------------------------------------%
  case 3
    device.forceTrigger();
    display('AlazarCard: tiggered\n');
    
  %------------------------------------------------%
  % OPERATION 4: Start/Re-arm acquisition          %
  %------------------------------------------------%
  case 4
      device.startAcquisition(1)
       
  %------------------------------%
  % OPERATION 5: configure board %
  %------------------------------%
  case 5    
    smdata.inst(ico(1)).datadim =  zeros(1, length( smdata.inst(ico(1)).data.config.operations ));
    
    for op_i = 1:length(smdata.inst(ico(1)).data.config.operations)
        mask = smdata.inst(ico(1)).data.config.masks{ smdata.inst(ico(1)).data.config.operations{op_i}.mask };
        
        switch smdata.inst(ico(1)).data.config.operations{op_i}.type
            case 'DS'
                switch mask.type
                    case 'Periodic Mask'
                        smdata.inst(ico(1)).datadim(op_i) = smdata.inst(ico(1)).data.config.total_record_size / mask.period;
                    case 'Auto Mask'
                        smdata.inst(ico(1)).datadim(op_i) = length(mask.begin);
                    otherwise
                        error('Unknown mask: %s',mask.type);
                end
            case 'REP AV'
                switch mask.type
                    case 'Periodic Mask'
                        smdata.inst(ico(1)).datadim(op_i) = mask.end-mask.begin;
                    case 'Auto Mask'
                        smdata.inst(ico(1)).datadim(op_i) = mask.length(1);
                    otherwise
                        error('Unknown mask: %s',mask.type);
                end
            otherwise
                error('Unknown operation: %s',smdata.inst(ico(1)).data.config.operations{op_i}.type);
        end
    end
    
    device.applyConfiguration( py.atsaverage.config.ScanlineConfiguration.parse(smdata.inst(ico(1)).data.config) );
    
    
    case 6
        if strcmp(smdata.inst(ico(1)).data.address,'local')
            smdata.inst(ico(1)).data.python_card = py.atsaverage.core.getLocalCard(1,1);
        else
            smdata.inst(ico(1)).data.python_card = py.atsaverage.client.getNetworkCard( smdata.inst(ico(1)).data.address, pyargs('keyfile',smdata.inst(ico(1)).data.keyfile) );
        end
        smdata.inst(ico(1)).data.python_card_wrapper = wrapCardFunctions(smdata.inst(ico(1)).data.python_card);
        
    case 99
        smdata.inst(ico(1)).data.config = varargin{1};
  otherwise
    error('Operation not supported: %i', ico(3));
end
end
