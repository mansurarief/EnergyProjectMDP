# Enhanced MDP implementation that uses the improved reward function

# Enhanced EnergyMDP that uses the comprehensive reward function
struct EnhancedEnergyMDP <: MDP{State, Action}
    base_mdp::EnergyMDP
    use_enhanced_reward::Bool
end

# Constructor that defaults to using enhanced reward
function EnhancedEnergyMDP(;
    cities = [
        City(name="HighIncome", demand=15.0, re_supply=1.0, nre_supply=6.0, 
             population=500_000, income=true),
        City(name="LowIncome", demand=15.0, re_supply=0.5, nre_supply=5.0, 
             population=500_000, income=false)
    ],
    numberOfCities = length(cities),
    costOfAddingRE = 140.0,
    costOfAddingNRE = 135.0,
    costOfRemovingRE = 90.0,
    costOfRemovingNRE = 150.0,
    operatingCostRE = fill(0.009, numberOfCities),
    operatingCostNRE = fill(0.047, numberOfCities),
    supplyOfRE = 6.0,
    supplyOfNRE = 6.0,
    weightBudget = 0.2,
    weightLowIncomeWithoutEnergy = -35.0,
    weightPopulationWithRE = 18.0,
    initialBudget = 3000.0,
    discountRate = 0.93,
    budgetDiscretization = 300.0,
    maxBudget = 4000.0,
    minBudget = -500.0,
    energyDiscretization = 3.0,
    maxEnergyPerCity = 60.0,
    use_enhanced_reward = true
)
    base = EnergyMDP(
        cities=cities,
        numberOfCities=numberOfCities,
        costOfAddingRE=costOfAddingRE,
        costOfAddingNRE=costOfAddingNRE,
        costOfRemovingRE=costOfRemovingRE,
        costOfRemovingNRE=costOfRemovingNRE,
        operatingCostRE=operatingCostRE,
        operatingCostNRE=operatingCostNRE,
        supplyOfRE=supplyOfRE,
        supplyOfNRE=supplyOfNRE,
        weightBudget=weightBudget,
        weightLowIncomeWithoutEnergy=weightLowIncomeWithoutEnergy,
        weightPopulationWithRE=weightPopulationWithRE,
        initialBudget=initialBudget,
        discountRate=discountRate,
        budgetDiscretization=budgetDiscretization,
        maxBudget=maxBudget,
        minBudget=minBudget,
        energyDiscretization=energyDiscretization,
        maxEnergyPerCity=maxEnergyPerCity
    )
    
    return EnhancedEnergyMDP(base, use_enhanced_reward)
end

# Override reward function to use enhanced reward
function POMDPs.reward(mdp::EnhancedEnergyMDP, s::State, a::Action)
    if mdp.use_enhanced_reward
        return enhanced_reward(mdp.base_mdp, s, a)
    else
        return reward(mdp.base_mdp, s, a)  # Fall back to original
    end
end

# Forward all other POMDPs interface functions to the base MDP
POMDPs.states(mdp::EnhancedEnergyMDP) = states(mdp.base_mdp)
POMDPs.actions(mdp::EnhancedEnergyMDP) = actions(mdp.base_mdp)
POMDPs.actions(mdp::EnhancedEnergyMDP, s::State) = actions(mdp.base_mdp, s)
POMDPs.transition(mdp::EnhancedEnergyMDP, s::State, a::Action) = transition(mdp.base_mdp, s, a)
POMDPs.initialstate(mdp::EnhancedEnergyMDP) = initialstate(mdp.base_mdp)
POMDPs.isterminal(mdp::EnhancedEnergyMDP, s::State) = isterminal(mdp.base_mdp, s)
POMDPs.discount(mdp::EnhancedEnergyMDP) = discount(mdp.base_mdp)
POMDPs.stateindex(mdp::EnhancedEnergyMDP, s::State) = stateindex(mdp.base_mdp, s)
POMDPs.actionindex(mdp::EnhancedEnergyMDP, a::Action) = actionindex(mdp.base_mdp, a)

# Convenience function to create pre-configured enhanced MDP
function create_enhanced_comparison_mdp()
    return EnhancedEnergyMDP(use_enhanced_reward=true)
end

export EnhancedEnergyMDP, create_enhanced_comparison_mdp