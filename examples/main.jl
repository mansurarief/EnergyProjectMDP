include("../src/mdp.jl")

hello_world()

# we can create struct as an object

using Parameters

@with_kw mutable struct City
    demand::Float64
    re_supply::Float64
    nre_supply::Float64
    population::Float64
    income::Bool
end



atlanta = City(10.0, 0.0, 8.0, 4e6, 1)

stanford = City(demand=12.0, re_supply=0.0, nre_supply=8.0, population=4e6, income = 0)


total_demands = atlanta.demand + stanford.demand
cities = [atlanta, stanford]
sum([city.demand for city in cities])

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

function calc_nre_percentage(s::State)
    eps = 0.000001
    total_demands = sum([city.demand for city in s.cities])
    total_nres = sum([city.nre_supply for city in s.cities])
    return total_nres/(total_demands + eps)
end

function calc_re_percentage(s::State)
    eps = 0.000001
    total_demands = sum([city.demand for city in s.cities])
    total_re = sum([city.re_supply for city in s.cities])
    return total_re/(total_demands + eps)
end


s0 = State(b=10e6, total_demand=0.0, cities = [atlanta, stanford])


calc_nre_percentage(s0)

calc_re_percentage(s0)

#plot and pkg are like parameters
using Pkg; Pkg.add("Plots")
using Plots; plot([1,2,3,4,5], [10,20,15,25,18])


bar([stanford.demand, atlanta.demand])


bar([city.nre_supply for city in s0.cities])

function percentageOfLowIncomePopulation(s::State)
    totalPopulation = sum([city.population for city in s.cities])
    lowIncomePopulation = sum([city.population * (city.income == 0) for city in s.cities])
    percentage = lowIncomePopulation/totalPopulation
end

percentageOfLowIncomePopulation(s0)


@with_kw mutable struct energyParameters
    numberOfCities::Int64 = 2
    costOfAddingRE::Float64 = 2.0
    costOfAddingNRE::Float64 = 1.5
    costOfRemovingRE::Float64 = 1.2
    costOfRemovingNRE::Float64 = 1.4
    operatingCostRE::Vector{Float64} = [.0015, 0.002]
    operatingCostNRE::Vector{Float64} = [0.001, 0.0015]
    supplyOfRE::Float64 = 200
    supplyOfNRE::Float64 = 200
end

MDPproblem = energyParameters()

function transition(p::energyParameters, s::State, a::Union{newAction,doNothing})
    if (a.energyType==0 && a.actionType == 1)
        bp = s.b - p.costOfAddingRE - sum([(city.re_supply + p.supplyOfRE) * p.operatingCostRE[i] + p.operatingCostNRE[i] * city.nre_supply for (i,city) in enumerate(s.cities)]) 

    # newCities = deepcopy(s.cities)
    # newCities = [city.re_supply = city.re_supply + p.supplyOfRE]
        sp = State(b = bp, cities = s.cities, total_demand = s.total_demand)
        return sp
    else 
        return s
    end
end


a0 = doNothing()
s1 = transition(MDPproblem, s0, a0)

a1 = newAction(0,1)
s2 = transition(MDPproblem, s1, a1)