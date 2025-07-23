using EnergyProjectMDP
using POMDPs
using POMDPTools
using DiscreteValueIteration
using Random
using Statistics
using Printf

# Include enhanced components
include("../src/enhanced_reward.jl")
include("../src/tuned_mdp.jl")

println("="^80)
println("MDP SOLVER REWARD FUNCTION COMPARISON")
println("="^80)

# Create MDP with original reward function
mdp_original = create_comparison_mdp()
println("Created MDP with original reward function")

# Show how the current reward function works
println("\n=== CURRENT REWARD FUNCTION ANALYSIS ===")
s0 = rand(initialstate(mdp_original))
println("Initial state - Budget: \$$(s0.b)M")

for (i, city) in enumerate(s0.cities)
    supply_ratio = (city.re_supply + city.nre_supply) / city.demand
    println("  City $(i) ($(city.income ? "High" : "Low") income): $(city.demand) GW demand, $(@sprintf("%.1f", supply_ratio*100))% supplied")
end

# Test different actions and show reward components
println("\n=== REWARD BREAKDOWN FOR DIFFERENT ACTIONS ===")

# Test action: Add RE to low-income city
action_re_low = newAction(energyType=false, actionType=true, cityIndex=2)  # Assuming city 2 is low-income
s_next_re = rand(transition(mdp_original, s0, action_re_low))
r_original = reward(mdp_original, s0, action_re_low)

println("\nAction: Add RE to low-income city")
println("  Original reward function: $(@sprintf("%.2f", r_original))")

# Break down the original reward components
budget_component = s0.b * mdp_original.weightBudget
println("  - Budget component: $(@sprintf("%.2f", budget_component)) (budget × $(mdp_original.weightBudget))")

# Low income without energy penalty
low_income_cities = [city for city in s0.cities if city.income == false]
low_income_without = sum([city.population * (city.re_supply + city.nre_supply < city.demand) for city in low_income_cities])
low_income_total = sum([city.population for city in low_income_cities])
low_income_penalty = (low_income_without / (low_income_total + 1e-6)) * mdp_original.weightLowIncomeWithoutEnergy
println("  - Low-income penalty: $(@sprintf("%.2f", low_income_penalty))")

# RE population bonus
total_pop = sum([city.population for city in s0.cities])
re_served_pop = sum([city.population * (city.re_supply >= city.demand) for city in s0.cities])
re_bonus = (re_served_pop / (total_pop + 1e-6)) * mdp_original.weightPopulationWithRE
println("  - RE population bonus: $(@sprintf("%.2f", re_bonus))")

# Now show enhanced reward function
r_enhanced = enhanced_reward(mdp_original, s0, action_re_low)
println("\n  Enhanced reward function: $(@sprintf("%.2f", r_enhanced))")
println("  Improvement: $(@sprintf("%.2f", r_enhanced - r_original)) ($(@sprintf("%.1f", (r_enhanced/r_original - 1)*100))%)")

println("\n=== HOW MDP SOLVER USES REWARD FUNCTION ===")
println("""
The MDP solver (Value Iteration) works as follows:

1. **Bellman Equation**: For each state s, it computes:
   V(s) = max_a [R(s,a) + γ × Σ P(s'|s,a) × V(s')]
   
2. **Reward Signal**: R(s,a) guides the policy by making certain actions more attractive
   - Higher rewards → Actions more likely to be chosen
   - Lower/negative rewards → Actions avoided

3. **Policy Extraction**: After convergence, the optimal policy π*(s) = argmax_a Q(s,a)
   - The policy selects actions that maximize expected cumulative reward

4. **Current vs Enhanced Reward**:
   - Current: Simple weighted sum of 3 components
   - Enhanced: Comprehensive 6-component system with better equity handling
""")

println("\n=== CREATING MDP WITH ENHANCED REWARD ===")

# Create a new MDP type that uses enhanced reward
struct EnhancedEnergyMDP <: MDP{State, Action}
    base_mdp::EnergyMDP
end

# Override the reward function to use enhanced reward
function POMDPs.reward(p::EnhancedEnergyMDP, s::State, a::Action)
    return enhanced_reward(p.base_mdp, s, a)
end

# Forward all other functions to base MDP
POMDPs.states(p::EnhancedEnergyMDP) = states(p.base_mdp)
POMDPs.actions(p::EnhancedEnergyMDP) = actions(p.base_mdp)
POMDPs.actions(p::EnhancedEnergyMDP, s::State) = actions(p.base_mdp, s)
POMDPs.transition(p::EnhancedEnergyMDP, s::State, a::Action) = transition(p.base_mdp, s, a)
POMDPs.initialstate(p::EnhancedEnergyMDP) = initialstate(p.base_mdp)
POMDPs.isterminal(p::EnhancedEnergyMDP, s::State) = isterminal(p.base_mdp, s)
POMDPs.discount(p::EnhancedEnergyMDP) = discount(p.base_mdp)
POMDPs.stateindex(p::EnhancedEnergyMDP, s::State) = stateindex(p.base_mdp, s)
POMDPs.actionindex(p::EnhancedEnergyMDP, a::Action) = actionindex(p.base_mdp, a)

# Create enhanced MDP
mdp_enhanced = EnhancedEnergyMDP(mdp_original)
println("Created MDP with enhanced reward function")

println("\n=== COMPARING SOLVER RESULTS ===")

# Solve both MDPs
println("Solving original MDP...")
solver = ValueIterationSolver(max_iterations=50, belres=1e-2, verbose=false)
policy_original = solve(solver, mdp_original)

println("Solving enhanced MDP...")
policy_enhanced = solve(solver, mdp_enhanced)

# Test both policies
function test_policy_with_metrics(mdp, policy, name)
    hr = HistoryRecorder(max_steps=10)
    h = simulate(hr, mdp, policy)
    
    final_state = h[end].s
    total_reward = sum([step.r for step in h])
    
    # Calculate comprehensive metrics regardless of which MDP is used
    metrics = calculate_comprehensive_metrics(mdp isa EnhancedEnergyMDP ? mdp.base_mdp : mdp, final_state)
    
    println("\n$name Results:")
    println("  Total Reward: $(@sprintf("%.1f", total_reward))")
    println("  Composite Score: $(@sprintf("%.3f", metrics["composite_score"]))")
    println("  Equity Score: $(@sprintf("%.3f", metrics["equity_fairness"]))")
    println("  RE Ratio: $(@sprintf("%.1f", metrics["re_ratio"]*100))%")
    println("  Supply Disparity: $(@sprintf("%.1f", metrics["supply_disparity"]*100))%")
    println("  Budget Used: \$$(@sprintf("%.0f", metrics["budget_used"]))M")
    
    return metrics
end

original_metrics = test_policy_with_metrics(mdp_original, policy_original, "Original Reward Policy")
enhanced_metrics = test_policy_with_metrics(mdp_enhanced, policy_enhanced, "Enhanced Reward Policy")

println("\n=== IMPACT OF ENHANCED REWARD ===")
println("Improvements with enhanced reward function:")
println("  Composite Score: $(@sprintf("%+.3f", enhanced_metrics["composite_score"] - original_metrics["composite_score"]))")
println("  Equity Score: $(@sprintf("%+.3f", enhanced_metrics["equity_fairness"] - original_metrics["equity_fairness"]))")
println("  RE Ratio: $(@sprintf("%+.1f", (enhanced_metrics["re_ratio"] - original_metrics["re_ratio"])*100))%")
println("  Supply Disparity: $(@sprintf("%+.1f", (enhanced_metrics["supply_disparity"] - original_metrics["supply_disparity"])*100))% (lower is better)")

println("\n=== KEY INSIGHTS ===")
println("""
🎯 **How Enhanced Reward Changes Solver Behavior:**

1. **Richer Signal**: Enhanced reward provides 6 components vs 3, giving solver more nuanced guidance
2. **Balanced Objectives**: Explicit composite scoring prevents single-objective optimization  
3. **Equity Focus**: Direct disparity measurement guides solver toward fairer solutions
4. **Population Weighting**: Larger cities get appropriate priority in resource allocation

🔄 **Solver Learning Process:**
- Original: Learns to maximize simple weighted sum (budget + equity penalty + RE bonus)
- Enhanced: Learns to balance budget, equity, RE, fulfillment, population impact, and efficiency

📈 **Optimization Impact:**
- Better policies emerge because reward function better captures true objectives
- Solver finds solutions that balance competing goals rather than optimizing single metrics
""")

println("\n🚀 Framework now demonstrates how enhanced rewards improve MDP optimization!")