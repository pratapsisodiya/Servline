#!/bin/bash

# Appwrite Authentication Test Script
# Tests if Appwrite auth is properly configured

echo "======================================"
echo "  APPWRITE AUTH VERIFICATION"
echo "======================================"
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASS=0
FAIL=0
WARN=0

check_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
    ((PASS++))
}

check_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    ((FAIL++))
}

check_warn() {
    echo -e "${YELLOW}⚠ WARN${NC}: $1"
    ((WARN++))
}

check_info() {
    echo -e "${BLUE}ℹ INFO${NC}: $1"
}

echo "1. Checking Appwrite Configuration..."
CONFIG_FILE="lib/core/config/appwrite_config.dart"

if [ -f "$CONFIG_FILE" ]; then
    check_pass "Config file exists"

    # Extract endpoint and project ID
    ENDPOINT=$(grep "endpoint = " "$CONFIG_FILE" | cut -d"'" -f2)
    PROJECT_ID=$(grep "projectId = " "$CONFIG_FILE" | cut -d"'" -f2)

    check_info "Endpoint: $ENDPOINT"
    check_info "Project ID: $PROJECT_ID"

    # Check if TODO comments exist
    if grep -q "TODO" "$CONFIG_FILE"; then
        check_warn "TODO comments found - credentials may need update"
    else
        check_pass "No TODO comments - config looks set"
    fi

    # Validate endpoint format
    if [[ $ENDPOINT == https://* ]]; then
        check_pass "Endpoint uses HTTPS"
    else
        check_fail "Endpoint should use HTTPS"
    fi

    # Check project ID format
    if [ ${#PROJECT_ID} -gt 10 ]; then
        check_pass "Project ID looks valid (length: ${#PROJECT_ID})"
    else
        check_warn "Project ID seems short - verify it's correct"
    fi
else
    check_fail "Config file not found"
fi
echo ""

echo "2. Checking Appwrite Service Setup..."
SERVICE_FILE="lib/core/services/appwrite_service.dart"

if [ -f "$SERVICE_FILE" ]; then
    check_pass "Service file exists"

    # Check if setSelfSigned is present
    if grep -q "setSelfSigned" "$SERVICE_FILE"; then
        check_fail "setSelfSigned() still present - SECURITY RISK!"
    else
        check_pass "SSL configured securely (no setSelfSigned)"
    fi

    # Check if all services are initialized
    for service in "Account" "Databases" "Realtime" "Storage"; do
        if grep -q "$service(_client)" "$SERVICE_FILE"; then
            check_pass "$service initialized"
        else
            check_warn "$service may not be initialized"
        fi
    done
else
    check_fail "Service file not found"
fi
echo ""

echo "3. Checking Auth Repository..."
AUTH_REPO="lib/repositories/auth_repository.dart"

if [ -f "$AUTH_REPO" ]; then
    check_pass "Auth repository exists"

    # Check for key methods
    AUTH_METHODS=("createAccount" "login" "loginAsGuest" "getCurrentUser" "logout" "sendPasswordRecovery")
    for method in "${AUTH_METHODS[@]}"; do
        if grep -q "Future.*$method" "$AUTH_REPO"; then
            check_pass "Method: $method() exists"
        else
            check_fail "Method: $method() missing"
        fi
    done

    # Check error handling
    if grep -q "_handleAppwriteException" "$AUTH_REPO"; then
        check_pass "Error handling implemented"
    else
        check_warn "Error handling may be missing"
    fi

    # Check guest login fallback
    if grep -q "User.guest()" "$AUTH_REPO"; then
        check_pass "Guest fallback implemented"
    else
        check_warn "No guest fallback - offline mode may not work"
    fi
else
    check_fail "Auth repository not found"
fi
echo ""

echo "4. Checking Auth Provider..."
AUTH_PROVIDER="lib/providers/auth_provider.dart"

if [ -f "$AUTH_PROVIDER" ]; then
    check_pass "Auth provider exists"

    # Check provider methods
    PROVIDER_METHODS=("login" "register" "loginAsGuest" "logout" "_checkExistingSession")
    for method in "${PROVIDER_METHODS[@]}"; do
        if grep -q "$method" "$AUTH_PROVIDER"; then
            check_pass "Method: $method exists"
        else
            check_fail "Method: $method missing"
        fi
    done

    # Check state management
    if grep -q "AuthState" "$AUTH_PROVIDER"; then
        check_pass "State management implemented"
    else
        check_fail "State management missing"
    fi
else
    check_fail "Auth provider not found"
fi
echo ""

echo "5. Checking Router Auth Guards..."
ROUTER="lib/router.dart"

if [ -f "$ROUTER" ]; then
    check_pass "Router exists"

    # Check if createRouter function exists
    if grep -q "GoRouter createRouter" "$ROUTER"; then
        check_pass "createRouter() function exists"
    else
        check_fail "createRouter() function missing"
    fi

    # Check if redirect is implemented
    if grep -q "redirect:.*authProvider" "$ROUTER"; then
        check_pass "Auth redirect logic implemented"
    else
        check_fail "Auth redirect logic missing - routes unprotected"
    fi

    # Check if public routes are defined
    if grep -q "_publicRoutes" "$ROUTER"; then
        check_pass "Public routes defined"
    else
        check_warn "Public routes may not be defined"
    fi

    # Check that legacy router is removed
    if grep -q "final router = GoRouter" "$ROUTER"; then
        check_fail "Legacy router still exists - auth bypass vulnerability!"
    else
        check_pass "Legacy router removed"
    fi
else
    check_fail "Router not found"
fi
echo ""

echo "6. Checking Main.dart Integration..."
MAIN="lib/main.dart"

if [ -f "$MAIN" ]; then
    check_pass "main.dart exists"

    # Check if ConsumerWidget is used
    if grep -q "class MyApp extends ConsumerWidget" "$MAIN"; then
        check_pass "MyApp uses ConsumerWidget (can access providers)"
    else
        check_fail "MyApp not using ConsumerWidget - can't access auth state"
    fi

    # Check if createRouter is called
    if grep -q "routerConfig: createRouter(ref)" "$MAIN"; then
        check_pass "createRouter(ref) called with auth context"
    else
        check_fail "createRouter not called - auth guards not active"
    fi

    # Check ProviderScope
    if grep -q "ProviderScope" "$MAIN"; then
        check_pass "ProviderScope wraps app"
    else
        check_fail "ProviderScope missing - Riverpod won't work"
    fi
else
    check_fail "main.dart not found"
fi
echo ""

echo "7. Testing Auth Flow Logic..."

# Check login screen
LOGIN_SCREEN="lib/screens/auth/login_screen.dart"
if [ -f "$LOGIN_SCREEN" ]; then
    if grep -q "authProvider.notifier.*login" "$LOGIN_SCREEN"; then
        check_pass "Login screen calls auth provider"
    else
        check_warn "Login screen may not call auth provider"
    fi
fi

# Check signup screen
SIGNUP_SCREEN="lib/screens/auth/signup_screen.dart"
if [ -f "$SIGNUP_SCREEN" ]; then
    if grep -q "authProvider.notifier.*register" "$SIGNUP_SCREEN"; then
        check_pass "Signup screen calls auth provider"
    else
        check_warn "Signup screen may not call auth provider"
    fi
fi
echo ""

echo "8. Checking Dependencies..."
PUBSPEC="pubspec.yaml"

if [ -f "$PUBSPEC" ]; then
    if grep -q "appwrite:" "$PUBSPEC"; then
        check_pass "Appwrite SDK in dependencies"
        APPWRITE_VERSION=$(grep "appwrite:" "$PUBSPEC" | awk '{print $2}')
        check_info "Appwrite version: $APPWRITE_VERSION"
    else
        check_fail "Appwrite SDK missing from dependencies"
    fi

    if grep -q "flutter_riverpod:" "$PUBSPEC"; then
        check_pass "Riverpod in dependencies"
    else
        check_fail "Riverpod missing - state management won't work"
    fi
else
    check_fail "pubspec.yaml not found"
fi
echo ""

echo "======================================"
echo "  TEST SUMMARY"
echo "======================================"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo -e "${YELLOW}Warnings: $WARN${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}✓ APPWRITE AUTH IS PROPERLY CONFIGURED!${NC}"
    echo ""
    echo "Next steps to test auth:"
    echo "1. Ensure Appwrite project exists at the endpoint"
    echo "2. Run: flutter run"
    echo "3. Test login flow:"
    echo "   - Sign up new account"
    echo "   - Login with credentials"
    echo "   - Continue as guest"
    echo "   - Logout and verify redirect"
    echo ""
    echo "Expected behavior:"
    echo "✓ Unauthenticated users redirected to /login"
    echo "✓ After login, navigate to /home"
    echo "✓ Protected routes require authentication"
    echo "✓ Guest mode works offline"
    exit 0
else
    echo -e "${RED}✗ APPWRITE AUTH HAS ISSUES${NC}"
    echo ""
    echo "Critical issues found. Fix the failures above."
    echo ""
    echo "Common fixes:"
    echo "1. Update credentials in appwrite_config.dart"
    echo "2. Ensure createRouter(ref) is called in main.dart"
    echo "3. Remove legacy router from router.dart"
    echo "4. Add Appwrite SDK to pubspec.yaml"
    exit 1
fi
