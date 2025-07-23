using EnergyProjectMDP
using POMDPs
using POMDPTools
using DiscreteValueIteration
using Random
using Statistics
using Printf

# Create a very small MDP that's guaranteed to work with Value Iteration
function create_tiny_mdp()
    # Use only 2 cities with simple configurations
    atlanta = City(name="Atlanta", demand=10.0, re_supply=0.0, nre_supply=5.0, 
                   population=500_000, income=true)
    memphis = City(name="Memphis", demand=8.0, re_supply=0.0, nre_supply=3.0, 
                   population=633_000, income=false)
    
    cities_tiny = [atlanta, memphis]
    
    return EnergyMDP(
        cities=cities_tiny,
        numberOfCities=2,
        budgetDiscretization=500.0,  # Very coarse discretization
        maxBudget=2000.0,
        minBudget=0.0,
        initialBudget=1000.0,
        maxEnergyPerCity=30.0,  # Lower max to reduce state space
        supplyOfRE=5.0,  # Smaller increments
        supplyOfNRE=5.0
    )
end

# Simple state space generation that's guaranteed to work
function create_simple_state_space(mdp::EnergyMDP)
    states = State[]
    
    # Just vary the budget and keep cities mostly fixed
    budget_values = [0.0, 500.0, 1000.0, 1500.0, 2000.0]
    
    for budget in budget_values
        # Original configuration
        push!(states, State(b=budget, cities=deepcopy(mdp.cities), 
                           total_demand=sum([city.demand for city in mdp.cities])))
        
        # Configuration with RE added to first city
        cities_mod1 = deepcopy(mdp.cities)
        cities_mod1[1] = City(
            name=cities_mod1[1].name,
            demand=cities_mod1[1].demand,
            re_supply=cities_mod1[1].re_supply + 5.0,
            nre_supply=cities_mod1[1].nre_supply,
            population=cities_mod1[1].population,
            income=cities_mod1[1].income
        )
        push!(states, State(b=budget, cities=cities_mod1, 
                           total_demand=sum([city.demand for city in cities_mod1])))
        
        # Configuration with RE added to second city
        cities_mod2 = deepcopy(mdp.cities)
        cities_mod2[2] = City(
            name=cities_mod2[2].name,
            demand=cities_mod2[2].demand,
            re_supply=cities_mod2[2].re_supply + 5.0,
            nre_supply=cities_mod2[2].nre_supply,
            population=cities_mod2[2].population,
            income=cities_mod2[2].income
        )
        push!(states, State(b=budget, cities=cities_mod2, 
                           total_demand=sum([city.demand for city in cities_mod2])))
    end
    
    return unique(states)
end

# Override the states function for this specific MDP
function POMDPs.states(p::EnergyMDP)
    return create_simple_state_space(p)
end

# Simple state indexing
function POMDPs.stateindex(p::EnergyMDP, s::State)
    state_list = states(p)
    
    for (idx, state) in enumerate(state_list)
        # Check if states match exactly
        if abs(state.b - s.b) < 1e-6 && 
           length(state.cities) == length(s.cities) &&
           all(abs(state.cities[i].re_supply - s.cities[i].re_supply) < 1e-6 && 
               abs(state.cities[i].nre_supply - s.cities[i].nre_supply) < 1e-6 
               for i in 1:length(state.cities))
            return idx
        end
    end
    
    # If exact match not found, return closest
    min_dist = Inf
    best_idx = 1
    for (idx, state) in enumerate(state_list)
        dist = abs(state.b - s.b)
        for i in 1:length(state.cities)
            dist += abs(state.cities[i].re_supply - s.cities[i].re_supply)
            dist += abs(state.cities[i].nre_supply - s.cities[i].nre_supply)
        end
        if dist < min_dist
            min_dist = dist
            best_idx = idx
        end
    end
    return best_idx
end

println("=== Testing Small MDP with Value Iteration ===\n")

# Create tiny MDP
mdp = create_tiny_mdp()
println("Created tiny MDP with $(length(mdp.cities)) cities")

# Check state space
state_list = states(mdp)
println("State space size: $(length(state_list)) states")

# Check if we can index states properly
s0 = rand(initialstate(mdp))
idx = stateindex(mdp, s0)
println("Initial state index: $idx")

# Test Value Iteration
println("\n=== Running Value Iteration ===")
try
    solver = ValueIterationSolver(max_iterations=50, belres=1e-2, verbose=true)
    policy = solve(solver, mdp)
    println("✅ Value Iteration succeeded!")
    
    # Test the policy
    println("\n=== Testing Optimal Policy ===")
    hr = HistoryRecorder(max_steps=10)
    h = simulate(hr, mdp, policy)
    
    total_reward = sum([step.r for step in h])
    final_state = h[end].s
    
    println("Simulation completed in $(length(h)) steps")
    println("Total reward: $total_reward")
    println("Final budget: \$$(final_state.b)M")
    
    # Compare with greedy policy
    println("\n=== Comparing with Greedy Policy ===")
    greedy_policy = GreedyREPolicy()
    hr_greedy = HistoryRecorder(max_steps=10)
    h_greedy = simulate(hr_greedy, mdp, greedy_policy)
    
    total_reward_greedy = sum([step.r for step in h_greedy])
    
    println("Optimal policy total reward: $total_reward")
    println("Greedy policy total reward: $total_reward_greedy")
    println("Improvement: $(total_reward - total_reward_greedy)")
    
catch e
    println("❌ Value Iteration failed: $e")
    println("Full error:")
    showerror(stdout, e, catch_backtrace())
end