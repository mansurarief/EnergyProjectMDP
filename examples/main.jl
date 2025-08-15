using EnergyProjectMDP
using POMDPs
using POMDPTools
using DiscreteValueIteration
using Random
using Printf
using MCTS
using Plots

rng = MersenneTwister(1234)
mdp = initialize_mdp(rng)
mdp_re = initialize_mdp(rng, 0.0001, -5.0, 100.0)
println("Created MDP with $(mdp.numberOfCities) cities")
println("Initial budget: \$$(mdp.initialBudget)M")
println("State space size: $(length(states(mdp))) states")
println("Action space size: $(length(actions(mdp))) actions\n")

# Test all policies including new stronger benchmarks
policies_to_test = [
    ("Random", RandomEnergyPolicy(rng)),
    ("Expert", EquityFirstPolicy())
]

println("Evaluating $(length(policies_to_test)) policies...")
results = Dict{String, Dict{String, Float64}}()

for (name, policy) in policies_to_test
    print("Evaluating $name... ")
    # Use the same RNG for all policies to ensure fair comparison
    rng = MersenneTwister(1234)
    result = evaluate_policy_comprehensive(mdp, policy, 30, 12, rng)
    results[name] = result
    println("✓")
end

# Test MDP Solvers
println("\n" * "="^60)
println("MDP SOLVER RUNNING...")
println("="^60)

# Test Value Iteration
try
    println("Testing Value Iteration...")
    vi_solver = ValueIterationSolver(max_iterations=100, belres=1e-3, verbose=false)
    vi_policy = solve(vi_solver, mdp)
    println("✅ Value Iteration converged!")
    
    vi_result = evaluate_policy_comprehensive(mdp, vi_policy, 30, 12, rng)
    results["Value Iteration"] = vi_result
    
    println("Value Iteration Performance:")
    println("  Avg Reward: $(@sprintf("%.1f ± %.1f", vi_result["total_reward_mean"], vi_result["total_reward_std"]))")

    # Test MCTS
    println("Testing MCTS Base...")
    MCTS_solver =  MCTSSolver(n_iterations=1000, depth=50, exploration_constant=15.0)
    MCTS_policy = solve(MCTS_solver, mdp)
    println("✅ MCTS Base converged!")
    
    MCTS_result = evaluate_policy_comprehensive(mdp, MCTS_policy, 30, 12, rng)
    results["MCTS Base"] = MCTS_result

    println("MCTS Base Performance:")
    println("  Avg Reward: $(@sprintf("%.1f ± %.1f", MCTS_result["total_reward_mean"], MCTS_result["total_reward_std"]))")

    # Test MCTS for RE
    println("Testing MCTS for RE...")
    MCTS_solver_re =  MCTSSolver(n_iterations=500, depth=30, exploration_constant=10.0)
    MCTS_policy_re = solve(MCTS_solver_re, mdp_re)
    println("✅ MCTS RE converged!")
    
    MCTS_result_re = evaluate_policy_comprehensive(mdp, MCTS_policy_re, 30, 12, rng)
    results["MCTS RE"] = MCTS_result_re

    println("MCTS RE Performance:")
    println("  Avg Reward: $(@sprintf("%.1f ± %.1f", MCTS_result_re["total_reward_mean"], MCTS_result_re["total_reward_std"]))")


    # Display reward components if available
    if haskey(vi_result, "budget_reward_sum_mean")
        println("  Reward Components:")
        println("    Budget:        $(@sprintf("%8.1f ± %5.1f", vi_result["budget_reward_sum_mean"], vi_result["budget_reward_sum_std"]))")
        println("    Equity Penalty: $(@sprintf("%8.1f ± %5.1f", vi_result["equity_penalty_reward_sum_mean"], vi_result["equity_penalty_reward_sum_std"]))")
        println("    RE Bonus:      $(@sprintf("%8.1f ± %5.1f", vi_result["re_bonus_reward_sum_mean"], vi_result["re_bonus_reward_sum_std"]))")
    end
    
catch e
    println("❌ Value Iteration failed: $e")
end



# Compare MDP solvers if available
mdp_solvers = filter(k -> contains(k, "Iteration") || contains(k, "MCTS"), keys(results))
if length(mdp_solvers) > 1
    println("\n🤖 MDP Solver Comparison:")
    for solver in mdp_solvers
        solver_result = results[solver]
        println("  $solver: $(@sprintf("%.1f ± %.1f", solver_result["total_reward_mean"], solver_result["total_reward_std"]))")
    end
end

println("\n🚀 Framework ready for energy policy optimization!")

# Print comprehensive comparison table at the end
print_policy_comparison(results)

colors = [:blue, :green, :orange, :red, :purple]

policies = ["MCTS Base", "Value Iteration", "MCTS RE", "Expert", "Random"]
rewards = [527, 373, 100, 580, 273]
re_stds = [80, 94, 97, 111, 57]

bar(policies, rewards, yerror=re_stds, title="Average Reward by Policy", 
    legend=false, ylabel="Reward", color=colors)

avg_rewards = [527, 373, 100, 580, 273]
avg_reward_err = [80, 94, 97, 111, 57]

re_percent = [15.9, 14.6, 28.6, 32.9, 22.0]
re_err = [3.2, 0.0, 3.2, 2.1, 4.9]

budget_used = [127, 145, 364, 426, 442]
budget_err = [112, 144, 374, 553, 440]

low_inc_cities = [2.2, 2.0, 1.9, 1.9, 2.2]
low_inc_cities_err = [0.7, 0.0, 0.5, 0.4, 0.9]

low_inc_pop = [0.54, 0.47, 0.47, 0.20, 0.58]
low_inc_pop_err = [0.18, 0.03, 0.12, 0.10, 0.28]

high_inc_pop = [0.40, 0.40, 0.37, 0.40, 0.37]
high_inc_pop_err = [0.05, 0.05, 0.13, 0.05, 0.16]

# Create subplots with consistent colors
p1 = bar(policies, avg_rewards, yerror=avg_reward_err, legend=false,
    title="Avg Reward ↑", ylabel="Reward", rotation=45, color=colors);
p2 = bar(policies, re_percent, yerror=re_err, legend=false,
    title="RE % ↑", ylabel="%", rotation=45, color=colors);
p3 = bar(policies, budget_used, yerror=budget_err, legend=false,
    title="Budget Used ↑", ylabel="Units", rotation=45, color=colors);
p4 = bar(policies, low_inc_cities, yerror=low_inc_cities_err, legend=false,
    title="Low-Inc Cities ↓", ylabel="#", rotation=45, color=colors);
p5 = bar(policies, low_inc_pop, yerror=low_inc_pop_err, legend=false,
    title="Low-Inc Pop (M) ↓", ylabel="Millions", rotation=45, color=colors);
p6 = bar(policies, high_inc_pop, yerror=high_inc_pop_err, legend=false,
    title="High-Inc Pop (M) ↓", ylabel="Millions", rotation=45, color=colors);

# Display in a 2x3 grid layout
plot(p1, p2, p3, p4, p5, p6, layout=(2, 3), size=(1200, 700), titlefontsize=12, 
     left_margin=5Plots.mm, right_margin=5Plots.mm, 
     top_margin=5Plots.mm, bottom_margin=5Plots.mm)

# Save the plot to a file
savefig("figs/policy_comparison.pdf")



