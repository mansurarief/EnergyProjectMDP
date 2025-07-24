# Enhanced reward function with better equity metrics and balanced objectives

# Calculate comprehensive metrics for policy evaluation
function calculate_comprehensive_metrics(mdp::EnergyMDP, final_state::State)
    metrics = Dict{String, Float64}()
    
    # Basic energy metrics
    total_demand = sum([city.demand for city in final_state.cities])
    total_supply = sum([city.re_supply + city.nre_supply for city in final_state.cities])
    total_re_supply = sum([city.re_supply for city in final_state.cities])
    total_nre_supply = sum([city.nre_supply for city in final_state.cities])
    
    metrics["total_demand"] = total_demand
    metrics["total_supply"] = total_supply
    metrics["supply_ratio"] = total_supply / total_demand
    metrics["re_ratio"] = total_supply > 0 ? total_re_supply / total_supply : 0.0
    metrics["unmet_demand"] = max(0, total_demand - total_supply)
    
    # Equity metrics - key for your objectives
    low_income_cities = [city for city in final_state.cities if city.income == false]
    high_income_cities = [city for city in final_state.cities if city.income == true]
    
    # Low-income metrics
    if !isempty(low_income_cities)
        low_income_demand = sum([city.demand for city in low_income_cities])
        low_income_supply = sum([city.re_supply + city.nre_supply for city in low_income_cities])
        low_income_re = sum([city.re_supply for city in low_income_cities])
        
        metrics["low_income_supply_ratio"] = low_income_supply / low_income_demand
        metrics["low_income_re_ratio"] = low_income_supply > 0 ? low_income_re / low_income_supply : 0.0
        metrics["low_income_unmet"] = max(0, low_income_demand - low_income_supply)
    else
        metrics["low_income_supply_ratio"] = 1.0
        metrics["low_income_re_ratio"] = 0.0
        metrics["low_income_unmet"] = 0.0
    end
    
    # High-income metrics
    if !isempty(high_income_cities)
        high_income_demand = sum([city.demand for city in high_income_cities])
        high_income_supply = sum([city.re_supply + city.nre_supply for city in high_income_cities])
        high_income_re = sum([city.re_supply for city in high_income_cities])
        
        metrics["high_income_supply_ratio"] = high_income_supply / high_income_demand
        metrics["high_income_re_ratio"] = high_income_supply > 0 ? high_income_re / high_income_supply : 0.0
        metrics["high_income_unmet"] = max(0, high_income_demand - high_income_supply)
    else
        metrics["high_income_supply_ratio"] = 1.0
        metrics["high_income_re_ratio"] = 0.0
        metrics["high_income_unmet"] = 0.0
    end
    
    # EQUITY DISPARITY METRICS - No disparate performance objective
    metrics["supply_disparity"] = abs(metrics["low_income_supply_ratio"] - metrics["high_income_supply_ratio"])
    metrics["re_disparity"] = abs(metrics["low_income_re_ratio"] - metrics["high_income_re_ratio"])
    
    # Equity fairness score (1.0 = perfect equity, 0.0 = maximum disparity)
    metrics["equity_fairness"] = 1.0 - (metrics["supply_disparity"] + 0.5 * metrics["re_disparity"]) / 1.5
    
    # Budget efficiency
    metrics["budget_used"] = mdp.initialBudget - final_state.b
    metrics["budget_efficiency"] = total_supply / max(1.0, metrics["budget_used"])  # GW per $M
    
    # Overall objective score (your three main objectives)
    budget_score = max(0, final_state.b / mdp.initialBudget)  # Remaining budget ratio
    equity_score = metrics["equity_fairness"]
    re_score = metrics["re_ratio"]
    fulfillment_score = min(1.0, metrics["supply_ratio"])
    
    # Balanced composite score
    metrics["composite_score"] = (0.25 * budget_score + 
                                 0.35 * equity_score + 
                                 0.25 * re_score + 
                                 0.15 * fulfillment_score)
    
    return metrics
end

# Enhanced reward function for the MDP
function enhanced_reward(p::EnergyMDP, s::State, a::Action)
    r = 0.0
    
    # 1. Budget conservation (scaled appropriately)
    budget_ratio = s.b / p.initialBudget
    r += budget_ratio * 500.0  # Reward for preserving budget
    
    # 2. Energy fulfillment rewards
    total_demand = sum([city.demand for city in s.cities])
    total_supply = sum([city.re_supply + city.nre_supply for city in s.cities])
    fulfillment_ratio = min(total_supply / total_demand, 1.0)
    r += fulfillment_ratio * 800.0  # Strong reward for meeting demand
    
    # 3. Equity component - no disparity between income groups
    low_income_cities = [city for city in s.cities if city.income == false]
    high_income_cities = [city for city in s.cities if city.income == true]
    
    if !isempty(low_income_cities) && !isempty(high_income_cities)
        # Calculate supply ratios for each group
        low_supply_ratio = sum([min((city.re_supply + city.nre_supply)/city.demand, 1.0) for city in low_income_cities]) / length(low_income_cities)
        high_supply_ratio = sum([min((city.re_supply + city.nre_supply)/city.demand, 1.0) for city in high_income_cities]) / length(high_income_cities)
        
        # Reward equity (small disparity)
        disparity = abs(low_supply_ratio - high_supply_ratio)
        equity_reward = (1.0 - disparity) * 600.0  # Strong reward for equity
        r += equity_reward
        
        # Bonus for ensuring both groups are well-served
        min_service_level = min(low_supply_ratio, high_supply_ratio)
        r += min_service_level * 400.0
    end
    
    # 4. Renewable energy maximization
    total_re = sum([city.re_supply for city in s.cities])
    total_energy = sum([city.re_supply + city.nre_supply for city in s.cities])
    re_ratio = total_energy > 0 ? total_re / total_energy : 0.0
    r += re_ratio * 700.0  # Strong reward for RE
    
    # 5. Population-weighted impact
    total_population = sum([city.population for city in s.cities])
    served_population = sum([city.population * min((city.re_supply + city.nre_supply)/city.demand, 1.0) for city in s.cities])
    population_service_ratio = served_population / total_population
    r += population_service_ratio * 300.0
    
    # 6. Penalty for inefficient resource use
    if total_supply > total_demand * 1.2  # Over 20% excess
        r -= (total_supply - total_demand * 1.2) * 50.0
    end
    
    return r
end