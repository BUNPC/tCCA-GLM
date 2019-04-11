function [nirs_hrf] = addSimHRF(nirs, hrf, utest)
%% adds simulated HRF to intensity nirs data, using random 50% of long
%% distance channels and a random 0-3.5s onset within 20s windows.
%% Lowpassfilters and downsamples the data to 25Hz.
%
% Input:    nirs        -   HOMER2 .nirs struct
%           hrf         -   hrf mat file with simulated HRF data
%           utest       -   flag for unit test: if true the output signals
%                           will be constant "ones" only with simulated hrf
% Output:   same struct with added simulated HRFs. New / updated fields:
%           .lstHrfAdd  -   list of channels with added HRFs
%           .s          -   timepoints of HRF onset
%           .d          -   has simulated HRFs added at lstHRFAdd channels
%           .d0         -   same data but without simulated HRFs


% write new nirs struct
nirs_hrf = nirs;

%% Subsample fnirs signal to 25Hz
% sample rate
n_fs = 1/mean(diff(nirs.t));
if n_fs == 50
    %lowpass filter order
    order = 3;
    % cutoff
    f_cut = 12.5;
    % butterworth coefficients
    [d,c] = butter(order, f_cut/n_fs*2, 'low');
    % filter and downsample
    nirs_hrf.d = downsample(filtfilt(d,c,nirs.d),2);
    nirs_hrf.aux = downsample(filtfilt(d,c,nirs.aux),2);
    nirs_hrf.t = downsample(nirs.t,2);
    nirs_hrf.s = downsample(nirs.s,2);
    if isfield(nirs,'tdml')
        nirs_hrf.tdml = downsample(nirs.tdml',2)';
    end
    if isfield(nirs,'tIncMan')
        nirs_hrf.tIncMan = downsample(nirs.tIncMan',2)';
    end
    
    nirs_hrf.fs = 25;
else
    warning(['sample rate is ' num2str(n_fs) 'Hz - no downsampling performed'])
end
% save downsampled and filtered data before adding synthetic HRFs
nirs_hrf.d0 = nirs_hrf.d;

%% Prune noisy channels
nirs.SD = enPruneChannels(nirs.d,nirs.SD,ones(size(nirs.d,1),1),[10000  10000000],5,[0  45],0);


%% Definition channel groups
% separate SS channels
ss_threshold = 15; % mm
ml = nirs.SD.MeasList;
lst = find(ml(:,4)==1); % 690
rhoSD = zeros(length(lst),1);
posM = zeros(length(lst),3);
for iML = 1:length(lst)
    rhoSD(iML) = sum((nirs.SD.SrcPos(ml(lst(iML),1),:) - nirs.SD.DetPos(ml(lst(iML),2),:)).^2).^0.5;
    posM(iML,:) = (nirs.SD.SrcPos(ml(lst(iML),1),:) + nirs.SD.DetPos(ml(lst(iML),2),:)) / 2;
end
nirs_hrf.lstLongAct = lst(find(rhoSD> ss_threshold & nirs.SD.MeasListAct(lst)==1)); % list of long and active channels
nirs_hrf.lstShortAct = lst(find(rhoSD< ss_threshold & nirs.SD.MeasListAct(lst)==1)); % list of long and active channels

% randomly select 50% of long separation channels that are to be modulated
% with sim HRF and save indices in lstHrfAdd
ridx = randsample(numel(nirs_hrf.lstLongAct),ceil(numel(nirs_hrf.lstLongAct)/2));
nirs_hrf.lstHrfAdd(:,1) = sort(nirs_hrf.lstLongAct(ridx));
% save for wavelength 2 in column 2
nirs_hrf.lstHrfAdd(:,2) = nirs_hrf.lstHrfAdd(:,1)+size(nirs_hrf.ml,1)/2;

%% Window data (wsize windows) and determine (randomized) HRF onsets, create new s field
wsize = 20; % window size in seconds
% window onset points
onsidx = 1:wsize*nirs_hrf.fs:numel(nirs_hrf.s);
onsidx = onsidx(1:end-1);
% add random 0-3.5s offset
maxoffs = 3.5; % max offset in seconds
onsidx = onsidx+ceil(rand(numel(onsidx),1) * maxoffs*nirs_hrf.fs)';
% create new s field and add triggers
nirs_hrf.s = zeros(numel(nirs_hrf.s),1);
nirs_hrf.s(onsidx) = 1;


%% Add sim HRFs to selected channels at generated time points
% length of simulated hrf in samples:
hrflen = size(hrf.hrf_d,1);

if utest % builds hrfs onto constant (ones) signal
    nirs_hrf.d = ones(size(nirs_hrf.d,1),size(nirs_hrf.d,2));
end

% for all windows/onset timings
for oo = 1:numel(onsidx)
    % indices (samples) within window
    widxes = onsidx(oo):1:onsidx(oo)+hrflen-1;
    % for all selected channels
    for ii = 1:size(nirs_hrf.lstHrfAdd,1)
        % for both wavelengths
        for ww = 1:2
            % modulate signal
            nirs_hrf.d(widxes,nirs_hrf.lstHrfAdd(ii,ww)) = nirs_hrf.d(widxes,nirs_hrf.lstHrfAdd(ii,ww)).*hrf.hrf_d(:,ww);
        end
    end
end

end

