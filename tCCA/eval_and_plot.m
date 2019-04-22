% ##### FOLLOWING TWO LINES NEED CHANGE ACCORDING TO USER!
clear all;

malexflag = 1;
if malexflag
    %Meryem
    path.code = 'C:\Users\mayucel\Documents\PROJECTS\CODES\tCCA-GLM'; addpath(genpath(path.code)); % code directory
    path.dir = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\FB_RESTING_DATA'; % data directory
    path.save = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER'; % save directory
else
    %Alex
    path.code = 'D:\Office\Research\Software - Scripts\Matlab\Regression tCCA GLM\tCCA-GLM'; addpath(genpath(path.code)); % code directory
    path.dir = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\FB_RESTING_DATA'; % data directory
    path.save = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER'; % save directory
end

% #####
filename = 'resting_sim';
set(groot,'defaultFigureCreateFcn',@(fig,~)addToolbarExplorationButtons(fig))
set(groot,'defaultAxesCreateFcn',@(ax,~)set(ax.Toolbar,'Visible','off'))
sbjfolder = {'Subj33','Subj34','Subj36','Subj37','Subj38','Subj39', 'Subj40', 'Subj41', 'Subj43', 'Subj44','Subj46','Subj47','Subj49','Subj51'};

% flags
TP_flag = 1;

% Validation parameters
tlags = 0:1:10;
stpsize = 2:2:24;
cthresh = 0.1:0.1:1;

%% load results data from all subjects
% Dimensions of output metrics
% # of sbjs x #CH x 2(Hbo+HbR) x 2 (cv split) x tlag x stepsize x corrthres

CORR_CCA = [];
for sbj = 1:numel(sbjfolder)
    res{sbj} = load([path.save '\results_sbj' num2str(sbj) '.mat']);
    
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


%% # of (TP) active channels
% for SS and CCA methods:
foo_SS = permute(DET_SS,[2 1 3 4 5 6 7]);
foo_SS = reshape(foo_SS, size(foo_SS,1), size(foo_SS,2)*size(foo_SS,3)*size(foo_SS,4)*size(foo_SS,5)*size(foo_SS,6)*size(foo_SS,7));

foo_CCA = permute(DET_CCA,[2 1 3 4 5 6 7]);
foo_CCA = reshape(foo_CCA, size(foo_CCA,1), size(foo_CCA,2)*size(foo_CCA,3)*size(foo_CCA,4)*size(foo_CCA,5)*size(foo_CCA,6)*size(foo_CCA,7));
% ROCLAB.name = {'TP','FP','FN','TN', 'PRND'};
for i = 1:size(foo_SS,2)
    % SS
    Ch_TP_SS(i) = sum(foo_SS(:,i)==1);
    Ch_FP_SS(i) = sum(foo_SS(:,i)==-1);
    Ch_FN_SS(i) = sum(foo_SS(:,i)==2);
    Ch_TN_SS(i) = sum(foo_SS(:,i)==-2);
    % CCA
    Ch_TP_CCA(i) = sum(foo_CCA(:,i)==1);
    Ch_FP_CCA(i) = sum(foo_CCA(:,i)==-1);
    Ch_FN_CCA(i) = sum(foo_CCA(:,i)==2);
    Ch_TN_CCA(i) = sum(foo_CCA(:,i)==-2);
end

% get F-score
% SS & CCA
Precision_SS = Ch_TP_SS .*(Ch_TP_SS + Ch_FP_SS);
Recall_SS = Ch_TP_SS .*(Ch_TP_SS + Ch_FN_SS);
F_score_SS = 2 * (Precision_SS .* Recall_SS)./(Precision_SS + Recall_SS);

Precision_CCA = Ch_TP_CCA .*(Ch_TP_CCA + Ch_FP_CCA);
Recall_CCA = Ch_TP_CCA .*(Ch_TP_CCA + Ch_FN_CCA);
F_score_CCA = 2 * (Precision_CCA .* Recall_CCA)./(Precision_CCA + Recall_CCA);

% reshape all to "# of sbjs x 2(Hbo+HbR) x 2 (cv split) x tlag x stepsize x corrthres
Ch_TP_SS = reshape(Ch_TP_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
Ch_FP_SS = reshape(Ch_FP_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
Ch_FN_SS = reshape(Ch_FN_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
Ch_TN_SS = reshape(Ch_TN_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
F_score_SS = reshape(F_score_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));

Ch_TP_CCA = reshape(Ch_TP_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
Ch_FP_CCA = reshape(Ch_FP_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
Ch_FN_CCA = reshape(Ch_FN_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
Ch_TN_CCA = reshape(Ch_TN_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
F_score_CCA = reshape(F_score_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));



%% ++++++++++++++++++++++++++++
% THIS IS EXPERIMENTAL AND FOR VALIDATION ATM


%% average across channels
% HERE WE NEED TO REDUCE TO e.g. ONLY TP
CORR_CCA = squeeze(nanmean(CORR_CCA,2));
CORR_SS = squeeze(nanmean(CORR_SS,2));
MSE_CCA = squeeze(nanmean(MSE_CCA,2));
MSE_SS = squeeze(nanmean(MSE_SS,2));
pval_CCA = squeeze(nanmean(pval_CCA,2));
pval_SS = squeeze(nanmean(pval_SS,2));

%% now average across splits
CORR_CCA = squeeze(nanmean(CORR_CCA,3));
CORR_SS = squeeze(nanmean(CORR_SS,3));
MSE_CCA = squeeze(nanmean(MSE_CCA,3));
MSE_SS = squeeze(nanmean(MSE_SS,3));
pval_CCA = squeeze(nanmean(pval_CCA,3));
pval_SS = squeeze(nanmean(pval_SS,3));

%% now average across subjects
CORR_CCA = squeeze(nanmean(CORR_CCA,1));
CORR_SS = squeeze(nanmean(CORR_SS,1));
MSE_CCA = squeeze(nanmean(MSE_CCA,1));
MSE_SS = squeeze(nanmean(MSE_SS,1));
pval_CCA = squeeze(nanmean(pval_CCA,1));
pval_SS = squeeze(nanmean(pval_SS,1));

% for only one subject
% CORR_CCA = squeeze(nanmean(CORR_CCA,2));
% CORR_SS = squeeze(nanmean(CORR_SS,2));
% MSE_CCA = squeeze(nanmean(MSE_CCA,2));
% MSE_SS = squeeze(nanmean(MSE_SS,2));
% pval_CCA = squeeze(nanmean(pval_CCA,2));
% pval_SS = squeeze(nanmean(pval_SS,2));


%% dimensions: HbO/HbR (2) x timelags (11) x stepsize (12) x corr thresh (10)

%% 3D surface plots

x = stpsize;
y = tlags;
z = cthresh;


%% plot correlation
figure
[X,Y] = meshgrid(x,y);
surf(X,Y, squeeze(CORR_CCA(1,:,:,1)),'FaceAlpha',0.5)
xlabel('stepsize / smpl')
ylabel('time lags / s')
zlabel('HbO correlation')
title('CCA GLM')
hold on
surf(X,Y, squeeze(CORR_CCA(1,:,:,10)),'FaceAlpha',0.5)
xlabel('stepsize / smpl')
ylabel('time lags / s')
zlabel('HbO correlation')
title('CCA GLM correlation')

[X,Y] = meshgrid(x,y);
figure
for ii=1:9
    subplot(3,3,ii)
    contourf(X,Y, squeeze(CORR_CCA(1,:,:,ii)), 20)
    xlabel('stepsize / smpl')
    ylabel('time lags / s')
    title(['HbO Correlation ctrsh: ' num2str(cthresh(ii))])
    colormap gray
    colorbar
end




%% plot MSE
figure
[X,Y] = meshgrid(x,y);
surf(X,Y, squeeze(MSE_CCA(1,:,:,1)),'FaceAlpha',0.5)
xlabel('stepsize / smpl')
ylabel('time lags / s')
zlabel('HbO MSE')
title('CCA GLM')
hold on
surf(X,Y, squeeze(MSE_CCA(1,:,:,10)),'FaceAlpha',0.5)
xlabel('stepsize / smpl')
ylabel('time lags / s')
zlabel('HbO MSE')
title('CCA GLM MSE')

[X,Y] = meshgrid(x,y);
figure
for ii=1:9
    subplot(3,3,ii)
    contourf(X,Y, squeeze(MSE_CCA(1,:,:,ii)), 20)
    xlabel('stepsize / smpl')
    ylabel('time lags / s')
    title(['HbO MSE ctrsh: ' num2str(cthresh(ii))])
    colormap gray
    colorbar
end


%% plot pvals
figure
[X,Y] = meshgrid(x,y);
surf(X,Y, squeeze(pval_CCA(1,:,:,1)),'FaceAlpha',0.5)
xlabel('stepsize / smpl')
ylabel('time lags / s')
zlabel('HbO pVals')
title('CCA GLM')
hold on
surf(X,Y, squeeze(pval_CCA(1,:,:,10)),'FaceAlpha',0.5)
xlabel('stepsize / smpl')
ylabel('time lags / s')
zlabel('HbO pval')
title('CCA GLM pval')

[X,Y] = meshgrid(x,y);
figure
for ii=1:9
    subplot(3,3,ii)
    contourf(X,Y, squeeze(pval_CCA(1,:,:,ii)), 20)
    xlabel('stepsize / smpl')
    ylabel('time lags / s')
    title(['HbO pVals ctrsh: ' num2str(cthresh(ii))])
    colormap gray
    colorbar
end

% will be useful, keep for later
%[r,c,v] = ind2sub(size(buf),find(buf == max(buf(:))))


