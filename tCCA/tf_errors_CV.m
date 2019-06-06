%% counters
nancnt = 0;
onecnt = 0;

%% # of TP/FP/FN/TN channels
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

% True Positive *Rate* and False Positive *Rate*
TPR_SS = Ch_TP_SS./(Ch_TP_SS + Ch_FN_SS);
FPR_SS = Ch_FP_SS./(Ch_FP_SS + Ch_TN_SS);

TPR_CCA = Ch_TP_CCA./(Ch_TP_CCA + Ch_FN_CCA);
FPR_CCA = Ch_FP_CCA./(Ch_FP_CCA + Ch_TN_CCA);

% get F-score
% SS & CCA
Precision_SS = Ch_TP_SS ./(Ch_TP_SS + Ch_FP_SS);
Recall_SS = Ch_TP_SS ./(Ch_TP_SS + Ch_FN_SS);
F_score_SS = 2 * (Precision_SS .* Recall_SS)./(Precision_SS + Recall_SS);

Precision_CCA = Ch_TP_CCA ./(Ch_TP_CCA + Ch_FP_CCA);
Recall_CCA = Ch_TP_CCA ./(Ch_TP_CCA + Ch_FN_CCA);
F_score_CCA = 2 * (Precision_CCA .* Recall_CCA)./(Precision_CCA + Recall_CCA);

for i = 1:size(foo_SS,2)
    % SS
    if (Ch_TP_SS(i) + Ch_FN_SS(i)) == 0
        F_score_SS(i) = NaN;
    end
    if (Ch_TP_SS(i) + Ch_FP_SS(i) + Ch_FN_SS(i)) == 0
        F_score_SS(i) = 1;
    end
    if Ch_TP_SS(i) == 0 && (Ch_FP_SS(i) + Ch_FN_SS(i)) ~= 0
        F_score_SS(i) = 0;
    end
    
    % CCA
    if (Ch_TP_CCA(i) + Ch_FN_CCA(i)) == 0
        F_score_CCA(i) = NaN;
        nancnt = nancnt+1;
    end
    if (Ch_TP_CCA(i) + Ch_FP_CCA(i) + Ch_FN_CCA(i)) == 0
        F_score_CCA(i) = 1;
        onecnt = onecnt+1;
    end
    if Ch_TP_CCA(i) == 0 && (Ch_FP_CCA(i) + Ch_FN_CCA(i)) ~= 0
        F_score_CCA(i) = 0;
    end
    
end



% reshape all to "# of sbjs x 2(Hbo+HbR) x 2 (cv split) x tlag x stepsize x corrthres
Ch_TP_SS = reshape(Ch_TP_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
Ch_FP_SS = reshape(Ch_FP_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
Ch_FN_SS = reshape(Ch_FN_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
Ch_TN_SS = reshape(Ch_TN_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
F_score_SS = reshape(F_score_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
TPR_SS = reshape(TPR_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
FPR_SS = reshape(FPR_SS, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));

Ch_TP_CCA = reshape(Ch_TP_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
Ch_FP_CCA = reshape(Ch_FP_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
Ch_FN_CCA = reshape(Ch_FN_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
Ch_TN_CCA = reshape(Ch_TN_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
F_score_CCA = reshape(F_score_CCA, size(DET_CCA,1), size(DET_CCA,3), size(DET_CCA,4), size(DET_CCA,5), size(DET_CCA,6), size(DET_CCA,7));
TPR_CCA = reshape(TPR_CCA, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
FPR_CCA = reshape(FPR_CCA, size(DET_SS,1), size(DET_SS,3), size(DET_SS,4), size(DET_SS,5), size(DET_SS,6), size(DET_SS,7));
