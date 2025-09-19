# Contributing to MTN MoMo API Elixir

Thank you for your interest in contributing to the MTN MoMo API Elixir library! 🎉

We welcome contributions from everyone, whether you're fixing a bug, adding a feature, improving documentation, or just asking questions.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing](#testing)
- [Documentation](#documentation)
- [Community](#community)

## Code of Conduct

This project adheres to a [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code. Please report unacceptable behavior to [patrick@oryono.dev].

## Getting Started

### Prerequisites

- Elixir 1.9 or later
- Erlang/OTP 22 or later
- Git

### Development Setup

1. **Fork the repository**
   ```bash
   # Fork on GitHub, then clone your fork
   git clone https://github.com/YOUR_USERNAME/momoapi-elixir.git
   cd momoapi-elixir
   ```

2. **Set up the development environment**
   ```bash
   # Install dependencies
   mix deps.get

   # Run tests to ensure everything works
   mix test

   # Format code
   mix format

   # Run static analysis
   mix credo
   ```

3. **Set up sandbox credentials (optional)**
   ```bash
   # For testing with real MTN sandbox API
   mix provision YOUR_SUBSCRIPTION_KEY https://your-callback-url.com
   ```

## How to Contribute

### 🐛 Reporting Bugs

Before creating a bug report, please:
1. Check the existing [issues](https://github.com/oryono/momoapi-elixir/issues)
2. Make sure you're using the latest version

When filing a bug report, please include:
- Elixir and Erlang versions
- Steps to reproduce the issue
- Expected vs actual behavior
- Code samples (if applicable)
- Error messages/stack traces

### 💡 Suggesting Features

Feature suggestions are welcome! Please:
1. Check existing [issues](https://github.com/oryono/momoapi-elixir/issues) and [discussions](https://github.com/oryono/momoapi-elixir/discussions)
2. Open a GitHub issue with the `enhancement` label
3. Clearly describe the feature and its use case
4. Consider starting with a discussion for major features

### 🔧 Contributing Code

We love code contributions! Here are some ways to help:

#### Good First Issues
Look for issues labeled `good first issue` - these are perfect for newcomers.

#### Areas Needing Help
- Improving error messages and validation
- Adding more comprehensive tests
- Performance optimizations
- Documentation improvements
- Examples and tutorials

## Pull Request Process

### 1. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b bugfix/issue-description
```

### 2. Make Your Changes

- Follow the [coding standards](#coding-standards)
- Add tests for new functionality
- Update documentation as needed
- Ensure all tests pass

### 3. Commit Your Changes

Use clear, descriptive commit messages:

```bash
git commit -m "Add support for recurring payments

- Implement recurring payment scheduling
- Add validation for payment intervals
- Update documentation with examples
- Add comprehensive test coverage

Fixes #123"
```

### 4. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub with:
- Clear title and description
- Reference to related issues
- Screenshots/examples if applicable
- Checklist of changes made

### 5. Code Review

- Address feedback constructively
- Make requested changes in new commits
- Keep the PR up to date with main branch

## Coding Standards

### Elixir Style Guide

We follow the standard [Elixir Style Guide](https://github.com/christopheradams/elixir_style_guide) with these additions:

#### Code Formatting
```bash
# Format your code before committing
mix format
```

#### Documentation
- Add `@doc` to all public functions
- Include examples in documentation
- Use proper typespecs with `@spec`

```elixir
@doc """
Request a payment from a consumer.

## Examples

    iex> config = %{subscription_key: "key", ...}
    iex> payment = %{amount: "100", currency: "UGX", ...}
    iex> Collections.request_to_pay(config, payment)
    {:ok, "reference-id-uuid"}
"""
@spec request_to_pay(config(), payment_request()) :: {:ok, String.t()} | {:error, term()}
def request_to_pay(config, payment) do
  # Implementation
end
```

#### Error Handling
- Use `{:ok, result}` / `{:error, reason}` tuples
- Provide structured error information
- Include helpful error messages

```elixir
case validate_payment(payment) do
  {:ok, validated_payment} ->
    # proceed
  {:error, validation_errors} ->
    {:error, {:validation_failed, validation_errors}}
end
```

#### Naming Conventions
- Use descriptive function and variable names
- Follow Elixir naming conventions (snake_case for functions, PascalCase for modules)
- Be consistent with existing code

## Testing

### Running Tests

```bash
# Run all tests
mix test

# Run specific test file
mix test test/collections_test.exs

# Run with coverage
mix test --cover

# Run tests continuously during development
mix test.watch
```

### Test Guidelines

1. **Write tests for all new functionality**
2. **Include both positive and negative test cases**
3. **Test error conditions thoroughly**
4. **Use descriptive test names**
5. **Mock external API calls using Mox**

#### Test Structure Example

```elixir
defmodule MomoapiElixir.CollectionsTest do
  use ExUnit.Case, async: true
  import Mox

  describe "request_to_pay/2" do
    test "returns reference_id on successful payment request" do
      # Setup mocks
      ClientMock
      |> expect(:post, fn _url, _body, _headers ->
        {:ok, %{status_code: 202, body: ""}}
      end)

      # Test
      result = Collections.request_to_pay(config, valid_payment)

      # Assert
      assert {:ok, reference_id} = result
      assert is_binary(reference_id)
    end

    test "returns validation errors for invalid payment" do
      invalid_payment = %{amount: ""}

      result = Collections.request_to_pay(config, invalid_payment)

      assert {:error, validation_errors} = result
      assert is_list(validation_errors)
    end
  end
end
```

## Documentation

### Code Documentation

- Add `@moduledoc` to all modules
- Add `@doc` to all public functions
- Include examples in documentation
- Use proper typespecs

### README Updates

- Update examples when changing APIs
- Keep installation instructions current
- Add new features to feature lists

### Changelog

- Update `CHANGELOG.md` for all notable changes
- Follow [Keep a Changelog](https://keepachangelog.com/) format
- Include migration guides for breaking changes

## Release Process

Releases are managed by maintainers. The process includes:

1. Update version in `mix.exs`
2. Update `CHANGELOG.md`
3. Create Git tag
4. Publish to Hex.pm
5. Update documentation on HexDocs

## Community

### Getting Help

- 📖 **Documentation**: [HexDocs](https://hexdocs.pm/momoapi_elixir)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/oryono/momoapi-elixir/discussions)
- 🐛 **Issues**: [GitHub Issues](https://github.com/oryono/momoapi-elixir/issues)

### Communication

- Be respectful and constructive
- Use clear, descriptive titles for issues and PRs
- Provide context and examples when asking questions
- Help others when you can

## Recognition

Contributors are recognized in:
- `CONTRIBUTORS.md` file
- Release notes
- GitHub contributors list

## Questions?

If you have questions about contributing, feel free to:
- Open a [GitHub Discussion](https://github.com/oryono/momoapi-elixir/discussions)
- Create an issue with the `question` label
- Reach out to maintainers

Thank you for contributing! 🚀