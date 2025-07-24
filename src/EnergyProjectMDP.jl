module EnergyProjectMDP

using Parameters
using POMDPs
using POMDPTools


include("mdp.jl")
export City,
         State,
         newAction,
         doNothing,
         Action,
         EnergyMDP

include("functions.jl")

include("policies.jl")
export RandomEnergyPolicy,
       GreedyREPolicy,
       BalancedEnergyPolicy,
       EquityFirstPolicy

include("enhanced_policies.jl")
export PriorityBasedPolicy,
       OptimizationGreedyPolicy,
       SmartSequentialPolicy,
       NearOptimalPolicy

include("enhanced_reward.jl")
export calculate_comprehensive_metrics,
       enhanced_reward

include("tuned_mdp.jl")
export create_tuned_mdp,
       create_enhanced_mdp,
       create_comparison_mdp

# Academic components will be included separately in examples

end # module EnergyProjectMDPs
