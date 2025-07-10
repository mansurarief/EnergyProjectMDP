using EnergyProjectMDP

p = EnergyMDP()

atlanta = City(10.0, 0.0, 8.0, 4e6, 1)
stanford = City(demand=12.0, re_supply=0.0, nre_supply=8.0, population=4e6, income = 0)

s0 = State(b=10e6, total_demand=0.0, cities = [atlanta, stanford])
a0 = doNothing()
r0 = reward(p, s0, a0)
println("Initial State: ", s0)
println("Action: ", a0)
println("Reward: ", r0)


s1 = transition(p, s0, a0)
a1 = newAction(0,1)
r1 = reward(p, s1, a1)
println("State after action: ", s1)
println("Action: ", a1)
println("Reward after action: ", r1)

s2 = transition(p, s1, a1)
println("State after action: ", s2)

a2 = newAction(1, 1)
s3 = transition(p, s2, a2)
r3 = reward(p, s3, a2)
println("Action: Add NRE")
print_state(s3)
println("Reward: ", r3)


