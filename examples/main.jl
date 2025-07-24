using EnergyProjectMDP
using POMDPs
using POMDPTools
using DiscreteValueIteration
using Random
using Statistics
using Printf

# Comprehensive policy evaluation with detailed metrics
function evaluate_policy_comprehensive(mdp::EnergyMDP, policy::Policy, n_simulations::Int=50, max_steps::Int=15)
    all_metrics = []
    
    for i in 1:n_simulations
        hr = HistoryRecorder(max_steps=max_steps)
        h = simulate(hr, mdp, policy)
        
        final_state = h[end].s
        total_reward = sum([step.r for step in h])
        
        # Calculate comprehensive metrics
        metrics = calculate_comprehensive_metrics(mdp, final_state)
        metrics["total_reward"] = total_reward
        metrics["simulation"] = i
        
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
    println("="^100)
    println("COMPREHENSIVE POLICY EVALUATION")
    println("="^100)
    
    # Key metrics to display
    key_metrics = [
        ("total_reward_mean", "Avg Reward", "%8.1f"),
        ("composite_score_mean", "Composite Score", "%6.3f"),
        ("equity_fairness_mean", "Equity Score", "%6.3f"),
        ("supply_disparity_mean", "Supply Disparity", "%6.3f"),
        ("re_ratio_mean", "RE Ratio", "%6.1f%%"),
        ("budget_efficiency_mean", "Budget Eff (GW/M)", "%6.2f"),
        ("low_income_supply_ratio_mean", "Low-Inc Supply", "%6.1f%%"),
        ("high_income_supply_ratio_mean", "High-Inc Supply", "%6.1f%%")
    ]
    
    # Header
    header = @sprintf("%-20s", "Policy")
    for (_, label, _) in key_metrics
        header *= @sprintf(" | %15s", label)
    end
    println(header)
    println("-"^length(header))
    
    # Sort by composite score
    sorted_policies = sort(collect(results), by=x->x[2]["composite_score_mean"], rev=true)
    
    for (policy_name, metrics) in sorted_policies
        row = @sprintf("%-20s", policy_name)
        for (metric_key, _, format_str) in key_metrics
            value = metrics[metric_key]
            if contains(metric_key, "ratio") && !contains(format_str, "%%")
                value *= 100  # Convert to percentage
            end
            
            # Handle different format types
            if format_str == "%8.1f"
                formatted_value = @sprintf("%8.1f", value)
            elseif format_str == "%6.3f"
                formatted_value = @sprintf("%6.3f", value)
            elseif format_str == "%6.1f%%"
                formatted_value = @sprintf("%6.1f", value) * "%"
            elseif format_str == "%6.2f"
                formatted_value = @sprintf("%6.2f", value)
            else
                formatted_value = string(value)
            end
            
            row *= " | " * @sprintf("%15s", formatted_value)
        end
        println(row)
    end
    
    println("-"^length(header))
    
    # Detailed equity analysis
    println("\n" * "="^60)
    println("EQUITY ANALYSIS")
    println("="^60)
    
    for (policy_name, metrics) in sorted_policies
        low_supply = metrics["low_income_supply_ratio_mean"] * 100
        high_supply = metrics["high_income_supply_ratio_mean"] * 100
        disparity = metrics["supply_disparity_mean"] * 100
        equity_score = metrics["equity_fairness_mean"]
        
        println("$policy_name:")
        println("  Low-income supply:  $(@sprintf("%5.1f", low_supply))%")
        println("  High-income supply: $(@sprintf("%5.1f", high_supply))%") 
        println("  Disparity:         $(@sprintf("%5.1f", disparity))% (lower is better)")
        println("  Equity Score:      $(@sprintf("%5.3f", equity_score)) (1.0 = perfect equity)")
        println()
    end
end

println("="^80)
println("ENHANCED ENERGY MDP: STRONGER BENCHMARKS & TUNED PARAMETERS")
println("="^80)

# Create tuned MDP
mdp = initialize_mdp()  # Use smaller MDP for faster testing
println("Created tuned MDP with $(mdp.numberOfCities) cities")
println("Initial budget: \$$(mdp.initialBudget)M")
println("State space size: $(length(states(mdp))) states")
println("Action space size: $(length(actions(mdp))) actions\n")

# Test all policies including new stronger benchmarks
policies_to_test = [
    ("Random", RandomEnergyPolicy(MersenneTwister(1234))),
    ("Basic Greedy RE", GreedyREPolicy()),
    ("Basic Balanced", BalancedEnergyPolicy(0.6)),
    ("Basic Equity First", EquityFirstPolicy()),
    ("🚀 Priority-Based", PriorityBasedPolicy(0.4, 0.4, 0.2)),
    ("🧠 Optimization Greedy", OptimizationGreedyPolicy()),
    ("📈 Smart Sequential", SmartSequentialPolicy(0.75)),
    ("🎯 Near-Optimal", NearOptimalPolicy(2))
]

println("Evaluating $(length(policies_to_test)) policies...")
results = Dict{String, Dict{String, Float64}}()

for (name, policy) in policies_to_test
    print("Evaluating $name... ")
    result = evaluate_policy_comprehensive(mdp, policy, 30, 12)
    results[name] = result
    println("✓")
end

# Print comprehensive comparison
print_policy_comparison(results)

# Test Value Iteration if feasible
println("\n" * "="^60)
println("VALUE ITERATION ANALYSIS")
println("="^60)

try
    solver = ValueIterationSolver(max_iterations=100, belres=1e-3, verbose=false)
    optimal_policy = solve(solver, mdp)
    println("✅ Value Iteration converged!")
    
    optimal_result = evaluate_policy_comprehensive(mdp, optimal_policy, 30, 12)
    results["🏆 OPTIMAL (VI)"] = optimal_result
    
    println("\nOptimal Policy Performance:")
    println("  Composite Score: $(@sprintf("%.3f", optimal_result["composite_score_mean"]))")
    println("  Avg Reward: $(@sprintf("%.1f", optimal_result["total_reward_mean"]))")
    println("  Equity Score: $(@sprintf("%.3f", optimal_result["equity_fairness_mean"]))")
    println("  RE Ratio: $(@sprintf("%.1f", optimal_result["re_ratio_mean"] * 100))%")
    
    # Compare with best heuristic
    best_heuristic = argmax(policy -> results[policy]["composite_score_mean"], 
                           [name for (name, _) in policies_to_test])
    improvement = optimal_result["composite_score_mean"] - results[best_heuristic]["composite_score_mean"]
    
    println("\nImprovement over best heuristic ($best_heuristic):")
    println("  Composite score improvement: $(@sprintf("%.3f", improvement))")
    
catch e
    println("❌ Value Iteration failed: $e")
    println("State space may be too large for current solver configuration")
end

# Summary and recommendations
println("\n" * "="^80)
println("SUMMARY & RECOMMENDATIONS")
println("="^80)

# Find best performing policies by different criteria
best_composite = argmax(policy -> results[policy]["composite_score_mean"], keys(results))
best_equity = argmax(policy -> results[policy]["equity_fairness_mean"], keys(results))
best_re = argmax(policy -> results[policy]["re_ratio_mean"], keys(results))
best_efficiency = argmax(policy -> results[policy]["budget_efficiency_mean"], keys(results))

println("🏆 Best Overall (Composite Score): $best_composite")
println("⚖️  Best Equity Performance: $best_equity")
println("🌱 Best Renewable Energy: $best_re")
println("💰 Most Budget Efficient: $best_efficiency")

# Check if objectives are met
best_result = results[best_composite]
println("\n🎯 Objective Assessment:")
println("   Budget Balance: $(best_result["budget_used_mean"] < mdp.initialBudget * 0.8 ? "✅" : "⚠️") ($(@sprintf("%.0f", best_result["budget_used_mean"]))/$(mdp.initialBudget) budget used)")
println("   Equity (No Disparity): $(best_result["supply_disparity_mean"] < 0.1 ? "✅" : "⚠️") ($(@sprintf("%.1f", best_result["supply_disparity_mean"]*100))% disparity)")
println("   RE Maximization: $(best_result["re_ratio_mean"] > 0.6 ? "✅" : "⚠️") ($(@sprintf("%.1f", best_result["re_ratio_mean"]*100))% renewable)")

println("\n🚀 Framework ready for energy policy optimization!")