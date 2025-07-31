# EnergyProjectMDP.jl

*A Julia package for energy resource allocation optimization using Markov Decision Processes*

[![Build Status](https://github.com/mansurarief/EnergyProjectMDP.jl/workflows/CI/badge.svg)](https://github.com/mansurarief/EnergyProjectMDP.jl/actions)
[![Coverage](https://codecov.io/gh/mansurarief/EnergyProjectMDP.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mansurarief/EnergyProjectMDP.jl)

## Overview

EnergyProjectMDP.jl provides a comprehensive framework for modeling and optimizing energy resource allocation across cities with different socioeconomic characteristics. The package uses Markov Decision Processes (MDPs) to balance renewable energy deployment, equity considerations, and budget constraints.

### Key Features

- **🏙️ Multi-City Energy Modeling**: Model energy supply and demand across multiple cities with different characteristics
- **⚖️ Equity-Aware Optimization**: Balance energy access across high-income and low-income communities
- **🌱 Renewable Energy Focus**: Prioritize renewable energy deployment while considering non-renewable alternatives
- **💰 Budget Management**: Optimize resource allocation under budget constraints
- **🤖 Multiple Policy Types**: Compare different decision-making strategies from random to expert-designed
- **🔍 MDP Solver Integration**: Use state-of-the-art solvers like Value Iteration and MCTS
- **📊 Comprehensive Evaluation**: Detailed metrics and visualization capabilities
- **🗺️ Geographic Visualization**: Create maps and charts showing energy distribution

## Quick Start

```julia
using EnergyProjectMDP
using Random

# Initialize MDP with random seed for reproducibility
rng = MersenneTwister(1234)
mdp = initialize_mdp(rng)

# Create a policy
policy = EquityFirstPolicy()

# Evaluate the policy
results = evaluate_policy_comprehensive(mdp, policy, 30, 12, rng)

# Print results
print_policy_comparison(Dict("EquityFirst" => results))

# Generate visualizations
final_state = rand(rng, initialstate(mdp))
generate_comprehensive_report(mdp, Dict("EquityFirst" => results), final_state)
```

## Problem Formulation

The energy allocation problem is modeled as an MDP where:

- **States**: Represent current budget and energy supply/demand status of all cities
- **Actions**: Add or remove renewable/non-renewable energy capacity in specific cities
- **Rewards**: Multi-objective function balancing budget efficiency, equity, and renewable energy deployment
- **Transitions**: Deterministic updates based on action costs and energy additions

### Reward Structure

The reward function considers three main components:

1. **Budget Efficiency**: Positive rewards for remaining budget
2. **Equity Penalty**: Large negative penalties for unmet demand in low-income cities
3. **Renewable Energy Bonus**: Positive rewards for cities fully powered by renewable energy

## Installation

```julia
using Pkg
Pkg.add("EnergyProjectMDP")
```

## Documentation Structure

- [Getting Started](getting_started.md): Installation and basic usage
- [MDP Formulation](mdp_formulation.md): Detailed problem formulation
- [Policies](policies.md): Available decision-making policies
- [Evaluation](evaluation.md): Performance evaluation methods
- [Visualization](visualization.md): Creating maps and charts
- [API Reference](api.md): Complete function documentation

## Contributing

We welcome contributions! Please see our [Contributing Guide](contributing.md) for details.

## Citation

If you use EnergyProjectMDP.jl in your research, please cite:

```bibtex
@software{EnergyProjectMDP,
  title = {EnergyProjectMDP.jl: A Julia Package for Energy Resource Allocation Optimization},
  author = {Arief, Mansur and Kinnarkar, Riya},
  year = {2024},
  url = {https://github.com/mansurarief/EnergyProjectMDP.jl}
}
```

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/mansurarief/EnergyProjectMDP.jl/blob/main/LICENSE) file for details.