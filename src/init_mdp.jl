function initialize_mdp(rng::AbstractRNG)
    # Define discretized value ranges for randomization
    demand_levels = [15.0, 18.0, 20.0, 22.0, 25.0, 28.0]  # Discretized demand levels
    re_supply_levels = [0.0, 1.0, 2.0, 3.0, 4.0, 6.0, 8.0]  # Discretized RE supply levels
    nre_supply_levels = [4.0, 6.0, 8.0, 10.0, 12.0, 15.0, 18.0, 20.0]  # Discretized NRE supply levels
    population_levels = [500_000, 580_000, 620_000, 650_000, 700_000, 850_000]  # Discretized population levels
    
    # More balanced city configurations with discretized randomness
    atlanta = City(
        name="Atlanta",
        demand=rand(rng, demand_levels),
        re_supply=rand(rng, re_supply_levels[1:4]),  # Lower to mid RE
        nre_supply=rand(rng, nre_supply_levels[3:6]), # Mid to high NRE
        population=rand(rng, population_levels),
        income=true         # High income
    )

    san_francisco = City(
        name="San Francisco",
        demand=rand(rng, demand_levels[4:6]),  # Higher demand levels
        re_supply=rand(rng, re_supply_levels[3:6]),  # Mid to high RE
        nre_supply=rand(rng, nre_supply_levels[5:8]), # High NRE
        population=rand(rng, population_levels[4:6]), # Higher population
        income=true
    )
    
    memphis = City(
        name="Memphis", 
        demand=rand(rng, demand_levels[2:5]),  # Mid-range demand
        re_supply=rand(rng, re_supply_levels[1:3]),  # Low RE (disadvantaged)
        nre_supply=rand(rng, nre_supply_levels[2:5]), # Low to mid NRE
        population=rand(rng, population_levels[2:5]), # Mid-range population
        income=false        # Low income
    )
    
    phoenix = City(
        name="Phoenix",
        demand=rand(rng, demand_levels[1:4]),  # Low to mid demand
        re_supply=rand(rng, re_supply_levels[1:2]),  # Minimal initial RE
        nre_supply=rand(rng, nre_supply_levels[4:7]), # Higher NRE
        population=rand(rng, population_levels[1:4]), # Lower to mid population
        income=false        # Low income
    )
    
    seattle = City(
        name="Seattle",
        demand=rand(rng, demand_levels[1:4]),  # Low to mid demand
        re_supply=rand(rng, re_supply_levels[5:7]),  # High initial RE (naturally advantaged)
        nre_supply=rand(rng, nre_supply_levels[1:3]), # Lower NRE
        population=rand(rng, population_levels[2:5]), # Mid-range population
        income=true         # High income
    )

    detroit = City(
        name="Detroit",
        demand=rand(rng, demand_levels[4:6]),  # Higher demand (industrial city)
        re_supply=rand(rng, re_supply_levels[1:3]),  # Limited renewable infrastructure
        nre_supply=rand(rng, nre_supply_levels[6:8]), # Heavy fossil fuel dependence
        population=rand(rng, population_levels[3:6]), # Mid to high population
        income=false
    )

    
    cities_tuned = [atlanta, memphis, phoenix, seattle, detroit, san_francisco]
    
    return EnergyMDP(
        # City configuration
        cities=cities_tuned,
        numberOfCities=6,
        
        # === COSTS WITH DISCRETIZED RANDOMNESS ===
        costOfAddingRE=rand(rng, [140.0, 150.0, 160.0, 170.0]),     # Randomized RE addition cost
        costOfAddingNRE=rand(rng, [120.0, 130.0, 140.0, 150.0]),    # Randomized NRE addition cost
        costOfRemovingRE=rand(rng, [90.0, 100.0, 110.0, 120.0]),    # Randomized RE removal cost
        costOfRemovingNRE=rand(rng, [150.0, 160.0, 170.0, 180.0]),  # Randomized NRE removal cost
        
        # Operating costs with discretized randomness
        operatingCostRE=[rand(rng, [0.006, 0.008, 0.010, 0.012]) for _ in 1:6],  # Randomized RE costs
        operatingCostNRE=[rand(rng, [0.040, 0.045, 0.050, 0.055]) for _ in 1:6], # Randomized NRE costs
        
        # === SUPPLY PARAMETERS ===
        supplyOfRE=8.0,            # Larger increments for efficiency
        supplyOfNRE=8.0,           # Same increment size
        
        # === TUNED REWARD WEIGHTS ===
        # More balanced weights for multiple objectives
        weightBudget=0.2,                        # Moderate budget weight
        weightLowIncomeWithoutEnergy=-50.0,      # Strong equity penalty
        weightPopulationWithRE=25.0,             # Strong RE incentive
        
       
        
        # Discretization for solving
        budgetDiscretization=250.0,    # Coarser for speed
        maxBudget=1000.0,
        minBudget=0.0,             # Allow more debt for strategic choices
        energyDiscretization=4.0,      # Larger increments
        maxEnergyPerCity=80.0,          # Higher capacity limits

        # Budget parameters for longer horizons with discretized randomness
        initialBudget=rand(rng, [250.0, 500.0, 750.0, 1000.0]),  # Discretized budget levels
        discountRate=rand(rng, [0.90, 0.92, 0.95, 0.97]),  # Discretized discount rates
    )
end