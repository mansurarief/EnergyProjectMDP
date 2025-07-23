using EnergyProjectMDP
using POMDPs
using POMDPTools
using DiscreteValueIteration
using Random
using Plots
using Statistics
using Printf

# Create the MDP with smaller state space for faster solving
function create_small_mdp()
    # Use fewer cities and coarser discretization for demonstration
    cities_small = [
        City(name="Atlanta", demand=16.7, re_supply=0.0, nre_supply=10.0, 
             population=500_000, income=true),
        City(name="Memphis", demand=13.9, re_supply=0.0, nre_supply=11.1, 
             population=633_000, income=false),
        City(name="Seattle", demand=13.5, re_supply=6.2, nre_supply=5.3, 
             population=750_000, income=true)
    ]
    
    return EnergyMDP(
        cities=cities_small,
        numberOfCities=3,
        budgetDiscretization=200.0,
        maxBudget=4000.0,
        minBudget=-200.0,
        initialBudget=2000.0
    )
end

# Simulate a policy and collect statistics
function simulate_policy(mdp::EnergyMDP, policy::Policy, n_simulations::Int=100, max_steps::Int=20)
    rewards = Float64[]
    final_re_ratios = Float64[]
    final_unmet_demands = Float64[]
    
    for i in 1:n_simulations
        hr = HistoryRecorder(max_steps=max_steps)
        h = simulate(hr, mdp, policy)
        
        # Calculate total reward
        total_reward = sum([step.r for step in h])
        push!(rewards, total_reward)
        
        # Calculate final RE ratio
        final_state = h[end].s
        total_re = sum([city.re_supply for city in final_state.cities])
        total_energy = sum([city.re_supply + city.nre_supply for city in final_state.cities])
        push!(final_re_ratios, total_energy > 0 ? total_re / total_energy : 0.0)
        
        # Calculate final unmet demand
        unmet = sum([max(0, city.demand - city.re_supply - city.nre_supply) for city in final_state.cities])
        push!(final_unmet_demands, unmet)
    end
    
    return (
        avg_reward = mean(rewards),
        std_reward = std(rewards),
        avg_re_ratio = mean(final_re_ratios),
        avg_unmet_demand = mean(final_unmet_demands)
    )
end

# Main execution
println("=== Energy Project MDP Solver Demo ===\n")

# Create MDP
mdp = create_small_mdp()
println("Created MDP with $(mdp.numberOfCities) cities")
println("State space size: $(length(states(mdp))) states")
println("Action space size: $(length(actions(mdp))) actions\n")

# Initialize policies
policies_to_test = [
    ("Random Policy", RandomEnergyPolicy(MersenneTwister(1234))),
    ("Greedy RE Policy", GreedyREPolicy()),
    ("Balanced Policy (50% RE)", BalancedEnergyPolicy(0.5)),
    ("Balanced Policy (70% RE)", BalancedEnergyPolicy(0.7)),
    ("Equity First Policy", EquityFirstPolicy())
]

# Test each policy
println("=== Policy Evaluation Results ===")
println("Policy Name                  | Avg Reward | Std Dev | Avg RE Ratio | Avg Unmet Demand")
println("-"^85)

results = Dict{String, Any}()
for (name, policy) in policies_to_test
    stats = simulate_policy(mdp, policy, 50, 15)
    results[name] = stats
    
    @printf("%-28s | %10.2f | %7.2f | %12.2f%% | %16.2f GW\n", 
            name, stats.avg_reward, stats.std_reward, 
            stats.avg_re_ratio * 100, stats.avg_unmet_demand)
end

# Try to solve with Value Iteration (if the state space is small enough)
println("\n=== Solving with Value Iteration ===")
try
    solver = ValueIterationSolver(max_iterations=100, belres=1e-3, verbose=true)
    vi_policy = solve(solver, mdp)
    println("\nValue Iteration converged!")
    
    # Test the optimal policy
    stats = simulate_policy(mdp, vi_policy, 50, 15)
    results["Value Iteration Policy"] = stats
    
    println("\nOptimal Policy Performance:")
    @printf("Avg Reward: %.2f, RE Ratio: %.2f%%, Unmet Demand: %.2f GW\n",
            stats.avg_reward, stats.avg_re_ratio * 100, stats.avg_unmet_demand)
            
catch e
    println("Value Iteration failed: $e")
    println("State space might be too large. Consider further discretization.")
end

# Visualize a sample trajectory
println("\n=== Sample Trajectory (Greedy RE Policy) ===")
policy = GreedyREPolicy()
state = rand(initialstate(mdp))
println("Initial state: Budget = \$$(state.b)M")

for step in 1:10
    local a = action(policy, state)
    local state_next = rand(transition(mdp, state, a))
    local r = reward(mdp, state, a)
    
    if typeof(a) == newAction
        action_str = "$(a.actionType ? "Add" : "Remove") $(a.energyType ? "NRE" : "RE") to/from $(state.cities[a.cityIndex].name)"
    else
        action_str = "Do nothing"
    end
    
    println("Step $step: $action_str")
    println("  Budget: \$$(state.b)M → \$$(state_next.b)M, Reward: $r")
    
    state = state_next
    
    if isterminal(mdp, state)
        println("Terminal state reached!")
        break
    end
end

# Plot results
println("\n=== Generating Performance Comparison Plot ===")
policy_names = [k for k in keys(results)]
avg_rewards = [results[k].avg_reward for k in policy_names]
re_ratios = [results[k].avg_re_ratio * 100 for k in policy_names]

p1 = bar(1:length(policy_names), avg_rewards, 
         xlabel="Policy", ylabel="Average Reward", 
         title="Policy Performance Comparison",
         xticks=(1:length(policy_names), policy_names),
         xrotation=45,
         legend=false)

p2 = bar(1:length(policy_names), re_ratios,
         xlabel="Policy", ylabel="RE Ratio (%)",
         title="Final Renewable Energy Ratio",
         xticks=(1:length(policy_names), policy_names),
         xrotation=45,
         legend=false,
         color=:green)

plot(p1, p2, layout=(2,1), size=(800,600))
savefig("policy_comparison.png")
println("Plot saved to policy_comparison.png")