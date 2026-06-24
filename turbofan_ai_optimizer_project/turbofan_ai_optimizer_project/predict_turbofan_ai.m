function predictionTable = predict_turbofan_ai(inputVector,modelFile)
% PREDICT_TURBOFAN_AI
% Predicts turbofan outputs using the trained AI surrogate.
%
% Example:
%   x = [0.78 30 1.45 5.2 1700 225 22735 47];
%   T = predict_turbofan_ai(x)
%
% inputVector order:
%   Ma, prc, prf, B, T04, Ta, pa, QR_MJkg

if nargin < 2
    modelFile = 'turbofan_ai_model.mat';
end

if ~isfile(modelFile)
    error('Model file not found. Run train_turbofan_ai_model first.');
end

S = load(modelFile,'models','inputNames','outputNames');

if istable(inputVector)
    X = table2array(inputVector(:,S.inputNames));
else
    X = inputVector;
end

if size(X,2) ~= numel(S.inputNames)
    error('Input must have %d columns: %s',numel(S.inputNames),strjoin(S.inputNames,', '));
end

Yhat = zeros(size(X,1),numel(S.outputNames));
for j = 1:numel(S.outputNames)
    Yhat(:,j) = predict(S.models{j},X);
end

predictionTable = array2table(Yhat,'VariableNames',S.outputNames);
end
