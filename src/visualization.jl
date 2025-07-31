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
    create_city_map_improved(mdp, state; filename="energy_map_improved.png", title="Energy Distribution Map")

Create a clean map visualization using GMT with simple, professional styling.
"""
function create_city_map(mdp, state; filename="energy_map_improved.png", title="Energy Distribution Map")
    
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
            @warn "No cities found with coordinates"
            return nothing
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

        # Better colors - more professional
        colors = [income ? "200/60/60" : "60/100/200" for income in income_levels]

        # Define region for Continental US
        region = (-130, -65, 24, 50)

        # Create the map with minimal clean style
        GMT.gmtbegin(filename, fmt=:png)

        # Create better color palette for elevation
        GMT.makecpt(cmap=:earth, range=(-1000, 4000), continuous=true)

        # Load and display topographic relief with clean styling
        topo = GMT.grdcut("@earth_relief_01m", region=region)

        # Display base relief map with clean styling
        GMT.grdimage(topo, 
            proj=(name=:Mercator, center=(-97.5, 37), width=8),
            frame=(axes=:none),
            cmap=true)

        # Add cleaner coastlines
        GMT.coast(
            region=region,
            shore=(pen=0.3, color=:black),
            borders=(level=1, pen=(0.25, :gray40)),
            water="lightblue")

        # Plot cities as circles with cleaner styling
        for i in eachindex(lons)
            # Main circle with white outline
            GMT.plot([lons[i]], [lats[i]], 
                symbol="c$(circle_sizes[i])i",
                fill=colors[i],
                pen="0.5p,white")
            
            # Add energy info for larger circles only - cleaner format
            if circle_sizes[i] > 0.3
                total_energy = Int(round(total_supplies[i]))
                re_percent = re_supplies[i] > 0 ? Int(round(100 * re_supplies[i] / total_supplies[i])) : 0
                energy_text = "$(re_percent)%"
                
                GMT.text([energy_text], x=lons[i]-0.5, y=lats[i]-0.1,
                    font="6p,Helvetica-Bold,white", justify=:center)
            end
            
            # City name with better positioning
            GMT.text([names[i]], x=lons[i]-2.5, y=lats[i] - 1.5,
                font="8p,Helvetica-Bold,black", justify=:center)
        end

        # Cleaner legend
        legend_x, legend_y = -78, 29

        GMT.plot([legend_x], [legend_y], 
            symbol="c0.2i",
            fill="200/60/60", pen="0.5p,white")

        GMT.text(["High Income"], x=legend_x + 1.5, y=legend_y,
            font="9p,Helvetica-Bold,black", justify=:left)

        GMT.plot([legend_x], [legend_y - 2], 
            symbol="c0.2i",
            fill="60/100/200", pen="0.5p,white")

        GMT.text(["Low Income"], x=legend_x + 1.5, y=legend_y - 2,
            font="9p,Helvetica-Bold,black", justify=:left)

        GMT.gmtend(show=false)
        
        println("\n🗺️  Clean GMT Map Created: $filename")
        println("Features:")
        println("  • Borderless design with earth color topography")
        println("  • Simple circles with clean white outlines")
        println("  • Renewable energy percentages on larger cities")
        println("  • Minimal legend positioned over Atlantic Ocean")
        println("\nLegend:")
        println("  🔴 Red circles = High-income cities")
        println("  🔵 Blue circles = Low-income cities")
        println("  📏 Circle size = Total energy supply")
        println("  📊 White % = Renewable energy percentage")
        
        return filename
        
    catch e
        @warn "GMT mapping failed: $e"
        return nothing
    end
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