@testset "Functions Tests" begin
    @testset "Transition Function Edge Cases" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test transition with negative budget state
        cities = [City(name="TestCity", demand=10.0, re_supply=2.0, nre_supply=3.0, population=100000, income=true)]
        s_negative = State(b=-5.0, total_demand=10.0, cities=cities)
        action = doNothing()
        
        transition_dist = transition(mdp, s_negative, action)
        s_next = rand(rng, transition_dist)
        @test s_next.b == s_negative.b  # Should remain the same for do nothing
        
        # Test transition when adding energy would exceed max capacity
        cities_max = [City(name="TestCity", demand=10.0, re_supply=mdp.maxEnergyPerCity, nre_supply=0.0, population=100000, income=true)]
        s_max = State(b=100.0, total_demand=10.0, cities=cities_max)
        valid_actions = actions(mdp, s_max)
        
        # Should not allow adding more RE when at max
        add_re_actions = filter(a -> isa(a, newAction) && !a.energyType && a.actionType, valid_actions)
        @test isempty(add_re_actions)
    end

    @testset "Reward Function Components" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test with state having positive budget
        cities_pos = [City(name="TestCity", demand=10.0, re_supply=2.0, nre_supply=3.0, population=100000, income=true)]
        s_pos = State(b=50.0, total_demand=10.0, cities=cities_pos)
        r_pos = reward(mdp, s_pos, doNothing())
        
        # Test with state having zero budget
        s_zero = State(b=0.0, total_demand=10.0, cities=cities_pos)
        r_zero = reward(mdp, s_zero, doNothing())
        
        # Positive budget should give higher reward (budget component)
        @test r_pos >= r_zero
        
        # Test equity component with low income city without energy
        low_income_unmet = City(name="LowIncomeCity", demand=10.0, re_supply=1.0, nre_supply=1.0, population=100000, income=false)
        cities_equity = [low_income_unmet]
        s_equity = State(b=50.0, total_demand=10.0, cities=cities_equity)
        r_equity = reward(mdp, s_equity, doNothing())
        
        # Should be negative due to equity penalty
        @test r_equity < 0
        
        # Test RE bonus with city fully powered by RE
        re_city = City(name="RECity", demand=10.0, re_supply=12.0, nre_supply=0.0, population=100000, income=true)
        cities_re = [re_city]
        s_re = State(b=50.0, total_demand=10.0, cities=cities_re)
        r_re = reward(mdp, s_re, doNothing())
        
        # Should have positive RE bonus component
        @test r_re > r_pos  # Better than basic positive budget case
    end

    @testset "Terminal State Edge Cases" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test with exactly zero budget
        cities = [City(name="TestCity", demand=10.0, re_supply=2.0, nre_supply=3.0, population=100000, income=true)]
        s_zero = State(b=0.0, total_demand=10.0, cities=cities)
        @test isterminal(mdp, s_zero) == false  # Zero budget is not negative
        
        # Test with exactly met demand
        cities_exact = [City(name="TestCity", demand=10.0, re_supply=5.0, nre_supply=5.0, population=100000, income=true)]
        s_exact = State(b=50.0, total_demand=10.0, cities=cities_exact)
        @test isterminal(mdp, s_exact) == true
        
        # Test with slightly over met demand
        cities_over = [City(name="TestCity", demand=10.0, re_supply=6.0, nre_supply=5.0, population=100000, income=true)]
        s_over = State(b=50.0, total_demand=10.0, cities=cities_over)
        @test isterminal(mdp, s_over) == true
    end

    @testset "Action Validation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test with insufficient budget for adding energy
        cities = [City(name="TestCity", demand=10.0, re_supply=2.0, nre_supply=3.0, population=100000, income=true)]
        s_poor = State(b=1.0, total_demand=10.0, cities=cities)  # Very low budget
        valid_actions = actions(mdp, s_poor)
        
        # Should still have doNothing action
        @test any(isa(a, doNothing) for a in valid_actions)
        
        # Should not have expensive add actions if budget is too low
        add_actions = filter(a -> isa(a, newAction) && a.actionType, valid_actions)
        for action in add_actions
            cost = action.energyType ? mdp.costOfAddingNRE : mdp.costOfAddingRE
            @test s_poor.b >= cost
        end
        
        # Test removal actions validity
        cities_removable = [City(name="TestCity", demand=10.0, re_supply=mdp.supplyOfRE * 2, nre_supply=mdp.supplyOfNRE * 2, population=100000, income=true)]
        s_removable = State(b=50.0, total_demand=10.0, cities=cities_removable)
        valid_actions_removable = actions(mdp, s_removable)
        
        # Should have removal actions available
        remove_re_actions = filter(a -> isa(a, newAction) && !a.energyType && !a.actionType, valid_actions_removable)
        remove_nre_actions = filter(a -> isa(a, newAction) && a.energyType && !a.actionType, valid_actions_removable)
        
        @test !isempty(remove_re_actions)
        @test !isempty(remove_nre_actions)
    end

    @testset "State Indexing Robustness" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Create states with slight variations
        cities1 = [City(name="TestCity", demand=10.0, re_supply=2.0, nre_supply=3.0, population=100000, income=true)]
        cities2 = [City(name="TestCity", demand=10.0, re_supply=2.00001, nre_supply=3.0, population=100000, income=true)]  # Tiny difference
        
        s1 = State(b=50.0, total_demand=10.0, cities=cities1)
        s2 = State(b=50.0, total_demand=10.0, cities=cities2)
        
        idx1 = stateindex(mdp, s1)
        idx2 = stateindex(mdp, s2)
        
        @test isa(idx1, Integer)
        @test isa(idx2, Integer)
        @test idx1 > 0
        @test idx2 > 0
    end

    @testset "Initial State Distribution" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Sample multiple initial states
        initial_states = [rand(MersenneTwister(1234 + i), initialstate(mdp)) for i in 1:10]
        
        # All should be valid states
        for s in initial_states
            @test isa(s, State)
            @test s.b > 0
            @test length(s.cities) == mdp.numberOfCities
            @test s.total_demand > 0
            @test !isterminal(mdp, s)  # Initial states should not be terminal
        end
        
        # Should have some variation in initial conditions
        budgets = [s.b for s in initial_states]
        @test length(unique(budgets)) > 1  # Should have variation
    end

    @testset "Action Space Completeness" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        all_actions = actions(mdp)
        
        # Should have doNothing action
        @test any(isa(a, doNothing) for a in all_actions)
        
        # Should have actions for each city and energy type
        for city_idx in 1:mdp.numberOfCities
            # Add RE action
            @test any(a -> isa(a, newAction) && !a.energyType && a.actionType && a.cityIndex == city_idx, all_actions)
            # Add NRE action
            @test any(a -> isa(a, newAction) && a.energyType && a.actionType && a.cityIndex == city_idx, all_actions)
            # Remove RE action
            @test any(a -> isa(a, newAction) && !a.energyType && !a.actionType && a.cityIndex == city_idx, all_actions)
            # Remove NRE action
            @test any(a -> isa(a, newAction) && a.energyType && !a.actionType && a.cityIndex == city_idx, all_actions)
        end
        
        # Expected number of actions: 1 (doNothing) + 4 * numberOfCities
        expected_actions = 1 + 4 * mdp.numberOfCities
        @test length(all_actions) == expected_actions
    end
end