function turbofan_ai_optimizer_app
% TURBOFAN_AI_OPTIMIZER_APP
% Professional dashboard UI for a machine learning turbofan performance optimizer.
%
% Features:
% 1) AI vs cycle-model comparison
% 2) Extra optimizer constraints
% 3) Pareto front plotting
% 4) Sensitivity analysis
% 5) Upgraded professional dark dashboard UI
% 6) Fixed scrollable control panel so buttons do not get cut off
%
% Before running this app, run:
%   generate_turbofan_ai_data(8000)
%   train_turbofan_ai_model
%
% Then run:
%   turbofan_ai_optimizer_app

clc; close all;

modelFile = 'turbofan_ai_model.mat';

if ~isfile(modelFile)
    error('Missing turbofan_ai_model.mat. Run generate_turbofan_ai_data, then train_turbofan_ai_model.');
end

S = load(modelFile);

% Compatible with toolbox-free model and older toolbox model.
if isfield(S,'model')
    inputNames = S.model.inputNames;
    outputNames = S.model.outputNames;
    lb = S.model.lb;
    ub = S.model.ub;
    modelType = S.model.modelType;
elseif isfield(S,'inputNames') && isfield(S,'outputNames')
    inputNames = S.inputNames;
    outputNames = S.outputNames;
    lb = S.lb;
    ub = S.ub;

    if isfield(S,'modelType')
        modelType = S.modelType;
    else
        modelType = 'AI surrogate model';
    end
else
    error('Model file is missing required fields. Re-run train_turbofan_ai_model.');
end

if isfield(S,'metricsTable')
    trainingMetrics = S.metricsTable;
else
    trainingMetrics = table();
end

idx = getOutputIndices(outputNames);

%% Default values
default.Ma = 0.78;
default.prc = 30;
default.prf = 1.45;
default.B = 5.2;
default.T04 = 1700;
default.Ta = 225;
default.pa = 22735;
default.QR_MJkg = 47;

% Optimizer constraints
default.minST = 120;
default.maxTSFC = 90;
default.minEta0 = 0.15;
default.minEtaP = 0.35;
default.nOpt = 15000;

% Sensitivity
default.sensStep = 5;

%% Theme
theme.bg      = [0.045 0.055 0.085];
theme.card    = [0.080 0.095 0.140];
theme.card2   = [0.105 0.120 0.175];
theme.text    = [0.94 0.96 1.00];
theme.muted   = [0.66 0.72 0.82];
theme.blue    = [0.20 0.48 0.95];
theme.cyan    = [0.10 0.78 0.92];
theme.green   = [0.20 0.75 0.45];
theme.orange  = [0.95 0.55 0.20];
theme.red     = [0.92 0.25 0.30];
theme.purple  = [0.55 0.35 0.95];
theme.gray    = [0.30 0.34 0.42];

%% Build GUI
fig = uifigure( ...
    'Name','Machine Learning Turbofan Performance Optimizer', ...
    'Position',[40 35 1500 875], ...
    'Color',theme.bg);

root = uigridlayout(fig,[2 1]);
root.RowHeight = {88,'1x'};
root.Padding = [14 14 14 14];
root.RowSpacing = 12;
root.BackgroundColor = theme.bg;

%% Header
headerPanel = uipanel(root, ...
    'BorderType','none', ...
    'BackgroundColor',theme.card);
headerPanel.Layout.Row = 1;

headerGrid = uigridlayout(headerPanel,[1 3]);
headerGrid.ColumnWidth = {'1x',330,220};
headerGrid.Padding = [22 10 22 10];
headerGrid.ColumnSpacing = 16;
headerGrid.BackgroundColor = theme.card;

titleGrid = uigridlayout(headerGrid,[2 1]);
titleGrid.Layout.Column = 1;
titleGrid.RowHeight = {46,'1x'};
titleGrid.Padding = [0 0 0 0];
titleGrid.BackgroundColor = theme.card;

uilabel(titleGrid, ...
    'Text','Machine Learning Turbofan Optimizer', ...
    'FontSize',30, ...
    'FontWeight','bold', ...
    'FontColor',theme.text);

modelBadge = uipanel(headerGrid, ...
    'BorderType','none', ...
    'BackgroundColor',theme.card2);
modelBadge.Layout.Column = 2;

badgeGrid = uigridlayout(modelBadge,[2 1]);
badgeGrid.RowHeight = {'1x','1x'};
badgeGrid.Padding = [14 9 14 9];
badgeGrid.BackgroundColor = theme.card2;

uilabel(badgeGrid, ...
    'Text','SURROGATE MODEL', ...
    'FontSize',11, ...
    'FontWeight','bold', ...
    'FontColor',theme.cyan);

uilabel(badgeGrid, ...
    'Text',sprintf('%s  |  %d inputs  |  %d outputs',modelType,numel(inputNames),numel(outputNames)), ...
    'FontSize',12, ...
    'FontColor',theme.text);

topOptButton = uibutton(headerGrid,'push', ...
    'Text','Optimize + Pareto', ...
    'FontSize',15, ...
    'FontWeight','bold', ...
    'FontColor',[1 1 1], ...
    'BackgroundColor',theme.green, ...
    'ButtonPushedFcn',@(~,~) optimizeDesign());
topOptButton.Layout.Column = 3;

%% Main body
mainGrid = uigridlayout(root,[1 2]);
mainGrid.Layout.Row = 2;
mainGrid.ColumnWidth = {455,'1x'};
mainGrid.ColumnSpacing = 14;
mainGrid.BackgroundColor = theme.bg;

%% Left control panel
controlPanel = uipanel(mainGrid, ...
    'Title','Inputs, Constraints, and Tools', ...
    'FontWeight','bold', ...
    'FontSize',14, ...
    'ForegroundColor',theme.text, ...
    'BackgroundColor',theme.card);
controlPanel.Layout.Column = 1;

% This makes the panel scrollable so buttons do not get cut off.
try
    controlPanel.Scrollable = 'on';
catch
end

controlGrid = uigridlayout(controlPanel,[31 2]);
controlGrid.ColumnWidth = {215,'1x'};

% Fixed-height rows, tightened spacing, and scroll support.
controlGrid.RowHeight = [ ...
    {24}, repmat({28},1,8), ...
    {8}, {24}, repmat({28},1,5), ...
    {8}, {24}, repmat({28},1,2), ...
    {8}, repmat({34},1,5), ...
    {8}, {60}, {8}, {44}, {8}];

controlGrid.Padding = [12 8 12 10];
controlGrid.RowSpacing = 4;
controlGrid.BackgroundColor = theme.card;

try
    controlGrid.Scrollable = 'on';
catch
end

sectionLabel(1,'Flight + Engine Inputs');

MaField    = addField(2,  'Mach number', default.Ma, [0.65 0.88]);
prcField   = addField(3,  'Compressor PR  p_{rc}', default.prc, [15 45]);
prfField   = addField(4,  'Fan PR  p_{rf}', default.prf, [1.15 1.70]);
BField     = addField(5,  'Bypass ratio  B', default.B, [3 12]);
T04Field   = addField(6,  'Burner exit T04 [K]', default.T04, [1400 1900]);
TaField    = addField(7,  'Ambient T_a [K]', default.Ta, [210 290]);
paField    = addField(8,  'Ambient p_a [Pa]', default.pa, [18000 101325]);
QRField    = addField(9,  'Fuel Q_R [MJ/kg]', default.QR_MJkg, [43 47]);

sectionLabel(11,'Optimizer Constraints');

minSTField   = addField(12, 'Minimum ST [N/(kg/s)]', default.minST, [1 1000]);
maxTSFCField = addField(13, 'Maximum TSFC [mg/(N*s)]', default.maxTSFC, [1 500]);
minEta0Field = addField(14, 'Minimum eta0', default.minEta0, [0 1]);
minEtaPField = addField(15, 'Minimum etaP', default.minEtaP, [0 1]);
nOptField    = addField(16, 'Optimizer samples', default.nOpt, [1000 100000]);

sectionLabel(18,'Plots + Sensitivity');

metricLabel = uilabel(controlGrid, ...
    'Text','Contour metric', ...
    'FontColor',theme.text, ...
    'FontSize',12, ...
    'FontWeight','bold');
metricLabel.Layout.Row = 19;
metricLabel.Layout.Column = 1;

metricDrop = uidropdown(controlGrid, ...
    'Items',{'Overall Efficiency','TSFC','Specific Thrust','Propulsive Efficiency','Thermal Efficiency'}, ...
    'Value','Overall Efficiency', ...
    'BackgroundColor',[1 1 1], ...
    'ValueChangedFcn',@(~,~) updateCurrent());
metricDrop.Layout.Row = 19;
metricDrop.Layout.Column = 2;

sensStepField = addField(20, 'Sensitivity step [%]', default.sensStep, [0.1 25]);

addButton(22,'Predict Current Design',theme.blue,@(~,~) updateCurrent());
addButton(23,'Compare AI vs Cycle Model',theme.orange,@(~,~) compareCurrent());
addButton(24,'Optimize + Pareto Front',theme.green,@(~,~) optimizeDesign());
addButton(25,'Run Sensitivity Analysis',theme.purple,@(~,~) runSensitivity());
addButton(26,'Reset Defaults',theme.gray,@(~,~) resetDefaults());

statusBox = uipanel(controlGrid, ...
    'BorderType','none', ...
    'BackgroundColor',theme.card2);
statusBox.Layout.Row = 28;
statusBox.Layout.Column = [1 2];

statusGrid = uigridlayout(statusBox,[1 1]);
statusGrid.Padding = [12 8 12 8];
statusGrid.BackgroundColor = theme.card2;

statusLabel = uilabel(statusGrid, ...
    'Text','Ready.', ...
    'FontColor',theme.text, ...
    'FontSize',12, ...
    'WordWrap','on');

modelLabel = uilabel(controlGrid, ...
    'Text',sprintf('Model loaded: %s',modelType), ...
    'FontColor',theme.muted, ...
    'FontSize',12, ...
    'WordWrap','on');
modelLabel.Layout.Row = 30;
modelLabel.Layout.Column = [1 2];

%% Right dashboard
dashGrid = uigridlayout(mainGrid,[3 1]);
dashGrid.Layout.Column = 2;
dashGrid.RowHeight = {115,'1x',245};
dashGrid.RowSpacing = 14;
dashGrid.BackgroundColor = theme.bg;

%% KPI cards
kpiGrid = uigridlayout(dashGrid,[1 4]);
kpiGrid.Layout.Row = 1;
kpiGrid.ColumnWidth = {'1x','1x','1x','1x'};
kpiGrid.ColumnSpacing = 12;
kpiGrid.BackgroundColor = theme.bg;

[kpiEta0Value,kpiEta0Sub] = addKpiCard(1,'Overall Efficiency','--','eta0',theme.green);
[kpiSTValue,kpiSTSub]     = addKpiCard(2,'Specific Thrust','--','N/(kg/s)',theme.blue);
[kpiTSFCValue,kpiTSFCSub] = addKpiCard(3,'TSFC','--','mg/(N*s)',theme.orange);
[kpiErrValue,kpiErrSub]   = addKpiCard(4,'AI vs Cycle Error','--','compare model',theme.purple);

%% Plot tabs
plotPanel = uipanel(dashGrid, ...
    'Title','Performance Visualization', ...
    'FontWeight','bold', ...
    'FontSize',14, ...
    'ForegroundColor',theme.text, ...
    'BackgroundColor',theme.card);
plotPanel.Layout.Row = 2;

plotGrid = uigridlayout(plotPanel,[1 1]);
plotGrid.Padding = [10 10 10 10];
plotGrid.BackgroundColor = theme.card;

tabGroup = uitabgroup(plotGrid);

contourTab = uitab(tabGroup,'Title','AI Contour');
paretoTab = uitab(tabGroup,'Title','Pareto Front');
sensitivityTab = uitab(tabGroup,'Title','Sensitivity Analysis');

axContour = uiaxes(contourTab);
axContour.Units = 'normalized';
axContour.Position = [0.055 0.09 0.89 0.84];

axPareto = uiaxes(paretoTab);
axPareto.Units = 'normalized';
axPareto.Position = [0.055 0.09 0.89 0.84];

axSensitivity = uiaxes(sensitivityTab);
axSensitivity.Units = 'normalized';
axSensitivity.Position = [0.065 0.12 0.88 0.80];

styleAxes(axContour);
styleAxes(axPareto);
styleAxes(axSensitivity);

%% Tables
tableTabs = uitabgroup(dashGrid);
tableTabs.Layout.Row = 3;

designTab = uitab(tableTabs,'Title','Design Results');
comparisonTab = uitab(tableTabs,'Title','AI vs Cycle / Sensitivity');
metricsTab = uitab(tableTabs,'Title','Training Metrics');

designTable = uitable(designTab);
designTable.Units = 'normalized';
designTable.Position = [0 0 1 1];
designTable.ColumnName = {'Case','Ma','PRC','PRF','B','T04','ST','TSFC mg/(N*s)','eta0','etaT','etaP','f'};
designTable.ColumnWidth = {135,60,60,60,60,70,90,120,75,75,75,75};
designTable.FontName = 'Segoe UI';
designTable.FontSize = 12;

comparisonTable = uitable(comparisonTab);
comparisonTable.Units = 'normalized';
comparisonTable.Position = [0 0 1 1];
comparisonTable.ColumnName = {'Output','AI Prediction','Cycle Model','Absolute Error','Percent Error'};
comparisonTable.ColumnWidth = {190,130,130,130,130};
comparisonTable.FontName = 'Segoe UI';
comparisonTable.FontSize = 12;

metricsTableUI = uitable(metricsTab);
metricsTableUI.Units = 'normalized';
metricsTableUI.Position = [0 0 1 1];
metricsTableUI.Data = trainingMetrics;
metricsTableUI.FontName = 'Segoe UI';
metricsTableUI.FontSize = 12;

updateCurrent();

%% UI helper functions
    function h = sectionLabel(row,text)
        h = uilabel(controlGrid, ...
            'Text',upper(text), ...
            'FontWeight','bold', ...
            'FontSize',13, ...
            'FontColor',theme.cyan);
        h.Layout.Row = row;
        h.Layout.Column = [1 2];
    end

    function field = addField(row,label,value,limits)
        lab = uilabel(controlGrid, ...
            'Text',label, ...
            'Interpreter','tex', ...
            'FontColor',theme.text, ...
            'FontSize',12);
        lab.Layout.Row = row;
        lab.Layout.Column = 1;

        field = uieditfield(controlGrid,'numeric', ...
            'Value',value, ...
            'Limits',limits, ...
            'BackgroundColor',[1 1 1], ...
            'FontSize',12, ...
            'ValueChangedFcn',@(~,~) updateCurrent());

        field.Layout.Row = row;
        field.Layout.Column = 2;
    end

    function btn = addButton(row,text,color,callback)
        btn = uibutton(controlGrid,'push', ...
            'Text',text, ...
            'FontWeight','bold', ...
            'FontSize',13, ...
            'FontColor',[1 1 1], ...
            'BackgroundColor',color, ...
            'ButtonPushedFcn',callback);
        btn.Layout.Row = row;
        btn.Layout.Column = [1 2];
    end

    function [valueLabel,subLabel] = addKpiCard(col,titleText,valueText,subText,accentColor)
        card = uipanel(kpiGrid, ...
            'BorderType','none', ...
            'BackgroundColor',theme.card);
        card.Layout.Column = col;

        cardGrid = uigridlayout(card,[3 1]);
        cardGrid.RowHeight = {28,'1x',25};
        cardGrid.Padding = [14 10 14 10];
        cardGrid.BackgroundColor = theme.card;

        uilabel(cardGrid, ...
            'Text',upper(titleText), ...
            'FontSize',11, ...
            'FontWeight','bold', ...
            'FontColor',accentColor);

        valueLabel = uilabel(cardGrid, ...
            'Text',valueText, ...
            'FontSize',26, ...
            'FontWeight','bold', ...
            'FontColor',theme.text);

        subLabel = uilabel(cardGrid, ...
            'Text',subText, ...
            'FontSize',11, ...
            'FontColor',theme.muted);
    end

    function styleAxes(ax)
        ax.Color = theme.card2;
        ax.XColor = theme.muted;
        ax.YColor = theme.muted;
        ax.GridColor = [0.25 0.28 0.34];
        ax.MinorGridColor = [0.20 0.23 0.28];
        ax.FontSize = 12;
        grid(ax,'on');
        box(ax,'on');
    end

%% App logic
    function x = readInputVector()
        x = [MaField.Value, prcField.Value, prfField.Value, BField.Value, ...
             T04Field.Value, TaField.Value, paField.Value, QRField.Value];
    end

    function resetDefaults()
        MaField.Value = default.Ma;
        prcField.Value = default.prc;
        prfField.Value = default.prf;
        BField.Value = default.B;
        T04Field.Value = default.T04;
        TaField.Value = default.Ta;
        paField.Value = default.pa;
        QRField.Value = default.QR_MJkg;

        minSTField.Value = default.minST;
        maxTSFCField.Value = default.maxTSFC;
        minEta0Field.Value = default.minEta0;
        minEtaPField.Value = default.minEtaP;
        nOptField.Value = default.nOpt;
        sensStepField.Value = default.sensStep;

        metricDrop.Value = 'Overall Efficiency';

        cla(axPareto);
        cla(axSensitivity);

        updateCurrent();
        setStatus('Defaults restored. Showing baseline AI prediction.','ok');
    end

    function updateCurrent()
        try
            xCurrent = readInputVector();
            yCurrentAI = fixedOutputs(aiPredict(xCurrent));

            designTable.Data = makeResultCell('Current AI',xCurrent,yCurrentAI);

            comparisonTable.ColumnName = {'Output','AI Prediction','Cycle Model','Absolute Error','Percent Error'};
            comparisonTable.Data = {'Click Compare AI vs Cycle Model','','','',''};

            updateKpis(yCurrentAI,NaN,'Current AI design');
            plotContour(xCurrent);

            setStatus('Showing AI surrogate prediction. Click Compare AI vs Cycle Model to validate against turbofan_func.','info');

        catch ME
            setStatus(['Error: ',ME.message],'error');
        end
    end

    function compareCurrent()
        try
            xCurrent = readInputVector();

            yAI = fixedOutputs(aiPredict(xCurrent));
            yCycle = cycleEvaluate(xCurrent);

            designTable.Data = [makeResultCell('Current AI',xCurrent,yAI); ...
                                makeResultCell('Cycle model',xCurrent,yCycle)];

            comparisonTable.ColumnName = {'Output','AI Prediction','Cycle Model','Absolute Error','Percent Error'};
            comparisonTable.Data = makeComparisonCell(yAI,yCycle);

            maxAbsPct = max(abs(percentError(yAI,yCycle)),[],'omitnan');

            updateKpis(yCycle,maxAbsPct,'Cycle model result');

            setStatus(sprintf('Comparison complete. Largest absolute percent error across outputs: %.2f%%.',maxAbsPct),'ok');
            tableTabs.SelectedTab = comparisonTab;

        catch ME
            setStatus(['Comparison error: ',ME.message],'error');
        end
    end

    function optimizeDesign()
        try
            nOpt = round(nOptField.Value);
            minST = minSTField.Value;
            maxTSFC = maxTSFCField.Value;
            minEta0 = minEta0Field.Value;
            minEtaP = minEtaPField.Value;

            setStatus(sprintf('Running constrained AI search across %d candidate designs...',nOpt),'info');
            drawnow;

            xBase = readInputVector();
            samples = repmat(xBase,nOpt,1);

            optCols = [2 3 4 5];
            samples(:,optCols) = lb(optCols) + rand(nOpt,numel(optCols)).*(ub(optCols)-lb(optCols));

            yRaw = aiPredict(samples);

            ST = yRaw(:,idx.ST);
            TSFC = yRaw(:,idx.TSFC);
            eta0 = yRaw(:,idx.eta0);
            etaT = yRaw(:,idx.etaT);
            etaP = yRaw(:,idx.etaP);

            feasible = ST >= minST & ...
                       TSFC <= maxTSFC & ...
                       eta0 >= minEta0 & ...
                       etaP >= minEtaP & ...
                       isfinite(ST) & isfinite(TSFC) & isfinite(eta0) & ...
                       ST > 0 & TSFC > 0 & eta0 > 0 & etaT > 0 & etaP > 0;

            if ~any(feasible)
                setStatus(['No feasible AI designs found. Try lowering minimum ST, increasing max TSFC, ', ...
                           'lowering minimum eta0/etaP, or increasing optimizer samples.'],'warn');
                plotPareto(samples,yRaw,feasible,[]);
                tabGroup.SelectedTab = paretoTab;
                return
            end

            score = eta0 - 1e-4*TSFC;
            score(~feasible) = -Inf;

            [~,bestIdx] = max(score);

            xBest = samples(bestIdx,:);
            yBestAI = fixedOutputs(yRaw(bestIdx,:));
            yBestCycle = cycleEvaluate(xBest);

            xCurrent = readInputVector();
            yCurrentAI = fixedOutputs(aiPredict(xCurrent));

            designTable.Data = [makeResultCell('Current AI',xCurrent,yCurrentAI); ...
                                makeResultCell('Best AI',xBest,yBestAI); ...
                                makeResultCell('Best cycle check',xBest,yBestCycle)];

            comparisonTable.ColumnName = {'Output','AI Prediction','Cycle Model','Absolute Error','Percent Error'};
            comparisonTable.Data = makeComparisonCell(yBestAI,yBestCycle);

            prcField.Value = xBest(2);
            prfField.Value = xBest(3);
            BField.Value = xBest(4);
            T04Field.Value = xBest(5);

            plotContour(xBest);

            hold(axContour,'on');
            plot(axContour,xBest(3),xBest(4),'p', ...
                'MarkerFaceColor',theme.green, ...
                'MarkerEdgeColor',[0 0 0], ...
                'MarkerSize',17, ...
                'LineWidth',1.5);
            hold(axContour,'off');

            plotPareto(samples,yRaw,feasible,bestIdx);

            maxAbsPct = max(abs(percentError(yBestAI,yBestCycle)),[],'omitnan');

            updateKpis(yBestAI,maxAbsPct,'Best AI design');

            setStatus(sprintf(['Optimization complete. Feasible designs: %d/%d. ', ...
                'Best cycle-check max absolute percent error: %.2f%%.'], ...
                sum(feasible),nOpt,maxAbsPct),'ok');

            tabGroup.SelectedTab = paretoTab;
            tableTabs.SelectedTab = designTab;

        catch ME
            setStatus(['Optimization error: ',ME.message],'error');
        end
    end

    function runSensitivity()
        try
            xBase = readInputVector();
            stepFrac = sensStepField.Value/100;

            yBaseRaw = aiPredict(xBase);
            [metricIdx,metricLabelText] = selectedMetricIndex();

            nInputs = numel(inputNames);
            deltaPlus = zeros(nInputs,1);
            deltaMinus = zeros(nInputs,1);
            centralEffect = zeros(nInputs,1);

            for k = 1:nInputs
                xPlus = xBase;
                xMinus = xBase;

                change = stepFrac*abs(xBase(k));

                if change == 0
                    change = stepFrac*(ub(k)-lb(k));
                end

                xPlus(k) = min(ub(k),xBase(k) + change);
                xMinus(k) = max(lb(k),xBase(k) - change);

                yPlus = aiPredict(xPlus);
                yMinus = aiPredict(xMinus);

                deltaPlus(k) = yPlus(metricIdx) - yBaseRaw(metricIdx);
                deltaMinus(k) = yMinus(metricIdx) - yBaseRaw(metricIdx);

                denom = xPlus(k) - xMinus(k);

                if denom == 0
                    centralEffect(k) = 0;
                else
                    centralEffect(k) = (yPlus(metricIdx) - yMinus(metricIdx))/denom;
                end
            end

            normEffect = abs(centralEffect);

            if max(normEffect) > 0
                normEffect = normEffect./max(normEffect);
            end

            cla(axSensitivity);
            bar(axSensitivity,normEffect, ...
                'FaceColor',theme.cyan, ...
                'EdgeColor',[0 0 0], ...
                'LineWidth',0.8);

            axSensitivity.XTick = 1:nInputs;
            axSensitivity.XTickLabel = inputNames;
            axSensitivity.XTickLabelRotation = 30;

            ylabel(axSensitivity,'Normalized sensitivity','Color',theme.muted);
            title(axSensitivity,['One-at-a-time sensitivity of ',metricLabelText], ...
                'Interpreter','none', ...
                'Color',theme.text, ...
                'FontWeight','bold');
            styleAxes(axSensitivity);

            sensitivityTable = cell(nInputs,5);

            for k = 1:nInputs
                sensitivityTable{k,1} = inputNames{k};
                sensitivityTable{k,2} = xBase(k);
                sensitivityTable{k,3} = deltaPlus(k);
                sensitivityTable{k,4} = deltaMinus(k);
                sensitivityTable{k,5} = normEffect(k);
            end

            comparisonTable.ColumnName = {'Input','Baseline Value','Metric Change + Step','Metric Change - Step','Normalized Sensitivity'};
            comparisonTable.Data = sensitivityTable;

            setStatus(sprintf('Sensitivity analysis complete using +/- %.2f%% perturbations.',sensStepField.Value),'ok');

            tabGroup.SelectedTab = sensitivityTab;
            tableTabs.SelectedTab = comparisonTab;

        catch ME
            setStatus(['Sensitivity error: ',ME.message],'error');
        end
    end

    function plotContour(xFixed)
        prfVec = linspace(lb(3),ub(3),90);
        BVec = linspace(lb(4),ub(4),90);

        [PRF,BG] = meshgrid(prfVec,BVec);

        Xmap = repmat(xFixed,numel(PRF),1);
        Xmap(:,3) = PRF(:);
        Xmap(:,4) = BG(:);

        Ymap = aiPredict(Xmap);

        switch metricDrop.Value
            case 'Overall Efficiency'
                z = Ymap(:,idx.eta0);
                zLabel = 'AI-predicted overall efficiency \eta_0';

            case 'TSFC'
                z = Ymap(:,idx.TSFC);
                zLabel = 'AI-predicted TSFC [mg/(N*s)]';

            case 'Specific Thrust'
                z = Ymap(:,idx.ST);
                zLabel = 'AI-predicted specific thrust [N/(kg/s)]';

            case 'Propulsive Efficiency'
                z = Ymap(:,idx.etaP);
                zLabel = 'AI-predicted propulsive efficiency \eta_P';

            case 'Thermal Efficiency'
                z = Ymap(:,idx.etaT);
                zLabel = 'AI-predicted thermal efficiency \eta_T';
        end

        Z = reshape(z,size(PRF));

        cla(axContour);
        contourf(axContour,PRF,BG,Z,42,'LineStyle','none');

        try
            colormap(axContour,turbo(256));
        catch
            colormap(axContour,parula(256));
        end

        hold(axContour,'on');
        plot(axContour,xFixed(3),xFixed(4),'o', ...
            'MarkerFaceColor',[1 1 1], ...
            'MarkerEdgeColor',[0 0 0], ...
            'MarkerSize',9, ...
            'LineWidth',1.4);
        hold(axContour,'off');

        xlabel(axContour,'Fan pressure ratio  p_{rf}','Color',theme.muted);
        ylabel(axContour,'Bypass ratio  B','Color',theme.muted);
        title(axContour,zLabel,'Interpreter','tex','Color',theme.text,'FontWeight','bold');

        styleAxes(axContour);

        cb = colorbar(axContour);
        cb.Color = theme.text;
        cb.Label.String = zLabel;
        cb.Label.Color = theme.text;
    end

    function plotPareto(samples,yRaw,feasible,bestIdx)
        ST = yRaw(:,idx.ST);
        TSFC = yRaw(:,idx.TSFC);
        eta0 = yRaw(:,idx.eta0);

        cla(axPareto);
        hold(axPareto,'on');

        if any(~feasible)
            scatter(axPareto,eta0(~feasible),TSFC(~feasible),12, ...
                [0.45 0.48 0.55], ...
                'filled', ...
                'MarkerFaceAlpha',0.45);
        end

        if any(feasible)
            scatter(axPareto,eta0(feasible),TSFC(feasible),22,ST(feasible),'filled');

            paretoMask = findParetoFront(eta0(feasible),TSFC(feasible));
            eta0Feas = eta0(feasible);
            TSFCFeas = TSFC(feasible);

            plot(axPareto,eta0Feas(paretoMask),TSFCFeas(paretoMask),'o', ...
                'MarkerSize',7, ...
                'MarkerEdgeColor',[0 0 0], ...
                'MarkerFaceColor',[1 1 1], ...
                'LineWidth',1.2);

            if ~isempty(bestIdx)
                plot(axPareto,eta0(bestIdx),TSFC(bestIdx),'p', ...
                    'MarkerFaceColor',theme.green, ...
                    'MarkerEdgeColor',[0 0 0], ...
                    'MarkerSize',17, ...
                    'LineWidth',1.5);
            end

            cb = colorbar(axPareto);
            cb.Label.String = 'Specific thrust [N/(kg/s)]';
            cb.Color = theme.text;
            cb.Label.Color = theme.text;
        end

        xlabel(axPareto,'Overall efficiency \eta_0','Color',theme.muted);
        ylabel(axPareto,'TSFC [mg/(N*s)]','Color',theme.muted);
        title(axPareto,'Pareto Front: High Efficiency vs Low TSFC', ...
            'Color',theme.text, ...
            'FontWeight','bold');

        styleAxes(axPareto);

        legend(axPareto, ...
            {'Infeasible designs','Feasible designs','Pareto front','Best selected design'}, ...
            'Location','best', ...
            'TextColor',theme.text, ...
            'Color',theme.card2);

        hold(Pareto,'off');
    end

    function updateKpis(y,maxAbsPct,subtitleText)
        ST = y(1);
        TSFC = y(2);
        eta0 = y(3);

        kpiEta0Value.Text = sprintf('%.1f%%',100*eta0);
        kpiSTValue.Text = sprintf('%.1f',ST);
        kpiTSFCValue.Text = sprintf('%.1f',TSFC);

        if isnan(maxAbsPct)
            kpiErrValue.Text = '--';
            kpiErrSub.Text = 'run comparison';
        else
            kpiErrValue.Text = sprintf('%.2f%%',maxAbsPct);
            kpiErrSub.Text = 'max abs error';
        end

        kpiEta0Sub.Text = subtitleText;
        kpiSTSub.Text = 'Specific thrust';
        kpiTSFCSub.Text = 'Lower is better';
    end

    function setStatus(msg,type)
        statusLabel.Text = msg;

        switch lower(type)
            case 'ok'
                statusLabel.FontColor = theme.green;
                statusBox.BackgroundColor = [0.07 0.15 0.11];
                statusGrid.BackgroundColor = [0.07 0.15 0.11];

            case 'warn'
                statusLabel.FontColor = theme.orange;
                statusBox.BackgroundColor = [0.17 0.12 0.07];
                statusGrid.BackgroundColor = [0.17 0.12 0.07];

            case 'error'
                statusLabel.FontColor = theme.red;
                statusBox.BackgroundColor = [0.18 0.08 0.09];
                statusGrid.BackgroundColor = [0.18 0.08 0.09];

            otherwise
                statusLabel.FontColor = theme.cyan;
                statusBox.BackgroundColor = theme.card2;
                statusGrid.BackgroundColor = theme.card2;
        end
    end

%% Model helper functions
    function Yhat = aiPredict(Xin)
        if isrow(Xin)
            Xin = reshape(Xin,1,[]);
        end

        % Toolbox-free polynomial ridge surrogate
        if isfield(S,'model') && isfield(S.model,'beta')
            Z = (Xin - S.model.xMu)./S.model.xSig;
            Phi = makePolyFeatures(Z);

            YhatZ = Phi*S.model.beta;
            Yhat = YhatZ.*S.model.ySig + S.model.yMu;

        % Older version using fitrnet / fitrensemble
        elseif isfield(S,'models') && ~isempty(S.models)
            Yhat = zeros(size(Xin,1),numel(outputNames));

            for jj = 1:numel(outputNames)
                Yhat(:,jj) = predict(S.models{jj},Xin);
            end

        % Fallback if predict_turbofan_ai.m exists
        elseif exist('predict_turbofan_ai','file') == 2
            T = predict_turbofan_ai(Xin,modelFile);
            Yhat = table2array(T(:,outputNames));

        else
            error('No compatible AI prediction method found. Re-run train_turbofan_ai_model.');
        end
    end

    function y = cycleEvaluate(x)
        [conditions,gammas,etas] = turbofanDefaults(x(6),x(7));

        QR = x(8)*1e6;

        perf = turbofan_func(conditions,gammas,etas,x(1),x(2),x(3),x(4),x(5),QR);

        y = [real(perf.ST), ...
             real(perf.TSFC)*1e6, ...
             real(perf.eta0), ...
             real(perf.etaT), ...
             real(perf.etaP), ...
             real(perf.f)];

        if ~all(isfinite(y)) || any(y <= 0)
            error('Cycle model returned invalid or nonphysical values at this design point.');
        end
    end

    function yFixed = fixedOutputs(yRaw)
        yFixed = [yRaw(:,idx.ST), ...
                  yRaw(:,idx.TSFC), ...
                  yRaw(:,idx.eta0), ...
                  yRaw(:,idx.etaT), ...
                  yRaw(:,idx.etaP), ...
                  yRaw(:,idx.f)];
    end

    function C = makeResultCell(caseName,x,y)
        C = {caseName, ...
             roundTo(x(1),3), roundTo(x(2),3), roundTo(x(3),3), ...
             roundTo(x(4),3), roundTo(x(5),1), ...
             roundTo(y(1),3), roundTo(y(2),3), ...
             roundTo(y(3),4), roundTo(y(4),4), roundTo(y(5),4), roundTo(y(6),5)};
    end

    function C = makeComparisonCell(yAI,yCycle)
        absErr = yAI - yCycle;
        pctErr = percentError(yAI,yCycle);

        labels = {'Specific thrust ST'; ...
                  'TSFC'; ...
                  'Overall efficiency eta0'; ...
                  'Thermal efficiency etaT'; ...
                  'Propulsive efficiency etaP'; ...
                  'Fuel-air ratio f'};

        C = cell(numel(labels),5);

        for k = 1:numel(labels)
            C{k,1} = labels{k};
            C{k,2} = roundTo(yAI(k),5);
            C{k,3} = roundTo(yCycle(k),5);
            C{k,4} = roundTo(absErr(k),5);
            C{k,5} = roundTo(pctErr(k),3);
        end
    end

    function pct = percentError(yAI,yCycle)
        pct = 100*(yAI - yCycle)./yCycle;
    end

    function [metricIdx,metricLabelText] = selectedMetricIndex()
        switch metricDrop.Value
            case 'Overall Efficiency'
                metricIdx = idx.eta0;
                metricLabelText = 'overall efficiency eta0';

            case 'TSFC'
                metricIdx = idx.TSFC;
                metricLabelText = 'TSFC';

            case 'Specific Thrust'
                metricIdx = idx.ST;
                metricLabelText = 'specific thrust';

            case 'Propulsive Efficiency'
                metricIdx = idx.etaP;
                metricLabelText = 'propulsive efficiency etaP';

            case 'Thermal Efficiency'
                metricIdx = idx.etaT;
                metricLabelText = 'thermal efficiency etaT';
        end
    end

    function val = roundTo(x,n)
        p = 10^n;
        val = round(x*p)/p;
    end

end

%% Local helper functions outside app
function [conditions,gammas,etas] = turbofanDefaults(Ta,pa)

conditions.Ta = Ta;
conditions.pa = pa;
conditions.R_air = 287;
conditions.gamma = 1.4;
conditions.R_products = conditions.R_air;

gammas.d = 1.4;  etas.d = 0.95;
gammas.f = 1.4;  etas.f = 0.82;
gammas.c = 1.4;  etas.c = 0.85;
gammas.b = 1.27; etas.b = 1.0;
gammas.t = 1.32; etas.t = 0.90;
gammas.n = 1.34; etas.n = 1.00;
gammas.nf = 1.4; etas.nf = 0.98;

gammas.a = conditions.gamma;

end

function Phi = makePolyFeatures(Z)

[n,p] = size(Z);

% Constant, linear, and squared terms
Phi = [ones(n,1), Z, Z.^2];

% Pairwise interaction terms
for i = 1:p
    for j = i+1:p
        Phi = [Phi, Z(:,i).*Z(:,j)]; %#ok<AGROW>
    end
end

end

function idx = getOutputIndices(outputNames)

idx.ST = find(strcmp(outputNames,'ST'),1);
idx.TSFC = find(strcmp(outputNames,'TSFC_mg_per_Ns'),1);
idx.eta0 = find(strcmp(outputNames,'eta0'),1);
idx.etaT = find(strcmp(outputNames,'etaT'),1);
idx.etaP = find(strcmp(outputNames,'etaP'),1);
idx.f = find(strcmp(outputNames,'f'),1);

values = {idx.ST,idx.TSFC,idx.eta0,idx.etaT,idx.etaP,idx.f};

if any(cellfun(@isempty,values))
    error('Output names in model file do not match expected names.');
end

end

function paretoMask = findParetoFront(eta0,TSFC)
% Pareto rule:
% A design is dominated if another design has:
%   eta0 >= current eta0
%   TSFC <= current TSFC
% and is strictly better in at least one of those.

n = numel(eta0);
paretoMask = true(n,1);

for i = 1:n
    if ~paretoMask(i)
        continue
    end

    dominatedByAnother = eta0 >= eta0(i) & TSFC <= TSFC(i) & ...
                         (eta0 > eta0(i) | TSFC < TSFC(i));

    if any(dominatedByAnother)
        paretoMask(i) = false;
    end
end

end