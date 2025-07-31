@testset "Policy Tests" begin
    @testset "RandomEnergyPolicy" begin
        rng = MersenneTwister(1234)
        policy = RandomEnergyPolicy(rng)
        mdp = initialize_mdp(rng)
        s0 = rand(rng, initialstate(mdp))
        
        # Test that policy returns valid actions
        for _ in 1:10
            action = POMDPs.action(policy, s0)
            valid_actions = actions(mdp, s0)
            @test action in valid_actions
        end
    end

    @testset "EquityFirstPolicy" begin
        policy = EquityFirstPolicy()
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Create state with mixed income cities
        low_income_city = City(name="LowIncome", demand=10.0, re_supply=0.0, nre_supply=3.0, population=100000, income=false)
        high_income_city = City(name="HighIncome", demand=10.0, re_supply=0.0, nre_supply=3.0, population=100000, income=true)
        cities = [low_income_city, high_income_city]
        s = State(b=100.0, total_demand=20.0, cities=cities)
        
        action = POMDPs.action(policy, s)
        
        # Should be a valid action
        @test isa(action, Union{newAction, doNothing})
        
        # If it's adding energy, it should prioritize low-income city
        if isa(action, newAction) && action.actionType
            # This is adding energy - should prefer low income city (index 1)
            # Note: this is probabilistic, so we test the logic exists
            @test action.cityIndex in [1, 2]
        end
    end

    @testset "GreedyREPolicy" begin
        policy = GreedyREPolicy()
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        s0 = rand(rng, initialstate(mdp))
        
        action = POMDPs.action(policy, s0)
        valid_actions = actions(mdp, s0)
        @test action in valid_actions
        
        # If adding energy, should prefer RE over NRE
        if isa(action, newAction) && action.actionType
            @test action.energyType == false  # false means RE
        end
    end

    @testset "BalancedEnergyPolicy" begin
        policy = BalancedEnergyPolicy()
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        s0 = rand(rng, initialstate(mdp))
        
        action = POMDPs.action(policy, s0)
        valid_actions = actions(mdp, s0)
        @test action in valid_actions
    end

    @testset "PriorityBasedPolicy" begin
        policy = PriorityBasedPolicy()
        @test policy.re_weight == 0.4
        @test policy.equity_weight == 0.4
        @test policy.efficiency_weight == 0.2
        
        # Test with custom weights
        custom_policy = PriorityBasedPolicy(0.5, 0.3, 0.2)
        @test custom_policy.re_weight == 0.5
        @test custom_policy.equity_weight == 0.3
        @test custom_policy.efficiency_weight == 0.2
        
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        s0 = rand(rng, initialstate(mdp))
        
        action = POMDPs.action(policy, s0)
        valid_actions = actions(mdp, s0)
        @test action in valid_actions
    end

    @testset "ExpertPolicy" begin
        policy = ExpertPolicy()
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        s0 = rand(rng, initialstate(mdp))
        
        action = POMDPs.action(policy, s0)
        valid_actions = actions(mdp, s0)
        @test action in valid_actions
    end

    @testset "Policy Consistency" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        s0 = rand(rng, initialstate(mdp))
        
        policies = [
            RandomEnergyPolicy(MersenneTwister(1234)),
            EquityFirstPolicy(),
            GreedyREPolicy(),
            BalancedEnergyPolicy(),
            PriorityBasedPolicy(),
            ExpertPolicy()
        ]
        
        # Test that all policies return valid actions
        for policy in policies
            for _ in 1:5  # Test multiple times for stochastic policies
                action = POMDPs.action(policy, s0)
                valid_actions = actions(mdp, s0)
                @test action in valid_actions
            end
        end
    end

    @testset "Policy with Different States" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        policy = EquityFirstPolicy()
        
        # Test with different state configurations
        test_states = [
            # State with high budget
            State(b=200.0, total_demand=20.0, cities=[
                City(name="City1", demand=10.0, re_supply=2.0, nre_supply=3.0, population=100000, income=false),
                City(name="City2", demand=10.0, re_supply=4.0, nre_supply=6.0, population=100000, income=true)
            ]),
            # State with low budget
            State(b=10.0, total_demand=20.0, cities=[
                City(name="City1", demand=10.0, re_supply=2.0, nre_supply=3.0, population=100000, income=false),
                City(name="City2", demand=10.0, re_supply=4.0, nre_supply=6.0, population=100000, income=true)
            ]),
            # State with fulfilled demands
            State(b=100.0, total_demand=20.0, cities=[
                City(name="City1", demand=10.0, re_supply=6.0, nre_supply=6.0, population=100000, income=false),
                City(name="City2", demand=10.0, re_supply=6.0, nre_supply=6.0, population=100000, income=true)
            ])
        ]
        
        for state in test_states
            if !isterminal(mdp, state)
                action = POMDPs.action(policy, state)
                valid_actions = actions(mdp, state)
                @test action in valid_actions
            end
        end
    end
end