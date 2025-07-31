# API Reference

## Core Types

```@docs
City
State
newAction
doNothing
Action
EnergyMDP
```

## MDP Functions

```@docs
initialize_mdp
POMDPs.transition
POMDPs.reward
POMDPs.initialstate
POMDPs.actions
POMDPs.states
POMDPs.isterminal
POMDPs.discount
```

## Policies

```@docs
RandomEnergyPolicy
EquityFirstPolicy
GreedyREPolicy
BalancedEnergyPolicy
PriorityBasedPolicy
ExpertPolicy
```

## Evaluation and Analysis

```@docs
evaluate_policy_comprehensive
print_policy_comparison
calculate_comprehensive_metrics
eval_reward
decompose_reward
analyze_reward_trajectory
```

## Visualization

```@docs
create_city_map
create_policy_comparison_chart
create_energy_distribution_pie
create_equity_analysis
create_simulation_trajectory
generate_comprehensive_report
```

## Index

```@index
Pages = ["api.md"]
```