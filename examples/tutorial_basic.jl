#!/usr/bin/env julia

"""
Basic Tutorial: Getting Started with EnergyProjectMDP.jl

This tutorial demonstrates the basic functionality of the EnergyProjectMDP.jl package.
We'll cover:
1. Setting up an MDP
2. Creating and using policies
3. Running simulations
4. Analyzing results
5. Creating visualizations
"""

using EnergyProjectMDP
using POMDPs
using Random
using Printf
using Statistics

println("🚀 EnergyProjectMDP.jl Basic Tutorial")
println("="^50)

# Step 1: Initialize the MDP
println("\n📋 Step 1: Initialize the MDP")
println("-"^30)

# Set random seed for reproducibility
rng = MersenneTwister(1234)

# Create an MDP with default parameters
mdp = initialize_mdp(rng)

println("✅ Created MDP with:")
println("   - $(mdp.numberOfCities) cities")
println("   - Initial budget: \$$(mdp.initialBudget)M")
println("   - Discount rate: $(mdp.discountRate)")
println("   - RE supply per action: $(mdp.supplyOfRE) GWh")
println("   - NRE supply per action: $(mdp.supplyOfNRE) GWh")

# Step 2: Explore the initial state
println("\n🏙️  Step 2: Explore Initial State")
println("-"^30)

# Sample an initial state
s0 = rand(rng, initialstate(mdp))

println("Initial state:")
println("  Budget: \$$(round(s0.b, digits=1))M")
println("  Total demand: $(round(s0.total_demand, digits=1)) GWh")
println()

for (i, city) in enumerate(s0.cities)
    supply = city.re_supply + city.nre_supply
    deficit = max(0, city.demand - supply)
    income_status = city.income ? "High" : "Low"
    
    println("  City $i: $(city.name)")
    println("    Population: $(Int(city.population/1000))K")
    println("    Income Level: $income_status")
    println("    Demand: $(round(city.demand, digits=1)) GWh")
    println("    Current Supply: $(round(supply, digits=1)) GWh")
    println("      - RE: $(round(city.re_supply, digits=1)) GWh")
    println("      - NRE: $(round(city.nre_supply, digits=1)) GWh")
    if deficit > 0
        println("    ⚠️  Energy Deficit: $(round(deficit, digits=1)) GWh")
    else
        println("    ✅ Fully Supplied")
    end
    println()
end

# Step 3: Try different policies
println("\n🤖 Step 3: Policy Comparison")
println("-"^30)

# Create different policies to compare
policies = [
    ("Random", RandomEnergyPolicy(MersenneTwister(1234))),
    ("Equity First", EquityFirstPolicy()),
    ("Greedy RE", GreedyREPolicy()),
    ("Balanced", BalancedEnergyPolicy()),
    ("Expert", ExpertPolicy())
]

println("Evaluating $(length(policies)) different policies...")
println("(This may take a moment...)")
println()

# Evaluate each policy
results = Dict{String, Dict{String, Float64}}()

for (name, policy) in policies
    print("  Evaluating '$name' policy... ")
    
    # Use relatively few simulations for tutorial speed
    result = evaluate_policy_comprehensive(mdp, policy, 10, 8, MersenneTwister(1234))
    results[name] = result
    
    reward_mean = result["total_reward_mean"]
    reward_std = result["total_reward_std"]
    println("✅ (Reward: $(round(reward_mean, digits=1)) ± $(round(reward_std, digits=1)))")
end

# Step 4: Analyze and compare results
println("\n📊 Step 4: Results Analysis")
println("-"^30)

print_policy_comparison(results)

# Find best performing policy
best_policy = ""
best_reward = -Inf
for (name, metrics) in results
    if metrics["total_reward_mean"] > best_reward
        best_reward = metrics["total_reward_mean"]
        best_policy = name
    end
end

println("\n🏆 Best performing policy: $best_policy")
println("   Average reward: $(round(best_reward, digits=1))")

# Step 5: Detailed analysis of one policy
println("\n🔍 Step 5: Detailed Policy Analysis")
println("-"^30)

# Let's analyze the Equity First policy in detail
policy = EquityFirstPolicy()
println("Analyzing Equity First Policy in detail...")

# Run a single simulation to trace the decision process
hr = HistoryRecorder(max_steps=8, rng=MersenneTwister(1234))
h = simulate(hr, mdp, policy)

println("\nSimulation trace:")
for (step, transition) in enumerate(h)
    s = transition.s
    a = transition.a
    r = transition.r
    
    println("\n  Step $step:")
    println("    Budget: \$$(round(s.b, digits=1))M")
    println("    Action: $(typeof(a).name.name)")
    
    if isa(a, newAction)
        city_name = s.cities[a.cityIndex].name
        energy_type = a.energyType ? "NRE" : "RE"
        action_type = a.actionType ? "Add" : "Remove"
        println("    Details: $action_type $energy_type to $city_name")
    end
    
    println("    Reward: $(round(r, digits=2))")
    
    if isterminal(mdp, s)
        println("    ⏹️  Terminal state reached")
        break
    end
end

# Analyze final state
final_state = h[end].s
println("\n📋 Final State Summary:")
println("  Final Budget: \$$(round(final_state.b, digits=1))M")

total_demand = sum([city.demand for city in final_state.cities])
total_supply = sum([city.re_supply + city.nre_supply for city in final_state.cities])
total_re = sum([city.re_supply for city in final_state.cities])

println("  Total Demand: $(round(total_demand, digits=1)) GWh")
println("  Total Supply: $(round(total_supply, digits=1)) GWh")
println("  Supply Gap: $(round(total_supply - total_demand, digits=1)) GWh")
println("  Renewable %: $(round(total_re/total_supply*100, digits=1))%")

# Step 6: Create visualizations
println("\n🎨 Step 6: Visualizations")
println("-"^30)

try
    println("Generating comprehensive visualization report...")
    
    generated_files = generate_comprehensive_report(
        mdp, 
        results, 
        final_state,
        output_dir="tutorial_output"
    )
    
    println("\n✅ Visualization report generated!")
    println("📁 Files created in 'tutorial_output/' directory:")
    for file in generated_files
        filename = split(file, "/")[end]  # Get just the filename
        println("   - $filename")
    end
    
catch e
    @warn "Visualization generation failed: $e"
    println("⚠️  Visualization generation failed, but tutorial completed successfully!")
end

# Step 7: Next steps and recommendations
println("\n🎯 Step 7: Next Steps")
println("-"^30)

println("Congratulations! You've completed the basic tutorial. Here are some next steps:")
println()
println("1. 🔬 Experiment with different MDP parameters:")
println("   mdp_custom = initialize_mdp(rng, 0.1, -100.0, 50.0)")
println()
println("2. 🏗️  Create your own custom policy:")
println("   See examples/custom_policy_example.jl")
println()
println("3. 🧮 Try MDP solvers (Value Iteration, MCTS):")
println("   See examples/solver_comparison.jl")
println()
println("4. 📊 Explore different visualization options:")
println("   See src/visualization.jl for all available functions")
println()
println("5. 📚 Read the full documentation:")
println("   https://mansurarief.github.io/EnergyProjectMDP.jl/stable/")

println("\n" * "="^50)
println("🎉 Tutorial completed successfully!")
println("Thank you for using EnergyProjectMDP.jl!")
println("="^50)