function train_genAllH5s
    %% Top level code that loads xml config, loads .mat ground truth file,
    %  then loops through all datapoints and calls genSingleH5s.m to form all H5 datacubes
    %
    % USAGE:
    %   train_genAllH5s;
    % INPUT:
    %   -
    % OUTPUT:
    %   -
    % THE UNIVERSITY OF BRISTOL: HAB PROJECT
    % Author Dr Paul Hill 26th June 2018
    % Updated March 2019 PRH
    % Updates for WIN compatibility: JVillegas 21 Feb 2019, Khalifa University
    clear; close all;

    if ismac,    xmlConfig= 'configHABmac.xml';
    elseif isunix
        [~, thisCmd] = system('rpm --query centos-release');
        isUnderDesk = strcmp(thisCmd(1:end-1),'centos-release-7-6.1810.2.el7.centos.x86_64');
        if isUnderDesk == 1, xmlConfig = 'configHABunderDesk.xml';
        else, xmlConfig = 'configHAB.xml';
        end
    elseif ispc, xmlConfig = 'configHAB_win.xml';
    end
    [confgData] = getHABConfig(xmlConfig);
    rmcommand= confgData.command.rm;
    pythonStr = confgData.command.pythonStr;
    
    system([confgData.command.rm confgData.outDir '*.h5']);
    load(confgData.inputFilename); 
    if confgData.numberOfSamples == -1;   confgData.numberOfSamples = length(count2); end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Loop through all samples in .mat Ground Truth File %%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    startIndex = 1;
    outputIndex = startIndex;
    for ii = startIndex: confgData.numberOfSamples %Loop through all the ground truth entries
         try
            if rem(ii,removeFreq) == 1 && ii>startIndex       % Delete the .nc files (every tenth one)
                system([rmcommand confgData.downloadDir '*.nc']);
            end

            inStruc.ii = ii;
            inStruc.thisLat = latitude(ii);
            inStruc.thisLon = longitude(ii);
            inStruc.dayEnd = sample_date(ii);
            inStruc.thisCount = count2(ii);
            
            fileName = ['Cube_' sprintf('%05d',outputIndex) '_' sprintf('%05d',ii) '_' num2str(sample_date(ii)) '.h5'];
            
            if isLandGEBCO(inStruc, confgData);  continue;  end
            
            inStruc.h5name = [confgData.outDir fileName];
            
            % Get single datacube H5
            genSingleH5s(inStruc, confgData);
            
            % Zip up the data and delete the original
            gzip(inStruc.h5name);
            system([rmcommand confgData.outDir '*.h5']);
            outputIndex = outputIndex+1;
        catch e   
            str_iden = num2str(ii);
            logErr(e,str_iden) 
            continue      
        end
    end
end


function logErr(e,str_iden)
    %fileID = fopen('errors.txt','at');
    %identifier = ['Error procesing sample ',str_iden, ' at ', datestr(now)];
    %text = [e.identifier, '::', e.message];
    %fprintf(fileID,'%s\n\r ',identifier);
    %fprintf(fileID,'%s\n\r ',text);
    %fclose(fileID);
end
