function [] = contour_plots(METRIC, ttl, evparams, pOpt, cntno, flip)
%CONTOUR_PLOTS Summary of this function goes here
%   Detailed explanation goes here

%% create combined surface plots (depict objective function)
[X,Y] = meshgrid(evparams.stpsize,evparams.tlags);

%% Plot Objective function results
figure
climits = [min(METRIC(:)) max(METRIC(:))];
for ii=1:10
    subplot(3,4,ii)
    contourf(X,Y, squeeze(METRIC(:,:,ii)), cntno)
    xlabel('stepsize / smpl')
    ylabel('time lags / s')
    title([ttl ', ctrsh: ' num2str(evparams.cthresh(ii))])
    
    buf =  squeeze(METRIC(:,:,ii));
    switch flip
        case 'max'
            colormap hot
            [r,c] = ind2sub(size(buf),find(buf == max(buf(:))));
            limit = climits(2);
        case 'min'
            colormap(flipud(hot))
            [r,c] = ind2sub(size(buf),find(buf == min(buf(:))));
            limit = climits(1);
    end
    colorbar
    caxis(climits)
    % mark local optima
    hold on
    if squeeze(METRIC(r(1),c(1),ii)) == limit
            mrkc = 'g';
        else
            mrkc = 'k';
        end
        if numel(r)<4
            p=numel(r);
        else
            p=1;
        end
        for pp = 1:p
            plot(evparams.stpsize(c(pp)),evparams.tlags(r(pp)),'ko','MarkerFaceColor', mrkc)
            if pp==1
                text(evparams.stpsize(c(pp)),evparams.tlags(r(pp)), ['\leftarrow ' num2str(METRIC(r(pp),c(pp),ii))])
            end
        end
        % mark optimum from objective function
        if ii == pOpt(1,3)
            plot(evparams.stpsize(pOpt(1,2)),evparams.tlags(pOpt(1,1)),'diamond','MarkerFaceColor', 'c')
            text(evparams.stpsize(pOpt(1,2)),evparams.tlags(pOpt(1,1)), ['\leftarrow ' num2str(METRIC(pOpt(1,1),pOpt(1,2),ii))])
        end
end
end

