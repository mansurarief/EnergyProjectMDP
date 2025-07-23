using EnergyProjectMDP
using POMDPs
using POMDPTools
using Random
using Distributions


rng = MersenneTwister(1234) #setting the random seed for reproducibility
p = EnergyMDP()
s0 = rand(rng, initialstate(p))


# Manual simulation
println("=== Manual Simulation ===")
s = s0
for step in 1:5
    # Pick an action (add RE to random city)
    city_idx = rand(rng, 1:p.numberOfCities)
    a = newAction(energyType=false, actionType=true, cityIndex=city_idx)
    
    # Transition
    sp = rand(transition(p, s, a))
    r = reward(p, s, a)
    
    println("Step $step: Add RE to city $city_idx")
    println("  Budget: $(s.b) -> $(sp.b)")
    println("  City $city_idx RE: $(s.cities[city_idx].re_supply) -> $(sp.cities[city_idx].re_supply)")
    println("  Reward: $r")
    println()
    
    s = sp
    
    if isterminal(p, s)
        println("Terminal state reached!")
        break
    end
end

# Final analysis
println("=== Final State Analysis ===")
total_re = sum([city.re_supply for city in s.cities])
total_nre = sum([city.nre_supply for city in s.cities])
total_demand = sum([city.demand for city in s.cities])
total_supply = total_re + total_nre

println("Total renewable supply: $total_re GWh")
println("Total non-renewable supply: $total_nre GWh")
println("Total supply: $total_supply GWh")
println("Total demand: $total_demand GWh")
println("Supply deficit: $(total_demand - total_supply) GWh")
println()

# City breakdown
println("=== City Breakdown ===")
for (i, city) in enumerate(s.cities)
    supply = city.re_supply + city.nre_supply
    deficit = max(0, city.demand - supply)
    income_status = city.income ? "High" : "Low"
    println("$i. $(city.name) ($income_status income)")
    println("   Demand: $(city.demand) GWh")
    println("   Supply: $supply GWh (RE: $(city.re_supply), NRE: $(city.nre_supply))")
    println("   Deficit: $deficit GWh")
end



# Action items for Riya: create your own policy, and run it, and report the rewards

function my_policy(state::State, mdp::EnergyMDP)
    deficits = [(city.demand - city.re_supply - city.nre_supply, i) for (i, city) in enumerate(state.cities)]
    sorted_deficits = sort(deficits, by = x -> -x[1])  # descending order by deficit
    city_idx = sorted_deficits[1][2]  # city index with largest deficit
    return newAction(energyType=false, actionType=true, cityIndex=city_idx)
end

# --- Policy-driven simulation ---
println("=== Policy-driven Simulation ===")

s0 = rand(rng, initialstate(p))
s = s0   # reset to initial state
total_reward = 0.0
max_steps = 10  # limit number of steps so it won't run forever

for step in 1:max_steps
    a = my_policy(s, p)                   # get action from policy
    sp = rand(transition(p, s, a))       # apply action and get new state
    r = reward(p, s, a)                   # calculate reward
    
    println("Step $step: Add RE to city $(a.cityIndex)")
    println("  Budget: $(s.b) -> $(sp.b)")
    println("  City $(a.cityIndex) RE: $(s.cities[a.cityIndex].re_supply) -> $(sp.cities[a.cityIndex].re_supply)")
    println("  Reward: $r\n")
    
    s = sp
    total_reward += r
    
    if isterminal(p, s)
        println("Terminal state reached at step $step")
        break
    end
end

println("Total reward over $(step) steps: $total_reward")
