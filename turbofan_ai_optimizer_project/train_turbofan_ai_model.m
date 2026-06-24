function train_turbofan_ai_model(datasetFile)
% TRAIN_TURBOFAN_AI_MODEL
% Trains an AI surrogate model for the turbofan cycle-analysis code.
%
% Run after generate_turbofan_ai_data:
%   train_turbofan_ai_model
%
% Output:
%   turbofan_ai_model.mat
%   turbofan_ai_model_metrics.csv

if nargin < 1
    datasetFile = 'turbofan_ai_dataset.mat';
end

clc;

if ~isfile(datasetFile)
    error('Dataset file not found. Run generate_turbofan_ai_data first.');
end

load(datasetFile,'X','Y','inputNames','outputNames','dataTable','lb','ub');

rng(12);
n = size(X,1);
idx = randperm(n);

nTrain = round(0.70*n);
nVal   = round(0.15*n);

trainIdx = idx(1:nTrain);
valIdx   = idx(nTrain+1:nTrain+nVal);
testIdx  = idx(nTrain+nVal+1:end);

Xtrain = X(trainIdx,:); Ytrain = Y(trainIdx,:);
Xval   = X(valIdx,:);   Yval   = Y(valIdx,:);
Xtest  = X(testIdx,:);  Ytest  = Y(testIdx,:);

nOut = numel(outputNames);
models = cell(1,nOut);
metrics = struct('Output',{},'RMSE',{},'MAE',{},'R2',{});

fprintf('Training AI surrogate using %d valid samples...\n',n);

for j = 1:nOut
    yTrain = Ytrain(:,j);

    fprintf('\nTraining output: %s\n',outputNames{j});

    % Preferred: neural-network regression model.
    % Backup: boosted trees, if fitrnet is unavailable.
    if exist('fitrnet','file') == 2
        modelType = 'fitrnet neural network';
        models{j} = fitrnet(Xtrain,yTrain, ...
            'LayerSizes',[32 16], ...
            'Activations','relu', ...
            'Standardize',true, ...
            'Lambda',1e-4, ...
            'IterationLimit',1000);
    elseif exist('fitrensemble','file') == 2
        modelType = 'fitrensemble boosted trees';
        template = templateTree('MinLeafSize',8);
        models{j} = fitrensemble(Xtrain,yTrain, ...
            'Method','LSBoost', ...
            'Learners',template, ...
            'NumLearningCycles',250, ...
            'LearnRate',0.05);
    else
        error(['This script needs either fitrnet or fitrensemble. ', ...
               'Install/use MATLAB Statistics and Machine Learning Toolbox.']);
    end

    yPred = predict(models{j},Xtest);

    err = yPred - Ytest(:,j);
    rmse = sqrt(mean(err.^2,'omitnan'));
    mae = mean(abs(err),'omitnan');
    ssRes = sum(err.^2,'omitnan');
    ssTot = sum((Ytest(:,j) - mean(Ytest(:,j),'omitnan')).^2,'omitnan');
    r2 = 1 - ssRes/ssTot;

    metrics(j).Output = outputNames{j};
    metrics(j).RMSE = rmse;
    metrics(j).MAE = mae;
    metrics(j).R2 = r2;

    fprintf('  RMSE = %.5g | MAE = %.5g | R^2 = %.4f\n',rmse,mae,r2);
end

metricsTable = struct2table(metrics);
disp(metricsTable);

save('turbofan_ai_model.mat', ...
    'models','modelType','inputNames','outputNames','metricsTable','lb','ub', ...
    'Xtrain','Ytrain','Xval','Yval','Xtest','Ytest');

writetable(metricsTable,'turbofan_ai_model_metrics.csv');

fprintf('\nSaved: turbofan_ai_model.mat\n');
fprintf('Saved: turbofan_ai_model_metrics.csv\n');

% Prediction quality plots
figure('Name','Turbofan AI Surrogate: Predicted vs Cycle Model');
tiledlayout(2,3);

for j = 1:nOut
    nexttile;
    yPred = predict(models{j},Xtest);
    scatter(Ytest(:,j),yPred,15,'filled');
    hold on;
    mn = min([Ytest(:,j); yPred]);
    mx = max([Ytest(:,j); yPred]);
    plot([mn mx],[mn mx],'k--','LineWidth',1.2);
    hold off;
    xlabel(['Cycle model ',outputNames{j}],'Interpreter','none');
    ylabel(['AI predicted ',outputNames{j}],'Interpreter','none');
    title(sprintf('%s | R^2 = %.3f',outputNames{j},metrics(j).R2),'Interpreter','none');
    grid on;
end

end
