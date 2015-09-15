% copyalladcp
%
% This function is meant to be called by: timer_adcpbackup_yq14
%
% This function copies all of the ADCP data from the ship's computer to a
% local computer. Right now it just recopies the entire folder every time.
% For now, this is okay. Possily, if a cruise gets really long, it should
% be rewritten so that the code checks the dates of all of the files and
% then only backs up the ones that have changed since the last backup.
% However, since the directory structure of the ADCP data is so complicated
% AND since the ADCP data only needs to be copied about every two hours AND
% because a day's worth of data takes about 15 seconds to copy, I am
% totally okay with not making this code more sleek. Time is of the essence
% right now. Possibly I will want to rewrite this while on the equator
% cruise in Fall 2014. A good reference will be: run_adcp_backup.
%
% Sally Warner, January 2014
%
%
%
%
set_currents_oceanus  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% copying from ship's computer to wdmycloud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% copy the UHDAS+CODAS data and all of its subdirectories
disp(['At ' datestr(now) ': Copying all of ' frompathbackup])
disp(['to ' topathbackup])
tic

% The ADCP code is very complicated with many many subdirectories. In the
% end, I will reprocess this data using the virtual machine (see
% UHDAS+CODAS documentation). When I reprocess, I recreate the gbins and
% the process folder. The important things are the raw files and the rbins.
% I will also bring in the processed data but not everything in the
% processed directory.
dirn = {'raw','ashtech','';...
        'raw','config','';...
        'raw','gpsnav','';...
        'raw','gyro','';...
        'raw','os75','';...
        'raw','os150','';...
        'raw','wh300','';...
        'rbin','ashtech','';...
        'rbin','gpsnav','';...
        'rbin','gyro','';...
%         'gbin','heading','';...
%         'gbin','os75','ashtech';...
%         'gbin','os75','gpsnav';...
%         'gbin','os75','gyro';...
%         'gbin','os75','time';...
%         'gbin','os150','ashtech';...
%         'gbin','os150','gpsnav';...
%         'gbin','os150','gyro';...
%         'gbin','os150','time';...
%         'gbin','wh300','ashtech';...
%         'gbin','wh300','gpsnav';...
%         'gbin','wh300','gyro';...
%         'gbin','wh300','time';...
        'proc','os75nb','contour';...
        'proc','os150nb','contour';...
        'proc','wh300','contour'};
    
% first, make all of the directories (they will not rewrite directories
% if the directory already exists)
warning off
for dd = 1:length(dirn) 
    mkdir([topathbackup char(dirn(dd,1))])
    mkdir([topathbackup char(dirn(dd,1)) filesep char(dirn(dd,2))])
    mkdir([topathbackup char(dirn(dd,1)) filesep char(dirn(dd,2))...
        filesep char(dirn(dd,3))])
end
warning on

for dd = 1:length(dirn)
    clear ddfrom ddto fromdates todates frommax tomax indcopy
    
    disp(['copying files to: ' topathbackup char(dirn(dd,1)) filesep ...
                char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep])
    
    % first, compare the datenum when the last file was written in each folder
    ddfrom = dir([frompathbackup char(dirn(dd,1)) filesep char(dirn(dd,2))...
        filesep char(dirn(dd,3))]);
    ddto   = dir([topathbackup char(dirn(dd,1)) filesep char(dirn(dd,2))...
        filesep char(dirn(dd,3))]);
    if length(ddto) <3
        copyfile([frompathbackup char(dirn(dd,1)) filesep ...
            char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep],...
            [topathbackup char(dirn(dd,1)) filesep ...
            char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep])
    else     
        for ii = 1:length(ddfrom)
            fromdates(ii) = ddfrom(ii).datenum;
        end
        for ii = 1:length(ddto)
            todates(ii) = ddto(ii).datenum;
        end
        frommax = max(fromdates);
        tomax   = max(todates);

        % now, copy any file that is in the from-directory that's newer than files
        % in the to-directory
        if frommax > tomax
            indcopy = find(fromdates > tomax);
            for ii = 1:length(indcopy)
                copyfile([frompathbackup char(dirn(dd,1)) filesep ...
                    char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep...
                    ddfrom(indcopy(ii)).name],...
                    [topathbackup char(dirn(dd,1)) filesep ...
                    char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep])
            end
        end  
    end
end     

toc
disp('')


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % copying from ship's computer to oobleck (my local computer)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% % copy the UHDAS+CODAS data and all of its subdirectories
% disp(['At ' datestr(now) ': Copying all of ' frompathbackup])
% disp(['to ' topathbackuplocal])
% tic
% 
% % The ADCP code is very complicated with many many subdirectories. In the
% % end, I will reprocess this data using the virtual machine (see
% % UHDAS+CODAS documentation). When I reprocess, I recreate the gbins and
% % the process folder. The important things are the raw files and the rbins.
% % I will also bring in the processed data but not everything in the
% % processed directory.
% dirn = {'raw','ashtech','';...
%         'raw','config','';...
%         'raw','gpsnav','';...
%         'raw','gyro','';...
%         'raw','os75','';...
%         'raw','os150','';...
%         'raw','wh300','';...
%         'rbin','ashtech','';...
%         'rbin','gpsnav','';...
%         'rbin','gyro','';...
% %         'gbin','heading','';...
% %         'gbin','os75','ashtech';...
% %         'gbin','os75','gpsnav';...
% %         'gbin','os75','gyro';...
% %         'gbin','os75','time';...
% %         'gbin','os150','ashtech';...
% %         'gbin','os150','gpsnav';...
% %         'gbin','os150','gyro';...
% %         'gbin','os150','time';...
% %         'gbin','wh300','ashtech';...
% %         'gbin','wh300','gpsnav';...
% %         'gbin','wh300','gyro';...
% %         'gbin','wh300','time';...
%         'proc','os75nb','contour';...
%         'proc','os150nb','contour';...
%         'proc','wh300','contour'};
%     
% % first, make all of the directories (they will not rewrite directories
% % if the directory already exists)
% warning off
% for dd = 1:length(dirn) 
%     mkdir([topathbackuplocal char(dirn(dd,1))])
%     mkdir([topathbackuplocal char(dirn(dd,1)) filesep char(dirn(dd,2))])
%     mkdir([topathbackuplocal char(dirn(dd,1)) filesep char(dirn(dd,2))...
%         filesep char(dirn(dd,3))])
% end
% warning on
% 
% for dd = 1:length(dirn)
%     clear ddfrom ddto fromdates todates frommax tomax indcopy
%     
%     disp(['copying files to: ' topathbackuplocal char(dirn(dd,1)) filesep ...
%                 char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep])
%     
%     % first, compare the datenum when the last file was written in each folder
%     ddfrom = dir([frompathbackup char(dirn(dd,1)) filesep char(dirn(dd,2))...
%         filesep char(dirn(dd,3))]);
%     ddto   = dir([topathbackuplocal char(dirn(dd,1)) filesep char(dirn(dd,2))...
%         filesep char(dirn(dd,3))]);
%     if length(ddto) <3
%         copyfile([frompathbackup char(dirn(dd,1)) filesep ...
%             char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep],...
%             [topathbackuplocal char(dirn(dd,1)) filesep ...
%             char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep])
%     else     
%         for ii = 1:length(ddfrom)
%             fromdates(ii) = ddfrom(ii).datenum;
%         end
%         for ii = 1:length(ddto)
%             todates(ii) = ddto(ii).datenum;
%         end
%         frommax = max(fromdates);
%         tomax   = max(todates);
% 
%         % now, copy any file that is in the from-directory that's newer than files
%         % in the to-directory
%         if frommax > tomax
%             indcopy = find(fromdates > tomax);
%             for ii = 1:length(indcopy)
%                 copyfile([frompathbackup char(dirn(dd,1)) filesep ...
%                     char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep...
%                     ddfrom(indcopy(ii)).name],...
%                     [topathbackuplocal char(dirn(dd,1)) filesep ...
%                     char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep])
%             end
%         end  
%     end
% end     
% 
% toc
% disp('')
% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% copy the ADCP data that has been processed by Sasha's code to wdmycloud
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

disp(['At ' datestr(now) ': Copying all of ' procfrompath])
disp(['to ' proctopath])
tic
clear dirn
dirn = {'os75','nobottomtrk','1min';...
        'os75','nobottomtrk','singleping';...
        'os150','nobottomtrk','1min';...
        'os150','nobottomtrk','singleping';...
        'wh300','nobottomtrk','1min';...
        'wh300','nobottomtrk','singleping';...
        'os75','bottomtrk','1min';...
        'os75','bottomtrk','singleping';...
        'os150','bottomtrk','1min';...
        'os150','bottomtrk','singleping';...
        'wh300','bottomtrk','1min';...
        'wh300','bottomtrk','singleping'};

% first, make all of the directories (they will not rewrite directories
% if the directory already exists)
warning off
for dd = 1:length(dirn) 
    mkdir([proctopath char(dirn(dd,1))])
    mkdir([proctopath char(dirn(dd,1)) filesep char(dirn(dd,2))])
    mkdir([proctopath char(dirn(dd,1)) filesep char(dirn(dd,2))...
        filesep char(dirn(dd,3))])
end
warning on

for dd = 1:length(dirn)
    clear ddfrom ddto fromdates todates frommax tomax indcopy
    
    disp(['copying files to: ' proctopath char(dirn(dd,1)) filesep ...
        char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep])
            
    % first, compare the datenum when the last file was written in each folder
    ddfrom = dir([procfrompath char(dirn(dd,1)) filesep char(dirn(dd,2))...
        filesep char(dirn(dd,3)) filesep]);
    ddto   = dir([proctopath char(dirn(dd,1)) filesep char(dirn(dd,2))...
        filesep char(dirn(dd,3)) filesep]);
    
    if length(ddto) < 3
        copyfile([procfrompath char(dirn(dd,1)) filesep ...
            char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep],...
            [proctopath char(dirn(dd,1)) filesep ...
            char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep],'f')
    else
        for ii = 1:length(ddfrom)
            fromdates(ii) = ddfrom(ii).datenum;
        end
        for ii = 1:length(ddto)
            todates(ii) = ddto(ii).datenum;
        end
        frommax = max(fromdates);
        tomax   = max(todates);

        % now, copy any file that is in the from-directory that's newer than files
        % in the to-directory
        if frommax > tomax
            indcopy = find(fromdates > tomax);
            for ii = 1:length(indcopy)
                copyfile([procfrompath char(dirn(dd,1)) filesep ...
                    char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep...
                    ddfrom(indcopy(ii)).name],...
                    [proctopath char(dirn(dd,1)) filesep ...
                    char(dirn(dd,2)) filesep char(dirn(dd,3)) filesep])
            end
        end
    end
            
end     

toc
