function POMDPs.transition(p::EnergyMDP, s::State, a::Action)

    # if action is adding (a.actionType==1) renewable energy (a.energyType==0)
    if (a.energyType==0 && a.actionType == 1)
        # calculate new budget after adding renewable energy
        bp = s.b - p.costOfAddingRE - sum([(city.re_supply + p.supplyOfRE) * p.operatingCostRE[i] + p.operatingCostNRE[i] * city.nre_supply for (i,city) in enumerate(s.cities)]) 

        # update the cities with the new renewable energy supply
        newCities = deepcopy(s.cities)
        for (i, city) in enumerate(newCities)
            if (i == a.cityIndex) # only update the city specified in the action
                # if action is adding renewable energy
                newCities[i] = City(demand = city.demand,
                                    name = city.name,
                                    re_supply = city.re_supply + p.supplyOfRE,
                                    nre_supply = city.nre_supply,
                                    population = city.population,
                                    income = city.income)       
            else
                newCities[i] = city # keep other cities unchanged    
            end
        end
        # create a new state with the updated budget and cities
        sp = State(b = bp, cities = newCities, total_demand = s.total_demand)
        return Deterministic(sp)

    elseif (a.energyType==1 && a.actionType == 1) #adding NRE
        # if action is adding non-renewable energy
        bp = s.b - p.costOfAddingNRE - sum([(city.re_supply) * p.operatingCostRE[i] + (city.nre_supply + p.supplyOfNRE) * p.operatingCostNRE[i] for (i,city) in enumerate(s.cities)]) 

        # update the cities with the new non-renewable energy supply
        newCities = deepcopy(s.cities)
        for (i, city) in enumerate(newCities)
            if (i == a.cityIndex) # only update the city specified in the action
                # if action is adding non-renewable energy
                newCities[i] = City(demand = city.demand,
                                    name = city.name,
                                    re_supply = city.re_supply,
                                    nre_supply = city.nre_supply + p.supplyOfNRE,
                                    population = city.population,
                                    income = city.income)
            else
                newCities[i] = city # keep other cities unchanged    
            end
        end
        
        # create a new state with the updated budget and cities
        sp = State(b = bp, cities = newCities, total_demand = s.total_demand)
        return Deterministic(sp)
    
    elseif (a.energyType==0 && a.actionType == 0) #removing RE
        # if action is removing renewable energy
        bp = s.b + p.costOfRemovingRE - sum([(city.re_supply - p.supplyOfRE) * p.operatingCostRE[i] + city.nre_supply * p.operatingCostNRE[i] for (i,city) in enumerate(s.cities)]) 

        # update the cities with the new renewable energy supply
        newCities = deepcopy(s.cities)
        for (i, city) in enumerate(newCities)
            if (i == a.cityIndex) # only update the city specified in the action
                # if action is removing renewable energy
                newCities[i] = City(demand = city.demand,
                                    name = city.name,
                                    re_supply = city.re_supply - p.supplyOfRE,
                                    nre_supply = city.nre_supply,
                                    population = city.population,
                                    income = city.income)
            else
                newCities[i] = city # keep other cities unchanged    
            end
        end
        # create a new state with the updated budget and cities
        sp = State(b = bp, cities = newCities, total_demand = s.total_demand)
        return Deterministic(sp)

    elseif (a.energyType==1 && a.actionType == 0) #removing NRE
        # if action is removing non-renewable energy

        bp = s.b + p.costOfRemovingNRE - sum([(city.re_supply) * p.operatingCostRE[i] + (city.nre_supply - p.supplyOfNRE) * p.operatingCostNRE[i] for (i,city) in enumerate(s.cities)])
        # update the cities with the new non-renewable energy supply
        newCities = deepcopy(s.cities)
        for (i, city) in enumerate(newCities)
            if (i == a.cityIndex) # only update the city specified in the action
                # if action is removing non-renewable energy
                newCities[i] = City(demand = city.demand,
                                    name = city.name,
                                    re_supply = city.re_supply,
                                    nre_supply = city.nre_supply - p.supplyOfNRE,
                                    population = city.population,
                                    income = city.income)
            else
                newCities[i] = city # keep other cities unchanged    
            end
        end
        # create a new state with the updated budget and cities
        sp = State(b = bp, cities = newCities, total_demand = s.total_demand)
        return Deterministic(sp)
        
    else
        # if action is do nothing
        sp = State(b = s.b, cities = deepcopy(s.cities), total_demand = s.total_demand)
        return Deterministic(sp)
    end
end



function POMDPs.reward(p::EnergyMDP, s::State, a::Action)
    r = 0.0

    # remaining budget (+)
    r += s.b * p.weightBudget

    # low income population without energy (-)
    populationLowIncomeWithoutEnergy = sum([city.population * (city.income == 0 && city.re_supply +  city.nre_supply < city.demand) for city in s.cities])
    populationLowIncome = sum([city.population * (city.income == 0) for city in s.cities])
    percentageLowIncomeWithoutEnergy = populationLowIncomeWithoutEnergy / (populationLowIncome + 1e-6)  # avoid division by zero
    r += percentageLowIncomeWithoutEnergy * p.weightLowIncomeWithoutEnergy

    # population with all demands fulfilled with renewable energy (+)
    populationWithRE = sum([city.population * (city.re_supply >= city.demand) for city in s.cities])
    totalPopulation = sum([city.population for city in s.cities])
    percentagePopulationWithRE = populationWithRE / (totalPopulation + 1e-6)
    r += percentagePopulationWithRE * p.weightPopulationWithRE

    return r
end


function POMDPs.isterminal(p::EnergyMDP, s::State)
    # our model stops when the budget is negative or all cities have their demands fulfilled
    if s.b < 0
        return true
    end

    # check if all cities have their demands fulfilled
    allDemandsFulfilled = all([city.re_supply + city.nre_supply >= city.demand for city in s.cities])
    return allDemandsFulfilled
end

function POMDPs.discount(p::EnergyMDP)
    return p.discountRate
end

function POMDPs.initialstate(p::EnergyMDP)
    # create an initial state with the budget and cities
    initialCities = p.cities
    s0 = State(b = p.initialBudget, cities = initialCities, total_demand = sum([city.demand for city in initialCities]))
    return Deterministic(s0)
end

#iterate all actions
function POMDPs.actions(p::EnergyMDP)
    actions = Action[]

    #add do nothing action
    push!(actions, doNothing())

    for i in 1:p.numberOfCities
        # add renewable NRE actions
        push!(actions, newAction(energyType=false, actionType=false, cityIndex=i))
        push!(actions, newAction(energyType=false, actionType=true, cityIndex=i))
        # add non-renewable RE actions
        push!(actions, newAction(energyType=true, actionType=false, cityIndex=i))
        push!(actions, newAction(energyType=true, actionType=true, cityIndex=i))
    end

    return actions
end

function POMDPs.actionindex(p::EnergyMDP, a::Action)
    # find the index of the action in the list of actions
    actions = POMDPs.actions(p)
    for (index, action) in enumerate(actions)
        if action == a
            return index
        end
    end
    return nothing  # action not found
end

# Generate all possible discrete states
function POMDPs.states(p::EnergyMDP)
    states = State[]
    
    # Discretize budget - use fewer budget levels for tractability
    n_budget_levels = min(10, Int(ceil((p.maxBudget - p.minBudget) / p.budgetDiscretization)))
    budget_values = range(p.minBudget, p.maxBudget, length=n_budget_levels)
    
    # Generate states by varying budget and limited city configurations
    for budget in budget_values
        # Original city configuration
        push!(states, State(b = budget, cities = deepcopy(p.cities), 
                           total_demand = sum([city.demand for city in p.cities])))
        
        # Add configurations with single energy additions to keep state space manageable
        n_cities_to_vary = min(2, length(p.cities))  # Only vary first 2 cities
        
        for city_idx in 1:n_cities_to_vary
            # State with added RE to one city
            cities_re = deepcopy(p.cities)
            if cities_re[city_idx].re_supply + p.supplyOfRE <= p.maxEnergyPerCity
                cities_re[city_idx] = City(
                    name = cities_re[city_idx].name,
                    demand = cities_re[city_idx].demand,
                    re_supply = cities_re[city_idx].re_supply + p.supplyOfRE,
                    nre_supply = cities_re[city_idx].nre_supply,
                    population = cities_re[city_idx].population,
                    income = cities_re[city_idx].income
                )
                push!(states, State(b = budget, cities = cities_re, 
                                   total_demand = sum([city.demand for city in cities_re])))
            end
            
            # State with added NRE to one city
            cities_nre = deepcopy(p.cities)
            if cities_nre[city_idx].nre_supply + p.supplyOfNRE <= p.maxEnergyPerCity
                cities_nre[city_idx] = City(
                    name = cities_nre[city_idx].name,
                    demand = cities_nre[city_idx].demand,
                    re_supply = cities_nre[city_idx].re_supply,
                    nre_supply = cities_nre[city_idx].nre_supply + p.supplyOfNRE,
                    population = cities_nre[city_idx].population,
                    income = cities_nre[city_idx].income
                )
                push!(states, State(b = budget, cities = cities_nre, 
                                   total_demand = sum([city.demand for city in cities_nre])))
            end
        end
    end
    
    return unique(states)
end

# Convert state to index for tabular methods
function POMDPs.stateindex(p::EnergyMDP, s::State)
    states_list = states(p)
    
    # First try exact match
    for (idx, state) in enumerate(states_list)
        if abs(state.b - s.b) < 1e-6 && 
           length(state.cities) == length(s.cities) &&
           all(abs(state.cities[i].re_supply - s.cities[i].re_supply) < 1e-6 && 
               abs(state.cities[i].nre_supply - s.cities[i].nre_supply) < 1e-6 
               for i in 1:length(state.cities))
            return idx
        end
    end
    
    # If no exact match, find closest matching state
    min_dist = Inf
    best_idx = 1
    
    for (idx, state) in enumerate(states_list)
        # Calculate distance based on budget and energy supplies
        dist = abs(state.b - s.b)
        for i in 1:length(s.cities)
            dist += abs(state.cities[i].re_supply - s.cities[i].re_supply)
            dist += abs(state.cities[i].nre_supply - s.cities[i].nre_supply)
        end
        
        if dist < min_dist
            min_dist = dist
            best_idx = idx
        end
    end
    
    return best_idx
end

# Check if an action is valid in a given state
function POMDPs.actions(p::EnergyMDP, s::State)
    valid_actions = Action[]
    
    # Always can do nothing
    push!(valid_actions, doNothing())
    
    for i in 1:length(s.cities)
        city = s.cities[i]
        
        # Check if we can add RE (budget and supply constraints)
        if s.b >= p.costOfAddingRE && city.re_supply + p.supplyOfRE <= p.maxEnergyPerCity
            push!(valid_actions, newAction(energyType=false, actionType=true, cityIndex=i))
        end
        
        # Check if we can remove RE
        if city.re_supply >= p.supplyOfRE
            push!(valid_actions, newAction(energyType=false, actionType=false, cityIndex=i))
        end
        
        # Check if we can add NRE
        if s.b >= p.costOfAddingNRE && city.nre_supply + p.supplyOfNRE <= p.maxEnergyPerCity
            push!(valid_actions, newAction(energyType=true, actionType=true, cityIndex=i))
        end
        
        # Check if we can remove NRE
        if city.nre_supply >= p.supplyOfNRE
            push!(valid_actions, newAction(energyType=true, actionType=false, cityIndex=i))
        end
    end
    
    return valid_actions
end


