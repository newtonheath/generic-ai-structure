# AI Slash Commands

This directory contains slash commands for quick, automated actions in the codebase.

## What are Slash Commands?

Slash commands are **automated actions** that execute predefined tasks without requiring AI analysis. They're ideal for:
- Running tests, linters, or formatters
- Generating boilerplate code
- Executing build or deployment scripts
- Performing routine maintenance tasks

**Key Difference from Skills:**
- **Skills** = AI analyzes and provides feedback (uses AI model)
- **Commands** = Automated execution of predefined actions (minimal/no AI)

---

## Available Commands

### Code Quality

- `/format` - Run `gofmt` and `goimports` on all Go files
- `/lint` - Run `golangci-lint run` with project configuration
- `/test` - Run all tests with coverage report
- `/test-unit` - Run only unit tests (exclude integration)
- `/test-integration` - Run only integration tests

### Kubernetes Operator Development

- `/generate-manifests` - Generate CRD manifests using `controller-gen`
- `/generate-deepcopy` - Generate DeepCopy methods for API types
- `/generate-client` - Generate clientset, listers, and informers
- `/update-crds` - Update CRD definitions and apply to cluster
- `/bundle` - Generate operator bundle for OLM

### Kubernetes Version Updates

- `/check-k8s-deps` - Check for outdated Kubernetes dependencies
- `/update-k8s-deps` - Update k8s.io/* dependencies to latest compatible versions
- `/verify-k8s-compat` - Verify compatibility with target Kubernetes version
- `/update-api-versions` - Update deprecated API versions in manifests

### Code Generation

- `/scaffold-controller` - Generate boilerplate for new controller
- `/scaffold-webhook` - Generate boilerplate for admission webhook
- `/scaffold-api` - Generate new API type (CRD)
- `/add-rbac` - Generate RBAC markers for controller

### Build & Deploy

- `/build` - Build operator binary
- `/build-image` - Build container image with proper tags
- `/deploy-local` - Deploy operator to local kind/minikube cluster
- `/undeploy` - Remove operator from cluster
- `/logs` - Tail operator logs from cluster

### Maintenance

- `/update-licenses` - Update license headers in all source files
- `/tidy` - Run `go mod tidy` and `go mod verify`
- `/vendor` - Update vendor directory
- `/security-scan` - Run security vulnerability scan (gosec, trivy)

---

## Command Structure

Each command should be a separate file (e.g., `format.sh`, `generate-manifests.sh`) that:
1. Has a clear, single purpose
2. Includes error handling
3. Provides useful output/feedback
4. Can be run idempotently when possible
5. Documents required tools/dependencies

---

## Useful Slash Commands for K8s Operators

### For New Development

**`/scaffold-operator`** - Initialize new operator project
- Creates project structure using `operator-sdk` or `kubebuilder`
- Sets up Makefile, Dockerfile, and CI configuration
- Initializes go.mod with correct k8s dependencies

**`/add-controller`** - Add new controller to existing operator
- Scaffolds controller boilerplate
- Updates manager to register controller
- Creates sample CR and RBAC

**`/add-status-conditions`** - Add standard status conditions to CRD
- Adds Ready, Progressing, Degraded conditions
- Generates helper methods for condition management
- Follows Kubernetes API conventions

### For Maintenance & K8s Updates

**`/k8s-upgrade-check`** - Comprehensive K8s version upgrade check
- Checks for deprecated APIs in code and manifests
- Identifies incompatible dependencies
- Suggests migration path
- Reports breaking changes

**`/migrate-api-versions`** - Migrate deprecated API versions
- Updates `apiVersion` in manifests (e.g., `extensions/v1beta1` → `apps/v1`)
- Updates imports in Go code
- Updates client-go usage patterns
- Creates backup before changes

**`/update-controller-runtime`** - Update controller-runtime and dependencies
- Updates controller-runtime to compatible version
- Updates k8s.io/* dependencies together
- Runs tests to verify compatibility
- Updates go.mod and vendor

**`/check-deprecated-apis`** - Scan for deprecated Kubernetes APIs
- Scans Go code for deprecated client-go APIs
- Scans YAML manifests for deprecated resource versions
- Provides replacement suggestions
- Links to migration guides

### For Testing & Validation

**`/e2e-test`** - Run end-to-end tests
- Spins up test cluster (kind/envtest)
- Deploys operator
- Runs test scenarios
- Cleans up resources

**`/envtest`** - Run tests using controller-runtime envtest
- Faster than full cluster
- Good for controller logic testing
- Uses real etcd and kube-apiserver

**`/verify-bundle`** - Verify OLM bundle is valid
- Runs `operator-sdk bundle validate`
- Checks CSV, CRDs, and metadata
- Validates upgrade paths

### For Documentation

**`/generate-api-docs`** - Generate API reference documentation
- Extracts godoc comments from API types
- Generates markdown documentation
- Updates README with API examples

**`/generate-metrics-docs`** - Document exposed metrics
- Extracts metric definitions from code
- Generates metrics reference
- Useful for monitoring setup

---

## Example Command Implementation

### `/format` Command

```bash
#!/bin/bash
# .ai/commands/format.sh
# Formats all Go code in the repository

set -e

echo "Running gofmt..."
gofmt -w -s .

echo "Running goimports..."
goimports -w .

echo "✓ Code formatting complete"
```

### `/generate-manifests` Command

```bash
#!/bin/bash
# .ai/commands/generate-manifests.sh
# Generates CRD manifests and RBAC

set -e

echo "Generating CRD manifests..."
controller-gen crd:crdVersions=v1 \
  rbac:roleName=manager-role \
  webhook \
  paths="./..." \
  output:crd:artifacts:config=config/crd/bases

echo "✓ Manifests generated in config/crd/bases"
```

---

## When to Use Commands vs Skills

### Use a **Command** when:
- ✅ The action is mechanical and deterministic
- ✅ No analysis or decision-making required
- ✅ You're executing existing tools (make, go, kubectl)
- ✅ The task is repetitive and well-defined
- ✅ You want fast execution without AI overhead

### Use a **Skill** when:
- ✅ You need code analysis or review
- ✅ Decisions require context and understanding
- ✅ You want explanations and learning
- ✅ The task involves judgment calls
- ✅ You're exploring or investigating

---

## Creating New Commands

To add a new command:

1. Create a script file in `.ai/commands/`
2. Make it executable: `chmod +x .ai/commands/your-command.sh`
3. Add documentation header explaining what it does
4. Include error handling and useful output
5. Test it works in a clean environment
6. Update this README with the command description

---

## Notes

- Commands should be idempotent when possible
- Always include error handling (`set -e` in bash)
- Provide clear success/failure messages
- Document any required tools or environment setup
- Consider adding a `/check-tools` command to verify prerequisites

