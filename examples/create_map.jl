using EnergyProjectMDP
using Random
using POMDPs
using POMDPTools
using MCTS

rng = MersenneTwister(1234)
mdp = initialize_mdp(rng)

s0 = rand(rng, initialstate(mdp))
filename = "renewable_energy_map_initial.png"
title = "Energy Distribution Map"


MCTS_solver =  MCTSSolver(n_iterations=500, depth=30, exploration_constant=10.0)
MCTS_policy = solve(MCTS_solver, mdp)
MCTS_result = evaluate_policy_comprehensive(mdp, MCTS_policy, 30, 12, rng)

hr = HistoryRecorder(max_steps=30)

mcts_hist = simulate(hr, mdp, MCTS_policy, s0)
filename = "renewable_energy_map_initial.png"
title = "Energy Distribution Map"
create_city_map(mdp, s0, filename=filename, title=title)

sf = mcts_hist[end].sp
filename = "renewable_energy_map_final_mcts.png"
create_city_map(mdp, sf, filename=filename, title=title)
