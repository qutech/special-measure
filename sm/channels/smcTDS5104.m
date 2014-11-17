function [val rate] = smcTDS5104(ico, val, rate, varargin)

global smdata;


switch ico(3)
    case 0
        
        %byten = query(TDS, 'WFMO:BYT_N?', '%s\n', '%d');
        if ico(2) <= 4
            fprintf(smdata.inst(ico(1)).data.inst, 'DAT:SOU CH%i', ico(2));
            while smdata.inst(ico(1)).data.nacq(ico(2)) < Inf && ...
                    smdata.inst(ico(1)).data.nacq(ico(2)) >= query(smdata.inst(ico(1)).data.inst, 'ACQ:NUMAC?', '%s\n', '%d');
%                 smdata.inst(ico(1)).data.nacq(ico(2))
%                 query(smdata.inst(ico(1)).data.inst, 'ACQ:NUMAC?', '%s\n', '%d')
%                 sprintf('line 17')
                pause(.02); % (.02); %(.3)
            end
            
            fprintf(smdata.inst(ico(1)).data.inst, 'CURV?');
            
            %ndig = fscanf(smdata.inst(ico(1)).data.inst, '#%d', 2);
            %nbyte = fscanf(smdata.inst(ico(1)).data.inst, '%d', ndig);
            ndig = sscanf(char(fread(smdata.inst(ico(1)).data.inst, 2)'), '#%d');
            nbyte = sscanf(char(fread(smdata.inst(ico(1)).data.inst, ndig)'), '%d');
            npts = smdata.inst(ico(1)).datadim(ico(2), 1);
            
            val = fread(smdata.inst(ico(1)).data.inst, npts, sprintf('int%d', nbyte/npts*8));
            
            fscanf(smdata.inst(ico(1)).data.inst);
            
            scale(1) =  query(smdata.inst(ico(1)).data.inst,'WFMP:YMU?', '%s\n', '%f');
            scale(2) =  query(smdata.inst(ico(1)).data.inst,'WFMP:YOFF?', '%s\n', '%f');
            scale(2) =  scale(2) - query(smdata.inst(ico(1)).data.inst,'WFMP:YZE?', '%s\n', '%f')/scale(1);
            
            
            val = (val-scale(2)) * scale(1);
            
            if smdata.inst(ico(1)).data.nacq(ico(2)) < Inf
                smdata.inst(ico(1)).data.nacq(ico(2)) = query(smdata.inst(ico(1)).data.inst, 'ACQ:NUMAC?', '%s\n', '%d');
            end
        else
            val = query(smdata.inst(ico(1)).data.inst, sprintf('MEASU:MEAS%d:VAL?', ico(2)-4), '%s\n', '%f');
        end
        
    case 3
        fprintf(smdata.inst(ico(1)).data.inst, 'TRIG FORCE');
        warning('scope TRIG:FORCE'); % RM

    
    case 4
        
    
    case 5
        
        fprintf(smdata.inst(ico(1)).data.inst, 'ACQ:STATE 0');
        fprintf(smdata.inst(ico(1)).data.inst,'HOR:POS 10');
        fprintf(smdata.inst(ico(1)).data.inst, 'TRIG:A:HOLD:BY TIME');
        
        fprintf(smdata.inst(ico(1)).data.inst, 'DAT:ENC SRIB');
        fprintf(smdata.inst(ico(1)).data.inst, 'HOR:ROLL OFF');
        % external clock
        fprintf(smdata.inst(ico(1)).data.inst, 'ROS:SOU EXT');
        
        % trigger delay
        fprintf(smdata.inst(ico(1)).data.inst,'HOR:DEL:MOD On');
        fprintf(smdata.inst(ico(1)).data.inst,'HOR:DEL:TIM 1E-6');
        fprintf(smdata.inst(ico(1)).data.inst,'HOR:POS 0');
        fprintf(smdata.inst(ico(1)).data.inst,'TRIG:A:MODE NORM');
        
        fprintf(smdata.inst(ico(1)).data.inst, 'HOR:MAI:SAMPLER %f', rate);
        if query(smdata.inst(ico(1)).data.inst, 'HOR:MAI:SAMPLER?', '%s\n', '%f') < rate;
            fprintf(smdata.inst(ico(1)).data.inst, 'HOR:MAI:SAMPLER %f', 2* rate);
        end
        
        rate = query(smdata.inst(ico(1)).data.inst, 'HOR:MAI:SAMPLER?', '%s\n', '%f');
        
        fprintf(smdata.inst(ico(1)).data.inst, 'HOR:RECO %d', val);
        if query(smdata.inst(ico(1)).data.inst, 'HOR:RECO?', '%s\n', '%d') < val;
            fprintf(smdata.inst(ico(1)).data.inst, 'HOR:RECO %d', 2*val);
        end
        
        val = query(smdata.inst(ico(1)).data.inst, 'HOR:RECO?', '%s\n', '%d');
        fprintf(smdata.inst(ico(1)).data.inst, 'DAT:STOP %d', val)
        fprintf(smdata.inst(ico(1)).data.inst, 'DAT:START 1');
        smdata.inst(ico(1)).datadim(1:4, 1) = val;
        
        pause(.5); % need a break for rearming.
        fprintf(smdata.inst(ico(1)).data.inst, 'ACQ:STATE 1');
        smdata.inst(ico(1)).data.nacq(1:4) = query(smdata.inst(ico(1)).data.inst, 'ACQ:NUMAC?', '%s\n', '%d');
        
    otherwise
        error('Operation not supported');
end
