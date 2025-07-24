# Publication-quality plotting functions for academic paper

using Plots
using StatsPlots
using PlotThemes
using Colors

# Set publication theme
theme(:wong)  # Color-blind friendly palette
default(
    fontfamily="Computer Modern",
    titlefontsize=14,
    guidefontsize=12,
    tickfontsize=10,
    legendfontsize=10,
    size=(800, 600),
    dpi=300,
    linewidth=2,
    markersize=6
)

# Policy comparison bar chart for the paper
function plot_policy_comparison(policy_results::Dict; save_path::String="figures")
    if !isdir(save_path)
        mkdir(save_path)
    end
    
    # Extract data for plotting
    policies = []
    re_percentages = []
    equity_scores = []
    budget_efficiencies = []
    
    for (policy_name, metrics) in policy_results
        if policy_name != "city_data"
            push!(policies, policy_name)
            push!(re_percentages, metrics["REPercentage"])
            push!(equity_scores, metrics["EquityScore"] * 100)  # Convert to percentage
            push!(budget_efficiencies, metrics["BudgetEfficiency"])
        end
    end
    
    # Create subplot layout
    p1 = bar(policies, re_percentages, 
             title="Renewable Energy Adoption",
             ylabel="RE Percentage (%)",
             color=:green,
             alpha=0.7,
             rotation=45)
    
    p2 = bar(policies, equity_scores,
             title="Energy Equity Achievement", 
             ylabel="Equity Score (%)",
             color=:blue,
             alpha=0.7,
             rotation=45)
    
    p3 = bar(policies, budget_efficiencies,
             title="Budget Efficiency",
             ylabel="GW per Million USD",
             color=:orange,
             alpha=0.7,
             rotation=45)
    
    # Combine plots
    combined_plot = plot(p1, p2, p3, layout=(1,3), size=(1200, 400))
    
    # Save plots
    savefig(combined_plot, joinpath(save_path, "policy_comparison.png"))
    savefig(combined_plot, joinpath(save_path, "policy_comparison.pdf"))
    
    println("✅ Saved policy comparison plots to $save_path/")
    return combined_plot
end

# City-level energy fulfillment visualization
function plot_city_energy_analysis(city_data::Vector; save_path::String="figures")
    if !isdir(save_path)
        mkdir(save_path)
    end
    
    # Organize data by policy
    policies = unique([data["Policy"] for data in city_data])
    cities = unique([data["City"] for data in city_data])
    
    # Create energy fulfillment plot
    city_names = []
    supply_ratios = []
    re_percentages = []
    income_levels = []
    policy_names = []
    
    for data in city_data
        push!(city_names, data["City"])
        push!(supply_ratios, data["SupplyRatio"] * 100)  # Convert to percentage
        push!(re_percentages, data["REPercentage"])
        push!(income_levels, data["IncomeLevel"])
        push!(policy_names, data["Policy"])
    end
    
    # Energy Security Plot (Supply Ratio by City)
    p1 = groupedbar(
        city_names, supply_ratios,
        group=policy_names,
        title="Energy Security by City",
        ylabel="Demand Fulfillment (%)",
        xlabel="Cities",
        rotation=45,
        alpha=0.8,
        size=(900, 500)
    )
    
    # Add reference line at 100%
    hline!([100], color=:red, linestyle=:dash, linewidth=2, label="Full Demand")
    
    # Renewable Energy by City
    p2 = groupedbar(
        city_names, re_percentages,
        group=policy_names,
        title="Renewable Energy Adoption by City",
        ylabel="RE Percentage (%)",
        xlabel="Cities", 
        rotation=45,
        alpha=0.8,
        size=(900, 500)
    )
    
    # Save plots
    savefig(p1, joinpath(save_path, "city_energy_security.png"))
    savefig(p1, joinpath(save_path, "city_energy_security.pdf"))
    savefig(p2, joinpath(save_path, "city_renewable_energy.png"))
    savefig(p2, joinpath(save_path, "city_renewable_energy.pdf"))
    
    println("✅ Saved city analysis plots to $save_path/")
    return p1, p2
end

# Equity analysis visualization
function plot_equity_analysis(policy_results::Dict, city_data::Vector; save_path::String="figures")
    if !isdir(save_path)
        mkdir(save_path)
    end
    
    # Extract equity data
    policies = []
    low_income_ratios = []
    high_income_ratios = []
    disparities = []
    
    for (policy_name, metrics) in policy_results
        if policy_name != "city_data" && haskey(metrics, "LowIncomeSupplyRatio")
            push!(policies, policy_name)
            push!(low_income_ratios, metrics["LowIncomeSupplyRatio"] * 100)
            push!(high_income_ratios, metrics["HighIncomeSupplyRatio"] * 100)
            push!(disparities, metrics["SupplyDisparity"] * 100)
        end
    end
    
    # Equity comparison plot
    x_pos = 1:length(policies)
    p1 = plot(x_pos, low_income_ratios, 
              label="Low-Income Cities",
              marker=:circle,
              linewidth=3,
              markersize=8,
              color=:red)
    plot!(x_pos, high_income_ratios,
          label="High-Income Cities", 
          marker=:square,
          linewidth=3,
          markersize=8,
          color=:blue)
    
    # Add reference line at 100%
    hline!([100], color=:gray, linestyle=:dash, alpha=0.6, label="Full Demand")
    
    plot!(title="Energy Equity Analysis",
          ylabel="Demand Fulfillment (%)",
          xlabel="Policy",
          xticks=(x_pos, policies),
          rotation=45,
          legend=:topright,
          size=(800, 500))
    
    # Disparity plot
    p2 = bar(policies, disparities,
             title="Supply Disparity Between Income Groups",
             ylabel="Disparity (%)",
             xlabel="Policy",
             color=:purple,
             alpha=0.7,
             rotation=45)
    
    # Add reference line at 0% (perfect equity)
    hline!([0], color=:green, linestyle=:dash, linewidth=2, label="Perfect Equity")
    
    # Save plots
    savefig(p1, joinpath(save_path, "equity_analysis.png"))
    savefig(p1, joinpath(save_path, "equity_analysis.pdf"))
    savefig(p2, joinpath(save_path, "supply_disparity.png"))
    savefig(p2, joinpath(save_path, "supply_disparity.pdf"))
    
    println("✅ Saved equity analysis plots to $save_path/")
    return p1, p2
end

# Geographic map visualization (simplified for US cities)
function plot_geographic_analysis(city_data::Vector; save_path::String="figures")
    if !isdir(save_path)
        mkdir(save_path)
    end
    
    # Filter for optimal policy results
    optimal_data = filter(data -> data["Policy"] == "Optimal", city_data)
    
    if isempty(optimal_data)
        # Use the first policy if "Optimal" not found
        available_policies = unique([data["Policy"] for data in city_data])
        optimal_data = filter(data -> data["Policy"] == available_policies[1], city_data)
    end
    
    # Extract coordinates and metrics
    lats = [data["Latitude"] for data in optimal_data if haskey(data, "Latitude")]
    lons = [data["Longitude"] for data in optimal_data if haskey(data, "Longitude")]
    cities = [data["City"] for data in optimal_data if haskey(data, "Latitude")]
    supply_ratios = [data["SupplyRatio"] for data in optimal_data if haskey(data, "Latitude")]
    re_percentages = [data["REPercentage"] for data in optimal_data if haskey(data, "Latitude")]
    income_levels = [data["IncomeLevel"] for data in optimal_data if haskey(data, "Latitude")]
    
    # Create geographic scatter plots
    
    # Energy Security Map
    colors_security = [ratio >= 1.0 ? :green : ratio >= 0.8 ? :orange : :red for ratio in supply_ratios]
    sizes_security = [max(8, min(20, ratio * 15)) for ratio in supply_ratios]
    
    p1 = scatter(lons, lats,
                 markersize=sizes_security,
                 markercolor=colors_security,
                 alpha=0.7,
                 title="Energy Security by Geographic Location",
                 xlabel="Longitude",
                 ylabel="Latitude",
                 legend=false)
    
    # Add city labels
    for i in 1:length(cities)
        annotate!(lons[i], lats[i] + 0.5, text(cities[i], 8, :center))
    end
    
    # Renewable Energy Map
    colors_re = [percentage >= 50 ? :darkgreen : percentage >= 25 ? :lightgreen : :yellow for percentage in re_percentages]
    sizes_re = [max(8, min(20, percentage / 5)) for percentage in re_percentages]
    
    p2 = scatter(lons, lats,
                 markersize=sizes_re,
                 markercolor=colors_re,
                 alpha=0.7,
                 title="Renewable Energy Adoption by Geography",
                 xlabel="Longitude", 
                 ylabel="Latitude",
                 legend=false)
    
    # Add city labels
    for i in 1:length(cities)
        annotate!(lons[i], lats[i] + 0.5, text(cities[i], 8, :center))
    end
    
    # Equity Map (colored by income level)
    colors_equity = [level == "High" ? :blue : :red for level in income_levels]
    shapes_equity = [level == "High" ? :circle : :square for level in income_levels]
    
    p3 = scatter(lons, lats,
                 markersize=12,
                 markercolor=colors_equity,
                 markershape=shapes_equity,
                 alpha=0.7,
                 title="Energy Equity by Income Level",
                 xlabel="Longitude",
                 ylabel="Latitude",
                 label=false)
    
    # Add manual legend
    scatter!([NaN], [NaN], markercolor=:blue, markershape=:circle, label="High Income")
    scatter!([NaN], [NaN], markercolor=:red, markershape=:square, label="Low Income")
    
    # Add city labels
    for i in 1:length(cities)
        annotate!(lons[i], lats[i] + 0.5, text(cities[i], 8, :center))
    end
    
    # Save plots
    savefig(p1, joinpath(save_path, "geographic_energy_security.png"))
    savefig(p1, joinpath(save_path, "geographic_energy_security.pdf"))
    savefig(p2, joinpath(save_path, "geographic_renewable_energy.png"))
    savefig(p2, joinpath(save_path, "geographic_renewable_energy.pdf"))
    savefig(p3, joinpath(save_path, "geographic_equity.png"))
    savefig(p3, joinpath(save_path, "geographic_equity.pdf"))
    
    println("✅ Saved geographic analysis plots to $save_path/")
    return p1, p2, p3
end

# Create comprehensive figure for the paper (multi-panel)
function create_paper_figure(policy_results::Dict, city_data::Vector; save_path::String="figures")
    if !isdir(save_path)
        mkdir(save_path)
    end
    
    # Extract key data
    policies = [name for name in keys(policy_results) if name != "city_data"]
    re_percentages = [policy_results[p]["REPercentage"] for p in policies]
    equity_scores = [policy_results[p]["EquityScore"] * 100 for p in policies]
    budget_efficiencies = [policy_results[p]["BudgetEfficiency"] for p in policies]
    
    # Panel A: Multi-objective performance
    p1 = scatter(re_percentages, equity_scores,
                markersize=10,
                alpha=0.7,
                color=:blue,
                title="A) Multi-Objective Performance",
                xlabel="Renewable Energy (%)",
                ylabel="Equity Score (%)",
                legend=false)
    
    # Add policy labels
    for i in 1:length(policies)
        annotate!(re_percentages[i], equity_scores[i] + 2, text(policies[i], 8, :center))
    end
    
    # Panel B: Budget efficiency
    p2 = bar(policies, budget_efficiencies,
             title="B) Budget Efficiency",
             ylabel="GW per Million USD",
             rotation=45,
             color=:orange,
             alpha=0.7)
    
    # Panel C: City-level equity analysis (simplified)
    optimal_city_data = filter(data -> data["Policy"] == policies[1], city_data)  # Use first policy
    city_names = [data["City"] for data in optimal_city_data]
    supply_ratios = [data["SupplyRatio"] * 100 for data in optimal_city_data]
    income_colors = [data["IncomeLevel"] == "High" ? :blue : :red for data in optimal_city_data]
    
    p3 = bar(city_names, supply_ratios,
             title="C) Energy Security by City",
             ylabel="Demand Fulfillment (%)",
             rotation=45,
             color=income_colors,
             alpha=0.7)
    hline!([100], color=:black, linestyle=:dash, label="Full Demand")
    
    # Combine into publication figure
    combined = plot(p1, p2, p3, layout=(2,2), size=(1000, 800))
    
    # Save combined figure
    savefig(combined, joinpath(save_path, "paper_figure_main.png"))
    savefig(combined, joinpath(save_path, "paper_figure_main.pdf"))
    
    println("✅ Saved main paper figure to $save_path/")
    return combined
end

export plot_policy_comparison, plot_city_energy_analysis, plot_equity_analysis,
       plot_geographic_analysis, create_paper_figure