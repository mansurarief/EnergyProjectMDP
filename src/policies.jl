# Policy implementations for EnergyMDP

using POMDPs
using POMDPTools
using Random

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

# Export all policies
export RandomEnergyPolicy, GreedyREPolicy, BalancedEnergyPolicy, EquityFirstPolicy