
function hello_world()
    print("Hello World")
end


@with_kw mutable struct City
    demand::Float64
    re_supply::Float64
    nre_supply::Float64
    population::Float64
    income::Bool
end

@with_kw struct State 
    b::Float64
    total_demand::Float64
    cities::Vector{City}
    
end

@with_kw struct newAction
    energyType::Bool #0 is RE, 1 is NRE
    actionType::Bool  #0 is remove, 1 is add
end

@with_kw struct doNothing
    energyType::Int64 = -1
    actionType::Int64 = -1
end

const Action = Union{newAction, doNothing}

@with_kw mutable struct EnergyMDP 
    numberOfCities::Int64 = 2
    costOfAddingRE::Float64 = 2.0
    costOfAddingNRE::Float64 = 1.5
    costOfRemovingRE::Float64 = 1.2
    costOfRemovingNRE::Float64 = 1.4
    operatingCostRE::Vector{Float64} = [.0015, 0.002]
    operatingCostNRE::Vector{Float64} = [0.001, 0.0015]
    supplyOfRE::Float64 = 200
    supplyOfNRE::Float64 = 200
    weightBudget::Float64 = 0.5 # maximize remaining budget
    weightLowIncomeWithoutEnergy::Float64 = -10.0 # minimize low income population without energy
    weightPopulationWithRE::Float64 = 5.0 # maximize population with RE
end

function transition(p::EnergyMDP, s::State, a::Action)

    # if action is adding (a.actionType==1) renewable energy (a.energyType==0)
    if (a.energyType==0 && a.actionType == 1)
        # calculate new budget after adding renewable energy
        bp = s.b - p.costOfAddingRE - sum([(city.re_supply + p.supplyOfRE) * p.operatingCostRE[i] + p.operatingCostNRE[i] * city.nre_supply for (i,city) in enumerate(s.cities)]) 

        # update the cities with the new renewable energy supply
        newCities = deepcopy(s.cities)
        for (i, city) in enumerate(newCities)
            newCities[i] = City(demand = city.demand,
                                re_supply = city.re_supply + p.supplyOfRE,
                                nre_supply = city.nre_supply,
                                population = city.population,
                                income = city.income)
        end
        # create a new state with the updated budget and cities
        sp = State(b = bp, cities = newCities, total_demand = s.total_demand)
        return sp

    else if (a.energyType==1 && a.actionType == 1) #adding NRE
        # if action is adding non-renewable energy
        bp = s.b - p.costOfAddingNRE - sum([(city.re_supply) * p.operatingCostRE[i] + (city.nre_supply + p.supplyOfNRE) * p.operatingCostNRE[i] for (i,city) in enumerate(s.cities)]) 

        # update the cities with the new non-renewable energy supply
        newCities = deepcopy(s.cities)
        for (i, city) in enumerate(newCities)
            newCities[i] = City(demand = city.demand,
                                re_supply = city.re_supply,
                                nre_supply = city.nre_supply + p.supplyOfNRE,
                                population = city.population,
                                income = city.income)
        end
        # create a new state with the updated budget and cities
        sp = State(b = bp, cities = newCities, total_demand = s.total_demand)
        return sp
    
    else if (a.energyType==0 && a.actionType == 0) #removing RE
        # if action is removing renewable energy
        bp = s.b + p.costOfRemovingRE - sum([(city.re_supply - p.supplyOfRE) * p.operatingCostRE[i] + city.nre_supply * p.operatingCostNRE[i] for (i,city) in enumerate(s.cities)]) 

        # update the cities with the new renewable energy supply
        newCities = deepcopy(s.cities)
        for (i, city) in enumerate(newCities)
            newCities[i] = City(demand = city.demand,
                                re_supply = city.re_supply - p.supplyOfRE,
                                nre_supply = city.nre_supply,
                                population = city.population,
                                income = city.income)
        end
        # create a new state with the updated budget and cities
        sp = State(b = bp, cities = newCities, total_demand = s.total_demand)
        return sp

    else if (a.energyType==1 && a.actionType == 0) #removing NRE
        # if action is removing non-renewable energy

        bp = s.b + p.costOfRemovingNRE - sum([(city.re_supply) * p.operatingCostRE[i] + (city.nre_supply - p.supplyOfNRE) * p.operatingCostNRE[i] for (i,city) in enumerate(s.cities)])
        # update the cities with the new non-renewable energy supply
        newCities = deepcopy(s.cities)
        for (i, city) in enumerate(newCities)
            newCities[i] = City(demand = city.demand,
                                re_supply = city.re_supply,
                                nre_supply = city.nre_supply - p.supplyOfNRE, 
                                population = city.population,
                                income = city.income)
        end
        # create a new state with the updated budget and cities
        sp = State(b = bp, cities = newCities, total_demand = s.total_demand)
        return sp
        
    else
        # if action is do nothing
        sp = State(b = s.b, cities = deepcopy(s.cities), total_demand = s.total_demand)
        return sp
    end
end


function reward(p::EnergyMDP, s::State, a::Action)
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

