using EnergyProjectMDP
using POMDPs
using POMDPTools
using Random

# Quick test to verify everything works
println("=== Testing EnergyProjectMDP Implementation ===\n")

# Create MDP
mdp = EnergyMDP()
println("✓ Created MDP with $(mdp.numberOfCities) cities")

# Test initial state
s0 = rand(initialstate(mdp))
println("✓ Initial state: Budget = \$$(s0.b)M")

# Test actions
all_actions = actions(mdp)
valid_actions = actions(mdp, s0)
println("✓ Total actions: $(length(all_actions)), Valid in initial state: $(length(valid_actions))")

# Test transition
if length(valid_actions) > 1
    a = valid_actions[2]  # Pick a non-doNothing action
    sp = rand(transition(mdp, s0, a))
    r = reward(mdp, s0, a)
    println("✓ Transition works: Budget changed from \$$(s0.b)M to \$$(sp.b)M")
    println("✓ Reward function works: r = $r")
end

# Test policies
println("\n=== Testing Policies ===")
policies = [
    ("Random", RandomEnergyPolicy()),
    ("Greedy RE", GreedyREPolicy()),
    ("Balanced", BalancedEnergyPolicy()),
    ("Equity First", EquityFirstPolicy())
]

for (name, policy) in policies
    a = action(policy, s0)
    println("✓ $name policy: $(typeof(a) == doNothing ? "Do nothing" : "Take action")")
end

# Test simulation
println("\n=== Testing Simulation ===")
policy = GreedyREPolicy()
hr = HistoryRecorder(max_steps=5)
h = simulate(hr, mdp, policy)
println("✓ Simulation completed with $(length(h)) steps")
println("  Final budget: \$$(h[end].s.b)M")

# Test state space (for small MDP)
small_mdp = EnergyMDP(
    cities=mdp.cities[1:2],
    numberOfCities=2,
    budgetDiscretization=500.0,
    maxBudget=3000.0,
    minBudget=0.0
)
println("\n=== Testing Discrete State Space ===")
state_list = states(small_mdp)
println("✓ Generated $(length(state_list)) discrete states")

# Test state indexing
si = stateindex(small_mdp, s0)
println("✓ State indexing works: index = $si")

println("\n✅ All tests passed!")