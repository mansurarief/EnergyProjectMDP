#!/usr/bin/env julia


using EnergyProjectMDP
using POMDPs
using POMDPTools
using DiscreteValueIteration
using Random
using Statistics
using Printf
using Plots

# Include academic modules (simplified versions)
include("../src/academic_mdp.jl")

println("="^80)
println("Multi-Objective Energy Policy Optimization using MDPs")
println("="^80)

# Setup
Random.seed!(12345)

# Academic MDP that uses enhanced reward
struct AcademicMDP <: MDP{State, Action}
    base_mdp::EnergyMDP
end

function POMDPs.reward(mdp::AcademicMDP, s::State, a::Action)
    return academic_enhanced_reward(mdp.base_mdp, s, a)
end

# Forward all other functions
POMDPs.states(mdp::AcademicMDP) = states(mdp.base_mdp)
POMDPs.actions(mdp::AcademicMDP) = actions(mdp.base_mdp)
POMDPs.actions(mdp::AcademicMDP, s::State) = actions(mdp.base_mdp, s)
POMDPs.transition(mdp::AcademicMDP, s::State, a::Action) = transition(mdp.base_mdp, s, a)
POMDPs.initialstate(mdp::AcademicMDP) = initialstate(mdp.base_mdp)
POMDPs.isterminal(mdp::AcademicMDP, s::State) = isterminal(mdp.base_mdp, s)
POMDPs.discount(mdp::AcademicMDP) = discount(mdp.base_mdp)
POMDPs.stateindex(mdp::AcademicMDP, s::State) = stateindex(mdp.base_mdp, s)
POMDPs.actionindex(mdp::AcademicMDP, a::Action) = actionindex(mdp.base_mdp, a)

# Create academic MDP
base_mdp = create_academic_mdp()
mdp = AcademicMDP(base_mdp)

println("\\n📊 EXPERIMENTAL SETUP")
println("Cities: $(length(base_mdp.cities))")
for city in base_mdp.cities
    println("  • $(city.name) ($(city.income ? "High" : "Low") income): $(city.demand) TWh")
end
println("Budget: \$$(base_mdp.initialBudget/1000)B")

# Policy evaluation
policies = [
    ("Random", RandomEnergyPolicy(MersenneTwister(1111))),
    ("Greedy RE", GreedyREPolicy()),
    ("Priority-Based", PriorityBasedPolicy(0.4, 0.4, 0.2)),
    ("Smart Sequential", SmartSequentialPolicy(0.75))
]

results = Dict()

println("\\n🔬 POLICY EVALUATION")
for (name, policy) in policies
    print("  • $name: ")
    
    # Simulate
    hr = HistoryRecorder(max_steps=10)
    h = simulate(hr, mdp, policy)
    
    final_state = h[end].s
    total_reward = sum([step.r for step in h])
    
    # Calculate metrics
    total_demand = sum([city.demand for city in final_state.cities])
    total_supply = sum([city.re_supply + city.nre_supply for city in final_state.cities])
    total_re = sum([city.re_supply for city in final_state.cities])
    
    low_income_cities = [city for city in final_state.cities if city.income == false]
    high_income_cities = [city for city in final_state.cities if city.income == true]
    
    low_supply_ratio = mean([min((city.re_supply + city.nre_supply)/city.demand, 1.0) for city in low_income_cities])
    high_supply_ratio = mean([min((city.re_supply + city.nre_supply)/city.demand, 1.0) for city in high_income_cities])
    
    metrics = Dict(
        "total_reward" => total_reward,
        "re_percentage" => total_supply > 0 ? (total_re / total_supply) * 100 : 0.0,
        "supply_ratio" => total_supply / total_demand,
        "equity_score" => 1.0 - abs(low_supply_ratio - high_supply_ratio),
        "budget_used" => base_mdp.initialBudget - final_state.b,
        "low_income_ratio" => low_supply_ratio,
        "high_income_ratio" => high_supply_ratio
    )
    
    results[name] = metrics
    println("✓ (Reward: $(@sprintf("%.0f", total_reward)))")
end

# Solve with Value Iteration
println("\\n  • Optimal (Value Iteration): ")
try
    solver = ValueIterationSolver(max_iterations=100, belres=1e-3, verbose=false)
    optimal_policy = solve(solver, mdp)
    
    hr = HistoryRecorder(max_steps=10)
    h = simulate(hr, mdp, optimal_policy)
    
    final_state = h[end].s
    total_reward = sum([step.r for step in h])
    
    # Calculate metrics for optimal
    total_demand = sum([city.demand for city in final_state.cities])
    total_supply = sum([city.re_supply + city.nre_supply for city in final_state.cities])
    total_re = sum([city.re_supply for city in final_state.cities])
    
    low_income_cities = [city for city in final_state.cities if city.income == false]
    high_income_cities = [city for city in final_state.cities if city.income == true]
    
    low_supply_ratio = mean([min((city.re_supply + city.nre_supply)/city.demand, 1.0) for city in low_income_cities])
    high_supply_ratio = mean([min((city.re_supply + city.nre_supply)/city.demand, 1.0) for city in high_income_cities])
    
    metrics = Dict(
        "total_reward" => total_reward,
        "re_percentage" => total_supply > 0 ? (total_re / total_supply) * 100 : 0.0,
        "supply_ratio" => total_supply / total_demand,
        "equity_score" => 1.0 - abs(low_supply_ratio - high_supply_ratio),
        "budget_used" => base_mdp.initialBudget - final_state.b,
        "low_income_ratio" => low_supply_ratio,
        "high_income_ratio" => high_supply_ratio
    )
    
    results["Optimal"] = metrics
    println("✓ (Reward: $(@sprintf("%.0f", total_reward)))")
catch e
    println("❌ Failed: $e")
end

# Generate results table
println("\\n📋 RESULTS TABLE")
println("="^80)
@printf("%-15s | %8s | %8s | %8s | %8s | %8s\\n", 
        "Policy", "RE (%)", "Equity", "Budget", "Low-Inc", "High-Inc")
println("-"^80)

for (policy_name, metrics) in results
    @printf("%-15s | %8.1f | %8.3f | %8.0f | %8.1f%% | %8.1f%%\\n",
            policy_name,
            metrics["re_percentage"],
            metrics["equity_score"],
            metrics["budget_used"],
            metrics["low_income_ratio"] * 100,
            metrics["high_income_ratio"] * 100)
end

# Save results to CSV format
println("\\n📁 SAVING RESULTS")
open("academic_results.csv", "w") do io
    # Header
    println(io, "Policy,RE_Percentage,Equity_Score,Budget_Used,Low_Income_Ratio,High_Income_Ratio,Total_Reward")
    
    # Data
    for (policy_name, metrics) in results
        println(io, "$(policy_name),$(metrics["re_percentage"]),$(metrics["equity_score"]),$(metrics["budget_used"]),$(metrics["low_income_ratio"]),$(metrics["high_income_ratio"]),$(metrics["total_reward"])")
    end
end

# Create publication plots
println("\\n📈 GENERATING PLOTS")

# Policy comparison plot
policy_names = collect(keys(results))
re_values = [results[p]["re_percentage"] for p in policy_names]
equity_values = [results[p]["equity_score"] for p in policy_names]

p1 = bar(policy_names, re_values, 
         title="Renewable Energy Adoption",
         ylabel="RE Percentage (%)",
         color=:green,
         alpha=0.7,
         rotation=45,
         size=(600, 400))

p2 = bar(policy_names, equity_values,
         title="Energy Equity Achievement",
         ylabel="Equity Score",
         color=:blue,
         alpha=0.7,
         rotation=45,
         size=(600, 400))

# Equity analysis plot
low_inc_values = [results[p]["low_income_ratio"] * 100 for p in policy_names]
high_inc_values = [results[p]["high_income_ratio"] * 100 for p in policy_names]

p3 = plot(policy_names, low_inc_values,
          label="Low-Income Cities",
          marker=:circle,
          linewidth=3,
          title="Energy Equity by Income Group",
          ylabel="Demand Fulfillment (%)",
          rotation=45)
plot!(policy_names, high_inc_values,
      label="High-Income Cities",
      marker=:square,
      linewidth=3)
hline!([100], color=:gray, linestyle=:dash, label="Full Demand")

# Combined figure
combined = plot(p1, p2, p3, layout=(2,2), size=(1000, 700))

# Save plots
savefig(p1, "renewable_energy_comparison.png")
savefig(p2, "equity_comparison.png") 
savefig(p3, "equity_analysis.png")
savefig(combined, "academic_paper_figure.png")

println("✅ Saved plots: renewable_energy_comparison.png, equity_comparison.png, equity_analysis.png, academic_paper_figure.png")

# Key findings
println("\\n🔍 KEY FINDINGS FOR PAPER")
println("="^50)

best_re = argmax(p -> results[p]["re_percentage"], policy_names)
best_equity = argmax(p -> results[p]["equity_score"], policy_names)

println("1. **Renewable Energy**: $best_re achieved $(@sprintf("%.1f", results[best_re]["re_percentage"]))% RE")
println("2. **Energy Equity**: $best_equity achieved $(@sprintf("%.3f", results[best_equity]["equity_score"])) equity score")

if "Optimal" in policy_names && "Random" in policy_names
    opt_re = results["Optimal"]["re_percentage"]
    rand_re = results["Random"]["re_percentage"]
    re_improvement = opt_re - rand_re
    
    opt_equity = results["Optimal"]["equity_score"]
    rand_equity = results["Random"]["equity_score"]
    equity_improvement = opt_equity - rand_equity
    
    println("3. **Optimal vs Random**:")
    println("   - RE improvement: +$(@sprintf("%.1f", re_improvement)) percentage points")
    println("   - Equity improvement: +$(@sprintf("%.3f", equity_improvement))")
end
