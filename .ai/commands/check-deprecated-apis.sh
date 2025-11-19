#!/bin/bash
# .ai/commands/check-deprecated-apis.sh
# Scans for deprecated Kubernetes APIs in code and manifests
#
# This command checks:
# 1. YAML manifests for deprecated apiVersion fields
# 2. Go code for deprecated client-go imports and API usage
# 3. Provides migration suggestions and documentation links
#
# Requirements:
# - grep, find (standard Unix tools)
# - Optional: pluto (for advanced K8s API deprecation detection)
#   Install: brew install FairwindsOps/tap/pluto
#   Or: https://github.com/FairwindsOps/pluto

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Kubernetes Deprecated API Scanner ===${NC}\n"

ISSUES_FOUND=0

# Function to print section header
print_header() {
    echo -e "\n${BLUE}▶ $1${NC}"
    echo "─────────────────────────────────────────────────────"
}

# Function to report finding
report_finding() {
    local severity=$1
    local file=$2
    local line=$3
    local message=$4
    
    ISSUES_FOUND=$((ISSUES_FOUND + 1))
    
    if [ "$severity" = "ERROR" ]; then
        echo -e "${RED}✗ ERROR${NC} $file:$line"
    else
        echo -e "${YELLOW}⚠ WARNING${NC} $file:$line"
    fi
    echo "  $message"
    echo ""
}

# Check if pluto is available
PLUTO_AVAILABLE=false
if command -v pluto &> /dev/null; then
    PLUTO_AVAILABLE=true
    echo -e "${GREEN}✓${NC} Pluto detected - will use for advanced scanning"
else
    echo -e "${YELLOW}ℹ${NC} Pluto not found - using basic scanning"
    echo "  Install for better results: brew install FairwindsOps/tap/pluto"
fi

# ============================================================================
# 1. Check YAML/JSON manifests for deprecated apiVersions
# ============================================================================

print_header "Scanning YAML/JSON Manifests"

# Common deprecated APIs (add more as K8s evolves)
declare -A DEPRECATED_APIS=(
    # Removed in K8s 1.16
    ["extensions/v1beta1.*Deployment"]="apps/v1 (removed in 1.16)"
    ["extensions/v1beta1.*DaemonSet"]="apps/v1 (removed in 1.16)"
    ["extensions/v1beta1.*ReplicaSet"]="apps/v1 (removed in 1.16)"
    ["extensions/v1beta1.*StatefulSet"]="apps/v1 (removed in 1.16)"
    ["extensions/v1beta1.*Ingress"]="networking.k8s.io/v1 (removed in 1.22)"
    ["apps/v1beta1.*Deployment"]="apps/v1 (removed in 1.16)"
    ["apps/v1beta1.*StatefulSet"]="apps/v1 (removed in 1.16)"
    ["apps/v1beta2.*Deployment"]="apps/v1 (removed in 1.16)"
    ["apps/v1beta2.*StatefulSet"]="apps/v1 (removed in 1.16)"
    
    # Removed in K8s 1.22
    ["admissionregistration.k8s.io/v1beta1.*ValidatingWebhookConfiguration"]="admissionregistration.k8s.io/v1 (removed in 1.22)"
    ["admissionregistration.k8s.io/v1beta1.*MutatingWebhookConfiguration"]="admissionregistration.k8s.io/v1 (removed in 1.22)"
    ["apiextensions.k8s.io/v1beta1.*CustomResourceDefinition"]="apiextensions.k8s.io/v1 (removed in 1.22)"
    ["networking.k8s.io/v1beta1.*Ingress"]="networking.k8s.io/v1 (removed in 1.22)"
    
    # Removed in K8s 1.25
    ["batch/v1beta1.*CronJob"]="batch/v1 (removed in 1.25)"
    ["policy/v1beta1.*PodSecurityPolicy"]="REMOVED - migrate to Pod Security Standards (removed in 1.25)"
    
    # Removed in K8s 1.26
    ["flowcontrol.apiserver.k8s.io/v1beta1.*FlowSchema"]="flowcontrol.apiserver.k8s.io/v1beta3 (removed in 1.26)"
    ["flowcontrol.apiserver.k8s.io/v1beta1.*PriorityLevelConfiguration"]="flowcontrol.apiserver.k8s.io/v1beta3 (removed in 1.26)"
    
    # Removed in K8s 1.27
    ["storage.k8s.io/v1beta1.*CSIStorageCapacity"]="storage.k8s.io/v1 (removed in 1.27)"
)

# Find all YAML and JSON files (excluding vendor, node_modules, etc.)
MANIFEST_FILES=$(find . -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.json" \) \
    -not -path "*/vendor/*" \
    -not -path "*/node_modules/*" \
    -not -path "*/.git/*" \
    -not -path "*/testdata/*" 2>/dev/null || true)

if [ -z "$MANIFEST_FILES" ]; then
    echo "No manifest files found"
else
    for pattern in "${!DEPRECATED_APIS[@]}"; do
        api_version=$(echo "$pattern" | cut -d'*' -f1)
        kind=$(echo "$pattern" | cut -d'*' -f2)
        replacement="${DEPRECATED_APIS[$pattern]}"
        
        while IFS= read -r file; do
            # Check if file contains both the apiVersion and kind
            if grep -q "apiVersion:.*$api_version" "$file" 2>/dev/null && \
               grep -q "kind:.*$kind" "$file" 2>/dev/null; then
                line_num=$(grep -n "apiVersion:.*$api_version" "$file" | head -1 | cut -d: -f1)
                report_finding "ERROR" "$file" "$line_num" \
                    "Deprecated API: $api_version $kind → Use $replacement"
            fi
        done <<< "$MANIFEST_FILES"
    done
fi

# ============================================================================
# 2. Use Pluto for advanced manifest scanning (if available)
# ============================================================================

if [ "$PLUTO_AVAILABLE" = true ]; then
    print_header "Running Pluto Advanced Scan"
    
    # Pluto can detect more deprecations and provide K8s version context
    if pluto detect-files -d . --ignore-deprecations=false --ignore-removals=false 2>/dev/null; then
        echo -e "${GREEN}✓${NC} Pluto scan complete"
    else
        echo -e "${YELLOW}⚠${NC} Pluto found deprecated APIs (see output above)"
        ISSUES_FOUND=$((ISSUES_FOUND + 1))
    fi
fi

# ============================================================================
# 3. Check Go code for deprecated client-go imports
# ============================================================================

print_header "Scanning Go Code for Deprecated Imports"

# Find all Go files
GO_FILES=$(find . -type f -name "*.go" \
    -not -path "*/vendor/*" \
    -not -path "*/.git/*" 2>/dev/null || true)

if [ -z "$GO_FILES" ]; then
    echo "No Go files found"
else
    # Deprecated client-go imports
    declare -A DEPRECATED_IMPORTS=(
        ["k8s.io/api/extensions/v1beta1"]="Use k8s.io/api/apps/v1 or k8s.io/api/networking/v1"
        ["k8s.io/api/apps/v1beta1"]="Use k8s.io/api/apps/v1"
        ["k8s.io/api/apps/v1beta2"]="Use k8s.io/api/apps/v1"
        ["k8s.io/api/batch/v1beta1"]="Use k8s.io/api/batch/v1 (for CronJob)"
        ["k8s.io/api/policy/v1beta1"]="PodSecurityPolicy removed - migrate to Pod Security Standards"
        ["k8s.io/api/networking.k8s.io/v1beta1"]="Use k8s.io/api/networking/v1"
        ["k8s.io/api/apiextensions/v1beta1"]="Use k8s.io/api/apiextensions/v1"
        ["k8s.io/api/admissionregistration/v1beta1"]="Use k8s.io/api/admissionregistration/v1"
    )
    
    for import_path in "${!DEPRECATED_IMPORTS[@]}"; do
        replacement="${DEPRECATED_IMPORTS[$import_path]}"
        
        while IFS= read -r file; do
            if grep -q "\"$import_path\"" "$file" 2>/dev/null; then
                line_num=$(grep -n "\"$import_path\"" "$file" | head -1 | cut -d: -f1)
                report_finding "WARNING" "$file" "$line_num" \
                    "Deprecated import: $import_path → $replacement"
            fi
        done <<< "$GO_FILES"
    done
fi

# ============================================================================
# 4. Check for deprecated API usage patterns in Go code
# ============================================================================

print_header "Scanning Go Code for Deprecated API Usage"

if [ -n "$GO_FILES" ]; then
    # Check for deprecated Scheme registration patterns
    while IFS= read -r file; do
        if grep -q "scheme.AddToScheme.*v1beta1" "$file" 2>/dev/null; then
            line_num=$(grep -n "scheme.AddToScheme.*v1beta1" "$file" | head -1 | cut -d: -f1)
            report_finding "WARNING" "$file" "$line_num" \
                "Deprecated scheme registration using v1beta1 API"
        fi
    done <<< "$GO_FILES"
    
    # Check for deprecated client usage
    while IFS= read -r file; do
        if grep -qE "\.ExtensionsV1beta1\(\)|\.AppsV1beta[12]\(\)" "$file" 2>/dev/null; then
            line_num=$(grep -nE "\.ExtensionsV1beta1\(\)|\.AppsV1beta[12]\(\)" "$file" | head -1 | cut -d: -f1)
            report_finding "WARNING" "$file" "$line_num" \
                "Deprecated client usage - use AppsV1() or NetworkingV1()"
        fi
    done <<< "$GO_FILES"
fi

# ============================================================================
# 5. Check go.mod for outdated k8s dependencies
# ============================================================================

print_header "Checking go.mod for K8s Dependencies"

if [ -f "go.mod" ]; then
    echo "Current Kubernetes dependencies:"
    grep "k8s.io" go.mod | grep -v "^//" || echo "  No k8s.io dependencies found"
    echo ""
    
    # Check for very old versions (< 0.20.0 is pre-1.18)
    if grep -q "k8s.io.*v0\.\(1[0-9]\|[0-9]\)\." go.mod 2>/dev/null; then
        report_finding "ERROR" "go.mod" "0" \
            "Very old Kubernetes dependencies detected (< v0.20.0). Consider upgrading."
    fi
else
    echo "No go.mod found"
fi

# ============================================================================
# Summary and Recommendations
# ============================================================================

print_header "Summary"

if [ $ISSUES_FOUND -eq 0 ]; then
    echo -e "${GREEN}✓ No deprecated APIs found!${NC}"
    echo ""
    exit 0
else
    echo -e "${YELLOW}Found $ISSUES_FOUND potential issue(s)${NC}"
    echo ""
    echo -e "${BLUE}Recommendations:${NC}"
    echo "1. Review the deprecated APIs listed above"
    echo "2. Update apiVersions in manifests to current versions"
    echo "3. Update Go imports to use stable API versions"
    echo "4. Run tests after making changes"
    echo "5. Consider using '/migrate-api-versions' command for automated fixes"
    echo ""
    echo -e "${BLUE}Useful Resources:${NC}"
    echo "• Kubernetes Deprecation Policy: https://kubernetes.io/docs/reference/using-api/deprecation-policy/"
    echo "• API Migration Guide: https://kubernetes.io/docs/reference/using-api/deprecation-guide/"
    echo "• Client-go Compatibility: https://github.com/kubernetes/client-go#compatibility-matrix"
    echo ""
    
    exit 1
fi

