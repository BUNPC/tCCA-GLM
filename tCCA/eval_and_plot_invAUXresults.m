clear all

%% +++++++++++++++++++++++
%% SCRIPT CONFIGURATION
% +++++++++++++++++++++++
% user: 1 Meryem | 0 Alex
melexflag = 1;
% select which hrf amplitude data: 1 (20%), 2 (50%) or 3 (100%)
hhh = [2];
% select which metric type: 1 (average of single trial HRF MSEs), 2: MSE of average HRF
mmm = [1];
% Use only true positives for evaluation of metrics
TP_flag = true;
% indices of optimal parameterset
pOptfix = [4 7 6];

%% Data
% ##### FOLLOWING TWO LINES NEED CHANGE ACCORDING TO USER!
if melexflag
    %Meryem
    path.code = 'C:\Users\mayucel\Documents\PROJECTS\CODES\tCCA-GLM'; addpath(genpath(path.code)); % code directory
    path.dir = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\FB_RESTING_DATA'; % data directory
    path.save = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER'; % save directory
    path.auxres20 = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_20'; % save directory
    path.auxres50 = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_50'; % save directory
    path.auxres100 = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_100'; % save directory
    path.auxres20stmse = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_20_stMSE'; % save directory
    path.auxres50stmse = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_50_stMSE'; % save directory
    path.auxres100stmse = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_100_stMSE'; % save directory
else
    %Alex
    path.code = 'D:\Office\Research\Software - Scripts\Matlab\Regression tCCA GLM\tCCA-GLM'; addpath(genpath(path.code)); % code directory
    path.dir = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\FB_RESTING_DATA'; % data directory
    path.save = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER'; % save directory
    path.auxres20 = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_20'; % save directory
    path.auxres50 = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_50'; % save directory
    path.auxres100 = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_100'; % save directory
    path.auxres20stmse = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_20_stMSE'; % save directory
    path.auxres50stmse = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_50_stMSE'; % save directory
    path.auxres100stmse = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\CV_AUX_contributions_100_stMSE'; % save directory
end

% Validation parameters
tlags = 0:1:10;
stpsize = 2:2:24;
cthresh = 0:0.1:0.9;
evparams.tlags = tlags;
evparams.stpsize = stpsize;
evparams.cthresh = cthresh;

metrlab = {'MSE', 'F-Score', 'CORR'};
hblab = {'HbO', 'HbR'};
metrttl = {'single trial', 'block avg'};



disp('=================================================================')
disp(['these parameters were chosen manually: ' ...
    num2str(tlags(pOptfix(1))) 's, stepsize: ' num2str(stpsize(pOptfix(2))) 'smpl, corr threshold: ' num2str(cthresh(pOptfix(3)))] )
disp('=================================================================')

for metr=mmm
    for hrff=hhh
        %% load results data from all subjects
        % Dimensions of output metrics
        % # of sbjs x #CH x 2(Hbo+HbR) x 2 (cv split) x tlag x stepsize x corrthres
        switch hrff
            case 1
                hrfamp = 20;
                switch metr
                    case 1
                        load([path.auxres20stmse  '\results_all_sbj.mat']);
                    case 2
                        load([path.auxres20 '\results_all_sbj.mat']);
                end
            case 2
                hrfamp = 50;
                switch metr
                    case 1
                        load([path.auxres50stmse  '\results_all_sbj.mat']);
                    case 2
                        load([path.auxres50 '\results_all_sbj.mat']);
                end
            case 3
                hrfamp = 100;
                switch metr
                    case 1
                        load([path.auxres100stmse  '\results_all_sbj.mat']);
                    case 2
                        load([path.auxres100 '\results_all_sbj.mat']);
                end
        end
        
        % true positive only flag
        if TP_flag
            pval_CCA(find(DET_CCA ~= 1)) = NaN;
        end
        
        %% Calculate True/false positive/negative rates, precision, recall, ...
        tf_errors_AUX
        
        %% Average data
        for aa = 1:size(MSE_CCA,5)
            for hh=1:2
                a = MSE_CCA(:,:,hh,:,aa);
                MSE(hh,aa)=nanmean(a(:));
                a = F_score_CCA(:,hh,:,aa);
                FSCORE(hh,aa)=nanmean(a(:));
                a = CORR_CCA(:,:,hh,:,aa);
                CORR(hh,aa)=nanmean(a(:));
            end
        end
        
        %% create imagesc matrices from data
        MSE_HbO = NaN(7,7);
        MSE_HbR = NaN(7,7);
        FSCORE_HbO = NaN(7,7);
        FSCORE_HbR = NaN(7,7);
        % MSE_HbO = ones(7,7)*min(MSE(1,:));
        % MSE_HbR = ones(7,7)*min(MSE(2,:));
        % FSCORE_HbO = ones(7,7)*max(FSCORE(1,:));
        % FSCORE_HbR = ones(7,7)*max(FSCORE(2,:));
        dd = {[1 2], [2 1]};
        for ii=1:size(auxinfo.auxid,2)
            for d=1:2
                MSE_HbO(auxinfo.auxid(dd{d}(1),ii)+1,auxinfo.auxid(dd{d}(2),ii)+1) = MSE(1,ii);
                MSE_HbR(auxinfo.auxid(dd{d}(1),ii)+1,auxinfo.auxid(dd{d}(2),ii)+1) = MSE(2,ii);
                FSCORE_HbO(auxinfo.auxid(dd{d}(1),ii)+1,auxinfo.auxid(dd{d}(2),ii)+1) = FSCORE(1,ii);
                FSCORE_HbR(auxinfo.auxid(dd{d}(1),ii)+1,auxinfo.auxid(dd{d}(2),ii)+1) = FSCORE(2,ii);
            end
        end
        dat = {-MSE_HbO, FSCORE_HbO, -MSE_HbR, FSCORE_HbR};
        figure
        for mm = 1:2
            for hh = 1:2
                subplot(2,2,(hh-1)*hh+mm)
                c = imagesc(dat{(hh-1)*hh+mm});
                title([metrlab{mm} ' ' hblab{hh} ' ' metrttl{metr} ' | hrf = ' num2str(hrfamp) '%'])
                colorbar
                set(gca,'xaxisLocation','top')
                xticks([1:7]);
                yticks([1:7]);
                xticklabels(auxinfo.lab)
                yticklabels(auxinfo.lab)
                set(c,'AlphaData',~isnan(dat{(hh-1)*hh+mm}))
                %% write delta values in percent into tiles
                offs=0.3;
                for yy=2:6
                    for xx=1:yy-1
                        mx = max(dat{(hh-1)*hh+mm}(:));
                        val = -(ceil(1000*(mx-dat{(hh-1)*hh+mm}(xx,yy))/mx))/10;
                        text(xx-offs, yy, [num2str(val,'%+2.0f') '%'])
                    end
                end
                text(1-offs, 7, 'MAX')
            end
        end
        colormap autumn
    end
end

