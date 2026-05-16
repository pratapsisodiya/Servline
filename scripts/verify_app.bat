@echo off
REM Servline App Verification Script for Windows
REM This script checks if the app is properly configured and working

echo ======================================
echo   SERVLINE APP VERIFICATION SCRIPT
echo ======================================
echo.

set PASS_COUNT=0
set FAIL_COUNT=0
set WARN_COUNT=0

echo 1. Checking Flutter installation...
flutter --version >nul 2>&1
if %errorlevel% equ 0 (
    echo [PASS] Flutter is installed
    flutter --version | findstr /C:"Flutter"
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] Flutter is not installed
    set /a FAIL_COUNT+=1
)
echo.

echo 2. Checking project structure...
if exist pubspec.yaml (
    echo [PASS] pubspec.yaml exists
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] pubspec.yaml not found
    set /a FAIL_COUNT+=1
)

if exist lib (
    echo [PASS] lib\ directory exists
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] lib\ directory not found
    set /a FAIL_COUNT+=1
)

if exist lib\main.dart (
    echo [PASS] lib\main.dart exists
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] lib\main.dart not found
    set /a FAIL_COUNT+=1
)
echo.

echo 3. Checking critical files...
for %%f in (
    "lib\router.dart"
    "lib\core\services\appwrite_service.dart"
    "lib\core\config\appwrite_config.dart"
    "lib\models\user.dart"
    "lib\models\ticket.dart"
    "lib\providers\auth_provider.dart"
    "lib\providers\ticket_provider.dart"
    "lib\repositories\auth_repository.dart"
    "lib\repositories\ticket_repository.dart"
) do (
    if exist %%f (
        echo [PASS] %%f exists
        set /a PASS_COUNT+=1
    ) else (
        echo [FAIL] %%f missing
        set /a FAIL_COUNT+=1
    )
)
echo.

echo 4. Checking for fixed critical issues...

REM C1-C2: Check if createRouter is used
findstr /C:"routerConfig: createRouter(ref)" lib\main.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo [PASS] Auth router properly configured
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] Legacy router still in use - auth bypass vulnerability
    set /a FAIL_COUNT+=1
)

REM C3: Check SSL self-signed is removed
findstr /C:"setSelfSigned" lib\core\services\appwrite_service.dart >nul 2>&1
if %errorlevel% neq 0 (
    echo [PASS] SSL properly configured
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] Self-signed SSL certificate still enabled - security risk
    set /a FAIL_COUNT+=1
)

REM Check MyHomePage placeholder removed
findstr /C:"class MyHomePage" lib\main.dart >nul 2>&1
if %errorlevel% neq 0 (
    echo [PASS] MyHomePage placeholder removed
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] MyHomePage placeholder still exists
    set /a FAIL_COUNT+=1
)

REM Check IntroScreen navigation
if exist lib\screens\intro_screen.dart (
    findstr /C:"context.go('/login')" lib\screens\intro_screen.dart >nul 2>&1
    if %errorlevel% equ 0 (
        echo [PASS] IntroScreen navigation fixed
        set /a PASS_COUNT+=1
    ) else (
        echo [WARN] IntroScreen may have navigation issues
        set /a WARN_COUNT+=1
    )
)
echo.

echo 5. Running Flutter analyze...
flutter analyze > temp_analyze.txt 2>&1
findstr /C:"error" temp_analyze.txt | find /C "error" > temp_count.txt
set /p ERROR_COUNT=<temp_count.txt

if "%ERROR_COUNT%"=="0" (
    echo [PASS] No Flutter analyze errors
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] Flutter analyze found errors
    set /a FAIL_COUNT+=1
    type temp_analyze.txt | findstr /C:"error"
)

del temp_analyze.txt temp_count.txt 2>nul
echo.

echo 6. Checking dependencies...
flutter pub get >nul 2>&1
if %errorlevel% equ 0 (
    echo [PASS] Dependencies resolved successfully
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] Failed to resolve dependencies
    set /a FAIL_COUNT+=1
)
echo.

echo 7. Checking for common issues...

REM Check AsyncNotifier usage
findstr /C:"AsyncNotifier<SettingsState>" lib\providers\settings_provider.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo [PASS] Settings provider uses AsyncNotifier
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] Settings provider not properly configured
    set /a FAIL_COUNT+=1
)

REM Check AbsorbPointer in loading overlay
findstr /C:"AbsorbPointer" lib\widgets\loading_overlay.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo [PASS] Loading overlay blocks interactions properly
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] Loading overlay missing AbsorbPointer
    set /a FAIL_COUNT+=1
)

REM Check guest email uniqueness
findstr /C:"guest_$timestamp@servline.local" lib\models\user.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo [PASS] Guest users have unique emails
    set /a PASS_COUNT+=1
) else (
    echo [FAIL] Guest email collision issue not fixed
    set /a FAIL_COUNT+=1
)
echo.

echo ======================================
echo   VERIFICATION SUMMARY
echo ======================================
echo Passed: %PASS_COUNT%
echo Failed: %FAIL_COUNT%
echo Warnings: %WARN_COUNT%
echo.

if %FAIL_COUNT% equ 0 (
    echo [SUCCESS] APP IS READY TO RUN!
    echo.
    echo Next steps:
    echo 1. Connect device/emulator: flutter devices
    echo 2. Run the app: flutter run
    echo 3. Test flow: Onboarding -^> Login -^> Home -^> Queue -^> Ticket
    exit /b 0
) else (
    echo [ERROR] APP HAS CRITICAL ISSUES
    echo.
    echo Please fix the failed checks above before running.
    exit /b 1
)
