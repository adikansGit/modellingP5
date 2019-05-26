/*---------------------------------------------------------------------------------------------------------------------------------------
Course: Modelling and optimisation of energy systems course spring semester 2019
EPFL Campus energ system optimization
IPESE, EPFL
---------------------------------------------------------------------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------------------------------------------------------------------
This is a model which will be the base of the project. It has the definition of the generic sets, parameters and variables. It also
includes equations that apply to the whole system. Depending on the modifications and additions to the model, the constraints are 
subject to change.
---------------------------------------------------------------------------------------------------------------------------------------*/

/*---------------------------------------------------------------------------------------------------------------------------------------
Generic Sets
---------------------------------------------------------------------------------------------------------------------------------------*/
set Buildings default {};										# set of buildings

set MediumTempBuildings default {};								# set of buildings heated by medium temperature loop
set LowTempBuildings default {};								# set of buildings heated by low temperature loop

set Time default {}; 											# time segments of the problem 
set Technologies default {};									# technologies to provide heating cooling and elec
set Grids default {};											# grid units to buy resources (fuel, electricity etc.)
set Utilities := Technologies union Grids;						# combination of technologies and grids
set Layers default {};											# resources to provide fuel, elec, etc.
set HeatingLevel default {};									# low and medium temlerature levels
set UtilityType default {};										# type of the utility: heating, cooling, elec	
set UtilitiesOfType{UtilityType} default {};					# utilities assigned to their respective utility type
set UtilitiesOfLayer{Layers} default {};

/*---------------------------------------------------------------------------------------------------------------------------------------
Generic Parameters
---------------------------------------------------------------------------------------------------------------------------------------*/
param dTmin default 5;											# minimum temperature difference in the heat exchangers
param top{Time};												# operating time [h] of each time step
param Theating{HeatingLevel};									# temperatue [C] of the heating levels
param irradiation{Time};										# solar irradiation [kW/m2] at each time step
param roofArea default 15500;									# available roof area for PV installation
param refSize default 1000;									    # reference size of the utilities [kW]
param Text{t in Time};  
param Tint default 21;											# internal set point temperature [C]
param specElec{Buildings,Time} default 0;
# param eps_cap default 1;
# param eps_op default 0;
# param eps_co2 default 0;
param pareto_limit := 15000;									# For obtaining points on the pareto curve
param n_years default 20;											# yrs to pay the full price
param i_rate default 0.06;											# interest rate
param tau := i_rate*(1+i_rate)^n_years/(((1+i_rate)^n_years)-1);	# factor to multiply with the total investment cost to obtain annual cost
param Treturn;

/*---------------------------------------------------------------------------------------------------------------------------------------
Calculation of heating demand
---------------------------------------------------------------------------------------------------------------------------------------*/
param FloorArea{Buildings} default 0;
param k_th{Buildings} default 0;								# thermal losses and ventilation coefficient in (kW/m2/K)
param k_sun{Buildings} default 0;								# solar radiation coefficient [−]
param share_q_e default 0.8; 									# share of internal gains from electricity [-]
param specQ_people{Buildings} default 0;						# specific average internal gains from people [kW/m2]
param Qheating{b in Buildings, t in Time} :=
		if Text[t] < 16  then 
			max(FloorArea[b]*(k_th[b]*(Tint-Text[t]) - k_sun[b]*irradiation[t]-specQ_people[b] - share_q_e*specElec[b,t]),0)
		else
			0
;
param Qheatingdemand{h in HeatingLevel, t in Time} :=
	if h == 'MediumT' then
		sum{b in MediumTempBuildings} Qheating[b,t]
	else
		sum{b in LowTempBuildings} Qheating[b,t]
	;

/*---------------------------------------------------------------------------------------------------------------------------------------
Calculation of electricity demand
---------------------------------------------------------------------------------------------------------------------------------------*/

param Ebuilding{b in Buildings, t in Time} :=
	specElec[b,t] * FloorArea[b];
param Edemand{t in Time} :=
	sum{b in Buildings} Ebuilding[b,t];

/*---------------------------------------------------------------------------------------------------------------------------------------
Utility paremeters
---------------------------------------------------------------------------------------------------------------------------------------*/
# minimum temperature of the heating technologies [C]
param Tminheating{UtilitiesOfType['Heating']} default 90;

# reference flow of the heating and cooling [kW]
param Qheatingsupply{UtilitiesOfType['Heating']};

# reference flow of the resources (elec, natgas etc) [kW] [m3/s] [kg/s]
param Flowin{l in Layers,u in UtilitiesOfLayer[l]} default 0;
param Flowout{l in Layers,u in UtilitiesOfLayer[l]} default 0;

# minimum and maximum scaling factors of the utilities
param Fmin{Utilities} default 0.001;
param Fmax{Utilities} default 1000;

# the exergy efficiency of Heat pump, assuming the same before integrating NLP and Vali results. by X.Li
param exergy_eff default 0.55; 
# the lake tempearture (heat source temperature for HPs)
param T_lake default 6;  # degree C

/*---------------------------------------------------------------------------------------------------------------------------------------
Utility variables
---------------------------------------------------------------------------------------------------------------------------------------*/
var use{Utilities} binary;										# binary variable to decide if a utility is used or not
var use_t{Utilities, Time} binary;								# binary variable to decide if a utility is used or not at time t
var mult{Utilities}>=0;											# continuous variable to decide the size of the utility
var mult_t{Utilities, Time}>=0;									# continuous variable to decide the size of the utility at time t

/*---------------------------------------------------------------------------------------------------------------------------------------
Resource variables
---------------------------------------------------------------------------------------------------------------------------------------*/
var FlowInUnit{Layers,Utilities,Time} >= 0;						# continuous variables to decide the size of the resource demand
var FlowOutUnit{Layers,Utilities,Time} >= 0;

/*---------------------------------------------------------------------------------------------------------------------------------------
Utility sizing constraints
---------------------------------------------------------------------------------------------------------------------------------------*/
subject to size_cstr1{u in Utilities, t in Time}: 				# coupling the binary variable with the continuous variable 1
	Fmin[u]*use_t[u,t] <= mult_t[u, t];
subject to size_cstr2{u in Utilities, t in Time}:				# coupling the binary variable with the continuous variable 2
	mult_t[u, t] <= Fmax[u]*use_t[u, t];
subject to size_cstr3{u in Utilities, t in Time}: 				# size in each time should be less than the nominal size
	mult_t[u, t] <= mult[u];
subject to size_cstr4{u in Utilities}:							# coupling the binary variable with the continuous variable 2
	mult[u] <= Fmax[u]*use[u];
subject to size_cstr5{u in Utilities}: 							# coupling the binary variable with the continuous variable
	Fmin[u]*use[u] <= mult[u];
/*---------------------------------------------------------------------------------------------------------------------------------------
Heating balance constraints: demand = supply
---------------------------------------------------------------------------------------------------------------------------------------*/
# heating balance: demand = supply
var mult_heating_t{UtilitiesOfType['Heating'], Time, HeatingLevel} >= 0;
subject to LT_balance{t in Time}:
	Qheatingdemand['LowT',t] = sum{u in UtilitiesOfType['Heating']: Tminheating[u] >= Theating['LowT'] + dTmin} (Qheatingsupply[u] * mult_heating_t[u,t,'LowT']);
subject to MT_balance{t in Time}:
	Qheatingdemand['MediumT',t] = sum{u in UtilitiesOfType['Heating']: Tminheating[u] >= Theating['MediumT'] + dTmin} (Qheatingsupply[u] * mult_heating_t[u,t,'MediumT']);
subject to heaitng_mult_cstr{u in UtilitiesOfType['Heating'], t in Time}:
	mult_t[u,t] = sum{h in HeatingLevel} mult_heating_t[u,t,h];
# the following two constraints are to ensure that one utility will not be used if the supply temperature is less than needed.
subject to zero_constraint1{t in Time}:
	sum{u in UtilitiesOfType['Heating']: Tminheating[u] <= Theating['MediumT'] + dTmin} mult_heating_t[u,t,'MediumT'] = 0;
subject to zero_constraint2{t in Time}:
	sum{u in UtilitiesOfType['Heating']: Tminheating[u] <= Theating['LowT'] + dTmin} mult_heating_t[u,t,'LowT'] = 0;

/*---------------------------------------------------------------------------------------------------------------------------------------
Resource balance constraints (except for electricity): flowin = flowout
---------------------------------------------------------------------------------------------------------------------------------------*/

subject to inflow_cstr {l in Layers, u in UtilitiesOfLayer[l], t in Time}:
	FlowInUnit[l, u, t] = mult_t[u,t] * Flowin[l,u]; 
subject to outflow_cstr {l in Layers, u in UtilitiesOfLayer[l], t in Time}:
	FlowOutUnit[l, u, t] = mult_t[u,t] * Flowout[l,u]; 
subject to balance_cstr {l in Layers, t in Time: l != 'Electricity'}:
	sum{u in UtilitiesOfLayer[l]} FlowInUnit[l,u,t] = sum{u in UtilitiesOfLayer[l]} FlowOutUnit[l,u,t];

/*---------------------------------------------------------------------------------------------------------------------------------------
Electricity balance constraints: building demand + utility cons = utility supply 
---------------------------------------------------------------------------------------------------------------------------------------*/
subject to electricity_balance{t in Time}:
	Edemand[t] + sum{u in UtilitiesOfType['ElectricityCons']} FlowInUnit['Electricity',u,t] = sum{u in UtilitiesOfType['ElectricitySup']} FlowOutUnit['Electricity',u,t];

/*---------------------------------------------------------------------------------------------------------------------------------------
Cost parameters and constraints
---------------------------------------------------------------------------------------------------------------------------------------*/
param c_spec{Grids} default 0;									# specific cost of the resource [CHF/kWh]
param cop2g{g in Grids} = c_spec[g] * refSize;					# mult_t dependent cost of the reosurce [CHF/kWh * refSize]

param cop1t{Technologies} default 0;							# fixed cost of the technology [CHF/h]
param cop2t{Technologies} default 0;							# variable cost of the technology [CHF/h]

param cop1{u in Utilities} = 									# fixed cost of the utility [CHF/h]
	if (exists{g in Grids} (g = u)) then 
		0 
	else 
		cop1t[u]
	;
param cop2{u in Utilities} = 									# variable cost of the utility [CHF/h]
	if (exists{g in Grids} (g = u)) then 
		cop2g[u] 
	else 
		cop2t[u]
	;
param cinv1{t in Technologies} default 0;						# fixed investment cost of the utility [CHF/year]
param cinv2{t in Technologies} default 0;						# variable investment cost of the utility [CHF/year]

param eff{Technologies diff {"Cogen","SOFC"}} default 0.9;		# efficiency of each technology, these values are not definitive ones. 
param c_co2_natgas default 0;									# emission of CO2 per kWh equivalent of natural gas burnt, kg/kWh
param c_co2_elec default 0;										# emission of CO2 per kWh of electricity in the grid generated, kg/kWh 
param co2_spec default 0;										# flat-rate carbon tax per unit emission, CHF/kg

# variable and constraint for operating cost calculation [CHF/year]
var OpCost;
subject to oc_cstr:
	OpCost = sum {u in Grids, t in Time} (cop1[u] * use_t[u,t] + cop2[u] * mult_t[u,t]) * top[t];

# variable and constraint for investment cost calculation [CHF/year]
var InvCost;
subject to ic_cstr:
	InvCost = sum{tc in Technologies} (cinv1[tc] * use[tc] + cinv2[tc] * mult[tc])*tau;

#CO2 emission in kg/year
var emission_cost >= 0;

subject to co2_cstr: 
	emission_cost = sum{t in Time} ((FlowOutUnit['Natgas','NatGasGrid',t]*c_co2_natgas + FlowOutUnit['Electricity','ElecGridBuy',t]*c_co2_elec)*co2_spec*top[t]);

#Constraint on one variable to form a Pareto curve
subject to pareto:
	emission_cost <= pareto_limit;



/*---------------------------------------------------------------------------------------------------------------------------------------
Objective function
---------------------------------------------------------------------------------------------------------------------------------------*/
#minimize ObjectiveFunction: InvCost;
minimize ObjectiveFunction: InvCost;