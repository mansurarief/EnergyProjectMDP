# Contributing to EnergyProjectMDP.jl

Thank you for your interest in contributing to EnergyProjectMDP.jl! This document provides guidelines and information for contributors.

## Code of Conduct

This project adheres to a code of conduct adapted from the [Contributor Covenant](https://www.contributor-covenant.org/). By participating, you are expected to uphold this code. Please report unacceptable behavior to the project maintainers.

## How to Contribute

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, please include:

- A clear and descriptive title
- Steps to reproduce the issue
- Expected vs actual behavior
- Your environment (OS, Julia version, package version)
- Minimal code example that demonstrates the issue
- Full error messages and stack traces

Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md).

### Suggesting Features

Feature requests are welcome! Please use our [feature request template](.github/ISSUE_TEMPLATE/feature_request.md) and include:

- Clear description of the proposed feature
- Use case and motivation
- Examples of how it would be used
- Any implementation ideas you might have

### Pull Requests

We actively welcome pull requests! Here's the process:

1. **Fork the repository** and create your branch from `main`
2. **Set up development environment**:
   ```bash
   git clone https://github.com/yourusername/EnergyProjectMDP.jl.git
   cd EnergyProjectMDP
   julia --project=.
   ```
   
   In Julia:
   ```julia
   using Pkg
   Pkg.instantiate()
   ```

3. **Make your changes** following our coding guidelines
4. **Add tests** for new functionality
5. **Update documentation** if needed
6. **Run tests** to ensure everything passes:
   ```bash
   make test
   # or
   julia --project=. -e "using Pkg; Pkg.test()"
   ```
7. **Submit a pull request** using our [PR template](.github/pull_request_template.md)

## Development Guidelines

### Code Style

- Follow [Julia style guidelines](https://docs.julialang.org/en/v1/manual/style-guide/)
- Use descriptive variable and function names
- Limit line length to 92 characters
- Use 4 spaces for indentation (no tabs)
- Add blank lines around function definitions
- Use snake_case for variable names and PascalCase for types

### Documentation

- Add docstrings for all public functions using Julia's docstring format:
  ```julia
  """
      function_name(arg1, arg2; keyword=default)

  Brief description of what the function does.

  # Arguments
  - `arg1::Type`: Description of arg1
  - `arg2::Type`: Description of arg2
  - `keyword::Type`: Description of keyword argument

  # Returns
  - `ReturnType`: Description of return value

  # Examples
  ```julia
  result = function_name(1, 2, keyword=3)
  ```
  """
  function function_name(arg1, arg2; keyword=default)
      # implementation
  end
  ```

- Update relevant documentation files in `docs/src/`
- Include examples in docstrings when helpful
- Keep documentation clear and concise

### Testing

- Write tests for all new functionality
- Place tests in appropriate files under `test/`
- Use descriptive test names and group related tests with `@testset`
- Aim for high test coverage
- Test edge cases and error conditions
- Example test structure:
  ```julia
  @testset "Feature Name Tests" begin
      @testset "Basic functionality" begin
          # Test normal cases
          @test expected_result == actual_result
      end
      
      @testset "Edge cases" begin
          # Test boundary conditions
          @test_throws ErrorType function_call(invalid_input)
      end
  end
  ```

### Commit Messages

Write clear, concise commit messages:

- Use the imperative mood ("Add feature" not "Added feature")
- Limit the first line to 50 characters
- Reference issues and pull requests when relevant
- Example:
  ```
  Add visualization for policy comparison

  - Create bar chart comparing policy performance
  - Include error bars for confidence intervals
  - Add customizable color schemes
  
  Fixes #123
  ```

### Adding New Policies

When adding new decision-making policies:

1. **Create the policy type** in `src/policies.jl`:
   ```julia
   struct MyNewPolicy <: Policy
       parameter1::Float64
       parameter2::Bool
   end
   ```

2. **Implement the action function**:
   ```julia
   function POMDPs.action(policy::MyNewPolicy, state::State)
       # Policy logic here
       return selected_action
   end
   ```

3. **Add comprehensive tests** in `test/test_policies.jl`
4. **Update documentation** with policy description and usage examples
5. **Add the policy to examples** for comparison

### Adding Visualization Features

When adding new visualization capabilities:

1. **Add functions to** `src/visualization.jl`
2. **Export new functions** in `src/EnergyProjectMDP.jl`
3. **Handle errors gracefully** (fallback to simpler plots if libraries unavailable)
4. **Include customization options** (colors, sizes, labels, etc.)
5. **Write comprehensive tests**
6. **Update documentation** with examples

## Release Process

Releases are handled by maintainers:

1. Update version number in `Project.toml`
2. Update `CHANGELOG.md` with release notes
3. Create and push a version tag
4. GitHub Actions will automatically create the release

## Getting Help

- Check existing [issues](https://github.com/mansurarief/EnergyProjectMDP.jl/issues)
- Read the [documentation](https://mansurarief.github.io/EnergyProjectMDP.jl/stable/)
- Start a [discussion](https://github.com/mansurarief/EnergyProjectMDP.jl/discussions)
- Contact maintainers directly for sensitive issues

## Recognition

Contributors will be recognized in:

- The project's README
- Release notes for significant contributions
- Academic papers that use the package (with permission)

## Development Roadmap

Current priorities include:

- [ ] Enhanced visualization capabilities
- [ ] More sophisticated policy algorithms
- [ ] Integration with real-world energy datasets
- [ ] Performance optimizations for large-scale problems
- [ ] Web interface for interactive exploration

## Questions?

Don't hesitate to ask! We're here to help make your contribution experience positive and productive.

Thank you for contributing to EnergyProjectMDP.jl! 🎉