# AI Agent Guide

This document serves as the primary reference for AI assistants working in this codebase. It provides guidance on available skills and slash commands.

## Available Skills

Skills leverage AI to analyze, review, and provide context-aware feedback.

### Golang Code Review

- **Golang Coding Standards**: `.ai/skills/golang-standards.md`
  - When: Reviewing Go code for idiomatic patterns, best practices, and coding standards
  - Tokens: ~2000
  - Use for: Code review, refactoring suggestions, understanding Go idioms
  - Note: Complements automated linters by focusing on patterns and context

## Available Slash Commands

Slash commands execute predefined automated actions without AI analysis. See `.ai/commands/README.md` for full list and usage.

### Quick Reference

- `/format` - Format all Go code (gofmt, goimports)
- `/lint` - Run golangci-lint
- `/test` - Run all tests with coverage
- `/generate-manifests` - Generate CRD manifests
- `/update-k8s-deps` - Update Kubernetes dependencies
- `/check-deprecated-apis` - Scan for deprecated K8s APIs

For complete command list and Kubernetes operator-specific commands, see `.ai/commands/README.md`.
