using EnergyProjectMDP
using POMDPs
using POMDPTools

p = EnergyMDP()
# s0 = initialstate(p) # TODO: fix implementation of initialstate

s0 = State(b=10e6, total_demand=0.0, cities = p.cities)

a0 = doNothing()

r0 = reward(p, s0, a0)

#using SARSOP
solver = SARSOP()
optimal_mdp = solve(p, solver)

#benchmark
#mansur_policy = [newAction(0, 1, 1), newAction(1, 1, 1), newAction(2, 1, 1)]
#simi_policy = [newAction(0, 1, 1), newAction(1, 1, 1), newAction(2, 1, 1)

]

mansur_total_reward = evaluate(p, s0, mansur_policy)
simi_total_reward = evaluate(p, s0, simi_policy)
mdp_optimal_reward = evaluate(p, optimal_mdp, s0)

s





# s0 = State(b=10e6, total_demand=0.0, cities = [atlanta, stanford])
# a0 = doNothing()
# r0 = reward(p, s0, a0)
# println("Initial State: ", s0)
# println("Action: ", a0)
# println("Reward: ", r0)


# s1 = transition(p, s0, a0)
# a1 = newAction(0,1)
# r1 = reward(p, s1, a1)
# println("State after action: ", s1)
# println("Action: ", a1)
# println("Reward after action: ", r1)

# s2 = transition(p, s1, a1)
# println("State after action: ", s2)

# a2 = newAction(1, 1)
# s3 = transition(p, s2, a2)
# r3 = reward(p, s3, a2)
# println("Action: Add NRE")
# print_state(s3)
# println("Reward: ", r3)


