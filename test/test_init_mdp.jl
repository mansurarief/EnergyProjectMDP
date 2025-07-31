@testset "Initialize MDP Tests" begin
    @testset "Basic MDP Initialization" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        @test isa(mdp, EnergyMDP)
        @test mdp.numberOfCities > 0
        @test mdp.initialBudget > 0
        @test mdp.discountRate >= 0 && mdp.discountRate <= 1
        @test length(mdp.cities) == mdp.numberOfCities
        
        # Test that cities have reasonable properties
        for city in mdp.cities
            @test !isempty(city.name)
            @test city.demand > 0
            @test city.re_supply >= 0
            @test city.nre_supply >= 0
            @test city.population > 0
            @test isa(city.income, Bool)
        end
    end

    @testset "MDP Initialization with Custom Weights" begin
        rng = MersenneTwister(1234)
        
        # Test with different weight parameters
        mdp1 = initialize_mdp(rng, 0.1, -10.0, 50.0)
        mdp2 = initialize_mdp(rng, 0.3, -100.0, 20.0)
        
        @test mdp1.weightBudget == 0.1
        @test mdp1.weightLowIncomeWithoutEnergy == -10.0
        @test mdp1.weightPopulationWithRE == 50.0
        
        @test mdp2.weightBudget == 0.3
        @test mdp2.weightLowIncomeWithoutEnergy == -100.0
        @test mdp2.weightPopulationWithRE == 20.0
        
        # Both should still be valid MDPs
        @test isa(mdp1, EnergyMDP)
        @test isa(mdp2, EnergyMDP)
    end

    @testset "Randomization in Initialization" begin
        # Test that different random seeds produce different configurations
        mdp1 = initialize_mdp(MersenneTwister(1234))
        mdp2 = initialize_mdp(MersenneTwister(5678))
        
        # Should have same structure but different values
        @test mdp1.numberOfCities == mdp2.numberOfCities
        @test length(mdp1.cities) == length(mdp2.cities)
        
        # Should have some differences in city configurations
        differences = 0
        for i in 1:length(mdp1.cities)
            if mdp1.cities[i].demand != mdp2.cities[i].demand ||
               mdp1.cities[i].re_supply != mdp2.cities[i].re_supply ||
               mdp1.cities[i].nre_supply != mdp2.cities[i].nre_supply ||
               mdp1.cities[i].population != mdp2.cities[i].population
                differences += 1
            end
        end
        @test differences > 0  # Should have at least some differences
    end

    @testset "City Configuration Validity" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Check that cities have realistic configurations
        for city in mdp.cities
            # Demand should be positive
            @test city.demand > 0
            
            # Supply should be non-negative
            @test city.re_supply >= 0
            @test city.nre_supply >= 0
            
            # Population should be reasonable
            @test city.population > 10000  # At least 10k people
            @test city.population < 10_000_000  # Less than 10M people
        end
        
        # Should have a mix of income levels
        income_levels = [city.income for city in mdp.cities]
        @test any(income_levels)      # Some high income
        @test any(.!income_levels)    # Some low income
    end

    @testset "Deterministic Initialization with Same Seed" begin
        # Same seed should produce identical results
        rng1 = MersenneTwister(42)
        rng2 = MersenneTwister(42)
        
        mdp1 = initialize_mdp(rng1)
        mdp2 = initialize_mdp(rng2)
        
        @test mdp1.numberOfCities == mdp2.numberOfCities
        @test mdp1.initialBudget == mdp2.initialBudget
        
        # Cities should be identical
        for i in 1:length(mdp1.cities)
            @test mdp1.cities[i].name == mdp2.cities[i].name
            @test mdp1.cities[i].demand == mdp2.cities[i].demand
            @test mdp1.cities[i].re_supply == mdp2.cities[i].re_supply
            @test mdp1.cities[i].nre_supply == mdp2.cities[i].nre_supply
            @test mdp1.cities[i].population == mdp2.cities[i].population
            @test mdp1.cities[i].income == mdp2.cities[i].income
        end
    end

    @testset "MDP Parameters Validation" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Check that MDP has all required parameters
        @test isdefined(mdp, :numberOfCities)
        @test isdefined(mdp, :initialBudget)
        @test isdefined(mdp, :cities)
        @test isdefined(mdp, :supplyOfRE)
        @test isdefined(mdp, :supplyOfNRE)
        @test isdefined(mdp, :costOfAddingRE)
        @test isdefined(mdp, :costOfAddingNRE)
        @test isdefined(mdp, :costOfRemovingRE)
        @test isdefined(mdp, :costOfRemovingNRE)
        @test isdefined(mdp, :discountRate)
        @test isdefined(mdp, :weightBudget)
        @test isdefined(mdp, :weightLowIncomeWithoutEnergy)
        @test isdefined(mdp, :weightPopulationWithRE)
        
        # Check parameter reasonableness
        @test mdp.supplyOfRE > 0
        @test mdp.supplyOfNRE > 0
        @test mdp.costOfAddingRE > 0
        @test mdp.costOfAddingNRE > 0
        @test mdp.discountRate > 0 && mdp.discountRate <= 1
    end

    @testset "City Name Uniqueness and Validity" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        city_names = [city.name for city in mdp.cities]
        
        # Names should not be empty
        @test all(!isempty(name) for name in city_names)
        
        # Names should be unique
        @test length(unique(city_names)) == length(city_names)
        
        # Should recognize some standard city names (from the predefined list)
        standard_names = ["Atlanta", "San Francisco", "Memphis", "Detroit", "Phoenix", "Seattle"]
        found_standard = any(name in standard_names for name in city_names)
        @test found_standard
    end

    @testset "Budget and Cost Relationships" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Initial budget should be enough for at least some actions
        @test mdp.initialBudget > mdp.costOfAddingRE
        @test mdp.initialBudget > mdp.costOfAddingNRE
        
        # Costs should be positive
        @test mdp.costOfAddingRE > 0
        @test mdp.costOfAddingNRE > 0
        @test mdp.costOfRemovingRE > 0
        @test mdp.costOfRemovingNRE > 0
        
        # Supply amounts should be positive
        @test mdp.supplyOfRE > 0
        @test mdp.supplyOfNRE > 0
    end

    @testset "Operating Costs Structure" begin
        rng = MersenneTwister(1234)
        mdp = initialize_mdp(rng)
        
        # Should have operating costs for each city
        @test length(mdp.operatingCostRE) == mdp.numberOfCities
        @test length(mdp.operatingCostNRE) == mdp.numberOfCities
        
        # Operating costs should be non-negative
        @test all(cost >= 0 for cost in mdp.operatingCostRE)
        @test all(cost >= 0 for cost in mdp.operatingCostNRE)
    end
end