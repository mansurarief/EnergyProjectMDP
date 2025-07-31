# EnergyProjectMDP.jl

*A Julia package for energy resource allocation optimization using Markov Decision Processes*

[![Build Status](https://github.com/mansurarief/EnergyProjectMDP.jl/workflows/CI/badge.svg)](https://github.com/mansurarief/EnergyProjectMDP.jl/actions)
[![Coverage](https://codecov.io/gh/mansurarief/EnergyProjectMDP.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/mansurarief/EnergyProjectMDP.jl)
[![Documentation](https://img.shields.io/badge/docs-stable-blue.svg)](https://mansurarief.github.io/EnergyProjectMDP.jl/stable)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Overview

EnergyProjectMDP.jl provides a comprehensive framework for modeling and optimizing energy resource allocation across cities with different socioeconomic characteristics. The package uses Markov Decision Processes (MDPs) to balance renewable energy deployment, equity considerations, and budget constraints.

### 🌟 Key Features

- **🏙️ Multi-City Energy Modeling**: Model energy supply and demand across multiple cities
- **⚖️ Equity-Aware Optimization**: Balance energy access across income levels
- **🌱 Renewable Energy Focus**: Prioritize sustainable energy deployment
- **💰 Budget Management**: Optimize under realistic budget constraints
- **🤖 Multiple Policy Types**: Compare different decision-making strategies
- **🔍 MDP Solver Integration**: Value Iteration, MCTS, and custom solvers
- **📊 Comprehensive Evaluation**: Detailed metrics and statistical analysis
- **🗺️ Rich Visualizations**: Maps, charts, and interactive reports

## 🚀 Quick Start

### Installation

```julia
using Pkg
Pkg.add("EnergyProjectMDP")
```

### Basic Usage

```julia
using EnergyProjectMDP
using Random

# Initialize MDP
rng = MersenneTwister(1234)
mdp = initialize_mdp(rng)

# Create and evaluate a policy
policy = EquityFirstPolicy()
results = evaluate_policy_comprehensive(mdp, policy, 30, 12, rng)

# Generate visualizations
final_state = rand(rng, initialstate(mdp))
generate_comprehensive_report(mdp, Dict("EquityFirst" => results), final_state)
```

### Running Examples

```bash
# Run main example with policy comparison
make main

# Run experimental analysis
julia --project=. examples/experiment.jl

# Run tests
make test
```

## 📋 Problem Formulation

The energy allocation problem is modeled as an MDP where:

- **States** (S): Budget level + energy supply/demand status for all cities
- **Actions** (A): Add/remove renewable or non-renewable energy in specific cities  
- **Rewards** (R): Multi-objective function balancing efficiency, equity, and sustainability
- **Transitions** (T): Deterministic updates based on action costs and capacity changes

### Reward Structure

```
R(s,a) = α·Budget(s) + β·EquityPenalty(s) + γ·REBonus(s)
```

Where:
- **Budget Component**: Positive reward for remaining budget
- **Equity Penalty**: Large negative penalty for unmet demand in low-income cities
- **RE Bonus**: Positive reward for cities fully powered by renewable energy

## 🏛️ Architecture

### Core Components

- **`src/mdp.jl`**: MDP formulation with states, actions, transitions, and rewards
- **`src/policies.jl`**: Decision-making policies from random to expert-designed
- **`src/functions.jl`**: Core MDP interface functions for POMDPs.jl
- **`src/init_mdp.jl`**: MDP initialization with realistic city configurations
- **`src/utils.jl`**: Policy evaluation and performance analysis
- **`src/eval_reward.jl`**: Comprehensive metrics calculation
- **`src/reward_analysis.jl`**: Reward component decomposition
- **`src/visualization.jl`**: Rich plotting and reporting capabilities

### Available Policies

| Policy | Description | Use Case |
|--------|-------------|----------|
| `RandomEnergyPolicy` | Random action selection | Baseline comparison |
| `EquityFirstPolicy` | Prioritizes low-income cities | Equity-focused planning |
| `GreedyREPolicy` | Maximizes renewable energy | Sustainability focus |
| `BalancedEnergyPolicy` | Balances multiple objectives | General-purpose |
| `PriorityBasedPolicy` | Multi-objective optimization | Configurable priorities |
| `ExpertPolicy` | Domain expert heuristics | Realistic benchmarks |

## 📊 Evaluation & Visualization

### Metrics

The package provides comprehensive evaluation including:

- **Performance**: Total reward, budget efficiency, supply-demand balance
- **Equity**: Income-based disparity analysis, population-weighted metrics  
- **Sustainability**: Renewable energy percentage, carbon footprint reduction
- **Statistical**: Confidence intervals, variance analysis across simulations



## 🔬 Research Applications

This package is designed for:

- **Energy Policy Research**: Compare policy interventions and their equity implications
- **Urban Planning**: Optimize energy infrastructure investments
- **Climate Studies**: Analyze renewable energy transition pathways
- **Social Justice**: Quantify and address energy equity disparities
- **Operations Research**: Benchmark MDP solvers on realistic problems
- **Education**: Teach MDP concepts with concrete applications

## 🛠️ Development

### Setup Development Environment

```bash
git clone https://github.com/mansurarief/EnergyProjectMDP.jl.git
cd EnergyProjectMDP
julia --project=.
```

In Julia:
```julia
using Pkg
Pkg.instantiate()
```

### Running Tests

```bash
# All tests
make test

# Specific test file  
julia --project=. -e "using Pkg; Pkg.test()"
```

### Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Code Style

- Follow [Julia style guidelines](https://docs.julialang.org/en/v1/manual/style-guide/)
- Use descriptive variable names
- Add docstrings for public functions
- Write tests for new functionality
- Ensure code passes all CI checks

## 📚 Documentation

- **[Getting Started](https://mansurarief.github.io/EnergyProjectMDP.jl/stable/getting_started/)**: Installation and basic usage
- **[API Reference](https://mansurarief.github.io/EnergyProjectMDP.jl/stable/api/)**: Complete function documentation
- **[Examples](https://mansurarief.github.io/EnergyProjectMDP.jl/stable/examples/basic_usage/)**: Detailed tutorials and use cases

## 📄 Citation

If you use EnergyProjectMDP.jl in your research, please cite:

```bibtex
@software{EnergyProjectMDP2024,
  title = {EnergyProjectMDP.jl: A Julia Package for Energy Resource Allocation Optimization},
  author = {Kinnarkar, Riya, and Arief, Mansur},
  year = {2024},
  url = {https://github.com/mansurarief/EnergyProjectMDP.jl},
  version = {0.1.0}
}
```

## 👥 Authors

- **[Riya Kinnarkar](https://github.com/riyakinnarkar)** - riyakinnarkar@gmail.com
- **[Mansur Arief](https://github.com/mansurarief)** - Stanford University - ariefm@stanford.edu

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built on the excellent [POMDPs.jl](https://github.com/JuliaPOMDP/POMDPs.jl) ecosystem
- MDP solvers from [DiscreteValueIteration.jl](https://github.com/JuliaPOMDP/DiscreteValueIteration.jl) and [MCTS.jl](https://github.com/JuliaPOMDP/MCTS.jl)

---

*For questions, issues, or contributions, please visit our [GitHub repository](https://github.com/mansurarief/EnergyProjectMDP.jl).*