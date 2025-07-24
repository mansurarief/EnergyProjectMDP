# Priority-based Multi-Objective Policy - considers budget efficiency
struct PriorityBasedPolicy <: Policy 
    re_weight::Float64
    equity_weight::Float64
    efficiency_weight::Float64
end

PriorityBasedPolicy() = PriorityBasedPolicy(0.4, 0.4, 0.2)

function POMDPs.action(p::PriorityBasedPolicy, s::State)
    mdp = EnergyMDP()
    valid_actions = actions(mdp, s)
    
    best_action = doNothing()
    best_score = -Inf
    
    for a in valid_actions
        if typeof(a) == newAction && a.actionType == true  # Only consider "add" actions
            city = s.cities[a.cityIndex]
            
            # Calculate multi-objective score
            score = 0.0
            
            # Energy fulfillment priority (efficiency)
            unmet_demand = max(0, city.demand - (city.re_supply + city.nre_supply))
            if unmet_demand > 0
                energy_add = a.energyType ? mdp.supplyOfNRE : mdp.supplyOfRE
                fulfillment_ratio = min(energy_add / unmet_demand, 1.0)
                score += p.efficiency_weight * fulfillment_ratio * 10.0
            end
            
            # Equity priority (low-income cities first)
            if city.income == false  # Low income
                score += p.equity_weight * 8.0
            end
            
            # RE priority
            if a.energyType == false  # Adding RE
                score += p.re_weight * 6.0
            end
            
            # Budget efficiency (cost per GW)
            cost = a.energyType ? mdp.costOfAddingNRE : mdp.costOfAddingRE
            supply = a.energyType ? mdp.supplyOfNRE : mdp.supplyOfRE
            cost_efficiency = supply / cost
            score += cost_efficiency * 0.5
            
            # Population impact (larger cities matter more)
            population_factor = city.population / 1_000_000  # Scale to millions
            score *= (1.0 + population_factor * 0.2)
            
            if score > best_score
                best_score = score
                best_action = a
            end
        end
    end
    
    return best_action
end

# Optimization-Inspired Greedy Policy - maximizes reward improvement per dollar
struct OptimizationGreedyPolicy <: Policy end

function POMDPs.action(p::OptimizationGreedyPolicy, s::State)
    mdp = EnergyMDP()
    valid_actions = actions(mdp, s)
    
    best_action = doNothing()
    best_roi = -Inf
    
    current_reward = reward(mdp, s, doNothing())
    
    for a in valid_actions
        if typeof(a) == newAction && a.actionType == true
            # Calculate reward improvement per dollar spent
            s_next = rand(transition(mdp, s, a))
            future_reward = reward(mdp, s_next, doNothing())
            reward_improvement = future_reward - current_reward
            
            cost = a.energyType ? mdp.costOfAddingNRE : mdp.costOfAddingRE
            roi = reward_improvement / cost
            
            if roi > best_roi
                best_roi = roi
                best_action = a
            end
        end
    end
    
    return best_action
end

# Smart Sequential Policy - follows a strategic sequence
struct SmartSequentialPolicy <: Policy 
    phase_threshold::Float64
end

SmartSequentialPolicy() = SmartSequentialPolicy(0.7)  # Switch phases at 70% budget

function POMDPs.action(p::SmartSequentialPolicy, s::State)
    mdp = EnergyMDP()
    valid_actions = actions(mdp, s)
    
    budget_ratio = s.b / mdp.initialBudget
    
    if budget_ratio > p.phase_threshold
        # Phase 1: Focus on equity (low-income cities first)
        return equity_first_action(valid_actions, s, mdp)
    else
        # Phase 2: Focus on efficiency and RE
        return efficiency_re_action(valid_actions, s, mdp)
    end
end

function equity_first_action(valid_actions::Vector{Action}, s::State, mdp::EnergyMDP)
    # Prioritize low-income cities with unmet demand
    for a in valid_actions
        if typeof(a) == newAction && a.actionType == true
            city = s.cities[a.cityIndex]
            if city.income == false && city.demand > (city.re_supply + city.nre_supply)
                # Prefer cheaper option (NRE) initially for equity
                if a.energyType == true  # NRE is cheaper
                    return a
                end
            end
        end
    end
    
    # Fallback to any equity action
    for a in valid_actions
        if typeof(a) == newAction && a.actionType == true
            city = s.cities[a.cityIndex]
            if city.income == false
                return a
            end
        end
    end
    
    return doNothing()
end

function efficiency_re_action(valid_actions::Vector{Action}, s::State, mdp::EnergyMDP)
    # Focus on RE and highest impact per dollar
    best_action = doNothing()
    best_impact = -Inf
    
    for a in valid_actions
        if typeof(a) == newAction && a.actionType == true && a.energyType == false  # RE only
            city = s.cities[a.cityIndex]
            unmet_demand = max(0, city.demand - (city.re_supply + city.nre_supply))
            
            # Impact = people served + RE bonus
            people_served = min(mdp.supplyOfRE, unmet_demand) * city.population / city.demand
            re_bonus = mdp.supplyOfRE * 100  # Bonus for RE
            impact = people_served + re_bonus
            
            if impact > best_impact
                best_impact = impact
                best_action = a
            end
        end
    end
    
    return best_action
end

# Near-Optimal Heuristic - tries to approximate optimal behavior
struct NearOptimalPolicy <: Policy 
    lookahead_depth::Int
end

NearOptimalPolicy() = NearOptimalPolicy(2)

function POMDPs.action(p::NearOptimalPolicy, s::State)
    mdp = EnergyMDP()
    valid_actions = actions(mdp, s)
    
    best_action = doNothing()
    best_value = -Inf
    
    for a in valid_actions
        value = evaluate_action_lookahead(mdp, s, a, p.lookahead_depth)
        if value > best_value
            best_value = value
            best_action = a
        end
    end
    
    return best_action
end

function evaluate_action_lookahead(mdp::EnergyMDP, s::State, a::Action, depth::Int)
    if depth == 0 || isterminal(mdp, s)
        return reward(mdp, s, a)
    end
    
    s_next = rand(transition(mdp, s, a))
    immediate_reward = reward(mdp, s, a)
    
    # Simple greedy lookahead for future value
    future_actions = actions(mdp, s_next)
    future_value = 0.0
    
    if !isempty(future_actions)
        # Take best immediate future action
        best_future_reward = -Inf
        for future_a in future_actions
            future_reward = evaluate_action_lookahead(mdp, s_next, future_a, depth - 1)
            if future_reward > best_future_reward
                best_future_reward = future_reward
            end
        end
        future_value = best_future_reward
    end
    
    return immediate_reward + mdp.discountRate * future_value
end



# Random Policy - Baseline benchmark
struct RandomEnergyPolicy <: Policy
    rng::AbstractRNG
end

RandomEnergyPolicy() = RandomEnergyPolicy(Random.GLOBAL_RNG)

function POMDPs.action(p::RandomEnergyPolicy, s::State)
    mdp = EnergyMDP()
    valid_actions = actions(mdp, s)
    return rand(p.rng, valid_actions)
end

# Greedy Renewable Policy - Always add renewable energy to cities with highest unmet demand
struct GreedyREPolicy <: Policy end

function POMDPs.action(p::GreedyREPolicy, s::State)
    mdp = EnergyMDP()
    valid_actions = actions(mdp, s)
    
    # First priority: Add RE to cities with unmet demand
    best_action = doNothing()
    best_unmet_demand = -Inf
    
    for a in valid_actions
        if typeof(a) == newAction && a.energyType == false && a.actionType == true
            # This is an "add RE" action
            city = s.cities[a.cityIndex]
            unmet_demand = city.demand - (city.re_supply + city.nre_supply)
            
            # Prioritize low-income cities
            if city.income == 0
                unmet_demand *= 2.0
            end
            
            if unmet_demand > best_unmet_demand
                best_unmet_demand = unmet_demand
                best_action = a
            end
        end
    end
    
    return best_action
end

# Balanced Policy - Try to maintain a balance between RE and NRE while meeting demand
struct BalancedEnergyPolicy <: Policy 
    re_target_ratio::Float64  # Target ratio of RE to total supply
end

BalancedEnergyPolicy() = BalancedEnergyPolicy(0.5)  # Default 50% RE target

function POMDPs.action(p::BalancedEnergyPolicy, s::State)
    mdp = EnergyMDP()
    valid_actions = actions(mdp, s)
    
    # Calculate current RE ratio for each city
    best_action = doNothing()
    best_score = -Inf
    
    for a in valid_actions
        if typeof(a) == newAction && a.actionType == true  # Only consider "add" actions
            city = s.cities[a.cityIndex]
            current_re_ratio = city.re_supply / (city.re_supply + city.nre_supply + 1e-6)
            unmet_demand = city.demand - (city.re_supply + city.nre_supply)
            
            # Score based on: meeting demand + achieving RE target ratio
            score = 0.0
            
            if unmet_demand > 0
                score += 10.0  # High priority for unmet demand
                
                # Extra points for low-income cities
                if city.income == 0
                    score += 5.0
                end
            end
            
            # Add score based on moving towards target RE ratio
            if a.energyType == false  # Adding RE
                new_re_ratio = (city.re_supply + mdp.supplyOfRE) / (city.re_supply + mdp.supplyOfRE + city.nre_supply)
                score += 5.0 * (1.0 - abs(new_re_ratio - p.re_target_ratio))
            else  # Adding NRE
                new_re_ratio = city.re_supply / (city.re_supply + city.nre_supply + mdp.supplyOfNRE)
                score += 5.0 * (1.0 - abs(new_re_ratio - p.re_target_ratio))
            end
            
            if score > best_score
                best_score = score
                best_action = a
            end
        end
    end
    
    return best_action
end

# Equity-First Policy - Prioritize low-income cities
struct EquityFirstPolicy <: Policy end

function POMDPs.action(p::EquityFirstPolicy, s::State)
    mdp = EnergyMDP()
    valid_actions = actions(mdp, s)
    
    # First, check low-income cities with unmet demand
    for a in valid_actions
        if typeof(a) == newAction && a.actionType == true
            city = s.cities[a.cityIndex]
            if city.income == 0 && city.demand > (city.re_supply + city.nre_supply)
                # Prefer RE for low-income cities
                if a.energyType == false
                    return a
                end
            end
        end
    end
    
    # If all low-income cities are satisfied, help high-income cities with RE
    for a in valid_actions
        if typeof(a) == newAction && a.energyType == false && a.actionType == true
            city = s.cities[a.cityIndex]
            if city.demand > (city.re_supply + city.nre_supply)
                return a
            end
        end
    end
    
    return doNothing()
end