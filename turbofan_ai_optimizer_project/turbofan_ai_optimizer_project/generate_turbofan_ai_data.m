function generate_turbofan_ai_data(nSamples)
% GENERATE_TURBOFAN_AI_DATA
% Creates a supervised-learning dataset from the turbofan cycle model.
%
% Run:
%   generate_turbofan_ai_data
% or:
%   generate_turbofan_ai_data(12000)
%
% Required in the same folder:
%   turbofan_func.m
%
% Outputs:
%   turbofan_ai_dataset.mat
%   turbofan_ai_dataset.csv

if nargin < 1
    nSamples = 8000;
end

clc;
rng(7);

% Inputs for the AI model:
% [Mach, compressor pressure ratio, fan pressure ratio, bypass ratio,
%  turbine/burner exit temperature, ambient temperature, ambient pressure,
%  fuel heating value]
inputNames = {'Ma','prc','prf','B','T04','Ta','pa','QR_MJkg'};

% Ranges chosen to stay mostly in realistic cruise/design-study territory.
% You can widen these later, but very wide ranges create many invalid engines.
lb = [0.65, 15, 1.15,  3.0, 1400, 210,  18000, 43];
ub = [0.88, 45, 1.70, 12.0, 1900, 290, 101325, 47];

nInputs = numel(inputNames);

% Latin hypercube gives better space-filling samples if available.
if exist('lhsdesign','file') == 2
    U = lhsdesign(nSamples,nInputs);
else
    U = rand(nSamples,nInputs);
end

X = lb + U.*(ub-lb);

outputNames = {'ST','TSFC_mg_per_Ns','eta0','etaT','etaP','f'};
Y = NaN(nSamples,numel(outputNames));
valid = false(nSamples,1);

fprintf('Generating %d turbofan cycle samples...\n',nSamples);

for i = 1:nSamples
    Ma      = X(i,1);
    prc     = X(i,2);
    prf     = X(i,3);
    B       = X(i,4);
    T04     = X(i,5);
    Ta      = X(i,6);
    pa      = X(i,7);
    QR_MJkg = X(i,8);
    QR      = QR_MJkg*1e6;

    [conditions,gammas,etas] = turbofanDefaults(Ta,pa);

    try
        perf = turbofan_func(conditions,gammas,etas,Ma,prc,prf,B,T04,QR);

        row = [real(perf.ST), ...
               real(perf.TSFC)*1e6, ...     % convert to mg/(N*s) for easier ML scaling
               real(perf.eta0), ...
               real(perf.etaT), ...
               real(perf.etaP), ...
               real(perf.f)];

        if isGoodOutput(row,perf)
            Y(i,:) = row;
            valid(i) = true;
        end
    catch
        valid(i) = false;
    end

    if mod(i,1000) == 0
        fprintf('  %d/%d complete, valid so far: %d\n',i,nSamples,sum(valid));
    end
end

X = X(valid,:);
Y = Y(valid,:);

dataTable = array2table([X Y], 'VariableNames', [inputNames outputNames]);

save('turbofan_ai_dataset.mat','X','Y','inputNames','outputNames','dataTable','lb','ub');
writetable(dataTable,'turbofan_ai_dataset.csv');

fprintf('\nDone. Valid samples: %d out of %d.\n',size(X,1),nSamples);
fprintf('Saved: turbofan_ai_dataset.mat\n');
fprintf('Saved: turbofan_ai_dataset.csv\n');

% Quick dataset visualization
figure('Name','Turbofan AI Dataset Overview');
tiledlayout(2,2);

nexttile;
scatter(dataTable.prf,dataTable.B,12,dataTable.eta0,'filled');
xlabel('Fan pressure ratio p_{rf}');
ylabel('Bypass ratio B');
title('Training samples colored by \eta_0');
colorbar; grid on;

nexttile;
scatter(dataTable.ST,dataTable.TSFC_mg_per_Ns,12,dataTable.eta0,'filled');
xlabel('Specific thrust [N/(kg/s)]');
ylabel('TSFC [mg/(N*s)]');
title('Thrust vs TSFC');
colorbar; grid on;

nexttile;
histogram(dataTable.eta0,30);
xlabel('Overall efficiency \eta_0');
ylabel('Count');
title('Overall efficiency distribution');
grid on;

nexttile;
histogram(dataTable.ST,30);
xlabel('Specific thrust [N/(kg/s)]');
ylabel('Count');
title('Specific thrust distribution');
grid on;

end

function tf = isGoodOutput(row,perf)
% Reject invalid or nonphysical cycle points.

valsAreReal = abs(imag(perf.ST)) < 1e-8 && ...
              abs(imag(perf.TSFC)) < 1e-8 && ...
              abs(imag(perf.eta0)) < 1e-8 && ...
              abs(imag(perf.etaT)) < 1e-8 && ...
              abs(imag(perf.etaP)) < 1e-8 && ...
              abs(imag(perf.f)) < 1e-8;

finiteVals = all(isfinite(row));
positiveVals = row(1) > 0 && row(2) > 0 && row(3) > 0 && ...
               row(4) > 0 && row(5) > 0 && row(6) > 0;
reasonableEff = row(3) < 1.0 && row(4) < 1.5 && row(5) < 1.5;
reasonableFuel = row(6) < 0.20;

tf = valsAreReal && finiteVals && positiveVals && reasonableEff && reasonableFuel;
end

function [conditions,gammas,etas] = turbofanDefaults(Ta,pa)
% Same component assumptions used in the GUI/cycle study.

conditions.Ta = Ta;          % K
conditions.pa = pa;          % Pa
conditions.R_air = 287;      % J/(kg*K)
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
