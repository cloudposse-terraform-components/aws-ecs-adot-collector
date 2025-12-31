# Testing

This directory contains tests for the `aws-ecs-adot-collector` component.

## Running Tests

```bash
atmos test run
```

## Prerequisites

- AWS credentials configured (profile: `cptest-test-gbl-sandbox-admin`)
- Atmos installed
- Go installed (for running Terratest)

## Test Structure

- `component_test.go` - Main test file
- `fixtures/` - Atmos fixtures for test scenarios
