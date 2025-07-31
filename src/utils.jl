
# Comprehensive policy evaluation with detailed metrics
function evaluate_policy_comprehensive(mdp::EnergyMDP, policy::Policy, n_simulations::Int=50, max_steps::Int=15, rng::AbstractRNG=Random.GLOBAL_RNG)
    all_metrics = []
    
    for i in 1:n_simulations
        # Use seeded RNG for reproducibility
        sim_rng = MersenneTwister(1234 + i)  # Different seed for each simulation
        hr = HistoryRecorder(max_steps=max_steps, rng=sim_rng)
        h = simulate(hr, mdp, policy)
        
        final_state = h[end].s
        total_reward = sum([step.r for step in h])
        
        # Analyze reward components
        reward_components = analyze_reward_trajectory(mdp, h)
        
        # Calculate comprehensive metrics
        metrics = calculate_comprehensive_metrics(mdp, final_state)
        metrics["total_reward"] = total_reward
        metrics["simulation"] = i
        
        # Add reward component metrics
        if !isempty(reward_components)
            for (component, stats) in reward_components
                metrics["$(component)_reward_sum"] = stats["sum"]
                metrics["$(component)_reward_mean"] = stats["mean"]
            end
        end
        
        # Calculate disparity in terms of cities and population
        low_income_cities_unserved = 0
        high_income_cities_unserved = 0
        low_income_pop_unserved = 0.0
        high_income_pop_unserved = 0.0
        
        for city in final_state.cities
            unmet_ratio = max(0, city.demand - (city.re_supply + city.nre_supply)) / city.demand
            if unmet_ratio > 0.1  # Consider city unserved if >10% demand unmet
                if city.income == false  # Low income
                    low_income_cities_unserved += 1
                    low_income_pop_unserved += city.population * unmet_ratio
                else
                    high_income_cities_unserved += 1
                    high_income_pop_unserved += city.population * unmet_ratio
                end
            end
        end
        
        metrics["low_income_cities_unserved"] = low_income_cities_unserved
        metrics["high_income_cities_unserved"] = high_income_cities_unserved
        metrics["low_income_pop_unserved"] = low_income_pop_unserved
        metrics["high_income_pop_unserved"] = high_income_pop_unserved
        
        push!(all_metrics, metrics)
    end
    
    # Aggregate results
    result = Dict{String, Float64}()
    metric_keys = keys(all_metrics[1])
    
    for key in metric_keys
        if key != "simulation"
            values = [m[key] for m in all_metrics]
            result["$(key)_mean"] = mean(values)
            result["$(key)_std"] = std(values)
            result["$(key)_min"] = minimum(values)
            result["$(key)_max"] = maximum(values)
        end
    end
    
    return result
end

# Print detailed policy comparison
function print_policy_comparison(results::Dict{String, Dict{String, Float64}})
    println("="^120)
    println("POLICY EVALUATION - RANKED BY REWARD (30 replications, mean ± std)")
    println("="^120)
    
    # Key metrics to display with mean ± std and directional indicators
    key_metrics = [
        ("total_reward", "Avg Reward ↑", "↑"),           # Higher is better
        ("re_ratio", "RE % ↑", "↑"),                      # Higher is better
        ("budget_used", "Budget Used ↓", "↓"),            # Lower is better (more efficient)
        ("low_income_cities_unserved", "Low-Inc Cities ↓", "↓"),  # Lower is better
        ("high_income_cities_unserved", "High-Inc Cities ↓", "↓"), # Lower is better
        ("low_income_pop_unserved", "Low-Inc Pop (M) ↓", "↓"),    # Lower is better
        ("high_income_pop_unserved", "High-Inc Pop (M) ↓", "↓")   # Lower is better
    ]
    
    # Header with better formatting
    header = @sprintf("%-16s", "Policy")
    for (_, label, _) in key_metrics
        header *= @sprintf(" | %14s", label)
    end
    println(header)
    println("-"^length(header))
    
    # Sort by average reward (descending)
    sorted_policies = sort(collect(results), by=x->x[2]["total_reward_mean"], rev=true)
    
    for (policy_name, metrics) in sorted_policies
        row = @sprintf("%-16s", policy_name)
        for (metric_base, _, direction) in key_metrics
            # Check if metric exists
            mean_key = "$(metric_base)_mean"
            std_key = "$(metric_base)_std"
            
            if !haskey(metrics, mean_key)
                row *= " | " * @sprintf("%14s", "N/A")
                continue
            end
            
            mean_val = metrics[mean_key]
            std_val = haskey(metrics, std_key) ? metrics[std_key] : 0.0
            
            # Special handling for different metrics
            if contains(metric_base, "pop_unserved")
                mean_val = mean_val / 1_000_000
                std_val = std_val / 1_000_000
            end
            
            if contains(metric_base, "ratio")
                mean_val *= 100
                std_val *= 100
            end
            
            # Format based on metric type with appropriate precision
            if metric_base == "total_reward"
                formatted_value = @sprintf("%.0f±%.0f", mean_val, std_val)
            elseif contains(metric_base, "ratio")
                formatted_value = @sprintf("%.1f±%.1f", mean_val, std_val)
            elseif metric_base == "budget_used"
                formatted_value = @sprintf("%.0f±%.0f", mean_val, std_val)
            elseif contains(metric_base, "cities")
                formatted_value = @sprintf("%.1f±%.1f", mean_val, std_val)
            else  # population
                formatted_value = @sprintf("%.2f±%.2f", mean_val, std_val)
            end
            
            row *= " | " * @sprintf("%14s", formatted_value)
        end
        println(row)
    end
    
    println("-"^length(header))
    
    # Legend for arrows
    println("\nLegend: ↑ = higher is better, ↓ = lower is better")
    
    # Summary statistics - only if disparity metrics exist
    if !isempty(sorted_policies) && haskey(sorted_policies[1][2], "low_income_cities_unserved_mean")
        println("\n" * "="^60)
        println("DISPARITY ANALYSIS (Top 3 Policies by Reward)")
        println("="^60)
        
        for (i, (policy_name, metrics)) in enumerate(sorted_policies[1:min(3, length(sorted_policies))])
            low_cities = get(metrics, "low_income_cities_unserved_mean", 0.0)
            high_cities = get(metrics, "high_income_cities_unserved_mean", 0.0)
            low_pop = get(metrics, "low_income_pop_unserved_mean", 0.0) / 1_000_000
            high_pop = get(metrics, "high_income_pop_unserved_mean", 0.0) / 1_000_000
            
            println("#$i. $policy_name:")
            println("    Unserved cities: Low-income = $(@sprintf("%.1f", low_cities)), High-income = $(@sprintf("%.1f", high_cities))")
            println("    Unserved population: Low-income = $(@sprintf("%.1f", low_pop))M, High-income = $(@sprintf("%.1f", high_pop))M")
            println()
        end
    end
end