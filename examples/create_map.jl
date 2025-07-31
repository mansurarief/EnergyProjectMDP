#!/usr/bin/env julia

"""
Create Map Example: Generate Beautiful Energy Distribution Maps

This example demonstrates how to create geographic visualizations
of energy distribution across US cities using the enhanced map features.
"""

using EnergyProjectMDP
using POMDPs
using Random
using Plots

println("=ú  Create Map Example")
println("="^50)

# Initialize the environment
rng = MersenneTwister(1234)
mdp = initialize_mdp(rng)

println("\n=Ë Creating different map scenarios...")
println("-"^40)

# Scenario 1: Initial state map
println("\n1ã Initial State Map")
initial_state = rand(rng, initialstate(mdp))

create_city_map(mdp, initial_state, 
    filename="maps/initial_state_map.png",
    title="Initial Energy Distribution")

# Scenario 2: After applying equity-first policy
println("\n2ã Equity-First Policy Results")
equity_policy = EquityFirstPolicy()

# Run simulation for several steps
current_state = deepcopy(initial_state)
for step in 1:8
    if !isterminal(mdp, current_state)
        action = POMDPs.action(equity_policy, current_state)
        current_state = rand(rng, transition(mdp, current_state, action))
    end
end

create_city_map(mdp, current_state,
    filename="maps/equity_policy_map.png", 
    title="After Equity-First Policy (8 steps)")

# Scenario 3: Renewable energy focused
println("\n3ã Renewable Energy Focus")
re_policy = GreedyREPolicy()

# Run simulation
current_state = deepcopy(initial_state)
for step in 1:8
    if !isterminal(mdp, current_state)
        action = POMDPs.action(re_policy, current_state)
        current_state = rand(rng, transition(mdp, current_state, action))
    end
end

create_city_map(mdp, current_state,
    filename="maps/renewable_focus_map.png",
    title="After Renewable Energy Policy (8 steps)")

# Scenario 4: Create a custom scenario
println("\n4ã Custom Scenario - Energy Crisis")

# Create a state with high energy deficits
crisis_cities = [
    City(name="New York City", demand=55.0, re_supply=2.0, nre_supply=10.0, 
         population=8_000_000, income=true),
    City(name="Los Angeles", demand=45.0, re_supply=5.0, nre_supply=8.0,
         population=4_000_000, income=true),
    City(name="Chicago", demand=30.0, re_supply=1.0, nre_supply=5.0,
         population=2_700_000, income=true),
    City(name="Detroit", demand=15.0, re_supply=0.5, nre_supply=2.0,
         population=700_000, income=false),
    City(name="Miami", demand=20.0, re_supply=3.0, nre_supply=4.0,
         population=450_000, income=false),
    City(name="Phoenix", demand=25.0, re_supply=8.0, nre_supply=3.0,
         population=1_600_000, income=true)
]

crisis_state = State(
    b=300.0,
    total_demand=sum([c.demand for c in crisis_cities]),
    cities=crisis_cities
)

create_city_map(mdp, crisis_state,
    filename="maps/energy_crisis_map.png",
    title="Energy Crisis Scenario - Major Deficits")

# Scenario 5: Success scenario
println("\n5ã Success Scenario - Renewable Transition")

success_cities = [
    City(name="Seattle", demand=20.0, re_supply=18.0, nre_supply=3.0,
         population=750_000, income=true),
    City(name="San Francisco", demand=25.0, re_supply=22.0, nre_supply=4.0,
         population=880_000, income=true),
    City(name="Denver", demand=15.0, re_supply=14.0, nre_supply=2.0,
         population=720_000, income=true),
    City(name="Atlanta", demand=18.0, re_supply=10.0, nre_supply=9.0,
         population=500_000, income=false),
    City(name="Houston", demand=35.0, re_supply=20.0, nre_supply=16.0,
         population=2_300_000, income=false),
    City(name="Boston", demand=22.0, re_supply=15.0, nre_supply=8.0,
         population=690_000, income=true)
]

success_state = State(
    b=100.0,
    total_demand=sum([c.demand for c in success_cities]),
    cities=success_cities
)

create_city_map(mdp, success_state,
    filename="maps/renewable_success_map.png",
    title="Renewable Energy Success Story")

# Create comparison visualization
println("\n=Ê Creating Comparison Visualization")

# Note: Since create_city_map saves files, we'll create a summary instead
println("\n=È Summary Statistics")
println("-"^40)

scenarios = [
    ("Initial", initial_state),
    ("Equity Policy", current_state),
    ("Crisis", crisis_state),
    ("Success", success_state)
]

for (name, state) in scenarios
    total_re = sum([c.re_supply for c in state.cities])
    total_nre = sum([c.nre_supply for c in state.cities])
    total_supply = total_re + total_nre
    total_demand = sum([c.demand for c in state.cities])
    
    re_percent = total_supply > 0 ? round(100 * total_re / total_supply, digits=1) : 0
    deficit = total_demand - total_supply
    
    println("\n$name Scenario:")
    println("  Total Demand: $(round(total_demand, digits=1)) GWh")
    println("  Total Supply: $(round(total_supply, digits=1)) GWh")
    println("  Renewable %: $re_percent%")
    println("  Energy Deficit: $(round(deficit, digits=1)) GWh")
    
    # Count unserved low-income cities
    low_income_unserved = 0
    for city in state.cities
        if !city.income && (city.re_supply + city.nre_supply < city.demand)
            low_income_unserved += 1
        end
    end
    println("  Low-income cities with deficit: $low_income_unserved")
end

# Tips for using the map visualization
println("\n=¡ Map Visualization Tips")
println("-"^40)
println("1. Circle size represents total energy supply (RE + NRE)")
println("2. Red circles = High-income cities, Blue = Low-income cities")
println("3. Numbers inside large circles show: Total GWh / RE%")
println("4. City names appear above circles for clarity")
println("5. Background shows simplified US boundaries")
println()
println("=Á Maps saved in 'maps/' directory (create it first!)")
println()

# Advanced customization example
println("<¨ Advanced Customization Example")
println("-"^40)

# You can also create custom visualizations by modifying the state
custom_state = deepcopy(initial_state)

# Example: Double renewable energy in all low-income cities
for city in custom_state.cities
    if !city.income
        city.re_supply *= 2
    end
end

create_city_map(mdp, custom_state,
    filename="maps/custom_equity_boost.png",
    title="Scenario: Double RE in Low-Income Cities")

println("\n Map examples completed!")
println("Check the 'maps/' directory for generated visualizations.")

# Create the maps directory if it doesn't exist
try
    mkpath("maps")
    println("\n=Á Created 'maps' directory for output files.")
catch e
    println("\n   Could not create 'maps' directory: $e")
end

println("\n" * "="^50)
println("<‰ Create Map Example Completed!")
println("Experiment with different scenarios and customizations!")
println("="^50)