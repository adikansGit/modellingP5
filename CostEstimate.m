clear all, close all;

k1 = 2.2897;
k2 = 1.3604;
k3 = -0.1027;
I_now = 603.1;
I_ref = 397;
Fbm = 1;

hx_k1 = 4.6656;
hx_k2 = -0.1557;
hx_k3 = 0.1547;
hx_Fbm = 2.65;


P = [2000 3000];

Cp = (I_now*10.^(k1 + (k2*log10(P)) + (k3*(log10(P)).^2)))/I_ref;

A = []

Cp_annual = Fbm*Cp;

cinv2 = (Cp_annual(2) - Cp_annual(1))/(P(2) - P(1));
cinv1 = Cp_annual(1) - (cinv2*P(1));

