
# Function to decompose reward components for analysis
function decompose_reward(mdp::EnergyMDP, s::State, a::Action)
    components = Dict{String, Float64}()
    
    # Budget component (only positive budget contributes)
    budget_reward = max(0, s.b) * mdp.weightBudget
    components["budget"] = budget_reward
    
    # Low income population without energy component (penalty)
    populationLowIncomeWithoutEnergy = sum([city.population * (city.income == false && city.re_supply + city.nre_supply < city.demand) for city in s.cities])
    populationLowIncome = sum([city.population * (city.income == false) for city in s.cities])
    percentageLowIncomeWithoutEnergy = populationLowIncomeWithoutEnergy / (populationLowIncome + 1e-6)
    equity_penalty = percentageLowIncomeWithoutEnergy * mdp.weightLowIncomeWithoutEnergy
    components["equity_penalty"] = equity_penalty
    
    # Population with renewable energy component (bonus)
    populationWithRE = sum([city.population * (city.re_supply >= city.demand) for city in s.cities])
    totalPopulation = sum([city.population for city in s.cities])
    percentagePopulationWithRE = populationWithRE / (totalPopulation + 1e-6)
    re_bonus = percentagePopulationWithRE * mdp.weightPopulationWithRE
    components["re_bonus"] = re_bonus
    
    # Total reward
    components["total"] = budget_reward + equity_penalty + re_bonus
    
    return components
end

# Function to analyze reward components across a trajectory
function analyze_reward_trajectory(mdp::EnergyMDP, trajectory)
    all_components = []
    
    for step in trajectory
        if haskey(step, :s) && haskey(step, :a)
            components = decompose_reward(mdp, step.s, step.a)
            push!(all_components, components)
        end
    end
    
    # Aggregate statistics
    if isempty(all_components)
        return Dict{String, Dict{String, Float64}}()
    end
    
    component_stats = Dict{String, Dict{String, Float64}}()
    
    for component in ["budget", "equity_penalty", "re_bonus", "total"]
        values = [comp[component] for comp in all_components]
        component_stats[component] = Dict(
            "mean" => mean(values),
            "std" => std(values),
            "min" => minimum(values),
            "max" => maximum(values),
            "sum" => sum(values)
        )
    end
    
    return component_stats
end