function performance=turbofan_func(conditions,gammas,etas, Ma,prc,prf,B,T04,QR)
%MATLAB function to compute performance of turbofan engines,
%following the analysis of Hill and Peterson.
%Inputs:
%-conditions: Structure for flight conditions
%conditions.Ma - flight Mach number
%conditions.Ta - flight static temperature (K)
%conditions.pa - flight static pressure (Pa)
%conditions.R_air - gas constant for air (J/kgK)
%conditions.R_products - gas constant for combustion products
%
%-gammas: structure for specific heat ratios throughout the engine
%gammas.a - flight gamma
%gammas.d - diffuser
%gammas.c - compressor
%gammas.b - burner
%gammas.t - turbine
%gammas.n - nozzle
%gammas.nf - fan nozzle


%-etas: structure for component efficiencies, as gammas structure

%prc: compressor pressure ratio, p03/p02
%prf: fan pressure ratio, p02.5/p02
%B: bypass ratio
%T04: burner outlet tempearture (K)
%QR: fuel lower heating value in J/kg
%To follow, all units are base SI

%Outputs
%-performance: Structure for performance
%performance.ST - specific thrust (N/(kg/s))
%performance.TSFC - thrust specific fuel consumption (kg/s)/N
%performance.etaP - propulsion efficiency
%performance.etaT - thermal efficiency
%performance.eta0 - overall efficiency

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%To follow, all units are base SI

%Flight conditions:
Ta=conditions.Ta;
pa=conditions.pa;
gamma_a=gammas.a;
R_air=conditions.R_air;
R_products=conditions.R_products;

ua=Ma*sqrt(gamma_a*R_air*Ta);


%Engine parameters:
%Core:
gamma_d=gammas.d;
eta_d=etas.d;
gamma_c=gammas.c;
eta_c=etas.c;

gamma_b=gammas.b;
eta_b=etas.b;

gamma_t=gammas.t;
eta_t=etas.t;

%fan:
gamma_f=gammas.f;
eta_f=etas.f;
% QR=45E6;

%nozzle:
gamma_n=gammas.n;
eta_n=etas.n;

%fan nozzle:
gamma_nf=gammas.nf;
eta_nf=etas.nf;

%%Turbojet:

%2. Diffuser outlet: (entrance to the compressor)
T02=Ta*(1+(gamma_a-1)/2*Ma.^2);
p02=pa*(1+eta_d*(T02./Ta-1)).^(gamma_d/(gamma_d-1));

%2.5 fan outlet: (this is new - now we have a fan.)
p02p5=p02.*prf;
T02p5=T02.*(1+1./eta_f.*(prf.^((gamma_f-1)/gamma_f)-1));

%3. Compressor outlet: (see all of these are just using pressure ratios and
%the efficiences)
p03=p02.*prc;
T03=T02.*(1+1./eta_c.*(prc.^((gamma_c-1)/gamma_c)-1));

%Burner inlet:
cp_burner=R_products*gamma_b/(gamma_b-1);

%4. Burner outlet:
T04_ratio=T04./T03;
f=(T04_ratio-1)./(eta_b*QR./(cp_burner*T03)-T04_ratio);
p04=p03;

%5. Turbine outlet
cp_t=R_products*gamma_t./(gamma_t-1);
cp_c=R_air*gamma_c./(gamma_c-1);
cp_f=R_air*gamma_f./(gamma_f-1);
% T05=1./(1+f)./cp_t.*((1+f).*T04*cp_t-cp_c.*(T03-T02)-B.*cp_f.*(T02p5-T02));
% (this is a little more accurate then the textbook form)
T05=T04-(T03-T02)-B.*(T02p5-T02); % this is the textbook form 
p05=p04.*(1-1./eta_t.*(1-T05./T04)).^(gamma_t/(gamma_t-1));


%6. Nozzle inlet: (you can put the afterburner here)
T06=T05; %if re-heat, change temperature here, change f to account for fuel mass
p06=p05; %if no afterburner, there will be no pressure loss here. See Chapter 6 for afterburner loss model

%7. Core nozzle exit:
ue=sqrt(2*eta_n.*gamma_n./(gamma_n-1).*R_products.*T06.*(1-(pa./p06).^((gamma_n-1)./gamma_n)));

%Fan nozzle exit:
uef=sqrt(2*eta_nf.*gamma_nf./(gamma_nf-1).*R_air.*T02p5.*(1-(pa./p02p5).^((gamma_nf-1)./gamma_nf)));

performance.ST=(1+f).*ue+B.*uef-(1+B).*ua;
performance.TSFC=f./performance.ST;
performance.etaP=performance.ST.*ua./((1+f).*ue.^2/2+B.*uef.^2/2-(1+B).*ua.^2/2);
performance.etaT=((1+f).*ue.^2/2+B.*uef.^2/2-(1+B)*ua.^2/2)./(f*QR);
performance.eta0=performance.etaP.*performance.etaT;
performance.f = f;