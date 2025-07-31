using EnergyProjectMDP
using POMDPs
using DiscreteValueIteration
using Random
using Printf
using MCTS

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
    MCTS_solver =  MCTSSolver(n_iterations=500, depth=30, exploration_constant=10.0)
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
