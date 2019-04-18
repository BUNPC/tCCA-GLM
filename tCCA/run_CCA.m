%% EXAMPLE SCRIPT
% BE AWARE:
% filtering and zscoring might be necessary/helpful. CCA components
% (regressors) have arbitrary scaling. Should not be a problem in the GLM
% regression, but keep it in mind!
clear all;
% ##### FOLLOWIG TWO LINES NEED CHANGE ACCRODING TO USER!
malexflag = 0;
if malexflag 
    path.code = 'C:\Users\mayucel\Documents\PROJECTS\CODES\tCCA-GLM'; addpath(genpath(path.code)); % code directory
    path.dir = 'C:\Users\mayucel\Google Drive\tCCA_GLM_PAPER\FB_RESTING_DATA'; % data directory
else
    path.code = 'D:\Office\Research\Software - Scripts\Matlab\Regression tCCA GLM\tCCA-GLM'; addpath(genpath(path.code)); % code directory
    path.dir = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER\FB_RESTING_DATA'; % data directory
end

% #####
filename = 'resting_sim';
set(groot,'defaultFigureCreateFcn',@(fig,~)addToolbarExplorationButtons(fig))
set(groot,'defaultAxesCreateFcn',@(ax,~)set(ax.Toolbar,'Visible','off'))
sbjfolder = {'Subj33','Subj34','Subj36','Subj37','Subj38','Subj39', 'Subj40', 'Subj41', 'Subj43', 'Subj44','Subj46','Subj47','Subj49','Subj51'};


%% Options/Parameter Settings
flag_half = 2;
rhoSD_ssThresh = 15;  % mm
flag_plot = 0;
flag_save = 0;
flag_conc = 1; % if 1 CCA inputs are in conc, if 0 CCA inputs are in intensity
% results eval parameters
eval_param.HRFmin = -2;
eval_param.HRFmax = 15; % used only for block design runs
eval_param.Hb = 1; % 1 HbO / 2 HbR (for block only)
eval_param.pre = 5;  % HRF range in sec to calculate ttest
eval_param.post = 10;
% CCA parameters
param.tau = 2;% 2 (time points); %stepwidth for embedding in samples (tune to sample frequency!)
% param.NumOfEmb = 50 ; %75 200 12/ number of total embeddings (total time window will be tau * NumOfEmb)
param.ct = 0.5;   % correlation threshold
flags.pcaf =  [0 0]; % no pca of X or AUX
% timelag = 10%Y not full rank after ~ 30 (i.e. time shifted regressor number is higher than the number of time points) % in sec


tic;

for tl = 1 % :1:10% time lag in sec
    timelag = tl;
    
    for ss = 1:numel(sbjfolder) % loop across subjects
        sbj = ss;
        % change to subject directory
        cd([path.dir filesep sbjfolder{ss} filesep]);
        
        %% load data
        [fq, t, AUX, d_long, d_short, d0_long, d0_short, d, d0, SD, s, lstLongAct,lstShortAct,lstHrfAdd] = load_nirs(filename,flag_conc);
        % number of embeddings
        param.NumOfEmb = timelag/param.tau * fq;
        
        %% AUX signals
        AUX = [AUX, d0_short]; % full AUX = [acc1 acc2 acc3 PPG BP RESP, d_short];
        
        %% check if the number of time points is odd/even, if odd make it even... (number of embedded should be the same)
        if mod(size(AUX,1),2) == 1
            AUX(end,:)=[];
            d(end,:)=[];
            d_long(end,:)=[];
            d_short(end,:)=[];
            d0(end,:)=[];
            d0_long(end,:)=[];
            d0_short(end,:)=[];
            t(end,:)=[];
            s(end,:)=[];
        end
        
        % create data split indices
        len = size(AUX,1);
        spltIDX = {1:len/2,len/2+1:len};
        trntst = {[1,2], [2,1]};
        
        %% run test and train CV splits
        for tt = 1:2
            tstIDX = spltIDX{trntst{tt}(1)};
            trnIDX = spltIDX{trntst{tt}(2)};
            
            %% zscore AUX signals
            AUX = zscore(AUX);
            
            %% Perform CCA on training data % AUX = [acc1 acc2 acc3 PPG BP RESP, d_short];
            % use test data of LD channels without synth HRF
            X = d0_long(trnIDX,:);
            [REG_trn{tt},  ADD_trn{tt}] = perf_temp_emb_cca(X,AUX(trnIDX,:),param,flags);
            
            %% Temporally embed auxiliary data from testing split
            aux_sigs = AUX(tstIDX,:);
            aux_emb = aux_sigs;
            for i=1:param.NumOfEmb
                aux=circshift( aux_sigs, i*param.tau, 1);
                aux(1:2*i,:)=repmat(aux(2*i+1,:),2*i,1);
                aux_emb=[aux_emb aux];
            end
            
            %% convert testing fNIRS data to concentration
            dod = hmrIntensity2OD(d(tstIDX,:));
            dod = hmrBandpassFilt(dod, fq, 0, 0.5);
            dc{tt} = hmrOD2Conc( dod, SD, [6 6]);
            
            %% Calculate testig regressors with CCA mapping matrix A from testing
            REG_tst = aux_emb*ADD_trn{tt}.Av_red;
            
            %% Perform GLM
            % GLM with SS
            [yavg_ss, yavgstd_ss, tHRF, nTrials, d_ss, yresid_ss, ysum2_ss, beta_ss, yR_ss] = ...
                hmrDeconvHRF_DriftSS(dc{tt}, s(tstIDX,:), t(tstIDX,:), SD, [], [], [eval_param.HRFmin eval_param.HRFmax], 1, 1, [0.5 0.5], rhoSD_ssThresh, 1, 3, 0);
            % GLM with CCA outpout
            [yavg_cca, yavgstd_cca, tHRF, nTrials, d_cca, yresid_cca, ysum2_cca, beta_cca, yR_cca] = ...
                hmrDeconvHRF_DriftSS(dc{tt}, s(tstIDX,:), t(tstIDX,:), SD, REG_tst, [], [eval_param.HRFmin eval_param.HRFmax], 1, 1, [0.5 0.5], 0, 0, 3, 0);
            
            %% list of channels with stimulus MERYEM NEEDS TO CHECK STH
            lst_stim = find(s(tstIDX,:)==1);
            lst_stim = lst_stim(1:nTrials);
            if lst_stim(1) < abs(eval_param.HRFmin) * fq
                lst_stim = lst_stim(2:end);
            end
            
            %% EVAL / PLOT
            [p_SS{ss,tt},p_CCA{ss,tt}, pOxy_SS{ss,tt}, pOxy_CCA{ss,tt}, FP_SS(ss,tt), FP_CCA(ss,tt)] = results_eval(sbj, d_ss, d_cca, tHRF, timelag, lst_stim, SD, fq, lstHrfAdd, eval_param, flag_plot, path);
        end
        
        clear vars AUX d d0 d_long d0_long d_short d0_short t s REG_trn ADD_trn 
    end
end

toc;




%% Briefly eval p val and # det ch improvement
for sbj = 1:numel(sbjfolder)
    for tt = 1:2
        ss_actidx = find(p_SS{sbj,tt});
        cca_actidx = find(p_CCA{sbj,tt});
        
        % number of activated channels
        nump_ss(sbj,tt) = numel(ss_actidx);
        nump_cca(sbj,tt) = numel(cca_actidx);
        % average pval of discovered channels
        format long
        foo = pOxy_SS{sbj,tt};
        if ~isempty(foo)
        avgp_ss(sbj,tt) = nanmean(foo(sbj,ss_actidx));
        end
        foo = pOxy_CCA{sbj,tt};
        if ~isempty(foo)
        avgp_cca(sbj,tt) = nanmean(foo(sbj,cca_actidx));
        end
    end
end
%% visualize # chan
figure
scatter(nump_ss(:), nump_cca(:));
mx=max([nump_ss(:); nump_cca(:)]);
mn=min([nump_ss(:); nump_cca(:)]);
xlim([mn mx])
ylim([mn mx])
hold on
plot([mn mx], [mn mx], 'k')
scatter(nanmean(nump_ss(:)), nanmean(nump_cca(:)), 'xr')
title(['# of significant channels. lag = ' num2str(timelag) 's, ct = ' num2str(param.ct) ' \tau = ' num2str(param.tau)])
xlabel('SS GLM')
ylabel('CCA GLM')

%% visualize pval
figure
scatter(avgp_ss(:), avgp_cca(:));
mx=max([avgp_ss(:); avgp_cca(:)]);
mn=min([avgp_ss(:); avgp_cca(:)]);
xlim([mn mx])
ylim([mn mx])
hold on
plot([mn mx], [mn mx], 'k')
scatter(nanmean(avgp_ss(:)), nanmean(avgp_cca(:)), 'xr')
title(['Average p-val. lag = ' num2str(timelag) 's, ct = ' num2str(param.ct) ' \tau = ' num2str(param.tau)])
xlabel('SS GLM')
ylabel('CCA GLM')


%% plot FP
%% visualize pval
figure
FP_SS = reshape(FP_SS,size(FP_SS,1)*size(FP_SS,2),1);
FP_CCA = reshape(FP_CCA,size(FP_SS,1)*size(FP_SS,2),1);
scatter(FP_SS,FP_CCA);
mx=max([FP_SS(:); FP_CCA(:)]);
mn=min([FP_SS(:); FP_CCA(:)]);
xlim([mn mx])
ylim([mn mx])
hold on
plot([mn mx], [mn mx], 'k')
scatter(nanmean(FP_SS(:)), nanmean(FP_CCA(:)), 'xr')
title(['# of channels with FP, lag = ' num2str(timelag) 's, ct = ' num2str(param.ct) ' \tau = ' num2str(param.tau)])
xlabel('SS GLM')
ylabel('CCA GLM')

