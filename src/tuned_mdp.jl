# Tuned MDP configuration for balanced objectives

# Create enhanced MDP with tuned parameters
function create_tuned_mdp()
    # More balanced city configurations for testing equity
    atlanta = City(
        name="Atlanta",
        demand=20.0,        # Standardized demands for fair comparison
        re_supply=2.0,      # Some initial RE
        nre_supply=8.0,     # But mostly NRE initially
        population=600_000,
        income=true         # High income
    )
    
    memphis = City(
        name="Memphis", 
        demand=20.0,        # Same demand as Atlanta for equity testing
        re_supply=1.0,      # Less initial RE (disadvantaged)
        nre_supply=7.0,     # Less initial supply overall
        population=650_000, # Slightly larger population
        income=false        # Low income
    )
    
    phoenix = City(
        name="Phoenix",
        demand=18.0,        # Slightly less demand
        re_supply=0.5,      # Minimal initial RE
        nre_supply=12.0,    # But higher NRE to test dynamics
        population=580_000,
        income=false        # Low income
    )
    
    seattle = City(
        name="Seattle",
        demand=18.0,        # Same as Phoenix
        re_supply=8.0,      # High initial RE (naturally advantaged)
        nre_supply=4.0,     # Lower NRE
        population=620_000,
        income=true         # High income
    )
    
    cities_tuned = [atlanta, memphis, phoenix, seattle]
    
    return EnergyMDP(
        # City configuration
        cities=cities_tuned,
        numberOfCities=4,
        
        # === TUNED COSTS FOR BALANCED OBJECTIVES ===
        # Costs favor RE but not excessively
        costOfAddingRE=150.0,      # Reduced from 180 to encourage RE
        costOfAddingNRE=130.0,     # Increased from 120 to discourage NRE
        costOfRemovingRE=100.0,    # Reduced removal cost for flexibility
        costOfRemovingNRE=160.0,   # Higher removal cost for NRE
        
        # Operating costs to reflect true lifecycle costs
        operatingCostRE=[0.008, 0.010, 0.009, 0.007],     # Lower than original
        operatingCostNRE=[0.045, 0.052, 0.048, 0.044],    # Higher than original
        
        # === SUPPLY PARAMETERS ===
        supplyOfRE=8.0,            # Larger increments for efficiency
        supplyOfNRE=8.0,           # Same increment size
        
        # === TUNED REWARD WEIGHTS ===
        # More balanced weights for multiple objectives
        weightBudget=0.2,                        # Moderate budget weight
        weightLowIncomeWithoutEnergy=-40.0,      # Strong equity penalty
        weightPopulationWithRE=15.0,             # Strong RE incentive
        
        # Budget parameters for longer horizons
        initialBudget=4000.0,      # Higher budget for more strategic decisions
        discountRate=0.92,         # Slightly lower discount for long-term thinking
        
        # Discretization for solving
        budgetDiscretization=250.0,    # Coarser for speed
        maxBudget=5000.0,
        minBudget=-1000.0,             # Allow more debt for strategic choices
        energyDiscretization=4.0,      # Larger increments
        maxEnergyPerCity=80.0          # Higher capacity limits
    )
end

# Alternative MDP with enhanced reward function
function create_enhanced_mdp()
    mdp = create_tuned_mdp()
    # This would use the enhanced_reward function instead of the default
    return mdp
end

# Quick comparison MDP with minimal cities for fast Value Iteration
function create_comparison_mdp()
    # Just 2 cities for quick benchmarking
    city_high = City(name="HighIncome", demand=15.0, re_supply=1.0, nre_supply=6.0, 
                     population=500_000, income=true)
    city_low = City(name="LowIncome", demand=15.0, re_supply=0.5, nre_supply=5.0, 
                    population=500_000, income=false)
    
    return EnergyMDP(
        cities=[city_high, city_low],
        numberOfCities=2,
        costOfAddingRE=140.0,
        costOfAddingNRE=135.0,
        costOfRemovingRE=90.0,
        costOfRemovingNRE=150.0,
        operatingCostRE=[0.008, 0.010],
        operatingCostNRE=[0.045, 0.050],
        supplyOfRE=6.0,
        supplyOfNRE=6.0,
        weightBudget=0.2,
        weightLowIncomeWithoutEnergy=-35.0,
        weightPopulationWithRE=18.0,
        initialBudget=3000.0,
        discountRate=0.93,
        budgetDiscretization=300.0,
        maxBudget=4000.0,
        minBudget=-500.0,
        energyDiscretization=3.0,
        maxEnergyPerCity=60.0
    )
end

export create_tuned_mdp, create_enhanced_mdp, create_comparison_mdp