@testset "Reward Evaluation Tests" begin
    @testset "Comprehensive Metrics Calculation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Create test state
        cities = [
            City(name="TestCity1", demand=10.0, re_supply=3.0, nre_supply=4.0, population=100000, income=true),
            City(name="TestCity2", demand=15.0, re_supply=5.0, nre_supply=2.0, population=200000, income=false)
        ]
        state = State(b=50.0, total_demand=25.0, cities=cities)
        
        metrics = calculate_comprehensive_metrics(mdp, state)
        
        @test isa(metrics, Dict)
        @test haskey(metrics, "budget_mean")
        @test haskey(metrics, "total_demand_mean")
        @test haskey(metrics, "total_supply_mean")
        @test haskey(metrics, "total_re_supply_mean")
        @test haskey(metrics, "total_nre_supply_mean")
        @test haskey(metrics, "supply_deficit_mean")
        @test haskey(metrics, "equity_score_mean")
        @test haskey(metrics, "re_percentage_mean")
        
        # Check values are reasonable
        @test metrics["budget_mean"] == 50.0
        @test metrics["total_demand_mean"] == 25.0
        @test metrics["total_supply_mean"] == 14.0  # 3+4+5+2
        @test metrics["total_re_supply_mean"] == 8.0  # 3+5
        @test metrics["total_nre_supply_mean"] == 6.0  # 4+2
        @test metrics["supply_deficit_mean"] == 11.0  # 25-14
    end

    @testset "Equity Score Calculation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test with low-income city having unmet demand
        cities_unequal = [
            City(name="HighIncome", demand=10.0, re_supply=6.0, nre_supply=5.0, population=100000, income=true),  # Met
            City(name="LowIncome", demand=15.0, re_supply=2.0, nre_supply=3.0, population=200000, income=false)   # Unmet
        ]
        state_unequal = State(b=50.0, total_demand=25.0, cities=cities_unequal)
        metrics_unequal = calculate_comprehensive_metrics(mdp, state_unequal)
        
        # Test with all demands met
        cities_equal = [
            City(name="HighIncome", demand=10.0, re_supply=6.0, nre_supply=5.0, population=100000, income=true),
            City(name="LowIncome", demand=15.0, re_supply=8.0, nre_supply=8.0, population=200000, income=false)
        ]
        state_equal = State(b=50.0, total_demand=25.0, cities=cities_equal)
        metrics_equal = calculate_comprehensive_metrics(mdp, state_equal)
        
        # Equal state should have better equity score
        @test metrics_equal["equity_score_mean"] >= metrics_unequal["equity_score_mean"]
    end

    @testset "RE Percentage Calculation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test with high RE percentage
        cities_high_re = [
            City(name="City1", demand=10.0, re_supply=8.0, nre_supply=2.0, population=100000, income=true)
        ]
        state_high_re = State(b=50.0, total_demand=10.0, cities=cities_high_re)
        metrics_high_re = calculate_comprehensive_metrics(mdp, state_high_re)
        
        # Test with low RE percentage
        cities_low_re = [
            City(name="City1", demand=10.0, re_supply=2.0, nre_supply=8.0, population=100000, income=true)
        ]
        state_low_re = State(b=50.0, total_demand=10.0, cities=cities_low_re)
        metrics_low_re = calculate_comprehensive_metrics(mdp, state_low_re)
        
        @test metrics_high_re["re_percentage_mean"] > metrics_low_re["re_percentage_mean"]
        @test metrics_high_re["re_percentage_mean"] ≈ 80.0  # 8/10
        @test metrics_low_re["re_percentage_mean"] ≈ 20.0   # 2/10
    end

    @testset "Eval Reward Function" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Create a simple state
        cities = [
            City(name="TestCity", demand=10.0, re_supply=3.0, nre_supply=4.0, population=100000, income=true)
        ]
        state = State(b=50.0, total_demand=10.0, cities=cities)
        
        # Test eval_reward function
        reward_value = eval_reward(mdp, state, doNothing())
        @test isa(reward_value, Real)
        
        # Should be the same as calling reward directly
        direct_reward = reward(mdp, state, doNothing())
        @test reward_value == direct_reward
    end

    @testset "Edge Cases in Metrics" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test with zero supply
        cities_zero = [
            City(name="TestCity", demand=10.0, re_supply=0.0, nre_supply=0.0, population=100000, income=true)
        ]
        state_zero = State(b=0.0, total_demand=10.0, cities=cities_zero)
        metrics_zero = calculate_comprehensive_metrics(mdp, state_zero)
        
        @test metrics_zero["total_supply_mean"] == 0.0
        @test metrics_zero["total_re_supply_mean"] == 0.0
        @test metrics_zero["total_nre_supply_mean"] == 0.0
        @test metrics_zero["supply_deficit_mean"] == 10.0
        @test metrics_zero["re_percentage_mean"] == 0.0
        
        # Test with oversupply
        cities_over = [
            City(name="TestCity", demand=10.0, re_supply=8.0, nre_supply=7.0, population=100000, income=true)
        ]
        state_over = State(b=100.0, total_demand=10.0, cities=cities_over)
        metrics_over = calculate_comprehensive_metrics(mdp, state_over)
        
        @test metrics_over["total_supply_mean"] == 15.0
        @test metrics_over["supply_deficit_mean"] == -5.0  # Negative deficit = surplus
    end

    @testset "Multiple Cities Metrics" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test with multiple cities of different characteristics
        cities_mixed = [
            City(name="BigCity", demand=20.0, re_supply=5.0, nre_supply=10.0, population=500000, income=true),
            City(name="SmallTown", demand=5.0, re_supply=3.0, nre_supply=1.0, population=50000, income=false),
            City(name="MediumCity", demand=12.0, re_supply=2.0, nre_supply=8.0, population=200000, income=true)
        ]
        state_mixed = State(b=75.0, total_demand=37.0, cities=cities_mixed)
        metrics_mixed = calculate_comprehensive_metrics(mdp, state_mixed)
        
        @test metrics_mixed["total_demand_mean"] == 37.0
        @test metrics_mixed["total_supply_mean"] == 29.0  # 15+4+10
        @test metrics_mixed["total_re_supply_mean"] == 10.0  # 5+3+2
        @test metrics_mixed["total_nre_supply_mean"] == 19.0  # 10+1+8
        @test metrics_mixed["supply_deficit_mean"] == 8.0   # 37-29
        
        # RE percentage should be 10/29
        expected_re_percentage = (10.0 / 29.0) * 100
        @test abs(metrics_mixed["re_percentage_mean"] - expected_re_percentage) < 1e-10
    end

    @testset "Metrics Consistency" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Same state should give same metrics
        cities = [
            City(name="TestCity", demand=10.0, re_supply=3.0, nre_supply=4.0, population=100000, income=true)
        ]
        state = State(b=50.0, total_demand=10.0, cities=cities)
        
        metrics1 = calculate_comprehensive_metrics(mdp, state)
        metrics2 = calculate_comprehensive_metrics(mdp, state)
        
        for key in keys(metrics1)
            @test metrics1[key] == metrics2[key]
        end
    end

    @testset "Population-Weighted Metrics" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test that population affects equity calculations appropriately
        cities_large_poor = [
            City(name="SmallRich", demand=10.0, re_supply=5.0, nre_supply=6.0, population=10000, income=true),   # Met
            City(name="LargePoor", demand=10.0, re_supply=2.0, nre_supply=3.0, population=1000000, income=false) # Unmet, large pop
        ]
        
        cities_small_poor = [
            City(name="SmallRich", demand=10.0, re_supply=5.0, nre_supply=6.0, population=1000000, income=true),  # Met, large pop
            City(name="SmallPoor", demand=10.0, re_supply=2.0, nre_supply=3.0, population=10000, income=false)   # Unmet, small pop
        ]
        
        state_large_poor = State(b=50.0, total_demand=20.0, cities=cities_large_poor)
        state_small_poor = State(b=50.0, total_demand=20.0, cities=cities_small_poor)
        
        metrics_large_poor = calculate_comprehensive_metrics(mdp, state_large_poor)
        metrics_small_poor = calculate_comprehensive_metrics(mdp, state_small_poor)
        
        # Large poor population should result in worse equity score
        @test metrics_large_poor["equity_score_mean"] <= metrics_small_poor["equity_score_mean"]
    end
end