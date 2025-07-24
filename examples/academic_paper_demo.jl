#!/usr/bin/env julia

"""
Academic Paper Demonstration: Multi-Objective Energy Policy Optimization
========================================================================

This script generates all results, tables, and figures for the academic paper on
energy policy optimization using Markov Decision Processes with multi-objective
reward functions balancing budget efficiency, social equity, and environmental sustainability.

Author: EnergyProjectMDP Team
Date: $(Dates.today())
"""

using EnergyProjectMDP
using POMDPs
using POMDPTools
using DiscreteValueIteration
using Random
using Statistics
using Printf
using Dates

# Load academic modules
include("../src/academic_mdp.jl")
include("../src/academic_analysis.jl")  
include("../src/academic_plots.jl")
include("../src/enhanced_reward.jl")

# Academic MDP that uses enhanced reward
struct AcademicMDP <: MDP{State, Action}
    base_mdp::EnergyMDP
end

# Override reward function
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

println("="^80)
println("ACADEMIC PAPER DEMONSTRATION")
println("Multi-Objective Energy Policy Optimization using MDPs")
println("="^80)
println("Generated on: $(now())")
println("Julia Version: $(VERSION)")
println()

# Setup reproducible random seed
Random.seed!(12345)

println("📊 EXPERIMENTAL SETUP")
println("="^50)

# Create academic MDP with realistic parameters
base_mdp = create_academic_mdp()
mdp = AcademicMDP(base_mdp)

println("Cities analyzed: $(length(base_mdp.cities))")
for (i, city) in enumerate(base_mdp.cities)
    println("  $i. $(city.name) ($(city.income ? "High" : "Low") income): $(city.demand) TWh demand")
end

println("\\nPolicy budget: \$$(base_mdp.initialBudget/1000)B")
println("State space size: $(length(states(mdp))) discrete states")
println("Action space size: $(length(actions(mdp))) possible actions")

println("\\n🔬 POLICY EVALUATION")
println("="^50)

# Define policies to evaluate
policies_to_evaluate = [
    ("Random Baseline", RandomEnergyPolicy(MersenneTwister(1111))),
    ("Greedy Renewable", GreedyREPolicy()),
    ("Priority-Based", PriorityBasedPolicy(0.4, 0.4, 0.2)),
    ("Optimization Greedy", OptimizationGreedyPolicy()),
    ("Smart Sequential", SmartSequentialPolicy(0.75))
]

# Store results for analysis
policy_results = Dict{String, Any}()
city_analysis_data = Dict{String, Vector}()

println("Evaluating $(length(policies_to_evaluate)) policy approaches...")

for (policy_name, policy) in policies_to_evaluate
    print("  • $policy_name: ")
    
    # Run multiple simulations for statistical significance
    all_final_states = []
    all_rewards = []
    
    for sim in 1:30  # 30 simulations for statistical robustness
        hr = HistoryRecorder(max_steps=12)
        h = simulate(hr, mdp, policy)
        
        final_state = h[end].s
        total_reward = sum([step.r for step in h])
        
        push!(all_final_states, final_state)
        push!(all_rewards, total_reward)
    end
    
    # Use the median final state for analysis (robust to outliers)
    median_idx = sortperm(all_rewards)[div(length(all_rewards), 2)]
    representative_state = all_final_states[median_idx]
    
    # Calculate comprehensive metrics
    metrics = calculate_academic_metrics(base_mdp, representative_state, policy_name)
    metrics["AvgTotalReward"] = mean(all_rewards)
    metrics["StdTotalReward"] = std(all_rewards)
    
    policy_results[policy_name] = metrics
    
    # Generate city-level analysis
    city_data = generate_city_analysis(base_mdp, representative_state, policy_name)
    city_analysis_data[policy_name] = city_data
    
    println("✓ (Avg Reward: $(@sprintf("%.0f", metrics["AvgTotalReward"])))")
end

# Solve with Value Iteration for optimal benchmark
println("\\n  • Optimal (Value Iteration): ")
try
    solver = ValueIterationSolver(max_iterations=100, belres=1e-3, verbose=false)
    optimal_policy = solve(solver, mdp)
    
    # Evaluate optimal policy
    hr = HistoryRecorder(max_steps=12)
    h = simulate(hr, mdp, optimal_policy)
    
    final_state = h[end].s
    total_reward = sum([step.r for step in h])
    
    metrics = calculate_academic_metrics(base_mdp, final_state, "Optimal")
    metrics["AvgTotalReward"] = total_reward
    metrics["StdTotalReward"] = 0.0  # Deterministic optimal policy
    
    policy_results["Optimal"] = metrics
    city_data = generate_city_analysis(base_mdp, final_state, "Optimal")
    city_analysis_data["Optimal"] = city_data
    
    println("✓ (Reward: $(@sprintf("%.0f", total_reward)))")
catch e
    println("❌ Failed: $e")
end

println("\\n📈 RESULTS GENERATION")
println("="^50)

# Combine city data for analysis
policy_results["city_data"] = city_analysis_data

# Generate and save CSV files for academic tables
println("Generating CSV exports for academic tables...")
policy_df, city_df, summary_df = save_academic_results(policy_results, "results")

# Generate all plots and figures
println("\\nGenerating publication-quality figures...")

# Get city data for plotting
all_city_data = []
for (policy_name, city_list) in city_analysis_data
    append!(all_city_data, city_list)
end

# Create all visualizations
plot_policy_comparison(policy_results, save_path="figures")
plot_city_energy_analysis(all_city_data, save_path="figures")
plot_equity_analysis(policy_results, all_city_data, save_path="figures")
plot_geographic_analysis(all_city_data, save_path="figures")
create_paper_figure(policy_results, all_city_data, save_path="figures")

println("\\n📋 ACADEMIC PAPER SUMMARY")
println("="^50)

# Generate summary table for paper
println("\\nTable 1: Policy Performance Comparison")
println("-" * 70)
@printf("%-18s | %8s | %8s | %8s | %8s\\n", 
        "Policy", "RE (%)", "Equity", "Budget Eff", "Pop Served")
println("-" * 70)

for (policy_name, metrics) in policy_results
    if policy_name != "city_data"
        @printf("%-18s | %8.1f | %8.3f | %8.2f | %8.1f\\n",
                policy_name[1:min(18, length(policy_name))],
                metrics["REPercentage"],
                metrics["EquityScore"],
                metrics["BudgetEfficiency"],
                metrics["PopulationServed"])
    end
end

println("-" * 70)

# Key findings for paper
println("\\n🔍 KEY FINDINGS FOR ACADEMIC PAPER")
println("="^50)

# Find best performing policies
best_re = argmax(policy -> policy_results[policy]["REPercentage"], 
                [p for p in keys(policy_results) if p != "city_data"])
best_equity = argmax(policy -> policy_results[policy]["EquityScore"],
                    [p for p in keys(policy_results) if p != "city_data"])
best_efficiency = argmax(policy -> policy_results[policy]["BudgetEfficiency"],
                        [p for p in keys(policy_results) if p != "city_data"])

println("1. **Renewable Energy Leadership**: $best_re achieved $(format_percentage(policy_results[best_re]["REPercentage"]))% renewable energy")
println("2. **Equity Champion**: $best_equity achieved $(format_academic(policy_results[best_equity]["EquityScore"], 3)) equity score")
println("3. **Budget Efficiency**: $best_efficiency achieved $(format_academic(policy_results[best_efficiency]["BudgetEfficiency"])) GW/\$M")

# Calculate improvements over baseline
baseline_metrics = policy_results["Random Baseline"]
if haskey(policy_results, "Optimal")
    optimal_metrics = policy_results["Optimal"]
    
    re_improvement = optimal_metrics["REPercentage"] - baseline_metrics["REPercentage"]
    equity_improvement = optimal_metrics["EquityScore"] - baseline_metrics["EquityScore"]
    efficiency_improvement = optimal_metrics["BudgetEfficiency"] - baseline_metrics["BudgetEfficiency"]
    
    println("\\n4. **Optimal Policy Improvements over Random Baseline**:")
    println("   - Renewable Energy: +$(format_percentage(re_improvement)) percentage points")
    println("   - Equity Score: +$(format_academic(equity_improvement, 3))")
    println("   - Budget Efficiency: +$(format_academic(efficiency_improvement)) GW/\$M")
end

# Equity analysis
if haskey(policy_results["Optimal"], "SupplyDisparity")
    disparity = policy_results["Optimal"]["SupplyDisparity"]
    println("\\n5. **Energy Justice**: Optimal policy achieves $(format_percentage(disparity*100))% supply disparity between income groups")
    
    if disparity < 0.15  # Less than 15% disparity
        println("   → Meets energy justice criteria (disparity < 15%)")
    else
        println("   → Opportunity for improvement in energy justice")
    end
end

println("\\n📁 OUTPUT FILES GENERATED")
println("="^50)
println("📊 **CSV Data Files** (in results/)")
println("   • policy_comparison.csv - Main results table")
println("   • city_analysis.csv - City-level detailed analysis")  
println("   • summary_statistics.csv - Statistical summary")

println("\\n📈 **Figures** (in figures/)")
println("   • paper_figure_main.pdf - Main figure for paper")
println("   • policy_comparison.pdf - Policy performance comparison")
println("   • equity_analysis.pdf - Energy equity analysis")
println("   • geographic_*.pdf - Geographic distribution maps")

println("\\n🎯 **Ready for Academic Submission!**")
println("="^50)
println("""
This demonstration has generated:
✅ Publication-quality figures with proper academic formatting
✅ CSV data files for creating tables in LaTeX/Word
✅ Geographic visualizations showing spatial equity patterns
✅ Statistical analysis with multiple simulation runs
✅ Comprehensive multi-objective policy evaluation

All outputs are ready for inclusion in your academic paper on
multi-objective energy policy optimization using MDPs.
""")

println("\\n📊 Files generated: $(length(readdir("results", join=false))) CSV files, $(length(readdir("figures", join=false))) figures")
println("Demonstration completed successfully! 🎉")