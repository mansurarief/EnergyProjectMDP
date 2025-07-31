@testset "Reward Analysis Tests" begin
    @testset "Reward Decomposition" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Create test state
        cities = [
            City(name="TestCity1", demand=10.0, re_supply=3.0, nre_supply=4.0, population=100000, income=true),
            City(name="TestCity2", demand=15.0, re_supply=2.0, nre_supply=5.0, population=200000, income=false)
        ]
        state = State(b=50.0, total_demand=25.0, cities=cities)
        action = doNothing()
        
        components = decompose_reward(mdp, state, action)
        
        @test isa(components, Dict)
        @test haskey(components, "budget")
        @test haskey(components, "equity_penalty") 
        @test haskey(components, "re_bonus")
        @test haskey(components, "total")
        
        # Components should sum to total
        calculated_total = components["budget"] + components["equity_penalty"] + components["re_bonus"]
        @test abs(calculated_total - components["total"]) < 1e-10
        
        # Total should match direct reward calculation
        direct_reward = reward(mdp, state, action)
        @test abs(components["total"] - direct_reward) < 1e-10
    end

    @testset "Budget Component Analysis" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        cities = [City(name="TestCity", demand=10.0, re_supply=5.0, nre_supply=5.0, population=100000, income=true)]
        
        # Positive budget
        state_pos = State(b=100.0, total_demand=10.0, cities=cities)
        components_pos = decompose_reward(mdp, state_pos, doNothing())
        
        # Zero budget
        state_zero = State(b=0.0, total_demand=10.0, cities=cities)
        components_zero = decompose_reward(mdp, state_zero, doNothing())
        
        # Negative budget
        state_neg = State(b=-50.0, total_demand=10.0, cities=cities)
        components_neg = decompose_reward(mdp, state_neg, doNothing())
        
        # Positive budget should give positive budget reward
        @test components_pos["budget"] > 0
        
        # Zero budget should give zero budget reward
        @test components_zero["budget"] == 0
        
        # Negative budget should give zero budget reward (max(0, budget))
        @test components_neg["budget"] == 0
        
        # Higher budget should give higher budget reward
        @test components_pos["budget"] > components_zero["budget"]
    end

    @testset "Equity Penalty Analysis" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # State with low-income city having unmet demand
        low_income_unmet = City(name="LowIncome", demand=10.0, re_supply=2.0, nre_supply=2.0, population=100000, income=false)
        high_income_unmet = City(name="HighIncome", demand=10.0, re_supply=2.0, nre_supply=2.0, population=100000, income=true)
        
        state_equity_problem = State(b=50.0, total_demand=20.0, cities=[low_income_unmet, high_income_unmet])
        components_equity = decompose_reward(mdp, state_equity_problem, doNothing())
        
        # Should have negative equity penalty
        @test components_equity["equity_penalty"] < 0
        
        # State with all demands met
        low_income_met = City(name="LowIncome", demand=10.0, re_supply=6.0, nre_supply=6.0, population=100000, income=false)
        high_income_met = City(name="HighIncome", demand=10.0, re_supply=6.0, nre_supply=6.0, population=100000, income=true)
        
        state_no_equity_problem = State(b=50.0, total_demand=20.0, cities=[low_income_met, high_income_met])
        components_no_equity = decompose_reward(mdp, state_no_equity_problem, doNothing())
        
        # Should have zero or minimal equity penalty
        @test components_no_equity["equity_penalty"] >= components_equity["equity_penalty"]
    end

    @testset "RE Bonus Analysis" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # City fully powered by RE
        city_all_re = City(name="RECity", demand=10.0, re_supply=12.0, nre_supply=0.0, population=100000, income=true)
        state_all_re = State(b=50.0, total_demand=10.0, cities=[city_all_re])
        components_all_re = decompose_reward(mdp, state_all_re, doNothing())
        
        # City with no RE
        city_no_re = City(name="NoRECity", demand=10.0, re_supply=0.0, nre_supply=12.0, population=100000, income=true)
        state_no_re = State(b=50.0, total_demand=10.0, cities=[city_no_re])
        components_no_re = decompose_reward(mdp, state_no_re, doNothing())
        
        # City with mixed energy
        city_mixed = City(name="MixedCity", demand=10.0, re_supply=5.0, nre_supply=7.0, population=100000, income=true)
        state_mixed = State(b=50.0, total_demand=10.0, cities=[city_mixed])
        components_mixed = decompose_reward(mdp, state_mixed, doNothing())
        
        # All RE should give highest bonus
        @test components_all_re["re_bonus"] >= components_mixed["re_bonus"]
        @test components_mixed["re_bonus"] >= components_no_re["re_bonus"]
    end

    @testset "Trajectory Analysis" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        policy = EquityFirstPolicy()
        
        # Create a short simulation
        hr = HistoryRecorder(max_steps=5, rng=rng)
        h = simulate(hr, mdp, policy)
        
        trajectory_analysis = analyze_reward_trajectory(mdp, h)
        
        @test isa(trajectory_analysis, Dict)
        
        # Should have statistics for each component
        for component in ["budget", "equity_penalty", "re_bonus"]
            if haskey(trajectory_analysis, component)
                stats = trajectory_analysis[component]
                @test haskey(stats, "sum")
                @test haskey(stats, "mean")
                @test haskey(stats, "std")
                @test isa(stats["sum"], Real)
                @test isa(stats["mean"], Real)
                @test isa(stats["std"], Real)
                @test stats["std"] >= 0
            end
        end
    end

    @testset "Empty Trajectory Handling" begin
        # Test with empty trajectory
        empty_history = []
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Should handle empty trajectory gracefully
        @test_nowarn analyze_reward_trajectory(mdp, empty_history)
        result = analyze_reward_trajectory(mdp, empty_history)
        @test isa(result, Dict)
    end

    @testset "Single Step Trajectory" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        policy = EquityFirstPolicy()
        
        # Create single-step simulation
        hr = HistoryRecorder(max_steps=1, rng=rng)
        h = simulate(hr, mdp, policy)
        
        trajectory_analysis = analyze_reward_trajectory(mdp, h)
        
        @test isa(trajectory_analysis, Dict)
        
        # With single step, std should be 0 or very small
        for component in keys(trajectory_analysis)
            if haskey(trajectory_analysis[component], "std")
                @test trajectory_analysis[component]["std"] >= 0
            end
        end
    end

    @testset "Component Value Ranges" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test various state configurations
        test_states = [
            # High budget, good equity, high RE
            State(b=200.0, total_demand=20.0, cities=[
                City(name="Good1", demand=10.0, re_supply=12.0, nre_supply=0.0, population=100000, income=false),
                City(name="Good2", demand=10.0, re_supply=12.0, nre_supply=0.0, population=100000, income=true)
            ]),
            # Low budget, poor equity, low RE  
            State(b=10.0, total_demand=20.0, cities=[
                City(name="Bad1", demand=10.0, re_supply=1.0, nre_supply=2.0, population=100000, income=false),
                City(name="Bad2", demand=10.0, re_supply=8.0, nre_supply=8.0, population=100000, income=true)
            ])
        ]
        
        for state in test_states
            components = decompose_reward(mdp, state, doNothing())
            
            # Budget component should be non-negative (max(0, budget))
            @test components["budget"] >= 0
            
            # Equity penalty should be non-positive (it's a penalty)
            @test components["equity_penalty"] <= 0
            
            # RE bonus should be non-negative
            @test components["re_bonus"] >= 0
            
            # All components should be finite
            for (key, value) in components
                @test isfinite(value)
            end
        end
    end

    @testset "Reward Decomposition Consistency" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test multiple times with same state - should be deterministic
        cities = [City(name="TestCity", demand=10.0, re_supply=3.0, nre_supply=4.0, population=100000, income=true)]
        state = State(b=50.0, total_demand=10.0, cities=cities)
        
        components1 = decompose_reward(mdp, state, doNothing())
        components2 = decompose_reward(mdp, state, doNothing())
        
        for key in keys(components1)
            @test components1[key] == components2[key]
        end
    end
end