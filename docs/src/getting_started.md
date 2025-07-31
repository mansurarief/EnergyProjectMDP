# Getting Started

This guide will help you get up and running with EnergyProjectMDP.jl quickly.

## Installation

EnergyProjectMDP.jl is a Julia package. First, make sure you have Julia installed (version 1.6 or later recommended).

### From Julia REPL

```julia
using Pkg
Pkg.add("EnergyProjectMDP")
```

### Development Installation

If you want to contribute or use the latest development version:

```julia
using Pkg
Pkg.add(url="https://github.com/mansurarief/EnergyProjectMDP.jl")
```

### Local Installation

If you have cloned the repository:

```bash
cd EnergyProjectMDP
julia --project=.
```

Then in Julia:

```julia
using Pkg
Pkg.instantiate()
```

## Basic Usage

### 1. Load the Package

```julia
using EnergyProjectMDP
using Random
```

### 2. Initialize an MDP

```julia
# Set random seed for reproducibility
rng = MersenneTwister(1234)

# Create an MDP with default parameters
mdp = initialize_mdp(rng)

println("Created MDP with $(mdp.numberOfCities) cities")
println("Initial budget: \$$(mdp.initialBudget)M")
```

### 3. Explore the Initial State

```julia
# Sample an initial state
s0 = rand(rng, initialstate(mdp))

println("Initial state:")
println("  Budget: \$$(s0.b)M")
println("  Total demand: $(s0.total_demand) GWh")

for (i, city) in enumerate(s0.cities)
    println("  City $i: $(city.name)")
    println("    Demand: $(city.demand) GWh")
    println("    RE Supply: $(city.re_supply) GWh") 
    println("    NRE Supply: $(city.nre_supply) GWh")
    println("    Income Level: $(city.income ? "High" : "Low")")
end
```

### 4. Try Different Policies

```julia
# Create different policies
policies = [
    ("Random", RandomEnergyPolicy(rng)),
    ("Equity First", EquityFirstPolicy()),
    ("Greedy RE", GreedyREPolicy()),
    ("Expert", ExpertPolicy())
]

# Evaluate each policy
results = Dict{String, Dict{String, Float64}}()

for (name, policy) in policies
    println("Evaluating $name policy...")
    result = evaluate_policy_comprehensive(mdp, policy, 10, 8, rng)
    results[name] = result
end

# Compare results
print_policy_comparison(results)
```

### 5. Create Visualizations

```julia
# Get final state from one policy evaluation
final_state = rand(rng, initialstate(mdp))

# Apply a few actions to see changes
policy = EquityFirstPolicy()
for _ in 1:5
    if !isterminal(mdp, final_state)
        action = POMDPs.action(policy, final_state)
        final_state = rand(rng, transition(mdp, final_state, action))
    end
end

# Generate comprehensive visualization report
generated_files = generate_comprehensive_report(mdp, results, final_state, 
                                              output_dir="my_results")

println("Generated visualization files:")
for file in generated_files
    println("  - $file")
end
```

## Understanding the Output

### Policy Evaluation Results

The `evaluate_policy_comprehensive` function returns a dictionary with metrics:

- `total_reward_mean`: Average total reward across simulations
- `total_reward_std`: Standard deviation of total rewards
- `budget_mean`: Average remaining budget
- `total_supply_mean`: Average total energy supply
- `equity_score_mean`: Equity metric (higher is better)
- `re_percentage_mean`: Percentage of renewable energy

### Visualization Files

The comprehensive report generates several files:

- `energy_map.png`: Geographic visualization of cities and their energy status
- `policy_comparison.png`: Bar chart comparing policy performance
- `energy_distribution.png`: Pie charts showing renewable vs non-renewable energy
- `equity_analysis.png`: Analysis of energy deficits by income level
- `summary_report.txt`: Detailed text summary of results

## Next Steps

Now that you have the basics working, you might want to:

1. **Learn about the MDP formulation**: See [MDP Formulation](mdp_formulation.md)
2. **Explore different policies**: Check out [Policies](policies.md)
3. **Create custom policies**: Look at [Custom Policies](examples/custom_policies.md)
4. **Use MDP solvers**: Try Value Iteration or MCTS solvers
5. **Analyze results in detail**: Use the evaluation and visualization tools

## Common Issues

### Missing Dependencies

If you get errors about missing packages, make sure all dependencies are installed:

```julia
using Pkg
Pkg.instantiate()
```

### Visualization Issues

If visualizations fail to generate:

1. Make sure you have plotting backends installed
2. Check that you have write permissions in the output directory
3. GMT visualizations require GMT to be installed separately

### Memory Issues with Large State Spaces

For very large problems, consider:

1. Reducing the number of cities in the MDP
2. Using fewer simulation runs in evaluation
3. Limiting the maximum number of steps per simulation

## Getting Help

- Check the [API Reference](api.md) for detailed function documentation
- Look at [Examples](examples/basic_usage.md) for more complex usage patterns
- Open an issue on [GitHub](https://github.com/mansurarief/EnergyProjectMDP.jl) for bugs or questions