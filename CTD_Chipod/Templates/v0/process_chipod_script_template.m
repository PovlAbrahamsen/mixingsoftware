%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
% process_chipod_script_template.m
%
% Script to do CTD-chipod processing.
%
% This script is part of CTD_Chipod software folder in the the mixingsoftware github repo.
% For latest version, download/sync the mixingsoftware github repo at
% https://github.com/OceanMixingGroup/mixingsoftware
%
% ~~Before running this script:
% - This script assumes that CTD data has been processed in a standard form
% (see folder 'ctd_processing'). CTD data are used for two purposes: (1) the
% 24Hz data is used to compute dp/dt and compare with chipod acceleration to
% find the time offset . (2) lower resolution (here 1m) N^2 and dTdz are
% needed to compute chi.
% - The raw Chipod data files need to be downloaded and saved as well. They should
% be in folders named by SN (ie /1002)
%
% Instructions to run:
% 1) Copy this file and save a new version with your cruise name to the end
% of the filename.
% 2) Modify paths for your computer and cruise % Note - I have tried to put
% '***' where you need to change paths.
% 3) Modify the chipod deployment info for your cruise.
% 4) Run!
%
% OUTPUT:
%  Saves a file for each cast and chipod with:
% - avg : Structure with estimated chi, epsilon, KT etc.
% - ctd
% - Writes a text file called 'Results.txt' that summarizes the settings used
% and the results (whether it found a chipod file, if it had good data etc.
% for each cast).
%
%
% 18 May 2015 - A. Pickering - apickering@coas.oregonstate.edu
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%%

clear ; close all ; clc

% *** To record in output which script was used
this_script_name='process_chipod_script_template.m'

tstart=tic;

%~~~~ '***' means Modify these paths for your cruise/computer ~~~~

% *** add path for 'mixingsoftware' ***
mixpath='/Users/Andy/Cruises_Research/mixingsoftware/'
% add subfolders we need
addpath(fullfile(mixpath,'CTD_Chipod'))
addpath(fullfile(mixpath,'general')) % makelen.m in /general is needed
addpath(fullfile(mixpath,'marlcham')) % for integrate.m
addpath(fullfile(mixpath,'adcp')) % need for mergefields_jn.m in load_chipod_data

% *** Base directory for processed CTD data
CTD_out_dir_root='/Users/Andy/Cruises_Research/mixingsoftware/CTD_Chipod/TestData/CTD/Processed/'

% Folder for processed 24Hz CTD data
CTD_out_dir_raw=fullfile(CTD_out_dir_root,'raw')

% Folder to save processed and binned (1m) CTD mat files to
CTD_out_dir_bin=fullfile(CTD_out_dir_root,'binned')

% Folder to save processed figures to
CTD_out_dir_figs=fullfile(CTD_out_dir_root,'figures')

%*** Folder where chipod data files are
chi_data_path='/Users/Andy/Cruises_Research/mixingsoftware/CTD_Chipod/TestData/Chipod/raw/'

%*** Folder for processed chipod data
chi_processed_path='/Users/Andy/Cruises_Research/mixingsoftware/CTD_Chipod/TestData/Chipod/processed/'

% path to save figures to
chi_fig_path=fullfile(chi_processed_path, 'figures');
ChkMkDir(chi_fig_path)

% Make a list of all ctd files
% *** replace 'TestData' with name that is in your ctd files ***
CTD_list=dir(fullfile(CTD_out_dir_raw, '*TestData_*.mat'));

%--- make a text file to print a summary of results to
txtfname=['Results' datestr(floor(now)) '.txt'];
 
if exist(fullfile(chi_processed_path,txtfname),'file')
    delete(fullfile(chi_processed_path,txtfname))
end

fileID= fopen(fullfile(chi_processed_path,txtfname),'a');
fprintf(fileID,['\n \n CTD-chipod Processing Summary\n']);
fprintf(fileID,['\n \n Created ' datestr(now) '\n']);
fprintf(fileID,'\n CTD path \n');
fprintf(fileID,[CTD_out_dir_root '\n']);
fprintf(fileID,'\n Chipod data path \n');
fprintf(fileID,[chi_data_path '\n']);
fprintf(fileID,'\n Chipod processed path \n');
fprintf(fileID,[chi_processed_path '\n']);
fprintf(fileID,'\n figure path \n');
fprintf(fileID,[chi_fig_path '\n \n']);
fprintf(fileID,[' \n There are ' num2str(length(CTD_list)) ' CTD files' ]);
%---

% start a waitbar
hb=waitbar(0,'Looping through ctd files');

% loop through casts and do processing for each ctd file
for a=1
    
    close all
    clear castname tlim time_range cast_suffix_tmp cast_suffix CTD_24hz
    
    % update waitbar
    waitbar(a/length(CTD_list),hb)
    
    castname=CTD_list(a).name;
    
    fprintf(fileID,[' \n \n ~' castname ]);
    
    %load 24Hz CTD profile (in a structure named 'data2')
    load(fullfile(CTD_out_dir_raw, castname))
    CTD_24hz=data2;clear data2
    CTD_24hz.ctd_file=castname;

    % Sometimes the 24hz ctd time needs to be converted from computer time into matlab (datenum?) time.
    tlim=now+5*365;
    if CTD_24hz.time > tlim
        tmp=linspace(CTD_24hz.time(1),CTD_24hz.time(end),length(CTD_24hz.time));
        CTD_24hz.datenum=tmp'/24/3600+datenum([1970 1 1 0 0 0]);
    end
    
    % get time limits for this cast
    time_range=[min(CTD_24hz.datenum) max(CTD_24hz.datenum)];
    
    % ** this might not work for other cruises/names ? - AP **
    cast_suffix_tmp=CTD_list(a).name; % Cast # may be different than file #. JRM
    cast_suffix=cast_suffix_tmp(end-8:end-6);
    
    %*** Load chipod deployment info ( needs to be modified for each cruise)
    Chipod_Deploy_Info_template
    
    % loop through each chipod sensor on CTD
    for up_down_big=1
        
        close all
        
        switch up_down_big
            case 1
                whSN='SN1012'; %
            case 2;
                whSN='SN1002' ;%
        end
        
        % get info for this sensor
        this_chi_info=ChiInfo.(whSN);
        clear chi_path az_correction suffix isbig cal is_downcast
        chi_path=fullfile(chi_data_path,this_chi_info.loggerSN);
        suffix=this_chi_info.suffix;
        isbig=this_chi_info.isbig;
        cal=this_chi_info.cal;
        az_correction=this_chi_info.az_correction;
        
        fprintf(fileID,[ ' \n \n ' whSN ]);
        
        d.time_range=datestr(time_range); % Time range of cast
        
        % specific paths for processed data from this instrument
        chi_processed_path_specific=fullfile(chi_processed_path,['chi_' whSN ]);
        ChkMkDir(chi_processed_path_specific)        
        chi_fig_path_specific=fullfile(chi_fig_path,['chi_' whSN ]);
        ChkMkDir(chi_fig_path_specific)
        
        % filename for processed chipod data (will check if already exists)
        processed_file=fullfile(chi_processed_path_specific,['cast_' cast_suffix '_' whSN '.mat']);
        
        %~~ Load chipod data
        if  1 %~exist(processed_file,'file')
            %load(processed_file)
            %            else
            
            % find and load chipod data for this time range, and plot raw
            % data
            disp('loading chipod data')
            chidat=load_chipod_data(chi_path,time_range,suffix,isbig,1);
            ab=get(gcf,'Children');
            axes(ab(end));
            title([whSN ' - ' castname ' - Raw Data '],'interpreter','none')            
            % save plot
            print('-dpng',fullfile(chi_fig_path,['chi_' whSN],[whSN '_cast_' cast_suffix '_Fig1_RawChipodTS']))
                        
            chidat.time_range=time_range;
            chidat.castname=castname;
            
            % save the file with chipod data for just this cast
            save(processed_file,'chidat')
            
            % carry over chipod info into this structure
            chidat.Info=this_chi_info;
            chidat.cal=this_chi_info.cal;
            
            % if there is enough good data, continue processing
            if length(chidat.datenum)>1000
                
                % find time-offset and align with CTD
                [CTD_24hz chidat]=AlignChipodCTD(CTD_24hz,chidat,az_correction,1);
                print('-dpng',fullfile(chi_fig_path,['chi_' whSN],[whSN '_cast_' cast_suffix '_Fig2_w_TimeOffset']))
                
                % zoom in and plot again (*check that alignment is correct)
                xlim([nanmin(chidat.datenum) nanmin(chidat.datenum)+400/86400])
                print('-dpng',fullfile(chi_fig_path,['chi_' whSN],[whSN '_cast_' cast_suffix '_Fig3_w_TimeOffset_Zoom']))
                
                % Calibrate chipod T and dT/dt
                [CTD_24hz chidat]=CalibrateChipodCTD(CTD_24hz,chidat,az_correction,1);
                print('-dpng',fullfile(chi_fig_path,['chi_' whSN],[whSN '_cast_' cast_suffix '_Fig4_dTdtSpectraCheck']))
                                
                % save file again, with time-offset and calibration added
                save(processed_file,'chidat')
                
                % check if T1 calibration is ok
                clear out2 err pvar
                out2=interp1(chidat.datenum,chidat.cal.T1,CTD_24hz.datenum);
                err=out2-CTD_24hz.t1;
                pvar=100* (1-(nanvar(err)/nanvar(CTD_24hz.t1)) );
                if pvar<50
                    disp('Warning T calibration not good')
                    fprintf(fileID,' *T calibration not good* ');
                end
                
                % check if T2 calibration is ok
                clear out2 err pvar
                out2=interp1(chidat.datenum,chidat.cal.T2,CTD_24hz.datenum);
                err=out2-CTD_24hz.t1;
                pvar=100* (1-(nanvar(err)/nanvar(CTD_24hz.t1)) );
                if pvar<50
                    disp('Warning T2 calibration not good')
                    fprintf(fileID,' *T2 calibration not good* ');
                end
                
                %~~ Make a timeseries plot of the aligned and calibr. data
                do_timeseries_plot=1;
                if do_timeseries_plot                    
                    h=ChiPodTimeseriesPlot(CTD_24hz,chidat)
                    axes(h(1))
                    title(['Cast ' cast_suffix ', ' whSN '  ' datestr(time_range(1),'dd-mmm-yyyy HH:MM') '-' datestr(time_range(2),15) ', ' CTD_list(a).name],'interpreter','none')
                    axes(h(end))
                    xlabel(['Time on ' datestr(time_range(1),'dd-mmm-yyyy')])                    
                    print('-dpng','-r300',fullfile(chi_fig_path,['chi_' whSN],[whSN '_cast_' cast_suffix '_Fig5_T_P_dTdz_fspd.png']));                    
                end
                %~~~~
                
                clear datad_1m datau_1m chi_inds p_max ind_max ctd
                
                % Now load the 1-m binned CTD data 
                if exist(fullfile(CTD_out_dir_bin,[ castname(1:end-6) '.mat']),'file')
                    load(fullfile(CTD_out_dir_bin,[ castname(1:end-6) '.mat']));
                    
                    % find max p from chi (which is really just P from CTD)
                    [p_max,ind_max]=max(chidat.cal.P);
                    
                    %~ break up chi into down and up casts
                    
                    % upcast
                    chi_up=struct();
                    chi_up.datenum=chidat.cal.datenum(ind_max:length(chidat.cal.P));
                    chi_up.P      =chidat.cal.P(ind_max:length(chidat.cal.P));
                    chi_up.T1P    =chidat.cal.T1P(ind_max:length(chidat.cal.P));
                    chi_up.fspd   =chidat.cal.fspd(ind_max:length(chidat.cal.P));
                    chi_up.castdir='up';
                    chi_up.Info   =this_chi_info;
                    if this_chi_info.isbig==1
                    % 2nd sensor on 'big' chipods
                    chi_up.T2P    =chidat.cal.T2P(ind_max:length(chidat.cal.P));
                    end
                    
                    % downcast
                    chi_dn=struct();
                    chi_dn.datenum=chidat.cal.datenum(1:ind_max);
                    chi_dn.P      =chidat.cal.P(1:ind_max);
                    chi_dn.T1P    =chidat.cal.T1P(1:ind_max);
                    chi_dn.fspd   =chidat.cal.fspd(1:ind_max);
                    chi_dn.castdir='down';
                    chi_dn.Info   =this_chi_info;
                    if this_chi_info.isbig==1
                    % 2nd sensor on 'big' chipods
                    chi_dn.T2P    =chidat.cal.T2P(1:ind_max);
                    end
                    %~                    
                    
                    %~~~
                    % save these data here now 
                    clear fname_dn fname_up
                    fname_dn=fullfile(chi_processed_path_specific,['cast_' cast_suffix '_' whSN '_downcast.mat']);
                    save(fname_dn,'chi_dn')
                    fname_up=fullfile(chi_processed_path_specific,['cast_' cast_suffix '_' whSN '_upcast.mat']);
                    save(fname_up,'chi_up')
                    %~~~
                                        
                    %~~
                    do_T2_big=1; % do calc for T2 if big chipod
                    % define some parameters that are the same for up/down and
                    % T1/T2:
                    z_smooth=20;
                    nfft=128;
                    extra_z=2; % number of extra meters to get rid of due to CTD pressure loops.
                    wthresh = 0.4;
                    
                    if isbig==1 && do_T2_big==1
                        Ncasestodo=4; % do T1 and T2 sensor (big chipod)
                    else
                        Ncasestodo=2; % just do T1 sensor (mini chipod)
                    end
                                        
                    whfig=6; % # for figure filename, so they can be viewed in order in Finder
                    
                    % loop through up/down casts and T1/T2 and compute chi
                    for whcasetodo=1:Ncasestodo
                        
                        clear ctd chi_todo_now whsens TP
                        
                        switch whcasetodo
                            
                            case 1 % downcast T1
                                clear ctd chi_todo_now
                                ctd=datad_1m;
                                chi_todo_now=chi_dn;
                                % ~~ Choose which dT/dt to use (for mini
                                % chipods, only T1P. For big, we will do T1P
                                % and T2P).
                                whsens='T1';
                                TP=chi_todo_now.T1P;
                                disp('Doing T1 downcast')
                            case 2 % upcast T1
                                clear avg ctd chi_todo_now
                                ctd=datau_1m;
                                chi_todo_now=chi_up;
                                whsens='T1';
                                TP=chi_todo_now.T1P;
                                disp('Doing T1 upcast')
                            case 3 %downcast T2
                                clear ctd chi_todo_now
                                ctd=datad_1m;
                                chi_todo_now=chi_dn;
                                TP=chi_todo_now.T2P;
                                whsens='T2';
                                disp('Doing T2 downcast')
                            case 4 % upcast T2
                                clear avg ctd chi_todo_now
                                ctd=datau_1m;
                                chi_todo_now=chi_up;
                                TP=chi_todo_now.T2P;
                                whsens='T2';
                                disp('Doing T2 upcast')
                        end
                        
                        
                        % compute N^2 and dT/dz from CTD for chi calculations
                        ctd=Compute_N2_dTdz_forChi(ctd,z_smooth);
                        
                        %~~~ now let's do the chi computations:
                        
                        % remove loops in CTD data
                        clear datau2 bad_inds tmp
                        [datau2,bad_inds] = ctd_rmdepthloops(CTD_24hz,extra_z,wthresh);
                        tmp=ones(size(datau2.p));
                        tmp(bad_inds)=0;                        
                        % find good chipod data (data not in depth loops)
                        chi_todo_now.is_good_data=interp1(datau2.datenum,tmp,chi_todo_now.datenum,'nearest');
                        
                        % plot p vs time to make sure we got right CTD data
                        figure(55);clf
                        plot(chi_todo_now.datenum,chi_todo_now.P)
                        xlabel('Time')
                        ylabel('Pressure')
                        title(['cast_' cast_suffix '_' chi_todo_now.castdir],'interpreter','none')
                        axis ij
                        datetick('x')
                        
                        %%% Now we'll do the main looping through of the data.
                        clear avg  todo_inds
                        
                        [avg todo_inds]=Prepare_Avg_for_ChiCalc(nfft,chi_todo_now,ctd);
                        
                        clear fspd good_chi_inds
                        fspd=chi_todo_now.fspd;
                        good_chi_inds=chi_todo_now.is_good_data;
                        
                        clear ib_loop Nloop
                        ib_loop=find(chi_todo_now.is_good_data==0);
                        Nloop=length(ib_loop);
                        fprintf(fileID,['\n  ' num2str(round(Nloop/length(chi_todo_now.datenum)*100)) ' percent of points removed for depth loops ']);
                        
                        %~~ plot histogram of avg.P to see if we have good
                        %data in each bin
                        figure
                        agutwocolumn(0.6)
                        wysiwyg
                        hi=histogram(avg.P,0:10:nanmax(avg.P),'edgecolor','none')
                        hi.Orientation='Horizontal';axis ij;
                        ylabel('P [db]','fontsize',15)
                        xlabel('# good data windows','fontsize',15)
                        xlim([0 40])
                        grid on
                        title([whSN ' cast ' cast_suffix ' - ' chi_todo_now.castdir 'cast'],'fontsize',15)
                        print('-dpng',fullfile(chi_fig_path,['chi_' whSN],[whSN '_cast_' cast_suffix '_Fig' num2str(whfig) '_' chi_todo_now.castdir 'cast_chi_' whsens '_avgPhist']))
                        whfig=whfig+1
                        
                        %~ compute chi in overlapping windows
                        avg=ComputeChi_for_CTDprofile(avg,nfft,fspd,TP,good_chi_inds,todo_inds);
                        %~ plot summary figure
                        ax=CTD_chipod_profile_summary(avg,chi_todo_now,TP);
                        axes(ax(1))
                        title(['cast ' cast_suffix])
                        axes(ax(2))
                        title([whSN],'interpreter','none')
                        axes(ax(3))
                        title(['Sensor ' whsens])                        
                        print('-dpng',fullfile(chi_fig_path,['chi_' whSN],[whSN '_cast_' cast_suffix '_Fig' num2str(whfig) '_' chi_todo_now.castdir 'cast_chi_' whsens '_avg_chi_KT_dTdz']))
                        whfig=whfig+1;
                        
                        
                        %~~~
                        avg.castname=castname;
                        avg.castdir=chi_todo_now.castdir;
                        avg.Info=this_chi_info;
                        ctd.castname=castname;
                        
                        avg.castname=castname;
                        ctd.castname=castname;
                        avg.MakeInfo=['Made ' datestr(now) ' w/ ' this_script_name ];
                        ctd.MakeInfo=['Made ' datestr(now) ' w/ ' this_script_name ];
                        
                        chi_processed_path_avg=fullfile(chi_processed_path_specific,'avg');
                        ChkMkDir(chi_processed_path_avg)
                        processed_file=fullfile(chi_processed_path_avg,['avg_' cast_suffix '_' avg.castdir 'cast_' whSN '_' whsens '.mat']);
                        save(processed_file,'avg','ctd')
                        %~~~
                        
                        ngc=find(~isnan(avg.chi1));
                        if numel(ngc)>1
                            fprintf(fileID,['\n Chi computed for ' chi_todo_now.castdir 'cast, sensor ' whsens]);
                            fprintf(fileID,['\n ' processed_file]);
                        end
                        
                    end % up,down, T1/T2
                    
                end % if we have binned ctd data
                
            else
                disp('no good chi data for this profile');
                fprintf(fileID,' No chi file found ');
            end % if we have good chipod data for this profile
            
        else
            disp('this file already processed')
            fprintf(fileID,' file already exists, skipping ');
        end % already processed
        
    end % each chipod on rosette (up_down_big)
    
end % each CTD file

delete(hb)

telapse=toc(tstart)
fprintf(fileID,['\n \n Done! \n Processing took ' num2str(telapse/60) ' mins to run']);

%
%%