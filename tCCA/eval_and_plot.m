clear all

%% +++++++++++++++++++++++
%% SCRIPT CONFIGURATION
% +++++++++++++++++++++++
% user: 1 Meryem | 0 Alex
melexflag = 0;
% select which hrf amplitude data: 50 or 100
hrfamp = 50;
% Use only true positives for evaluation of metrics
TP_flag = true;
% number of contours in contour plots
cntno = 10;
% use mean (1) or median (2) in metric contour plots
mflag = 2;
% plot pvalue results or not
pvalflag = false;
% plot other metrics
plotmetrics = false;
%% parameters for determining optima
% normalize metrics: 1 X/max | 2 (X-min)/(max-min)
Jparam.nflag = 2;
% smoothing / optimization metrics: 1 mean, 2 median or 3 all channels
Jparam.mtype = 3;
% Objective function J weights
Jparam.fact.corr = 1;
Jparam.fact.mse =2;
Jparam.fact.pval =0;
Jparam.fact.fscore=2;
Jparam.fact.HbO=1;
Jparam.fact.HbR=1;
% use weighted region of stepsize reg in all directions around evaluation point?
reg.step = 1;
reg.weight =0.1;
% segmentation approach: threshold for segmentation
Jparam.thresh = 0.7;
% set optimal point per hand to investigate (overwrites opt function
% result), otherwise leave empty
pOpt =[];
%pOpt = [5 2 3];

%% settings to keep in mind
% hrf = 50, Jparam.mtype = 2, fact.corr=1,mse=2,fscore=2 -> Timelag 2, stepsize corr thresh 0.8
% hrf = 50, Jparam.mtype = 3, fact.corr=1,mse=2,fscore=2 -> Timelag 4, stepsize 4, corr thresh 0.5
%                                                           -> vs Timelag 4 stepsize 4 corr thresh 0.2
% pOpt = [5 2 3];


%% Data
% ##### FOLLOWING TWO LINES NEED CHANGE ACCORDING TO USER!
if melexflag
    %Meryem
    path.code = 'C:\Users\mayucel\Documents\PROJECTS\CODES\tCCA-GLM'; addpath(genpath(path.code)); % code directory
    path.dir = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\FB_RESTING_DATA'; % data directory
    path.save = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER'; % save directory
    path.cvres50 = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\CV_results_data_50'; % save directory
    path.cvres100 = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\CV_results_data_100'; % save directory
else
    %Alex
    path.code = 'D:\Office\Research\Software - Scripts\Matlab\Regression tCCA GLM\tCCA-GLM'; addpath(genpath(path.code)); % code directory
    path.dir = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\FB_RESTING_DATA'; % data directory
    path.save = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER'; % save directory
    path.cvres50 = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\CV_results_data_50'; % save directory
    path.cvres100 = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\CV_results_data_100'; % save directory
end

% #####
filename = 'resting_sim';
set(groot,'defaultFigureCreateFcn',@(fig,~)addToolbarExplorationButtons(fig))
set(groot,'defaultAxesCreateFcn',@(ax,~)set(ax.Toolbar,'Visible','off'))
sbjfolder = {'Subj33','Subj34','Subj36','Subj37','Subj38','Subj39', 'Subj40', 'Subj41', 'Subj43', 'Subj44','Subj46','Subj47','Subj49','Subj51'};

% Validation parameters
tlags = 0:1:10;
stpsize = 2:2:24;
cthresh = 0:0.1:0.9;
evparams.tlags = tlags;
evparams.stpsize = stpsize;
evparams.cthresh = cthresh;

%% load results data from all subjects
% Dimensions of output metrics
% # of sbjs x #CH x 2(Hbo+HbR) x 2 (cv split) x tlag x stepsize x corrthres
for sbj = 1:numel(sbjfolder)
    switch hrfamp
        case 50
            res{sbj} = load([path.cvres50 '\results_sbj' num2str(sbj) '.mat']);
        case 100
            res{sbj} = load([path.cvres100 '\results_sbj' num2str(sbj) '.mat']);
    end
    
    %% append subject matrices here
    CORR_CCA(sbj,:,:,:,:,:,:,:) = res{sbj}.CORR_CCA;
    CORR_SS(sbj,:,:,:,:,:,:,:) = res{sbj}.CORR_SS;
    DET_CCA(sbj,:,:,:,:,:,:,:) = res{sbj}.DET_CCA;
    DET_SS(sbj,:,:,:,:,:,:,:) = res{sbj}.DET_SS;
    MSE_CCA(sbj,:,:,:,:,:,:,:) = res{sbj}.MSE_CCA;
    MSE_SS(sbj,:,:,:,:,:,:,:) = res{sbj}.MSE_SS;
    pval_CCA(sbj,:,:,:,:,:,:,:) = res{sbj}.pval_CCA;
    pval_SS(sbj,:,:,:,:,:,:,:) = res{sbj}.pval_SS;
    nTrials(sbj,:,:,:,:) = res{sbj}.nTrials;
    
end

% true positive only flag
if TP_flag
    pval_SS(find(DET_SS ~= 1)) = NaN;
    pval_CCA(find(DET_CCA ~= 1)) = NaN;
end

%% Calculate True/false positive/negative rates, precision, recall, ...
tf_errors


%% Find Global topology and optimum with objective function, includes segmentation approach
% calculate objective function output for all input tupel
fval = J_opt(CORR_CCA, MSE_CCA, pval_CCA, F_score_CCA, Jparam ,reg);
% find optimal parameter set
[t,s,c] = ind2sub(size(fval),find(fval == min(fval(:))));
%% overwrite if OPT POINT chosen individually before for further exploration
if isempty(pOpt)
    pOpt = [t s c];
else
    disp('=================================================================')
    disp(['these parameters were chosen manually: ' ...
        num2str(tlags(pOpt(1))) 's, stepsize: ' num2str(stpsize(pOpt(2))) 'smpl, corr threshold: ' num2str(cthresh(pOpt(3)))] )
    disp('=================================================================')
end
    

disp('=================================================================')
disp(['these parameters minimize the objective function: timelag: ' ...
    num2str(tlags(t)) 's, stepsize: ' num2str(stpsize(s)) 'smpl, corr threshold: ' num2str(cthresh(c))] )
disp('=================================================================')

%% Calculate median/mean metrics
[CORR,MSE,PVAL,FSCORE] = medmean(CORR_CCA, MSE_CCA, pval_CCA, F_score_CCA, mflag);

%% create combined surface plots (depict objective function)
hblab = {'HbO', 'HbR'};

%% Plot Objective function results
% normalize fval
fval = (fval-min(fval(:)))/(max(fval(:))-min(fval(:)));
ttl= ['Objective Function, hrf= ' num2str(hrfamp)];
contour_plots(fval, ttl, evparams, pOpt, cntno, 'min');

if plotmetrics
    %% plot correlation
    %HBO and HbR
    for hh = 1:2
        ttl= [hblab{hh} ' Correlation'];
        contour_plots(squeeze(CORR(:,hh,:,:,:)), ttl,evparams, pOpt, cntno, 'max');
    end
    
    %% plot MSE
    %HBO and HbR
    for hh = 1:2
        ttl= [hblab{hh} ' MSE'];
        contour_plots(squeeze(MSE(:,hh,:,:,:)), ttl,evparams, pOpt, cntno, 'min');
    end
    
    %% plot pvals
    if pvalflag
        %HBO and HbR
        for hh = 1:2
            ttl= [hblab{hh} ' p-values'];
            contour_plots(squeeze(PVAL(:,hh,:,:,:)), ttl,evparams, pOpt, cntno, 'min');
        end
    end
    
    %% plot FSCORE
    %HBO and HbR
    for hh = 1:2
        ttl= [hblab{hh} ' FSCORE'];
        contour_plots(squeeze(FSCORE(:,hh,:,:,:)), ttl,evparams, pOpt, cntno, 'max');
    end
end

%% plot Summary contours for fixed correlation threshold
ct = pOpt(3);
[X,Y] = meshgrid(evparams.stpsize,evparams.tlags);
figure
dat = {1-fval(:,:,ct), squeeze(CORR(:,1,:,:,ct)), squeeze(-MSE(:,1,:,:,ct)), ...
    squeeze(FSCORE(:,1,:,:,ct)), [], ...
    squeeze(CORR(:,2,:,:,ct)), squeeze(-MSE(:,2,:,:,ct)), ...
    squeeze(FSCORE(:,2,:,:,ct))};
ttl = {'J Opt','CORR HbO','MSE HbO','F HbO', '', 'CORR HbR', 'MSE HbR','F HbR'};
for dd = 1:numel(dat)
    if ~isempty(dat{dd})
        subplot(2,4,dd)
        climits = [min(dat{dd}(:)) max(dat{dd}(:))];
        contourf(X,Y, dat{dd}, cntno)
        xlabel('stepsize / smpl')
        ylabel('time lags / s')
        title([ttl{dd} ', cthresh: ' num2str(cthresh(ct)), ', hrf=' num2str(hrfamp)])
        colormap hot
        limit = climits(2);
        colorbar
        caxis(climits)
        % mark optimum from objective function
        hold on
        plot(evparams.stpsize(pOpt(1,2)),evparams.tlags(pOpt(1,1)),'diamond','MarkerFaceColor', 'c')
        text(evparams.stpsize(pOpt(1,2)),evparams.tlags(pOpt(1,1)), ['\leftarrow ' num2str(dat{dd}(pOpt(1,1),pOpt(1,2)))])
    end
end



%% create scatter plots comparing SS and tCCA
%append all points
[CORRcca,MSEcca,PVALcca,FSCOREcca] = medmean(CORR_CCA, MSE_CCA, pval_CCA, F_score_CCA, 3);
[CORRss,MSEss,PVALss,FSCOREss] = medmean(CORR_SS, MSE_SS, pval_SS, F_score_SS, 3);
%pOpt = [pOpt(1) pOpt(2) 4]; %(re-)set the optimal parameterset 
figure
ttl = {'CORR', 'MSE', 'F-SCORE'};
datss = {squeeze(CORRss(:,:,pOpt(1),pOpt(2),pOpt(3))), squeeze(MSEss(:,:,pOpt(1),pOpt(2),pOpt(3))), squeeze(FSCOREss(:,:,pOpt(1),pOpt(2),pOpt(3)))};
datcca = {squeeze(CORRcca(:,:,pOpt(1),pOpt(2),pOpt(3))), squeeze(MSEcca(:,:,pOpt(1),pOpt(2),pOpt(3))), squeeze(FSCOREcca(:,:,pOpt(1),pOpt(2),pOpt(3)))};
ptcol = {'+r', 'xb', '*k'};
for ff = 1:3
    for hh = 1:2
        axlim = [min([datss{ff}(:,hh); datcca{ff}(:,hh)]) max([datss{ff}(:,hh); datcca{ff}(:,hh)])];
        subplot(2,3,(hh-1)*3+ff)
        hold on
        scatter(squeeze(datss{ff}(:,hh)), squeeze(datcca{ff}(:,hh)), ptcol{hh})
        plot([axlim(1) axlim(2)], [axlim(1) axlim(2)] ,'k')
        scatter(nanmean(squeeze(datss{ff}(:,hh))), nanmean(squeeze(datcca{ff}(:,hh))), ptcol{3})
        % ttest
        [h,p] = ttest(squeeze(datss{ff}(:,hh)),squeeze(datcca{ff}(:,hh)));
        if h
            scatter(nanmean(squeeze(datss{ff}(:,hh))), nanmean(squeeze(datcca{ff}(:,hh))), 'ok')
        end
        title([ttl{ff} ' for Tlag/Ssize/Cthresh: ' num2str(tlags(pOpt(1))) ' / ' num2str(stpsize(pOpt(2))) ' / ' num2str(cthresh(pOpt(3))), ' | p = ' num2str(p)])
        xlim ([axlim(1) axlim(2)])
        ylim ([axlim(1) axlim(2)])
        xlabel('SS GLM')
    ylabel('tCCA GLM')
    end   
end

%% Plot F-Score vs corr threshold
[CORRcca,MSEcca,PVALcca,FSCOREcca] = medmean(CORR_CCA, MSE_CCA, pval_CCA, F_score_CCA, mflag);
[CORRss,MSEss,PVALss,FSCOREss] = medmean(CORR_SS, MSE_SS, pval_SS, F_score_SS, mflag);
datss = {squeeze(CORRss(:,:,pOpt(1),pOpt(2),:)), squeeze(MSEss(:,:,pOpt(1),pOpt(2),:)), squeeze(FSCOREss(:,:,pOpt(1),pOpt(2),:))};
datcca = {squeeze(CORRcca(:,:,pOpt(1),pOpt(2),:)), squeeze(MSEcca(:,:,pOpt(1),pOpt(2),:)), squeeze(FSCOREcca(:,:,pOpt(1),pOpt(2),:))};
figure
ylabs={'CORR','MSE','F-Score'};
for ff = 1:3
    subplot(1,3,ff)
    hold on
        plot(cthresh, datcca{ff}(1,:), 'r')
        plot(cthresh, datss{ff}(1,:), '.r')
        plot(cthresh, datcca{ff}(2,:), 'b')
        plot(cthresh, datss{ff}(2,:), '.b')
        xlabel('Corr threshold')
        ylabel(ylabs{ff})
        title([ttl{ff} ' vs Cthresh for Tlag = ' num2str(tlags(pOpt(1))) ' / Stepsize = ' num2str(stpsize(pOpt(2))), ' / hrf = ' num2str(hrfamp)])
end



