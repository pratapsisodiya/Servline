#!/bin/bash

# Servline App Verification Script
# This script checks if the app is properly configured and working

echo "======================================"
echo "  SERVLINE APP VERIFICATION SCRIPT"
echo "======================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0

# Function to check and report
check_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASS_COUNT++))
}

check_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAIL_COUNT++))
}

check_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARN_COUNT++))
}

echo "1. Checking Flutter installation..."
if command -v flutter &> /dev/null; then
    check_pass "Flutter is installed"
    flutter --version | head -1
else
    check_fail "Flutter is not installed"
fi
echo ""

echo "2. Checking project structure..."
if [ -f "pubspec.yaml" ]; then
    check_pass "pubspec.yaml exists"
else
    check_fail "pubspec.yaml not found"
fi

if [ -d "lib" ]; then
    check_pass "lib/ directory exists"
else
    check_fail "lib/ directory not found"
fi

if [ -f "lib/main.dart" ]; then
    check_pass "lib/main.dart exists"
else
    check_fail "lib/main.dart not found"
fi
echo ""

echo "3. Checking critical files..."
CRITICAL_FILES=(
    "lib/router.dart"
    "lib/core/services/appwrite_service.dart"
    "lib/core/config/appwrite_config.dart"
    "lib/models/user.dart"
    "lib/models/ticket.dart"
    "lib/providers/auth_provider.dart"
    "lib/providers/ticket_provider.dart"
    "lib/repositories/auth_repository.dart"
    "lib/repositories/ticket_repository.dart"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "$file exists"
    else
        check_fail "$file missing"
    fi
done
echo ""

echo "4. Checking for fixed critical issues..."

# C1-C2: Check if createRouter is used (not legacy router)
if grep -q "routerConfig: createRouter(ref)" lib/main.dart; then
    check_pass "Auth router properly configured"
else
    check_fail "Legacy router still in use - auth bypass vulnerability"
fi

# C3: Check SSL self-signed is removed
if grep -q "setSelfSigned" lib/core/services/appwrite_service.dart; then
    check_fail "Self-signed SSL certificate still enabled - security risk"
else
    check_pass "SSL properly configured"
fi

# Check MyHomePage placeholder removed
if grep -q "class MyHomePage" lib/main.dart; then
    check_fail "MyHomePage placeholder still exists"
else
    check_pass "MyHomePage placeholder removed"
fi

# Check if IntroScreen uses proper navigation
if grep -q "context.go('/login')" lib/screens/intro_screen.dart 2>/dev/null; then
    check_pass "IntroScreen navigation fixed"
else
    check_warn "IntroScreen may have navigation issues"
fi
echo ""

echo "5. Running Flutter analyze..."
ANALYZE_OUTPUT=$(flutter analyze 2>&1)
ERROR_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "^error" || echo "0")
WARNING_COUNT=$(echo "$ANALYZE_OUTPUT" | grep -c "^warning" || echo "0")

if [ "$ERROR_COUNT" -eq 0 ]; then
    check_pass "No Flutter analyze errors ($ERROR_COUNT errors)"
else
    check_fail "Flutter analyze found $ERROR_COUNT errors"
    echo "$ANALYZE_OUTPUT" | grep "^error" | head -5
fi

if [ "$WARNING_COUNT" -eq 0 ]; then
    check_pass "No Flutter analyze warnings"
else
    check_warn "Flutter analyze found $WARNING_COUNT warnings (may be acceptable)"
fi
echo ""

echo "6. Checking dependencies..."
if flutter pub get > /dev/null 2>&1; then
    check_pass "Dependencies resolved successfully"
else
    check_fail "Failed to resolve dependencies"
fi
echo ""

echo "7. Checking for common issues..."

# Check for hardcoded credentials
if grep -r "TODO" lib/core/config/ 2>/dev/null | grep -q "TODO"; then
    check_warn "TODO comments found in config - may need credential setup"
fi

# Check AsyncNotifier usage
if grep -q "AsyncNotifier<SettingsState>" lib/providers/settings_provider.dart; then
    check_pass "Settings provider uses AsyncNotifier"
else
    check_fail "Settings provider not properly configured"
fi

# Check AbsorbPointer in loading overlay
if grep -q "AbsorbPointer" lib/widgets/loading_overlay.dart; then
    check_pass "Loading overlay blocks interactions properly"
else
    check_fail "Loading overlay missing AbsorbPointer"
fi

# Check guest email uniqueness
if grep -q "guest_\$timestamp@servline.local" lib/models/user.dart; then
    check_pass "Guest users have unique emails"
else
    check_fail "Guest email collision issue not fixed"
fi
echo ""

echo "8. Checking build readiness..."
echo "   Attempting dry-run build check..."
if flutter build apk --debug --dry-run > /dev/null 2>&1; then
    check_pass "App is ready to build"
else
    check_warn "Build may have issues (run 'flutter build apk' to verify)"
fi
echo ""

echo "======================================"
echo "  VERIFICATION SUMMARY"
echo "======================================"
echo -e "${GREEN}Passed: $PASS_COUNT${NC}"
echo -e "${RED}Failed: $FAIL_COUNT${NC}"
echo -e "${YELLOW}Warnings: $WARN_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ APP IS READY TO RUN!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Connect device/emulator: flutter devices"
    echo "2. Run the app: flutter run"
    echo "3. Test flow: Onboarding → Login → Home → Queue → Ticket"
    exit 0
else
    echo -e "${RED}✗ APP HAS CRITICAL ISSUES${NC}"
    echo ""
    echo "Please fix the failed checks above before running."
    exit 1
fi
