using DataFrames
using Colors
using Printf
using Dates
try
    using GMT
    global GMT_AVAILABLE = true
catch e
    @warn "GMT not available, falling back to Plots.jl for mapping: $e"
    global GMT_AVAILABLE = false
end
using Plots

# City coordinates for visualization (approximate)
const CITY_COORDINATES = Dict(
    "Atlanta" => (-84.3880, 33.7490),
    "New York City" => (-74.0060, 40.7128),
    "San Francisco" => (-122.4194, 37.7749),
    "Memphis" => (-90.0490, 35.1495),
    "Detroit" => (-83.0458, 42.3314),
    "Phoenix" => (-112.0740, 33.4484),
    "Seattle" => (-122.3321, 47.6062),
    "Miami" => (-80.1918, 25.7617),
    "Chicago" => (-87.6298, 41.8781),
    "Los Angeles" => (-118.2537, 34.0522),
    "Houston" => (-95.3698, 29.7604),
    "Philadelphia" => (-75.1652, 39.9526),
    "Boston" => (-71.0589, 42.3601),
    "Dallas" => (-96.7970, 32.7767),
    "Denver" => (-104.9903, 39.7392)
)

"""
    create_city_map(mdp::EnergyMDP, state::State; filename="city_energy_map.png")

Create a map visualization of energy distribution across cities.
Automatically uses GMT if available, otherwise falls back to Plots.jl.
"""
function create_city_map(mdp::EnergyMDP, state::State; filename="city_energy_map.png", 
                        title="Energy Distribution Map")
    if GMT_AVAILABLE
        return create_city_map_gmt(mdp, state, filename=filename, title=title)
    else
        return create_city_map_plots(mdp, state, filename=filename, title=title)
    end
end

"""
    create_city_map_gmt(mdp::EnergyMDP, state::State; filename="city_energy_map.png")

Create a professional map visualization using GMT with topographic base.
"""
function create_city_map_gmt(mdp::EnergyMDP, state::State; filename="city_energy_map.png", 
                            title="Energy Distribution Map")
    if !GMT_AVAILABLE
        @warn "GMT not available, using Plots.jl fallback"
        return create_city_map_plots(mdp, state, filename=filename, title=title)
    end
    
    try
        # Prepare city data
        lons = Float64[]
        lats = Float64[]
        re_supplies = Float64[]
        nre_supplies = Float64[]
        demands = Float64[]
        names = String[]
        income_levels = Bool[]
        
        for city in state.cities
            if haskey(CITY_COORDINATES, city.name)
                lon, lat = CITY_COORDINATES[city.name]
                push!(lons, lon)
                push!(lats, lat)
                push!(re_supplies, city.re_supply)
                push!(nre_supplies, city.nre_supply)
                push!(demands, city.demand)
                push!(names, city.name)
                push!(income_levels, city.income)
            end
        end
        
        if isempty(lons)
            @warn "No cities found with coordinates, using Plots.jl fallback"
            return create_city_map_plots(mdp, state, filename=filename, title=title)
        end
        
        # Calculate circle sizes and colors
        total_supplies = re_supplies .+ nre_supplies
        max_supply = maximum(total_supplies)
        
        # Circle sizes: 0.15 to 0.6 inches for cleaner look
        if max_supply > 0
            circle_sizes = 0.15 .+ (total_supplies ./ max_supply) .* 0.45
        else
            circle_sizes = fill(0.25, length(total_supplies))
        end
        
        # Colors for income levels - using more subtle colors
        colors = [income ? "180/50/50" : "50/100/180" for income in income_levels]
        
        # Define region for Continental US
        region = (-130, -65, 24, 50)
        
        # Create the map with minimal clean style
        GMT.gmtbegin(filename, fmt=:png)
        
        # Load and display topographic relief with minimal styling
        topo = GMT.grdcut("@earth_relief_01m", region=region)
        
        # Create simple color palette for elevation
        GMT.makecpt(cmap=:gray, range=(-1000, 4000), continuous=true)
        
        # Display base relief map with clean styling
        GMT.grdimage(topo, 
            proj=(name=:Mercator, center=(-97.5, 37), width=8),
            frame=(axes=:WSen, annot=:auto, title=title),
            cmap=true)
        
        # Add minimal coastlines
        GMT.coast(
            region=region,
            shore=(pen=0.5, color=:darkgray),
            borders=(level=1, pen=(0.3, :gray50)),
            water=:lightblue)
        
        # Plot cities as circles with clean styling
        for i in eachindex(lons)
            # Main circle using GMT plot
            GMT.plot([lons[i]], [lats[i]], 
                symbol="c$(circle_sizes[i])i",
                fill=colors[i],
                pen="0.5p,white")
            
            # Add energy info for larger circles only
            if circle_sizes[i] > 0.3
                total_energy = Int(round(total_supplies[i]))
                re_percent = re_supplies[i] > 0 ? Int(round(100 * re_supplies[i] / total_supplies[i])) : 0
                energy_text = "$total_energy\n$re_percent%"
                
                GMT.text([lons[i]], [lats[i]], 
                    text=[energy_text],
                    font="5p,Helvetica-Bold,white",
                    justify=:center)
            end
            
            # City name with minimal offset  
            GMT.text([lons[i]], [lats[i] + 1.2], 
                text=[names[i]],
                font="7p,Helvetica,black",
                justify=:center)
        end
        
        # Minimal legend
        legend_x, legend_y = -127, 46
        
        GMT.plot([legend_x], [legend_y], 
            symbol="c0.25i",
            fill="180/50/50", pen="0.5p,white")
        GMT.text([legend_x + 1.5], [legend_y], 
            text=["High Income"],
            font="8p,Helvetica,black")
            
        GMT.plot([legend_x], [legend_y - 1.5], 
            symbol="c0.25i",
            fill="50/100/180", pen="0.5p,white")
        GMT.text([legend_x + 1.5], [legend_y - 1.5], 
            text=["Low Income"],
            font="8p,Helvetica,black")
        
        GMT.text([legend_x], [legend_y - 3], 
            text=["Size ∝ Total Supply"],
            font="7p,Helvetica,black")
        
        GMT.gmtend(show=false)
        
        println("\n🗺️  GMT Map Created: $filename")
        println("Legend:")
        println("  🔴 Red = High-income cities")
        println("  🔵 Blue = Low-income cities") 
        println("  📏 Circle size = Total energy supply (GWh)")
        println("  📊 Numbers = Total supply (GWh) / Renewable %")
        
        return filename
        
    catch e
        @warn "GMT mapping failed: $e. Using Plots.jl fallback."
        return create_city_map_plots(mdp, state, filename=filename, title=title)
    end
end

"""
    create_city_map_plots(mdp::EnergyMDP, state::State; filename="city_energy_map.png")

Fallback map visualization using Plots.jl
"""
function create_city_map_plots(mdp::EnergyMDP, state::State; filename="city_energy_map.png", 
                              title="Energy Distribution Map")
    # Prepare data for plotting
    lons = Float64[]
    lats = Float64[]
    re_supplies = Float64[]
    nre_supplies = Float64[]
    demands = Float64[]
    names = String[]
    income_levels = Bool[]
    
    for city in state.cities
        if haskey(CITY_COORDINATES, city.name)
            lon, lat = CITY_COORDINATES[city.name]
            push!(lons, lon)
            push!(lats, lat)
            push!(re_supplies, city.re_supply)
            push!(nre_supplies, city.nre_supply)
            push!(demands, city.demand)
            push!(names, city.name)
            push!(income_levels, city.income)
        end
    end
    
    if isempty(lons)
        @warn "No cities found with coordinates. Using default coordinates."
        # Create default visualization
        for (i, city) in enumerate(state.cities)
            push!(lons, -120.0 + i * 5.0)  # Spread across longitude
            push!(lats, 35.0 + (i % 3) * 5.0)  # Vary latitude
            push!(re_supplies, city.re_supply)
            push!(nre_supplies, city.nre_supply)
            push!(demands, city.demand)
            push!(names, city.name)
            push!(income_levels, city.income)
        end
    end
    
    # Create geographic-style plot with US base map
    try
        # Calculate circle sizes based on total supply
        total_supplies = re_supplies .+ nre_supplies
        max_supply = maximum(total_supplies)
        if max_supply > 0
            # Scale circles: min 50 pixels, max 400 pixels for better visibility
            circle_sizes = 50 .+ (total_supplies ./ max_supply) .* 350
        else
            circle_sizes = fill(100, length(total_supplies))
        end
        
        # Create color scheme for income levels
        colors = [income ? :red : :blue for income in income_levels]
        
        # Create base map plot with US boundaries
        p = Plots.plot(
            title=title,
            xlabel="Longitude",
            ylabel="Latitude", 
            xlims=(-130, -65),  # Continental US longitude bounds
            ylims=(24, 50),     # Continental US latitude bounds
            size=(1000, 700),
            dpi=300,
            grid=true,
            gridcolor=:gray90,
            framestyle=:box,
            background_color=:aliceblue
        )
        
        # Add simple US state boundaries (approximate)
        # Draw continental US outline
        us_outline_lon = [-125, -125, -117, -117, -110, -102, -94, -83, -80, -75, -67, -67, -69, -70, -74, -75, -80, -81, -82, -87, -89, -89, -95, -98, -104, -111, -117, -124, -125]
        us_outline_lat = [48, 32, 32, 33, 31, 29, 29, 25, 25, 25, 45, 47, 47, 45, 41, 40, 35, 31, 28, 30, 29, 36, 36, 38, 40, 42, 43, 46, 48]
        
        Plots.plot!(p, us_outline_lon, us_outline_lat, 
              color=:gray50, linewidth=2, linestyle=:solid, label="")
        
        # Add Great Lakes (simplified)
        Plots.plot!(p, [-92, -92, -83, -79, -76, -79, -83, -87, -92], 
              [46, 48, 46, 44, 43, 42, 41, 42, 46], 
              color=:lightblue, fill=(0, :lightblue), label="", alpha=0.5)
        
        # Plot cities as circles with proper sizing
        for i in eachindex(lons)
            # Draw circle with fill
            Plots.scatter!(p, [lons[i]], [lats[i]], 
                    markersize=circle_sizes[i]/10,  # Adjust scale for Plots.jl
                    markercolor=colors[i],
                    markerstrokecolor=:white,
                    markerstrokewidth=2,
                    alpha=0.8,
                    label="")
            
            # Add energy info inside circle if large enough
            if circle_sizes[i] > 150
                total_energy = total_supplies[i]
                re_percent = re_supplies[i] > 0 ? round(100 * re_supplies[i] / total_energy, digits=0) : 0
                Plots.annotate!(p, lons[i], lats[i], 
                         Plots.text("$(Int(round(total_energy)))\n$(Int(re_percent))%", 6, :white, :center))
            end
        end
        
        # Add city labels above circles
        for i in eachindex(lons)
            y_offset = circle_sizes[i] / 2000 + 0.5  # Dynamic offset based on circle size
            Plots.annotate!(p, lons[i], lats[i] + y_offset, 
                     Plots.text(names[i], 9, :black, :center, :bold))
        end
        
        # Add custom legend with proper sizing examples
        legend_x = -128
        legend_y = 47
        
        # Legend title
        Plots.annotate!(p, legend_x, legend_y, Plots.text("Legend", 10, :black, :left, :bold))
        
        # Income level legend
        Plots.scatter!(p, [legend_x], [legend_y - 1.5], markercolor=:red, markersize=8, 
                markerstrokecolor=:white, markerstrokewidth=1, label="", alpha=0.8)
        Plots.annotate!(p, legend_x + 1, legend_y - 1.5, Plots.text("High Income", 8, :black, :left))
        
        Plots.scatter!(p, [legend_x], [legend_y - 2.5], markercolor=:blue, markersize=8,
                markerstrokecolor=:white, markerstrokewidth=1, label="", alpha=0.8)
        Plots.annotate!(p, legend_x + 1, legend_y - 2.5, Plots.text("Low Income", 8, :black, :left))
        
        # Size legend
        Plots.annotate!(p, legend_x, legend_y - 4, Plots.text("Circle Size = Total Energy Supply", 8, :black, :left))
        Plots.annotate!(p, legend_x, legend_y - 5, Plots.text("Numbers: Total GWh / RE%", 8, :black, :left))
        
        # Add title box
        Plots.plot!(p, annotation=((-97.5, 49), Plots.text("US Energy Distribution by City", 14, :black, :center, :bold)))
        
        # Save the plot if filename is provided
        if !isempty(filename)
            Plots.savefig(p, filename)
        end
        
        # Create legend information
        println("\n📊 Map Created: $filename")
        println("Legend:")
        println("  🔴 Red = High-income cities")
        println("  🔵 Blue = Low-income cities") 
        println("  📏 Circle size = Total energy supply (GWh)")
        println("  📊 Numbers = Total supply (GWh) / Renewable %")
        
    catch e
        @warn "Geographic visualization failed: $e. Creating alternative plot."
        create_alternative_city_plot(state, filename, title)
    end
    
    return filename
end

"""
    create_alternative_city_plot(state::State, filename::String, title::String)

Create an alternative visualization using Plots.jl when GMT is not available.
"""
function create_alternative_city_plot(state::State, filename::String, title::String)
    # Create scatter plot
    x_coords = 1:length(state.cities)
    re_supplies = [city.re_supply for city in state.cities]
    nre_supplies = [city.nre_supply for city in state.cities]
    demands = [city.demand for city in state.cities]
    names = [city.name for city in state.cities]
    
    p = Plots.plot(title=title, xlabel="Cities", ylabel="Energy (GWh)", 
             size=(800, 600), dpi=300)
    
    # Plot stacked bars for supply
    Plots.bar!(p, x_coords, re_supplies, label="Renewable Energy", color=:green, alpha=0.7)
    Plots.bar!(p, x_coords, nre_supplies, bottom=re_supplies, label="Non-Renewable Energy", 
         color=:red, alpha=0.7)
    
    # Plot demand as line
    Plots.plot!(p, x_coords, demands, label="Demand", linewidth=3, color=:black, 
          linestyle=:dash)
    
    # Add city names as x-axis labels
    Plots.plot!(p, xticks=(x_coords, names), xrotation=45)
    
    # Save plot
    Plots.savefig(p, filename)
    return filename
end

"""
    create_policy_comparison_chart(results::Dict; filename="policy_comparison.png")

Create a comparison chart of different policies' performance.
"""
function create_policy_comparison_chart(results::Dict; filename="policy_comparison.png")
    policy_names = collect(keys(results))
    rewards_mean = [results[name]["total_reward_mean"] for name in policy_names]
    rewards_std = [results[name]["total_reward_std"] for name in policy_names]
    
    # Create bar chart with error bars
    p = Plots.bar(policy_names, rewards_mean, yerror=rewards_std,
            title="Policy Performance Comparison",
            xlabel="Policy", ylabel="Average Total Reward",
            size=(800, 600), dpi=300,
            color=:viridis, alpha=0.8)
    
    # Rotate x-axis labels if needed
    Plots.plot!(p, xrotation=45)
    
    # Add value labels on bars
    for (i, (mean_val, std_val)) in enumerate(zip(rewards_mean, rewards_std))
        Plots.annotate!(p, i, mean_val + std_val + 5, 
                 Plots.text(@sprintf("%.1f±%.1f", mean_val, std_val), 8, :center))
    end
    
    Plots.savefig(p, filename)
    return filename
end

"""
    create_energy_distribution_pie(state::State; filename="energy_distribution.png")

Create pie charts showing renewable vs non-renewable energy distribution.
"""
function create_energy_distribution_pie(state::State; filename="energy_distribution.png")
    total_re = sum([city.re_supply for city in state.cities])
    total_nre = sum([city.nre_supply for city in state.cities])
    total_demand = sum([city.demand for city in state.cities])
    unmet_demand = max(0, total_demand - total_re - total_nre)
    
    # Create supply pie chart
    if total_re + total_nre > 0
        p1 = Plots.pie(["Renewable", "Non-Renewable"], 
                [total_re, total_nre],
                title="Energy Supply Distribution",
                colors=[:green, :red], alpha=0.8)
    else
        p1 = Plots.plot(title="No Energy Supply", showaxis=false, grid=false)
    end
    
    # Create demand fulfillment pie chart
    met_demand = total_re + total_nre
    if total_demand > 0
        p2 = Plots.pie(["Met Demand", "Unmet Demand"], 
                [met_demand, unmet_demand],
                title="Demand Fulfillment",
                colors=[:lightblue, :orange], alpha=0.8)
    else
        p2 = Plots.plot(title="No Demand", showaxis=false, grid=false)
    end
    
    # Combine plots
    combined_plot = Plots.plot(p1, p2, layout=(1, 2), size=(800, 400), dpi=300)
    Plots.savefig(combined_plot, filename)
    return filename
end

"""
    create_equity_analysis(state::State; filename="equity_analysis.png")

Create visualization showing equity distribution across cities.
"""
function create_equity_analysis(state::State; filename="equity_analysis.png")
    city_names = [city.name for city in state.cities]
    deficits = [max(0, city.demand - city.re_supply - city.nre_supply) for city in state.cities]
    income_levels = [city.income ? "High Income" : "Low Income" for city in state.cities]
    populations = [city.population / 1000000 for city in state.cities]  # Convert to millions
    
    # Create grouped bar chart
    high_income_deficits = [deficit for (deficit, income) in zip(deficits, income_levels) if income == "High Income"]
    low_income_deficits = [deficit for (deficit, income) in zip(deficits, income_levels) if income == "Low Income"]
    high_income_names = [name for (name, income) in zip(city_names, income_levels) if income == "High Income"]
    low_income_names = [name for (name, income) in zip(city_names, income_levels) if income == "Low Income"]
    
    p = Plots.plot(title="Energy Deficit by City Income Level", 
             xlabel="Cities", ylabel="Energy Deficit (GWh)",
             size=(800, 600), dpi=300)
    
    if !isempty(high_income_names)
        Plots.bar!(p, high_income_names, high_income_deficits, 
             label="High Income Cities", color=:blue, alpha=0.7)
    end
    
    if !isempty(low_income_names)
        Plots.bar!(p, low_income_names, low_income_deficits, 
             label="Low Income Cities", color=:red, alpha=0.7)
    end
    
    Plots.plot!(p, xrotation=45)
    
    Plots.savefig(p, filename)
    return filename
end

"""
    create_simulation_trajectory(history; filename="simulation_trajectory.png")

Create visualization showing the trajectory of a simulation.
"""
function create_simulation_trajectory(history; filename="simulation_trajectory.png")
    if isempty(history)
        @warn "Empty history provided"
        return filename
    end
    
    steps = 1:length(history)
    budgets = [step.s.b for step in history]
    rewards = [step.r for step in history]
    
    # Calculate total supply over time
    total_supplies = []
    total_demands = []
    re_supplies = []
    
    for step in history
        total_supply = sum([city.re_supply + city.nre_supply for city in step.s.cities])
        total_demand = sum([city.demand for city in step.s.cities])
        re_supply = sum([city.re_supply for city in step.s.cities])
        
        push!(total_supplies, total_supply)
        push!(total_demands, total_demand)
        push!(re_supplies, re_supply)
    end
    
    # Create subplots
    p1 = Plots.plot(steps, budgets, title="Budget Over Time", 
              xlabel="Step", ylabel="Budget (\$M)", 
              linewidth=2, color=:green)
    
    p2 = Plots.plot(steps, rewards, title="Rewards Over Time",
              xlabel="Step", ylabel="Reward",
              linewidth=2, color=:red)
    
    p3 = Plots.plot(steps, total_supplies, label="Total Supply", linewidth=2, color=:blue)
    Plots.plot!(p3, steps, total_demands, label="Total Demand", linewidth=2, color=:black, linestyle=:dash)
    Plots.plot!(p3, steps, re_supplies, label="RE Supply", linewidth=2, color=:green)
    Plots.plot!(p3, title="Energy Over Time", xlabel="Step", ylabel="Energy (GWh)")
    
    # Combine plots
    combined_plot = Plots.plot(p1, p2, p3, layout=(3, 1), size=(800, 900), dpi=300)
    Plots.savefig(combined_plot, filename)
    return filename
end

"""
    generate_comprehensive_report(mdp::EnergyMDP, results::Dict, final_state::State; 
                                 output_dir="visualization_output")

Generate a comprehensive visualization report with multiple charts and maps.
"""
function generate_comprehensive_report(mdp::EnergyMDP, results::Dict, final_state::State; 
                                     output_dir="visualization_output")
    # Create output directory
    if !isdir(output_dir)
        mkdir(output_dir)
    end
    
    generated_files = String[]
    
    try
        # 1. City energy map
        map_file = joinpath(output_dir, "energy_map.png")
        create_city_map(mdp, final_state, filename=map_file, 
                       title="Final Energy Distribution Map")
        push!(generated_files, map_file)
        
        # 2. Policy comparison
        if length(results) > 1
            comparison_file = joinpath(output_dir, "policy_comparison.png")
            create_policy_comparison_chart(results, filename=comparison_file)
            push!(generated_files, comparison_file)
        end
        
        # 3. Energy distribution pie charts
        pie_file = joinpath(output_dir, "energy_distribution.png")
        create_energy_distribution_pie(final_state, filename=pie_file)
        push!(generated_files, pie_file)
        
        # 4. Equity analysis
        equity_file = joinpath(output_dir, "equity_analysis.png")
        create_equity_analysis(final_state, filename=equity_file)
        push!(generated_files, equity_file)
        
        # 5. Create summary report
        summary_file = joinpath(output_dir, "summary_report.txt")
        create_summary_report(mdp, results, final_state, summary_file)
        push!(generated_files, summary_file)
        
        println("📊 Comprehensive visualization report generated!")
        println("🗂️  Output directory: $output_dir")
        println("📁 Generated files:")
        for file in generated_files
            println("   - $(basename(file))")
        end
        
    catch e
        @warn "Error generating comprehensive report: $e"
    end
    
    return generated_files
end

"""
    create_summary_report(mdp::EnergyMDP, results::Dict, final_state::State, filename::String)

Create a text summary report of the analysis.
"""
function create_summary_report(mdp::EnergyMDP, results::Dict, final_state::State, filename::String)
    open(filename, "w") do file
        println(file, "="^80)
        println(file, "ENERGY PROJECT MDP - ANALYSIS SUMMARY REPORT")
        println(file, "="^80)
        println(file)
        
        # MDP Configuration
        println(file, "MDP CONFIGURATION:")
        println(file, "-"^40)
        println(file, "Number of Cities: $(mdp.numberOfCities)")
        println(file, "Initial Budget: \$$(mdp.initialBudget)M")
        println(file, "Discount Rate: $(mdp.discountRate)")
        println(file, "RE Supply per Action: $(mdp.supplyOfRE) GWh")
        println(file, "NRE Supply per Action: $(mdp.supplyOfNRE) GWh")
        println(file, "Cost of Adding RE: \$$(mdp.costOfAddingRE)M")
        println(file, "Cost of Adding NRE: \$$(mdp.costOfAddingNRE)M")
        println(file)
        
        # Final State Analysis
        println(file, "FINAL STATE ANALYSIS:")
        println(file, "-"^40)
        println(file, "Final Budget: \$$(final_state.b)M")
        
        total_demand = sum([city.demand for city in final_state.cities])
        total_re = sum([city.re_supply for city in final_state.cities])
        total_nre = sum([city.nre_supply for city in final_state.cities])
        total_supply = total_re + total_nre
        
        println(file, "Total Demand: $(total_demand) GWh")
        println(file, "Total Supply: $(total_supply) GWh")
        println(file, "  - Renewable: $(total_re) GWh ($(round(total_re/total_supply*100, digits=1))%)")
        println(file, "  - Non-Renewable: $(total_nre) GWh ($(round(total_nre/total_supply*100, digits=1))%)")
        println(file, "Supply-Demand Gap: $(total_supply - total_demand) GWh")
        println(file)
        
        # City Details
        println(file, "CITY DETAILS:")
        println(file, "-"^40)
        for (i, city) in enumerate(final_state.cities)
            supply = city.re_supply + city.nre_supply
            deficit = max(0, city.demand - supply)
            income_str = city.income ? "High" : "Low"
            
            println(file, "$i. $(city.name) ($income_str Income)")
            println(file, "   Population: $(Int(city.population/1000))K")
            println(file, "   Demand: $(city.demand) GWh")
            println(file, "   Supply: $(supply) GWh (RE: $(city.re_supply), NRE: $(city.nre_supply))")
            if deficit > 0
                println(file, "   ⚠️  Deficit: $(deficit) GWh")
            else
                println(file, "   ✅ Fully Supplied")
            end
            println(file)
        end
        
        # Policy Results
        if !isempty(results)
            println(file, "POLICY PERFORMANCE COMPARISON:")
            println(file, "-"^40)
            for (policy_name, metrics) in results
                println(file, "$(policy_name):")
                total_reward_mean = round(metrics["total_reward_mean"], digits=1)
                total_reward_std = round(metrics["total_reward_std"], digits=1)
                println(file, "  Total Reward: $total_reward_mean ± $total_reward_std")
                if haskey(metrics, "budget_mean")
                    budget_mean = round(metrics["budget_mean"], digits=1)
                    println(file, "  Final Budget: \$$(budget_mean)M")
                end
                println(file)
            end
        end
        
        # Equity Analysis
        println(file, "EQUITY ANALYSIS:")
        println(file, "-"^40)
        low_income_cities = filter(city -> !city.income, final_state.cities)
        high_income_cities = filter(city -> city.income, final_state.cities)
        
        low_income_unmet = sum([max(0, city.demand - city.re_supply - city.nre_supply) for city in low_income_cities])
        high_income_unmet = sum([max(0, city.demand - city.re_supply - city.nre_supply) for city in high_income_cities])
        
        println(file, "Low-Income Cities Unmet Demand: $(low_income_unmet) GWh")
        println(file, "High-Income Cities Unmet Demand: $(high_income_unmet) GWh")
        
        if low_income_unmet > high_income_unmet
            println(file, "⚠️  Equity Issue: Low-income cities have higher unmet demand")
        else
            println(file, "✅ Equity Status: Reasonable distribution")
        end
        
        println(file)
        println(file, "="^80)
        println(file, "Report generated on: $(Dates.now())")
        println(file, "="^80)
    end
end

# Export visualization functions
export create_city_map, create_policy_comparison_chart, create_energy_distribution_pie,
       create_equity_analysis, create_simulation_trajectory, generate_comprehensive_report