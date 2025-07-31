@testset "Utils Tests" begin
    @testset "Policy Evaluation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        policy = RandomEnergyPolicy(MersenneTwister(1234))
        
        # Test basic evaluation
        result = evaluate_policy_comprehensive(mdp, policy, 5, 10, rng)
        
        @test isa(result, Dict)
        @test haskey(result, "total_reward_mean")
        @test haskey(result, "total_reward_std")
        @test isa(result["total_reward_mean"], Real)
        @test isa(result["total_reward_std"], Real)
        @test result["total_reward_std"] >= 0
        
        # Should have metrics about final states
        @test haskey(result, "budget_mean")
        @test haskey(result, "budget_std")
        @test haskey(result, "total_demand_mean")
        @test haskey(result, "total_supply_mean")
    end

    @testset "Multiple Policy Evaluation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        policies = [
            ("Random", RandomEnergyPolicy(MersenneTwister(1234))),
            ("Equity", EquityFirstPolicy())
        ]
        
        results = Dict{String, Dict{String, Float64}}()
        
        for (name, policy) in policies
            result = evaluate_policy_comprehensive(mdp, policy, 3, 8, rng)  # Small numbers for testing
            results[name] = result
            
            @test haskey(result, "total_reward_mean")
            @test haskey(result, "budget_mean")
        end
        
        @test length(results) == 2
        @test haskey(results, "Random")
        @test haskey(results, "Equity")
    end

    @testset "Evaluation with Different Parameters" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        policy = EquityFirstPolicy()
        
        # Test with different simulation counts
        result_few = evaluate_policy_comprehensive(mdp, policy, 2, 5, rng)
        result_many = evaluate_policy_comprehensive(mdp, policy, 10, 5, rng)
        
        @test isa(result_few, Dict)
        @test isa(result_many, Dict)
        
        # Both should have same keys
        @test Set(keys(result_few)) == Set(keys(result_many))
        
        # Test with different max steps
        result_short = evaluate_policy_comprehensive(mdp, policy, 3, 5, rng)
        result_long = evaluate_policy_comprehensive(mdp, policy, 3, 15, rng)
        
        @test isa(result_short, Dict)
        @test isa(result_long, Dict)
    end

    @testset "Print Policy Comparison" begin
        # Create mock results
        results = Dict{String, Dict{String, Float64}}(
            "Policy1" => Dict(
                "total_reward_mean" => 100.0,
                "total_reward_std" => 10.0,
                "budget_mean" => 50.0,
                "total_supply_mean" => 80.0
            ),
            "Policy2" => Dict(
                "total_reward_mean" => 120.0,
                "total_reward_std" => 15.0,
                "budget_mean" => 45.0,
                "total_supply_mean" => 85.0
            )
        )
        
        # Test that function doesn't crash
        @test_nowarn print_policy_comparison(results)
    end

    @testset "Edge Cases in Evaluation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test with policy that might lead to quick termination
        policy = EquityFirstPolicy()
        
        # Very short evaluation
        result = evaluate_policy_comprehensive(mdp, policy, 1, 3, rng)
        @test isa(result, Dict)
        @test haskey(result, "total_reward_mean")
        
        # Single step evaluation
        result_single = evaluate_policy_comprehensive(mdp, policy, 1, 1, rng)
        @test isa(result_single, Dict)
    end

    @testset "Evaluation Consistency" begin
        rng1 = MersenneTwister(1234)
        rng2 = MersenneTwister(1234)  # Same seed
        mdp = initialize_mdp(rng1)
        policy = RandomEnergyPolicy(MersenneTwister(1234))
        
        # Same seed should give same results (approximately)
        result1 = evaluate_policy_comprehensive(mdp, policy, 3, 5, rng1)
        
        # Reset everything with same seeds
        rng1 = MersenneTwister(1234)
        rng2 = MersenneTwister(1234)
        mdp = initialize_mdp(rng1)
        policy = RandomEnergyPolicy(MersenneTwister(1234))
        
        result2 = evaluate_policy_comprehensive(mdp, policy, 3, 5, rng2)
        
        # Results should be similar (accounting for floating point precision)
        @test abs(result1["total_reward_mean"] - result2["total_reward_mean"]) < 1e-10
    end

    @testset "Evaluation Metrics Coverage" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        policy = EquityFirstPolicy()
        
        result = evaluate_policy_comprehensive(mdp, policy, 5, 8, rng)
        
        # Should have comprehensive metrics
        expected_keys = [
            "total_reward_mean", "total_reward_std",
            "budget_mean", "budget_std",
            "total_demand_mean", "total_supply_mean",
            "total_re_supply_mean", "total_nre_supply_mean"
        ]
        
        for key in expected_keys
            @test haskey(result, key)
        end
        
        # All values should be finite
        for (key, value) in result
            @test isfinite(value)
        end
    end
end