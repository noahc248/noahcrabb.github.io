function CubeSat_Attitude_Animated_App
% CubeSat Attitude Control Animated GUI
% Run by typing:
% CubeSat_Attitude_Animated_App

clc; close all;

sim = struct();
sim.playing = false;

%% Main window
fig = uifigure('Name','Animated CubeSat Attitude Control Simulator', ...
    'Position',[75 75 1350 800]);

mainGrid = uigridlayout(fig,[1 2]);
mainGrid.ColumnWidth = {340,'1x'};

%% Controls
controlPanel = uipanel(mainGrid,'Title','Simulation Controls');
controlPanel.Layout.Row = 1;
controlPanel.Layout.Column = 1;

controlGrid = uigridlayout(controlPanel,[23 2]);
controlGrid.RowHeight = repmat({30},1,23);
controlGrid.ColumnWidth = {170,'1x'};
controlGrid.Padding = [10 10 10 10];

%% Default values
defaults.Kp = 0.008;
defaults.Kd = 0.015;
defaults.tauMax = 0.001;
defaults.distAmp = 2e-5;
defaults.simTime = 150;

defaults.I = 0.02;
defaults.theta0 = 25;
defaults.omega0 = 0;

defaults.Jx = 0.020;
defaults.Jy = 0.025;
defaults.Jz = 0.015;
defaults.roll0 = 20;
defaults.pitch0 = -10;
defaults.yaw0 = 15;
defaults.wx0 = 0.5;
defaults.wy0 = -0.3;
defaults.wz0 = 0.2;
defaults.Nmc = 30;

%% Simulation mode dropdown
modeLabel = uilabel(controlGrid,'Text','Simulation mode');
modeLabel.Layout.Row = 1;
modeLabel.Layout.Column = 1;

modeDrop = uidropdown(controlGrid, ...
    'Items',{'1-Axis Animated Model','3-Axis Animated Quaternion Model','Monte Carlo'}, ...
    'Value','1-Axis Animated Model');
modeDrop.Layout.Row = 1;
modeDrop.Layout.Column = 2;

%% Parameter fields
KpField      = addField(2,  'Kp', defaults.Kp);
KdField      = addField(3,  'Kd', defaults.Kd);
tauField     = addField(4,  'Max torque [N*m]', defaults.tauMax);
distField    = addField(5,  'Disturbance amp [N*m]', defaults.distAmp);
timeField    = addField(6,  'Sim time [s]', defaults.simTime);

IField       = addField(7,  '1-axis inertia I', defaults.I);
thetaField   = addField(8,  'Initial angle [deg]', defaults.theta0);
omegaField   = addField(9,  'Initial rate [deg/s]', defaults.omega0);

JxField      = addField(10, 'Jx [kg*m^2]', defaults.Jx);
JyField      = addField(11, 'Jy [kg*m^2]', defaults.Jy);
JzField      = addField(12, 'Jz [kg*m^2]', defaults.Jz);

rollField    = addField(13, 'Initial roll [deg]', defaults.roll0);
pitchField   = addField(14, 'Initial pitch [deg]', defaults.pitch0);
yawField     = addField(15, 'Initial yaw [deg]', defaults.yaw0);

wxField      = addField(16, 'Initial wx [deg/s]', defaults.wx0);
wyField      = addField(17, 'Initial wy [deg/s]', defaults.wy0);
wzField      = addField(18, 'Initial wz [deg/s]', defaults.wz0);

NmcField     = addField(19, 'Monte Carlo runs', defaults.Nmc);

autoBox = uicheckbox(controlGrid,'Text','Auto update after edits','Value',true);
autoBox.Layout.Row = 20;
autoBox.Layout.Column = [1 2];

runButton = uibutton(controlGrid,'push','Text','Run Simulation', ...
    'ButtonPushedFcn', @(~,~) runSimulation());
runButton.Layout.Row = 21;
runButton.Layout.Column = [1 2];

playButton = uibutton(controlGrid,'push','Text','Play Animation', ...
    'ButtonPushedFcn', @(~,~) playAnimation());
playButton.Layout.Row = 22;
playButton.Layout.Column = 1;

stopButton = uibutton(controlGrid,'push','Text','Stop', ...
    'ButtonPushedFcn', @(~,~) stopAnimation());
stopButton.Layout.Row = 22;
stopButton.Layout.Column = 2;

resetButton = uibutton(controlGrid,'push','Text','Reset Defaults', ...
    'ButtonPushedFcn', @(~,~) resetDefaults());
resetButton.Layout.Row = 23;
resetButton.Layout.Column = [1 2];

modeDrop.ValueChangedFcn = @(~,~) maybeRun();

%% Right side: plots and animation
rightGrid = uigridlayout(mainGrid,[3 2]);
rightGrid.Layout.Row = 1;
rightGrid.Layout.Column = 2;
rightGrid.RowHeight = {'1x','1x',70};
rightGrid.ColumnWidth = {'1x','1x'};

ax1 = uiaxes(rightGrid);
ax1.Layout.Row = 1;
ax1.Layout.Column = 1;

ax2 = uiaxes(rightGrid);
ax2.Layout.Row = 1;
ax2.Layout.Column = 2;

ax3 = uiaxes(rightGrid);
ax3.Layout.Row = 2;
ax3.Layout.Column = 1;

ax4 = uiaxes(rightGrid);
ax4.Layout.Row = 2;
ax4.Layout.Column = 2;

sliderPanel = uipanel(rightGrid,'Title','Animation Timeline');
sliderPanel.Layout.Row = 3;
sliderPanel.Layout.Column = [1 2];

sliderGrid = uigridlayout(sliderPanel,[1 2]);
sliderGrid.ColumnWidth = {'1x',160};

timeSlider = uislider(sliderGrid);
timeSlider.Layout.Row = 1;
timeSlider.Layout.Column = 1;
timeSlider.Limits = [0 1];
timeSlider.Value = 0;
timeSlider.Enable = 'off';
timeSlider.ValueChangingFcn = @(~,event) updateFrame(event.Value);
timeSlider.ValueChangedFcn = @(~,event) updateFrame(event.Value);

statusLabel = uilabel(sliderGrid,'Text','');
statusLabel.Layout.Row = 1;
statusLabel.Layout.Column = 2;

runSimulation();

%% UI helper
    function field = addField(row,label,value)
        lab = uilabel(controlGrid,'Text',label);
        lab.Layout.Row = row;
        lab.Layout.Column = 1;

        field = uieditfield(controlGrid,'numeric','Value',value, ...
            'ValueChangedFcn', @(~,~) maybeRun());
        field.Layout.Row = row;
        field.Layout.Column = 2;
    end

    function maybeRun()
        if exist('autoBox','var') && autoBox.Value
            runSimulation();
        end
    end

    function resetDefaults()
        KpField.Value = defaults.Kp;
        KdField.Value = defaults.Kd;
        tauField.Value = defaults.tauMax;
        distField.Value = defaults.distAmp;
        timeField.Value = defaults.simTime;

        IField.Value = defaults.I;
        thetaField.Value = defaults.theta0;
        omegaField.Value = defaults.omega0;

        JxField.Value = defaults.Jx;
        JyField.Value = defaults.Jy;
        JzField.Value = defaults.Jz;

        rollField.Value = defaults.roll0;
        pitchField.Value = defaults.pitch0;
        yawField.Value = defaults.yaw0;

        wxField.Value = defaults.wx0;
        wyField.Value = defaults.wy0;
        wzField.Value = defaults.wz0;

        NmcField.Value = defaults.Nmc;

        modeDrop.Value = '1-Axis Animated Model';
        runSimulation();
    end

%% Main runner
    function runSimulation()
        sim.playing = false;

        cla(ax1); cla(ax2); cla(ax3); cla(ax4);
        statusLabel.Text = '';

        try
            switch modeDrop.Value
                case '1-Axis Animated Model'
                    runOneAxis();

                case '3-Axis Animated Quaternion Model'
                    runThreeAxis();

                case 'Monte Carlo'
                    runMonteCarlo();
            end
        catch ME
            statusLabel.Text = ['Error: ' ME.message];
        end
    end

%% 1-axis model
    function runOneAxis()
        I = IField.Value;
        Kp = KpField.Value;
        Kd = KdField.Value;
        tauMax = tauField.Value;
        distAmp = distField.Value;
        simTime = timeField.Value;

        theta0 = deg2rad(thetaField.Value);
        omega0 = deg2rad(omegaField.Value);

        x0 = [theta0; omega0];
        tspan = linspace(0,simTime,800);

        [t,x] = ode45(@(t,x) oneAxisDynamics(t,x,I,Kp,Kd,tauMax,distAmp), tspan, x0);

        theta = x(:,1);
        omega = x(:,2);

        tauCmd = -Kp*theta - Kd*omega;
        tauActual = saturate(tauCmd,tauMax);
        tauDist = distAmp*sin(0.1*t);

        plot(ax1,t,rad2deg(theta),'LineWidth',2);
        xlabel(ax1,'Time [s]');
        ylabel(ax1,'Angle [deg]');
        title(ax1,'Attitude Angle');
        grid(ax1,'on');

        plot(ax2,t,rad2deg(omega),'LineWidth',2);
        xlabel(ax2,'Time [s]');
        ylabel(ax2,'Angular velocity [deg/s]');
        title(ax2,'Angular Velocity');
        grid(ax2,'on');

        plot(ax3,t,tauCmd,'--','LineWidth',2);
        hold(ax3,'on');
        plot(ax3,t,tauActual,'LineWidth',2);
        hold(ax3,'off');
        xlabel(ax3,'Time [s]');
        ylabel(ax3,'Torque [N*m]');
        title(ax3,'Commanded vs Limited Torque');
        legend(ax3,'Commanded','Actual','Location','best');
        grid(ax3,'on');

        setupOneAxisAnimation(theta(1));

        sim.mode = '1D';
        sim.t = t;
        sim.theta = theta;
        sim.omega = omega;
        sim.tauCmd = tauCmd;
        sim.tauActual = tauActual;
        sim.tauDist = tauDist;

        sim.cursor1 = xline(ax1,t(1),'--');
        sim.cursor2 = xline(ax2,t(1),'--');
        sim.cursor3 = xline(ax3,t(1),'--');

        prepareSlider(t);
        updateFrame(t(1));
    end

    function setupOneAxisAnimation(thetaNow)
        cla(ax4);
        hold(ax4,'on');
        axis(ax4,'equal');
        xlim(ax4,[-1.5 1.5]);
        ylim(ax4,[-1.5 1.5]);
        grid(ax4,'on');
        xlabel(ax4,'X');
        ylabel(ax4,'Y');

        plot(ax4,[0 1.25],[0 0],'k--','LineWidth',1.5);
        text(ax4,1.28,0,'Target');

        sim.cubeX = [-0.45  0.45  0.45 -0.45 -0.45];
        sim.cubeY = [-0.45 -0.45  0.45  0.45 -0.45];

        R = [cos(thetaNow) -sin(thetaNow);
             sin(thetaNow)  cos(thetaNow)];

        rotated = R*[sim.cubeX; sim.cubeY];
        pointer = R*[0 0.8; 0 0];

        sim.cubePatch = patch(ax4,rotated(1,:),rotated(2,:),[0.75 0.85 1], ...
            'FaceAlpha',0.6,'LineWidth',2);
        sim.pointerLine = plot(ax4,pointer(1,:),pointer(2,:),'r','LineWidth',3);

        title(ax4,'Animated CubeSat Rotation');
        hold(ax4,'off');
    end

%% 3-axis quaternion model
    function runThreeAxis()
        Kp = KpField.Value;
        Kd = KdField.Value;
        tauMax = tauField.Value;
        distAmp = distField.Value;
        simTime = timeField.Value;

        J = diag([JxField.Value, JyField.Value, JzField.Value]);

        roll0 = deg2rad(rollField.Value);
        pitch0 = deg2rad(pitchField.Value);
        yaw0 = deg2rad(yawField.Value);

        q0 = eulerToQuat(roll0,pitch0,yaw0);
        w0 = deg2rad([wxField.Value; wyField.Value; wzField.Value]);

        x0 = [q0; w0];

        tspan = linspace(0,simTime,900);

        [t,x] = ode45(@(t,x) quatDynamics(t,x,J,Kp,Kd,tauMax,distAmp), tspan, x0);

        q = normalizeQuatRows(x(:,1:4));
        w = x(:,5:7);
        attitudeError = 2*acos(abs(q(:,1)));

        torqueHistory = zeros(length(t),3);
        for i = 1:length(t)
            torqueHistory(i,:) = quaternionController(q(i,:)',w(i,:)',Kp,Kd,tauMax)';
        end

        plot(ax1,t,rad2deg(attitudeError),'LineWidth',2);
        xlabel(ax1,'Time [s]');
        ylabel(ax1,'Attitude error [deg]');
        title(ax1,'3-Axis Attitude Error');
        grid(ax1,'on');

        plot(ax2,t,rad2deg(w),'LineWidth',2);
        xlabel(ax2,'Time [s]');
        ylabel(ax2,'Angular velocity [deg/s]');
        title(ax2,'Body Rates');
        legend(ax2,'\omega_x','\omega_y','\omega_z','Location','best');
        grid(ax2,'on');

        plot(ax3,t,torqueHistory,'LineWidth',2);
        xlabel(ax3,'Time [s]');
        ylabel(ax3,'Torque [N*m]');
        title(ax3,'Reaction Wheel Torques');
        legend(ax3,'\tau_x','\tau_y','\tau_z','Location','best');
        grid(ax3,'on');

        setupThreeAxisAnimation(q(1,:)');

        sim.mode = '3D';
        sim.t = t;
        sim.q = q;
        sim.w = w;
        sim.attitudeError = attitudeError;
        sim.torqueHistory = torqueHistory;

        sim.cursor1 = xline(ax1,t(1),'--');
        sim.cursor2 = xline(ax2,t(1),'--');
        sim.cursor3 = xline(ax3,t(1),'--');

        prepareSlider(t);
        updateFrame(t(1));
    end

    function setupThreeAxisAnimation(qNow)
        cla(ax4);
        hold(ax4,'on');
        axis(ax4,'equal');
        grid(ax4,'on');
        view(ax4,3);
        xlabel(ax4,'X');
        ylabel(ax4,'Y');
        zlabel(ax4,'Z');
        xlim(ax4,[-1 1]);
        ylim(ax4,[-1 1]);
        zlim(ax4,[-1 1]);

        sim.V0 = 0.35*[
            -1 -1 -1;
             1 -1 -1;
             1  1 -1;
            -1  1 -1;
            -1 -1  1;
             1 -1  1;
             1  1  1;
            -1  1  1];

        faces = [
            1 2 3 4;
            5 6 7 8;
            1 2 6 5;
            2 3 7 6;
            3 4 8 7;
            4 1 5 8];

        R = quatToDCM(qNow);
        Vrot = (R*sim.V0')';

        sim.cube3D = patch(ax4,'Vertices',Vrot,'Faces',faces, ...
            'FaceColor',[0.75 0.85 1],'FaceAlpha',0.55,'LineWidth',1.5);

        axesLength = 0.75;
        bodyAxes = R*axesLength*eye(3);

        sim.xAxisLine = plot3(ax4,[0 bodyAxes(1,1)],[0 bodyAxes(2,1)],[0 bodyAxes(3,1)],'r','LineWidth',3);
        sim.yAxisLine = plot3(ax4,[0 bodyAxes(1,2)],[0 bodyAxes(2,2)],[0 bodyAxes(3,2)],'g','LineWidth',3);
        sim.zAxisLine = plot3(ax4,[0 bodyAxes(1,3)],[0 bodyAxes(2,3)],[0 bodyAxes(3,3)],'b','LineWidth',3);

        title(ax4,'Animated 3D CubeSat');
        hold(ax4,'off');
    end

%% Monte Carlo
    function runMonteCarlo()
        Kp = KpField.Value;
        Kd = KdField.Value;
        tauMax = tauField.Value;
        distAmp = distField.Value;
        simTime = timeField.Value;
        Nmc = round(NmcField.Value);

        J = diag([JxField.Value, JyField.Value, JzField.Value]);

        tspan = linspace(0,simTime,500);
        finalError = zeros(Nmc,1);
        settlingEstimate = zeros(Nmc,1);

        hold(ax1,'on');

        for k = 1:Nmc
            randomRoll  = deg2rad(-30 + 60*rand);
            randomPitch = deg2rad(-30 + 60*rand);
            randomYaw   = deg2rad(-30 + 60*rand);

            randomQ = eulerToQuat(randomRoll,randomPitch,randomYaw);
            randomW = deg2rad([-1 + 2*rand; -1 + 2*rand; -1 + 2*rand]);

            x0 = [randomQ; randomW];

            [t,x] = ode45(@(t,x) quatDynamics(t,x,J,Kp,Kd,tauMax,distAmp), tspan, x0);

            q = normalizeQuatRows(x(:,1:4));
            err = 2*acos(abs(q(:,1)));

            plot(ax1,t,rad2deg(err),'LineWidth',1);

            finalError(k) = rad2deg(err(end));

            idx = find(rad2deg(err) < 1,1,'first');
            if isempty(idx)
                settlingEstimate(k) = NaN;
            else
                settlingEstimate(k) = t(idx);
            end
        end

        hold(ax1,'off');
        xlabel(ax1,'Time [s]');
        ylabel(ax1,'Attitude error [deg]');
        title(ax1,'Monte Carlo Attitude Error');
        grid(ax1,'on');

        histogram(ax2,finalError,10);
        xlabel(ax2,'Final attitude error [deg]');
        ylabel(ax2,'Runs');
        title(ax2,'Final Pointing Error');
        grid(ax2,'on');

        histogram(ax3,settlingEstimate,10);
        xlabel(ax3,'Settling time [s]');
        ylabel(ax3,'Runs');
        title(ax3,'Settling Time Distribution');
        grid(ax3,'on');

        bar(ax4,[mean(finalError,'omitnan'), max(finalError), mean(settlingEstimate,'omitnan')]);
        ax4.XTickLabel = {'Mean error','Max error','Mean settle'};
        ylabel(ax4,'Value');
        title(ax4,'Monte Carlo Summary');
        grid(ax4,'on');

        sim.mode = 'MC';
        sim.t = [];
        timeSlider.Enable = 'off';
        statusLabel.Text = 'Monte Carlo complete';
    end

%% Slider and animation functions
    function prepareSlider(t)
        timeSlider.Enable = 'on';
        timeSlider.Limits = [t(1) t(end)];
        timeSlider.Value = t(1);
        timeSlider.MajorTicks = linspace(t(1),t(end),6);
        statusLabel.Text = sprintf('t = %.1f s',t(1));
    end

    function updateFrame(tNow)
        if ~isfield(sim,'t') || isempty(sim.t)
            return
        end

        [~,idx] = min(abs(sim.t - tNow));
        tCurrent = sim.t(idx);

        statusLabel.Text = sprintf('t = %.1f s',tCurrent);

        if isfield(sim,'cursor1') && isvalid(sim.cursor1)
            sim.cursor1.Value = tCurrent;
        end
        if isfield(sim,'cursor2') && isvalid(sim.cursor2)
            sim.cursor2.Value = tCurrent;
        end
        if isfield(sim,'cursor3') && isvalid(sim.cursor3)
            sim.cursor3.Value = tCurrent;
        end

        switch sim.mode
            case '1D'
                thetaNow = sim.theta(idx);

                R = [cos(thetaNow) -sin(thetaNow);
                     sin(thetaNow)  cos(thetaNow)];

                rotated = R*[sim.cubeX; sim.cubeY];
                pointer = R*[0 0.8; 0 0];

                set(sim.cubePatch,'XData',rotated(1,:),'YData',rotated(2,:));
                set(sim.pointerLine,'XData',pointer(1,:),'YData',pointer(2,:));

                title(ax4,sprintf('Animated CubeSat | t = %.1f s | theta = %.2f deg', ...
                    tCurrent,rad2deg(thetaNow)));

            case '3D'
                qNow = sim.q(idx,:)';
                R = quatToDCM(qNow);

                Vrot = (R*sim.V0')';
                set(sim.cube3D,'Vertices',Vrot);

                axesLength = 0.75;
                bodyAxes = R*axesLength*eye(3);

                set(sim.xAxisLine,'XData',[0 bodyAxes(1,1)],'YData',[0 bodyAxes(2,1)],'ZData',[0 bodyAxes(3,1)]);
                set(sim.yAxisLine,'XData',[0 bodyAxes(1,2)],'YData',[0 bodyAxes(2,2)],'ZData',[0 bodyAxes(3,2)]);
                set(sim.zAxisLine,'XData',[0 bodyAxes(1,3)],'YData',[0 bodyAxes(2,3)],'ZData',[0 bodyAxes(3,3)]);

                title(ax4,sprintf('Animated 3D CubeSat | t = %.1f s | Error = %.2f deg', ...
                    tCurrent,rad2deg(sim.attitudeError(idx))));
        end

        drawnow limitrate
    end

    function playAnimation()
        if ~isfield(sim,'t') || isempty(sim.t)
            return
        end

        sim.playing = true;
        playButton.Text = 'Playing...';

        [~,startIdx] = min(abs(sim.t - timeSlider.Value));
        step = max(1,round(length(sim.t)/250));

        for i = startIdx:step:length(sim.t)
            if ~sim.playing
                break
            end

            timeSlider.Value = sim.t(i);
            updateFrame(sim.t(i));

            pause(0.02);
            drawnow limitrate
        end

        sim.playing = false;
        playButton.Text = 'Play Animation';
    end

    function stopAnimation()
        sim.playing = false;
        playButton.Text = 'Play Animation';
    end

end

%% Local dynamics functions

function dxdt = oneAxisDynamics(t,x,I,Kp,Kd,tauMax,distAmp)

theta = x(1);
omega = x(2);

tauCmd = -Kp*theta - Kd*omega;
tauControl = saturate(tauCmd,tauMax);

tauDisturbance = distAmp*sin(0.1*t);

thetaDot = omega;
omegaDot = (tauControl + tauDisturbance)/I;

dxdt = [thetaDot; omegaDot];

end

function dxdt = quatDynamics(t,x,J,Kp,Kd,tauMax,distAmp)

q = x(1:4);
w = x(5:7);

q = q/norm(q);

tauControl = quaternionController(q,w,Kp,Kd,tauMax);

tauDisturbance = distAmp * [
    sin(0.05*t);
   -0.5;
    cos(0.03*t)
];

tauTotal = tauControl + tauDisturbance;

wDot = J \ (tauTotal - cross(w,J*w));

qDot = 0.5 * quatOmega(w) * q;

dxdt = [qDot; wDot];

end

function tau = quaternionController(q,w,Kp,Kd,tauMax)

q = q/norm(q);

if q(1) < 0
    q = -q;
end

qVec = q(2:4);

tauCmd = -Kp*qVec - Kd*w;

tau = max(min(tauCmd,tauMax),-tauMax);

end

function Omega = quatOmega(w)

wx = w(1);
wy = w(2);
wz = w(3);

Omega = [
     0  -wx  -wy  -wz;
    wx    0   wz  -wy;
    wy  -wz    0   wx;
    wz   wy  -wx    0
];

end

function q = eulerToQuat(roll,pitch,yaw)

cr = cos(roll/2);
sr = sin(roll/2);

cp = cos(pitch/2);
sp = sin(pitch/2);

cy = cos(yaw/2);
sy = sin(yaw/2);

q0 = cr*cp*cy + sr*sp*sy;
q1 = sr*cp*cy - cr*sp*sy;
q2 = cr*sp*cy + sr*cp*sy;
q3 = cr*cp*sy - sr*sp*cy;

q = [q0; q1; q2; q3];
q = q/norm(q);

end

function qNorm = normalizeQuatRows(q)

qNorm = zeros(size(q));

for i = 1:size(q,1)
    qNorm(i,:) = q(i,:)/norm(q(i,:));
end

end

function y = saturate(x,limit)

y = max(min(x,limit),-limit);

end

function R = quatToDCM(q)

q = q/norm(q);

q0 = q(1);
q1 = q(2);
q2 = q(3);
q3 = q(4);

R = [
    1 - 2*(q2^2 + q3^2),     2*(q1*q2 - q0*q3),     2*(q1*q3 + q0*q2);
        2*(q1*q2 + q0*q3), 1 - 2*(q1^2 + q3^2),     2*(q2*q3 - q0*q1);
        2*(q1*q3 - q0*q2),     2*(q2*q3 + q0*q1), 1 - 2*(q1^2 + q2^2)
];

end