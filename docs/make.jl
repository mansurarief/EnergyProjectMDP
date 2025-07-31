using Documenter
using EnergyProjectMDP

makedocs(;
    modules=[EnergyProjectMDP],
    authors="Mansur Arief <ariefm@stanford.edu>, Riya Kinnarkar <riyakinnarkar@gmail.com>",
    repo="https://github.com/mansurarief/EnergyProjectMDP.jl/blob/{commit}{path}#{line}",
    sitename="EnergyProjectMDP.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://mansurarief.github.io/EnergyProjectMDP.jl",
        assets=String[],
        sidebar_sitename=false
    ),
    pages=[
        "Home" => "index.md",
        "Getting Started" => "getting_started.md",
        "User Guide" => [
            "MDP Formulation" => "mdp_formulation.md",
            "Policies" => "policies.md",
            "Evaluation" => "evaluation.md",
            "Visualization" => "visualization.md"
        ],
        "Examples" => [
            "Basic Usage" => "examples/basic_usage.md",
            "Policy Comparison" => "examples/policy_comparison.md",
            "Custom Policies" => "examples/custom_policies.md"
        ],
        "API Reference" => "api.md",
        "Contributing" => "contributing.md"
    ],
)

deploydocs(;
    repo="github.com/mansurarief/EnergyProjectMDP.jl",
    devbranch="main",
)