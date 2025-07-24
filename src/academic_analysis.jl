# Academic analysis functions for publication-quality results

using CSV
using DataFrames
using Statistics

# Calculate comprehensive metrics for academic evaluation
function calculate_academic_metrics(mdp::EnergyMDP, final_state::State, policy_name::String)
    metrics = Dict{String, Any}()
    
    # Basic identifiers
    metrics["Policy"] = policy_name
    metrics["FinalBudget"] = final_state.b
    metrics["BudgetUsed"] = mdp.initialBudget - final_state.b
    metrics["BudgetEfficiency"] = (mdp.initialBudget - final_state.b) > 0 ? 
        sum([city.re_supply + city.nre_supply for city in final_state.cities]) / (mdp.initialBudget - final_state.b) : 0.0
    
    # Energy metrics
    total_demand = sum([city.demand for city in final_state.cities])
    total_supply = sum([city.re_supply + city.nre_supply for city in final_state.cities])
    total_re = sum([city.re_supply for city in final_state.cities])
    
    metrics["TotalDemand"] = total_demand
    metrics["TotalSupply"] = total_supply
    metrics["TotalRE"] = total_re
    metrics["SupplyRatio"] = total_supply / total_demand
    metrics["REPercentage"] = total_supply > 0 ? (total_re / total_supply) * 100 : 0.0
    metrics["UnmetDemand"] = max(0, total_demand - total_supply)
    
    # Equity analysis
    low_income_cities = [city for city in final_state.cities if city.income == false]
    high_income_cities = [city for city in final_state.cities if city.income == true]
    
    if !isempty(low_income_cities)
        low_demand = sum([city.demand for city in low_income_cities])
        low_supply = sum([city.re_supply + city.nre_supply for city in low_income_cities])
        low_re = sum([city.re_supply for city in low_income_cities])
        
        metrics["LowIncomeSupplyRatio"] = low_supply / low_demand
        metrics["LowIncomeREPercentage"] = low_supply > 0 ? (low_re / low_supply) * 100 : 0.0
        metrics["LowIncomeUnmet"] = max(0, low_demand - low_supply)
    end
    
    if !isempty(high_income_cities)
        high_demand = sum([city.demand for city in high_income_cities])
        high_supply = sum([city.re_supply + city.nre_supply for city in high_income_cities])
        high_re = sum([city.re_supply for city in high_income_cities])
        
        metrics["HighIncomeSupplyRatio"] = high_supply / high_demand
        metrics["HighIncomeREPercentage"] = high_supply > 0 ? (high_re / high_supply) * 100 : 0.0
        metrics["HighIncomeUnmet"] = max(0, high_demand - high_supply)
    end
    
    # Equity disparity metrics
    if haskey(metrics, "LowIncomeSupplyRatio") && haskey(metrics, "HighIncomeSupplyRatio")
        metrics["SupplyDisparity"] = abs(metrics["LowIncomeSupplyRatio"] - metrics["HighIncomeSupplyRatio"])
        metrics["REDisparity"] = abs(metrics["LowIncomeREPercentage"] - metrics["HighIncomeREPercentage"])
        metrics["EquityScore"] = 1.0 - min(1.0, metrics["SupplyDisparity"])
    end
    
    # Population-weighted metrics
    total_population = sum([city.population for city in final_state.cities])
    served_population = sum([city.population * min((city.re_supply + city.nre_supply)/city.demand, 1.0) for city in final_state.cities])
    metrics["PopulationServed"] = (served_population / total_population) * 100
    
    return metrics
end

# Generate city-level detailed analysis
function generate_city_analysis(mdp::EnergyMDP, final_state::State, policy_name::String)
    city_data = []
    
    for (i, city) in enumerate(final_state.cities)
        city_metrics = Dict{String, Any}()
        city_metrics["Policy"] = policy_name
        city_metrics["City"] = city.name
        city_metrics["IncomeLevel"] = city.income ? "High" : "Low"
        city_metrics["Population"] = city.population
        city_metrics["Demand"] = city.demand
        city_metrics["RESupply"] = city.re_supply
        city_metrics["NRESupply"] = city.nre_supply
        city_metrics["TotalSupply"] = city.re_supply + city.nre_supply
        city_metrics["SupplyRatio"] = (city.re_supply + city.nre_supply) / city.demand
        city_metrics["REPercentage"] = (city.re_supply + city.nre_supply) > 0 ? 
            (city.re_supply / (city.re_supply + city.nre_supply)) * 100 : 0.0
        city_metrics["UnmetDemand"] = max(0, city.demand - city.re_supply - city.nre_supply)
        city_metrics["EnergySecurityIndex"] = min(1.0, (city.re_supply + city.nre_supply) / city.demand)
        
        # Add coordinates for mapping
        if haskey(CITY_COORDINATES, city.name)
            coords = CITY_COORDINATES[city.name]
            city_metrics["Latitude"] = coords[1]
            city_metrics["Longitude"] = coords[2]
        end
        
        push!(city_data, city_metrics)
    end
    
    return city_data
end

# Save results to CSV for academic tables
function save_academic_results(policy_results::Dict, output_dir::String="results")
    # Create output directory if it doesn't exist
    if !isdir(output_dir)
        mkdir(output_dir)
    end
    
    # 1. Policy comparison table
    policy_df = DataFrame()
    for (policy_name, metrics) in policy_results
        if policy_name != "city_data"  # Skip city data for now
            row_dict = Dict{String, Any}()
            for (key, value) in metrics
                row_dict[key] = value
            end
            push!(policy_df, row_dict, cols=:union)
        end
    end
    
    # Save policy comparison
    CSV.write(joinpath(output_dir, "policy_comparison.csv"), policy_df)
    println("✅ Saved policy comparison to $(output_dir)/policy_comparison.csv")
    
    # 2. City-level analysis
    if haskey(policy_results, "city_data")
        all_city_data = []
        for (policy_name, city_list) in policy_results["city_data"]
            append!(all_city_data, city_list)
        end
        
        city_df = DataFrame(all_city_data)
        CSV.write(joinpath(output_dir, "city_analysis.csv"), city_df)
        println("✅ Saved city analysis to $(output_dir)/city_analysis.csv")
    end
    
    # 3. Summary statistics for paper
    summary_stats = calculate_summary_statistics(policy_results)
    summary_df = DataFrame(summary_stats)
    CSV.write(joinpath(output_dir, "summary_statistics.csv"), summary_df)
    println("✅ Saved summary statistics to $(output_dir)/summary_statistics.csv")
    
    return policy_df, city_df, summary_df
end

# Calculate summary statistics for the paper
function calculate_summary_statistics(policy_results::Dict)
    summary = []
    
    metrics_of_interest = [
        "REPercentage", "SupplyDisparity", "BudgetEfficiency", 
        "PopulationServed", "EquityScore"
    ]
    
    for metric in metrics_of_interest
        values = []
        policies = []
        
        for (policy_name, metrics) in policy_results
            if policy_name != "city_data" && haskey(metrics, metric)
                push!(values, metrics[metric])
                push!(policies, policy_name)
            end
        end
        
        if !isempty(values)
            push!(summary, Dict(
                "Metric" => metric,
                "Mean" => mean(values),
                "Std" => std(values),
                "Min" => minimum(values),
                "Max" => maximum(values),
                "BestPolicy" => policies[argmax(values)],
                "BestValue" => maximum(values)
            ))
        end
    end
    
    return summary
end

# Format numbers for academic presentation
function format_academic(value::Float64, precision::Int=2)
    return round(value, digits=precision)
end

function format_percentage(value::Float64, precision::Int=1)
    return round(value, digits=precision)
end

export calculate_academic_metrics, generate_city_analysis, save_academic_results, 
       calculate_summary_statistics, format_academic, format_percentage