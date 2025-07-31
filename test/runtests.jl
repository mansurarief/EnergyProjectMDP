using Test
using EnergyProjectMDP
using POMDPs
using Random
using Statistics

# Set random seed for reproducible tests
Random.seed!(1234)

@testset "EnergyProjectMDP Tests" begin
    include("test_mdp.jl")
    include("test_policies.jl")
    include("test_functions.jl")
    include("test_utils.jl")
    include("test_init_mdp.jl")
    include("test_eval_reward.jl")
    include("test_reward_analysis.jl")
end