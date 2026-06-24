function turbofan_gui
% TURBOFAN_GUI
% Interactive turbofan engine simulator.
%
% Put this file in the same folder as turbofan_func.m, then run:
%   turbofan_gui
%
% Pressure input is in Pa to match your base turbofan code.

close all

% -----------------------------
% Default design/input values
% -----------------------------
default.Ma = 0.85;
default.prc = 96.8856;
default.prf = 1.50;
default.B = 5.00;
default.T04 = 2200;          % K
default.Ta = 225;            % K
default.pa = 22.735E3;       % Pa
default.QR_MJkg = 47;        % MJ/kg
default.mdot_core = 94.8061; % kg/s
default.M_fanface = 0.5;

% Map limits based on original search ranges
map.prf_min = 1.00;
map.prf_max = 2.00;
map.B_min = 5.00;
map.B_max = 25.00;
map.Nprf = 125;
map.NB = 125;

% -----------------------------
% Build GUI
% -----------------------------
fig = uifigure('Name','Turbofan Engine Simulator', ...
    'Position',[100 100 1200 720]);

mainGrid = uigridlayout(fig,[1 2]);
mainGrid.ColumnWidth = {310,'1x'};
mainGrid.RowHeight = {'1x'};

controlPanel = uipanel(mainGrid,'Title','Inputs');
controlPanel.Layout.Row = 1;
controlPanel.Layout.Column = 1;

controlGrid = uigridlayout(controlPanel,[15 2]);
controlGrid.RowHeight = repmat({32},1,15);
controlGrid.ColumnWidth = {145,'1x'};
controlGrid.Padding = [10 10 10 10];

MaField       = addNumberField(1,  'Flight Mach, M_a',          default.Ma,       [0.01 3.00]);
prcField      = addNumberField(2,  'Compressor PR, p_{r_c}',   default.prc,      [1.00 200.00]);
prfField      = addNumberField(3,  'Fan PR, p_{r_f}',          default.prf,      [1.00 2.00]);
BField        = addNumberField(4,  'Bypass ratio, B',           default.B,        [5.00 25.00]);
T04Field      = addNumberField(5,  'Burner exit T_{04} [K]',    default.T04,      [800 3000]);
TaField       = addNumberField(6,  'Ambient T_a [K]',           default.Ta,       [150 330]);
paField       = addNumberField(7,  'Ambient p_a [Pa]',          default.pa,       [1e3 110e3]);
QRField       = addNumberField(8,  'Fuel heating Q_R [MJ/kg]',  default.QR_MJkg,  [20 60]);
mdotField     = addNumberField(9,  'Core mdot [kg/s]',          default.mdot_core,[1 1000]);
MfanField     = addNumberField(10, 'Fan-face Mach',             default.M_fanface,[0.05 0.90]);

metricLabel = uilabel(controlGrid,'Text','Plot metric');
metricLabel.Layout.Row = 11;
metricLabel.Layout.Column = 1;

metricDropDown = uidropdown(controlGrid, ...
    'Items', {'Specific Thrust','TSFC','Overall Efficiency','Propulsion Efficiency','Thermal Efficiency'}, ...
    'Value', 'Overall Efficiency', ...
    'ValueChangedFcn', @(~,~) updateApp());
metricDropDown.Layout.Row = 11;
metricDropDown.Layout.Column = 2;

updateButton = uibutton(controlGrid,'push','Text','Update Plots', ...
    'ButtonPushedFcn', @(~,~) updateApp());
updateButton.Layout.Row = 12;
updateButton.Layout.Column = [1 2];

resetButton = uibutton(controlGrid,'push','Text','Reset Defaults', ...
    'ButtonPushedFcn', @(~,~) resetDefaults());
resetButton.Layout.Row = 13;
resetButton.Layout.Column = [1 2];

noteLabel = uilabel(controlGrid, ...
    'Text', sprintf('Map range: p_rf %.1f-%.1f, B %.0f-%.0f', ...
    map.prf_min,map.prf_max,map.B_min,map.B_max), ...
    'WordWrap','on');
noteLabel.Layout.Row = [14 15];
noteLabel.Layout.Column = [1 2];

rightGrid = uigridlayout(mainGrid,[3 1]);
rightGrid.Layout.Row = 1;
rightGrid.Layout.Column = 2;
rightGrid.RowHeight = {'1x',170,40};
rightGrid.ColumnWidth = {'1x'};

ax = uiaxes(rightGrid);
ax.Layout.Row = 1;
ax.Layout.Column = 1;

outputTable = uitable(rightGrid);
outputTable.Layout.Row = 2;
outputTable.Layout.Column = 1;
outputTable.ColumnName = {'Quantity','Value','Units'};
outputTable.ColumnWidth = {230,130,160};

statusLabel = uilabel(rightGrid,'Text','');
statusLabel.Layout.Row = 3;
statusLabel.Layout.Column = 1;

updateApp();

% -----------------------------
% Nested helper functions
% -----------------------------

    function field = addNumberField(row,labelText,value,limits)
        lab = uilabel(controlGrid,'Text',labelText);
        lab.Layout.Row = row;
        lab.Layout.Column = 1;

        field = uieditfield(controlGrid,'numeric', ...
            'Value', value, ...
            'Limits', limits, ...
            'ValueChangedFcn', @(~,~) updateApp());
        field.Layout.Row = row;
        field.Layout.Column = 2;
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
        mdotField.Value = default.mdot_core;
        MfanField.Value = default.M_fanface;
        metricDropDown.Value = 'Overall Efficiency';
        updateApp();
    end

    function [conditions,gammas,etas,Ma,prc,prf,B,T04,QR,mdot_core,M_fanface] = readInputs()
        Ma = MaField.Value;
        prc = prcField.Value;
        prf = prfField.Value;
        B = BField.Value;
        T04 = T04Field.Value;
        QR = QRField.Value*1e6;
        mdot_core = mdotField.Value;
        M_fanface = MfanField.Value;

        conditions.Ta = TaField.Value;
        conditions.pa = paField.Value;   % Pa
        conditions.R_air = 287;
        conditions.gamma = 1.4;
        conditions.R_products = conditions.R_air;

        gammas.d = 1.4;
        etas.d = 0.95;

        gammas.f = 1.4;
        etas.f = 0.82;

        gammas.c = 1.4;
        etas.c = 0.85;

        gammas.b = 1.27;
        etas.b = 1.0;

        gammas.t = 1.32;
        etas.t = 0.90;

        gammas.n = 1.34;
        etas.n = 1.00;

        gammas.nf = 1.4;
        etas.nf = 0.98;

        gammas.a = conditions.gamma;
    end

    function updateApp()
        try
            [conditions,gammas,etas,Ma,prc,prf_current,B_current,T04,QR,mdot_core,M_fanface] = readInputs();

            prf_vec = linspace(map.prf_min,map.prf_max,map.Nprf);
            B_vec = linspace(map.B_min,map.B_max,map.NB);
            [PRF,Bgrid] = meshgrid(prf_vec,B_vec);

            surfPerf = turbofan_func(conditions,gammas,etas,Ma,prc,PRF,Bgrid,T04,QR);
            surfPerf = cleanPerformance(surfPerf);

            pointPerf = turbofan_func(conditions,gammas,etas,Ma,prc,prf_current,B_current,T04,QR);
            pointPerf = cleanPerformance(pointPerf);

            [Z,zLabel] = chooseMetric(surfPerf);

            cla(ax)
            contourf(ax,PRF,Bgrid,Z,35,'LineStyle','none');
            hold(ax,'on')

            plot(ax,prf_current,B_current,'ko','MarkerFaceColor','w','MarkerSize',8)

            [eta0_max,idx] = max(surfPerf.eta0(:),[],'omitnan');

            if ~isempty(idx) && ~isnan(eta0_max)
                prf_opt = PRF(idx);
                B_opt = Bgrid(idx);
                plot(ax,prf_opt,B_opt,'rp','MarkerFaceColor','r','MarkerSize',12)
            else
                prf_opt = NaN;
                B_opt = NaN;
            end

            hold(ax,'off')
            grid(ax,'on')
            xlabel(ax,'Fan pressure ratio, p_{r_f}')
            ylabel(ax,'Bypass ratio, B')
            title(ax,zLabel)

            cb = colorbar(ax);
            cb.Label.String = zLabel;

            legend(ax,{'Map','Current design','Max \eta_0'},'Location','best')

            [thrust_kN,fanDiameter_m] = fanSizing(pointPerf,conditions,gammas,etas,Ma,B_current,mdot_core,M_fanface);

            outputTable.Data = {
                'Specific thrust',       fmt(pointPerf.ST),          'N/(kg/s)'
                'TSFC',                  fmt(pointPerf.TSFC),        'kg/(N*s)'
                'TSFC',                  fmt(pointPerf.TSFC*1e6),    'mg/(N*s)'
                'Fuel-air ratio, f',     fmt(pointPerf.f),           '-'
                'Overall efficiency',    fmt(pointPerf.eta0),        '-'
                'Thermal efficiency',    fmt(pointPerf.etaT),        '-'
                'Propulsive efficiency', fmt(pointPerf.etaP),        '-'
                'Total thrust',          fmt(thrust_kN),             'kN'
                'Fan diameter',          fmt(fanDiameter_m),         'm'
                'Best p_rf on map',      fmt(prf_opt),               '-'
                'Best B on map',         fmt(B_opt),                 '-'
                'Max eta_0 on map',      fmt(eta0_max),              '-'
                };

            if any(isnan([pointPerf.ST pointPerf.TSFC pointPerf.eta0]))
                statusLabel.Text = 'Current point is outside the valid model region. Try lower B, lower PRC, or higher T04.';
            else
                statusLabel.Text = sprintf('Current design: M = %.2f, PRC = %.2f, PRF = %.3f, B = %.2f, T04 = %.0f K', ...
                    Ma,prc,prf_current,B_current,T04);
            end

            drawnow limitrate

        catch ME
            statusLabel.Text = ['Error: ' ME.message];
        end
    end

    function [Z,zLabel] = chooseMetric(perf)
        switch metricDropDown.Value
            case 'Specific Thrust'
                Z = perf.ST;
                zLabel = 'Specific Thrust [N/(kg/s)]';

            case 'TSFC'
                Z = perf.TSFC*1e6;
                zLabel = 'TSFC [mg/(N*s)]';

            case 'Overall Efficiency'
                Z = perf.eta0;
                zLabel = 'Overall Efficiency, eta_0';

            case 'Propulsion Efficiency'
                Z = perf.etaP;
                zLabel = 'Propulsive Efficiency, eta_P';

            case 'Thermal Efficiency'
                Z = perf.etaT;
                zLabel = 'Thermal Efficiency, eta_T';
        end
    end

    function perf = cleanPerformance(perf)
        tol = 1e-6;
        bad = false(size(perf.ST));

        fields = {'ST','TSFC','eta0','etaT','etaP','f'};

        for k = 1:numel(fields)
            vals = perf.(fields{k});
            bad = bad | abs(imag(vals)) > tol | ~isfinite(real(vals));
        end

        bad = bad | real(perf.ST) <= 0 | real(perf.TSFC) <= 0 | ...
                    real(perf.eta0) <= 0 | real(perf.etaT) <= 0 | real(perf.etaP) <= 0;

        for k = 1:numel(fields)
            vals = real(perf.(fields{k}));
            vals(bad) = NaN;
            perf.(fields{k}) = vals;
        end
    end

    function [thrust_kN,D_fan] = fanSizing(perf,conditions,gammas,etas,Ma,B,mdot_core,M_fanface)
        if isnan(perf.ST)
            thrust_kN = NaN;
            D_fan = NaN;
            return
        end

        thrust_kN = perf.ST*mdot_core/1000;

        gamma_a = gammas.a;
        gamma_d = gammas.d;
        eta_d = etas.d;
        R_air = conditions.R_air;
        Ta = conditions.Ta;
        pa = conditions.pa;

        T02 = Ta*(1 + (gamma_a - 1)/2*Ma^2);
        p02 = pa*(1 + eta_d*(T02/Ta - 1))^(gamma_d/(gamma_d - 1));

        T2 = T02/(1 + (gamma_a - 1)/2*M_fanface^2);
        p2 = p02/(1 + (gamma_a - 1)/2*M_fanface^2)^(gamma_a/(gamma_a - 1));

        rho2 = p2/(R_air*T2);
        u2 = M_fanface*sqrt(gamma_a*R_air*T2);

        mdot_fan = (1 + B)*mdot_core;
        A_fan = mdot_fan/(rho2*u2);
        D_fan = sqrt(4*A_fan/pi);
    end

    function out = fmt(x)
        if isempty(x) || ~isfinite(x) || isnan(x)
            out = 'Invalid';
        elseif abs(x) >= 100
            out = sprintf('%.3f',x);
        elseif abs(x) >= 1
            out = sprintf('%.4f',x);
        else
            out = sprintf('%.6g',x);
        end
    end

end