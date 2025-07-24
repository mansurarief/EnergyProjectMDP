# This file is part of the EnergyMDP.jl package
# The cities and parameters are based on Claude (AI) generated data

@with_kw mutable struct City
    # City properties
    name::String
    demand::Float64
    re_supply::Float64
    nre_supply::Float64
    population::Float64
    income::Bool
end

@with_kw struct State 
    b::Float64
    total_demand::Float64
    cities::Vector{City}
end

@with_kw struct newAction
    energyType::Bool #0 is RE, 1 is NRE
    actionType::Bool  #0 is remove, 1 is add
    cityIndex::Int64 # Index of the city to apply the action
end

@with_kw struct doNothing
    energyType::Int64 = -1
    actionType::Int64 = -1
    cityIndex::Int64 = -1
end

const Action = Union{newAction, doNothing}


# Examples of cities with their energy profiles

atlanta = City(
    name="Atlanta",
    demand=16.7,        # 16.7 billion kWh annually
    re_supply=0.0,      # 2.0 GW renewable (solar + wind, conservative estimate for metro area)
    nre_supply=10.0,    # 14.7 GW non-renewable (natural gas, coal, nuclear)
    population=500_000, # City proper population
    income=1            # High income (median $81,938)
)

nyc = City(
    name="New York City",
    demand=55.7,        # 55.7 billion kWh annually
    re_supply=6.0,     # ~30% of total capacity from renewables
    nre_supply=36.0,    # ~70% from natural gas, some nuclear
    population=8_300_000, # City population
    income=1           # Medium income (metro average, high inequality)
)

houston = City(
    name="Houston",
    demand=28.6,        # 28.6 billion kWh annually  
    re_supply=2.6,      # ~30% renewable capacity (Texas has strong wind/solar)
    nre_supply=10.0,    # ~70% natural gas and some coal
    population=2_300_000, # City population
    income=1           # Medium income (median $62,894)
)

phoenix = City(
    name="Phoenix",
    demand=24.8,        # 24.8 billion kWh annually
    re_supply=0.4,      # ~30% renewable (strong solar potential)
    nre_supply=10.4,    # ~70% natural gas
    population=1_700_000, # City population  
    income=0           # Medium income
)

denver = City(
    name="Denver",
    demand=13.1,        # 13.1 billion kWh annually
    re_supply=0.2,      # ~40% renewable (Colorado has good wind/solar policies)
    nre_supply=9.9,     # ~60% natural gas
    population=715_000, # City population
    income=1           # High income
)

memphis = City(
    name="Memphis",
    demand=13.9,        # 13.9 billion kWh annually
    re_supply=0.0,      # ~20% renewable (hydro, some solar)
    nre_supply=11.1,    # ~80% coal, natural gas, nuclear
    population=633_000, # City population
    income=0           # Low income (below national average)
)

seattle = City(
    name="Seattle",
    demand=13.5,        # 13.5 billion kWh annually
    re_supply=6.2,     # ~90% renewable (mostly hydro, some wind/solar)
    nre_supply=5.3,     # ~10% natural gas
    population=750_000, # City population
    income=1           # High income
)

san_antonio = City(
    name="San Antonio",
    demand=23.1,        # 23.1 billion kWh annually
    re_supply=0.9,      # ~30% renewable (solar, wind)
    nre_supply=6.2,    # ~70% natural gas, some coal
    population=1_500_000, # City population
    income=0           # Medium income
)

cities = [atlanta, nyc, houston, phoenix, denver, memphis, seattle, san_antonio]

# Semi-Realistic EnergyMDP Parameters Based on 2024 Market Data
# All costs in millions of dollars per GW unless otherwise specified

cities = [atlanta, nyc, houston, phoenix, denver, memphis, seattle, san_antonio]

@with_kw mutable struct EnergyMDP <: MDP{State, Action}
    # MDP properties
    cities::Vector{City} = cities
    numberOfCities::Int64 = length(cities)
    
    # === CAPITAL COSTS (Construction/Installation) ===
    # Based on 2024 EIA and industry data
    costOfAddingRE::Float64 = 180.0        # $1,588/kW = $1.588B/GW (average solar+wind)
    costOfAddingNRE::Float64 = 120.0        # $820/kW = $0.82B/GW (natural gas combined cycle)
    
    # Decommissioning costs (removing capacity)
    costOfRemovingRE::Float64 = 120.0       # ~10% of construction cost (solar/wind removal)
    costOfRemovingNRE::Float64 = 180.0      # ~20% of construction cost (natural gas cleanup)
    
    # === OPERATING COSTS (per MWh generated) ===
    # Based on IRENA and EIA O&M cost data
    # Order matches cities: [atlanta, nyc, houston, phoenix, denver, memphis, seattle, san_antonio]
    operatingCostRE::Vector{Float64} = [0.010, 0.013, 0.009, 0.008, 0.011, 0.014, 0.009, 0.011]    # $8-14/MWh (wind/solar O&M)
    operatingCostNRE::Vector{Float64} = [0.038, 0.048, 0.035, 0.036, 0.042, 0.045, 0.040, 0.037]   # $35-48/MWh (natural gas including fuel)
    
    # === SUPPLY CONSTRAINTS (GW available for deployment) ===
    # Representing policy/economic limits on new capacity additions per period
    supplyOfRE::Float64 = 10.0             # 100 GW of RE available (reflects supply chain constraints)
    supplyOfNRE::Float64 = 10.0             # 50 GW of NRE available (limited due to climate policies)
    
    # === POLICY OBJECTIVE WEIGHTS ===
    # Based on energy justice and policy literature
    
    # Economic efficiency (budget conservation)
    weightBudget::Float64 = 0.15            # Moderate weight on remaining budget
    
    # Energy justice (primary objective)
    # Research shows energy burden disproportionately affects low-income households
    weightLowIncomeWithoutEnergy::Float64 = -25.0  # High penalty for low-income energy deprivation
    
    # Environmental/decarbonization goals
    weightPopulationWithRE::Float64 = 12.0  # Strong incentive for renewable energy access
    

    # Planning horizon effects
    discountRate::Float64 = 0.95            # 5% social discount rate for long-term planning

    initialBudget::Float64 = 3000.0  # Initial budget in millions of dollars
    
    # Discretization parameters for solving
    budgetDiscretization::Float64 = 100.0   # Discretize budget in steps of $100M
    maxBudget::Float64 = 5000.0             # Maximum budget to consider
    minBudget::Float64 = -500.0             # Minimum budget (can go negative for terminal)
    energyDiscretization::Float64 = 2.0     # Discretize energy supply in steps of 2 GW
    maxEnergyPerCity::Float64 = 100.0       # Maximum energy supply per city
end