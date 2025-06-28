include("../src/mdp.jl")

hello_world()

a = 1
b = 10
a + b

# we can create struct as an object

using Parameters

struct Region
    demand::Float64
    re_supply::Float64
    nre_supply::Float64
    population::Float64
end

# atlanta = Region(demand=10.0, re_supply=0.0, nre_supply=8.0, population=4e6)

atlanta = Region(10.0, 0.0, 8.0, 4e6)

atlanta.demand


@with_kw mutable struct City
    demand::Float64
    re_supply::Float64
    nre_supply::Float64
    population::Float64
end



atlanta = City(10.0, 0.0, 8.0, 4e6)

stanford = City(demand=12.0, re_supply=0.0, nre_supply=8.0, population=4e6)


total_demands = atlanta.demand + stanford.demand
cities = [atlanta, stanford]
sum([city.demand for city in cities])



@with_kw struct State 
    b::Float64
    total_demand::Float64
    cities::Vector{City}
end


function calc_nre_percentage(s::State)
    eps = 0.000001
    total_demands = sum([city.demand for city in s.cities])
    total_nres = sum([city.nre_supply for city in s.cities])
    return total_nres/(total_demands + eps)
end


s0 = State(b=10e6, total_demand=0.0, cities = [atlanta, stanford])


calc_nre_percentage(s0)

