@testset "MDP Core Tests" begin
    @testset "City Construction" begin
        city = City(name="TestCity", demand=10.0, re_supply=2.0, nre_supply=5.0, population=100000, income=true)
        
        @test city.name == "TestCity"
        @test city.demand == 10.0
        @test city.re_supply == 2.0
        @test city.nre_supply == 5.0
        @test city.population == 100000
        @test city.income == true
    end

    @testset "State Construction" begin
        cities = [City(name="City1", demand=10.0, re_supply=2.0, nre_supply=5.0, population=100000, income=true)]
        state = State(b=100.0, total_demand=10.0, cities=cities)
        
        @test state.b == 100.0
        @test state.total_demand == 10.0
        @test length(state.cities) == 1
    end

    @testset "Action Types" begin
        # Test newAction
        action1 = newAction(energyType=false, actionType=true, cityIndex=1)
        @test action1.energyType == false
        @test action1.actionType == true
        @test action1.cityIndex == 1
        
        # Test doNothing
        action2 = doNothing()
        @test action2.energyType == -1
        @test action2.actionType == -1
        @test action2.cityIndex == -1
    end

    @testset "EnergyMDP Construction and Basic Properties" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        @test isa(mdp, EnergyMDP)
        @test mdp.numberOfCities > 0
        @test mdp.initialBudget > 0
        @test mdp.discountRate >= 0 && mdp.discountRate <= 1
        
        # Test POMDPs interface
        @test discount(mdp) == mdp.discountRate
        
        # Test state and action spaces
        s0 = rand(MersenneTwister(1234), initialstate(mdp))
        @test isa(s0, State)
        @test s0.b > 0
        @test length(s0.cities) == mdp.numberOfCities
        
        # Test actions
        actions_list = actions(mdp)
        @test length(actions_list) > 0
        @test any(isa(a, doNothing) for a in actions_list)
        
        valid_actions = actions(mdp, s0)
        @test length(valid_actions) > 0
        @test all(a in actions_list for a in valid_actions)
    end

    @testset "Transition Function" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        s0 = rand(rng, initialstate(mdp))
        
        # Test do nothing action
        action_nothing = doNothing()
        transition_dist = transition(mdp, s0, action_nothing)
        s1 = rand(rng, transition_dist)
        @test s1.b == s0.b  # Budget should remain same
        @test all(s1.cities[i].re_supply == s0.cities[i].re_supply for i in 1:length(s0.cities))
        
        # Test adding RE action (if valid)
        valid_actions = actions(mdp, s0)
        add_re_actions = filter(a -> isa(a, newAction) && !a.energyType && a.actionType, valid_actions)
        
        if !isempty(add_re_actions)
            action_add_re = add_re_actions[1]
            city_idx = action_add_re.cityIndex
            initial_re = s0.cities[city_idx].re_supply
            initial_budget = s0.b
            
            transition_dist = transition(mdp, s0, action_add_re)
            s2 = rand(rng, transition_dist)
            
            @test s2.cities[city_idx].re_supply ≈ initial_re + mdp.supplyOfRE
            @test s2.b < initial_budget  # Budget should decrease
        end
    end

    @testset "Reward Function" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        s0 = rand(rng, initialstate(mdp))
        
        # Test reward calculation
        action_nothing = doNothing()
        r = reward(mdp, s0, action_nothing)
        @test isa(r, Real)
        
        # Test that reward considers budget
        # Positive budget should contribute positively
        @test s0.b > 0  # Ensure we have positive budget
        
        # Test reward components exist
        valid_actions = actions(mdp, s0)
        for action in valid_actions[1:min(3, length(valid_actions))]  # Test first few actions
            r = reward(mdp, s0, action)
            @test isa(r, Real)
        end
    end

    @testset "Terminal State Detection" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Create state with negative budget
        cities = [City(name="TestCity", demand=10.0, re_supply=5.0, nre_supply=5.0, population=100000, income=true)]
        s_negative_budget = State(b=-10.0, total_demand=10.0, cities=cities)
        @test isterminal(mdp, s_negative_budget) == true
        
        # Create state with all demands fulfilled
        cities_fulfilled = [City(name="TestCity", demand=10.0, re_supply=6.0, nre_supply=5.0, population=100000, income=true)]
        s_fulfilled = State(b=50.0, total_demand=10.0, cities=cities_fulfilled)
        @test isterminal(mdp, s_fulfilled) == true
        
        # Create non-terminal state
        cities_ongoing = [City(name="TestCity", demand=10.0, re_supply=2.0, nre_supply=3.0, population=100000, income=true)]
        s_ongoing = State(b=50.0, total_demand=10.0, cities=cities_ongoing)
        @test isterminal(mdp, s_ongoing) == false
    end

    @testset "State and Action Indexing" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Test action indexing
        actions_list = actions(mdp)
        for (i, action) in enumerate(actions_list[1:min(5, length(actions_list))])
            idx = actionindex(mdp, action)
            @test idx == i
        end
        
        # Test state indexing
        s0 = rand(rng, initialstate(mdp))
        idx = stateindex(mdp, s0)
        @test isa(idx, Integer)
        @test idx > 0
    end

    @testset "State Space Generation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        states_list = states(mdp)
        @test length(states_list) > 0
        @test all(isa(s, State) for s in states_list)
        
        # Check that states have reasonable properties
        budgets = [s.b for s in states_list]
        @test minimum(budgets) >= mdp.minBudget
        @test maximum(budgets) <= mdp.maxBudget
    end
end