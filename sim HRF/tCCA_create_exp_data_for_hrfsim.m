path.dir = 'C:\Users\avolu\Google Drive\tCCA_GLM_PAPER';
path.fname = 'resting.nirs';
path.hrfname = 'hrf_simdat_dummy.mat';
path.savename = 'resting_ds.nirs';
path.code = 'D:\Office\Research\Software - Scripts\Matlab\Regression tCCA GLM\tCCA-GLM';
addpath(genpath(path.code));
sbjfolder = {'Subj33','Subj34','Subj36','Subj37','Subj38','Subj39', 'Subj40', 'Subj41', 'Subj43', 'Subj44','Subj46','Subj47','Subj49','Subj51'};


for ss = 1:numel(sbjfolder) % loop across subjects
% load participant data
nirs = load([path.dir filesep 'FB_RESTING_DATA' filesep sbjfolder{ss} filesep path.fname], '-mat');
% load simulated hrf
hrf = load([path.code filesep 'sim HRF' filesep path.hrfname]);
% hrf = load([path.dir path.hrfname]);

%% call the function
flag_prune = false;
[nirs_hrf] = addSimHRF(nirs, hrf, false, flag_prune);

save([path.dir filesep 'FB_RESTING_DATA' filesep sbjfolder{ss} filesep path.savename], '-struct', 'nirs_hrf')
disp('data saved.')
end





