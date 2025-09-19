# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Major refactor: Convert to functional API and improve architecture
- Add `MomoapiElixir.Config` module for environment variable support
- Add production configuration with proper base URLs (`config/prod.exs`)
- Add comprehensive input validation with structured error responses
- Add environment-specific configuration (dev/test/prod)
- Add support for environment variables (MOMO_SUBSCRIPTION_KEY, etc.)
- Add proper typespecs and documentation throughout
- Add comprehensive test coverage including validator tests

### Changed
- **BREAKING**: Replace GenServer-based API with functional approach
- **BREAKING**: Replace `MomoapiElixir.Collection` with `MomoapiElixir.Collections`
- **BREAKING**: Replace `MomoapiElixir.Disbursement` with `MomoapiElixir.Disbursements`
- **BREAKING**: Change from stateful to stateless API calls
- Replace deprecated `Mix.Config` with modern `Config` module
- Improve error handling with `{:ok, result}` / `{:error, reason}` patterns
- Update base URLs: sandbox vs production endpoints
- Implement compile-time HTTP client configuration for better testability

### Fixed
- Remove code duplication between collections and disbursements
- Fix incomplete error handling for HTTP status codes
- Fix validation logic to return structured errors instead of raising exceptions
- Fix hard-coded sandbox environment in production

### Removed
- **BREAKING**: Remove GenServer-based API modules
- Remove global state requirements
- Remove complex setup procedures

## [0.1.1] - 2023-XX-XX

### Added
- Disbursement functionality with tests
- Refactored disbursements module
- Added comprehensive test coverage for disbursements

### Fixed
- Various bug fixes and improvements

## [0.1.0] - Initial Release

### Added
- Basic MTN MoMo API integration
- Collections API support
- Disbursements API support
- GenServer-based architecture
- Basic test coverage
- Mix task for credential provisioning
- README documentation

### Features
- Payment collection from consumers
- Money transfer to payees
- Account balance checking
- Transaction status monitoring
- Sandbox environment support

---

## Migration Guide

### From 0.1.x to 1.0.0

The v1.0.0 release includes breaking changes that modernize the API. Here's how to migrate:

#### Old API (v0.1.x)
```elixir
# GenServer-based approach
options = %Collection.Option{
  subscription_key: "key",
  user_id: "user",
  api_key: "api"
}
Collection.start(options)
Collection.request_to_pay(body)
```

#### New API (v1.0.0+)
```elixir
# Functional approach
config = %{
  subscription_key: "key",
  user_id: "user",
  api_key: "api",
  target_environment: "sandbox"
}
{:ok, reference_id} = MomoapiElixir.Collections.request_to_pay(config, body)
```

#### Key Changes
1. **No more GenServer setup** - Direct function calls
2. **Module names** - `Collection` → `Collections`, `Disbursement` → `Disbursements`
3. **Configuration** - Pass config to each function call
4. **Error handling** - Structured errors instead of exceptions
5. **Environment variables** - Built-in support via `MomoapiElixir.Config`

#### Benefits of Migration
- **Simpler API** - No GenServer management
- **Better testing** - Pure functions, easy mocking
- **Production ready** - Environment-specific configuration
- **Modern Elixir** - Follows current best practices
- **Better errors** - Detailed validation feedback

For detailed migration examples, see the [Migration Guide](docs/MIGRATION.md).