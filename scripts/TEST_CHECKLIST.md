# Servline App Testing Checklist

## 🔧 Setup Verification

### Prerequisites
- [ ] Flutter SDK installed (`flutter --version`)
- [ ] Device/Emulator connected (`flutter devices`)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] No analyze errors (`flutter analyze`)

---

## 🧪 Manual Testing Flow

### 1. App Launch
- [ ] App starts without crashes
- [ ] Splash screen appears
- [ ] No white screen / blank errors

### 2. Onboarding Flow
- [ ] Welcome/Intro screen displays correctly
- [ ] Can swipe through onboarding pages
- [ ] "Skip" button works
- [ ] "Get Started" button navigates to login
- [ ] Navigation doesn't crash

### 3. Authentication
#### Login
- [ ] Login screen displays properly
- [ ] Email field accepts input
- [ ] Password field accepts input and hides characters
- [ ] "Login" button works
- [ ] Error messages display for invalid credentials
- [ ] Successfully logs in with valid credentials
- [ ] Navigates to home after successful login

#### Sign Up
- [ ] Can navigate to signup from login
- [ ] Name, email, password fields work
- [ ] "Create Account" button functions
- [ ] Account creation succeeds
- [ ] Auto-login after signup

#### Guest Login
- [ ] "Continue as Guest" button works
- [ ] Guest user gets unique ID/email
- [ ] Can access limited features

### 4. Home Screen
- [ ] Home screen loads after login
- [ ] User profile info displays (name, avatar)
- [ ] "Smart Picks" section shows locations
- [ ] "Upcoming Appointments" section visible
- [ ] "Nearby Locations" button works
- [ ] Location cards display correctly
- [ ] Can tap location to see services

### 5. Queue Management
#### Join Queue
- [ ] Tap location → see services list
- [ ] Select service
- [ ] "Join Queue" button works
- [ ] Token number generated
- [ ] Queue position displays
- [ ] Estimated wait time shows

#### Active Ticket
- [ ] Navigate to "Tickets" tab
- [ ] Active ticket displays
- [ ] Token number visible
- [ ] QR code generated
- [ ] Queue position updates
- [ ] Status text shows correct state (not hardcoded "WAITING")
- [ ] Progress bar moves
- [ ] "Cancel Ticket" button works

#### Your Turn
- [ ] Notification when it's your turn
- [ ] "Your Turn" screen appears
- [ ] Vibration works (if supported)
- [ ] "I'm Here" button acknowledges
- [ ] Navigates to counter/serving state

### 6. Appointments
- [ ] Can schedule appointment from location
- [ ] Date picker works
- [ ] Time slot selection works
- [ ] "Book Appointment" creates ticket
- [ ] Appointment appears in home screen
- [ ] Appointment has correct scheduled time (no null crash)

### 7. History
- [ ] Navigate to "History" tab
- [ ] Past tickets display
- [ ] Ticket details correct
- [ ] Can view old tickets
- [ ] Empty state shows if no history

### 8. Notifications
- [ ] Navigate to notifications
- [ ] Notification list displays
- [ ] Unread count badge works
- [ ] Can mark as read
- [ ] Notification actions work

### 9. Profile
- [ ] Navigate to "Profile" tab
- [ ] User info displays
- [ ] Avatar/initials show correctly
- [ ] "Edit Profile" dialog opens (even if not fully implemented)
- [ ] "Logout" button works
- [ ] Guest users see "Create Account" option

### 10. Settings
- [ ] Navigate to settings
- [ ] Settings load without error
- [ ] Text size slider works
- [ ] Notification sounds toggle works
- [ ] Vibration toggle works
- [ ] Dark mode toggle works (if implemented)
- [ ] "Done" button returns to home

### 11. Help & Support
- [ ] Help center screen opens
- [ ] FAQ sections display
- [ ] Search works (if implemented)
- [ ] Contact support button present

---

## 🐛 Bug Verification (Fixed Issues)

### Critical Fixes
- [ ] ✅ Auth router enforces login (not bypassed)
- [ ] ✅ SSL certificate secure (no self-signed)
- [ ] ✅ No crash on appointment scheduled time
- [ ] ✅ Intro screen navigates to login (not broken)
- [ ] ✅ Vibration doesn't crash

### High Priority Fixes
- [ ] ✅ Settings load properly (not wrong defaults)
- [ ] ✅ Guest login shows error if fails (not silent)
- [ ] ✅ Token numbers are unique (4-digit)
- [ ] ✅ Queue position accurate (no +5 mock)
- [ ] ✅ Ticket status shows correct text (not "WAITING")

### Medium Priority Fixes
- [ ] ✅ Appointments have scheduled time in realtime
- [ ] ✅ Multiple guests have different emails
- [ ] ✅ Tab re-tap resets to root
- [ ] ✅ Navigation uses `go` not `push` where needed
- [ ] ✅ Loading overlay blocks interactions

---

## 🚨 Known Issues (Not Yet Fixed)

### Non-Critical Issues
- [ ] ⚠️ Search in nearby locations not functional
- [ ] ⚠️ Filter chips don't filter
- [ ] ⚠️ Profile edit doesn't save
- [ ] ⚠️ Help center buttons not wired
- [ ] ⚠️ Language selection not implemented

---

## 📱 Device Testing

### Android
- [ ] Runs on Android emulator
- [ ] Runs on physical Android device
- [ ] Permissions requested properly
- [ ] QR scanner works
- [ ] Notifications work

### iOS (if applicable)
- [ ] Runs on iOS simulator
- [ ] Runs on physical iOS device
- [ ] Permissions requested properly
- [ ] QR scanner works
- [ ] Notifications work

### Web (if applicable)
- [ ] Runs in Chrome
- [ ] Runs in other browsers
- [ ] Basic functionality works

---

## ✅ Pass Criteria

**Minimum for "Working App":**
- ✅ App launches without crash
- ✅ Can complete auth flow (login/signup)
- ✅ Can join queue and get ticket
- ✅ Active ticket displays correctly
- ✅ Can navigate between tabs
- ✅ Critical bugs fixed (no auth bypass, no crashes)

**Ideal (Fully Working):**
- All above +
- All screens accessible
- All navigation works
- Settings persist
- Notifications work
- No analyze errors

---

## 🔍 How to Test

1. **Run verification script:**
   ```bash
   # Windows
   cd scripts
   verify_app.bat
   
   # Mac/Linux
   chmod +x scripts/verify_app.sh
   ./scripts/verify_app.sh
   ```

2. **Run the app:**
   ```bash
   flutter devices          # Check connected device
   flutter run             # Run on default device
   flutter run -d chrome   # Run on web
   ```

3. **Go through checklist:**
   - Check each item
   - Note any issues
   - Verify fixed bugs work

---

## 📝 Report Format

**Test Date:** _________  
**Device:** _________  
**Flutter Version:** _________

**Pass Rate:** ___/___

**Critical Issues:** (list any blockers)

**Notes:** (any observations)

---

## 🎯 Quick Test (5 minutes)

For a quick smoke test, verify:
1. ✅ App launches
2. ✅ Can skip onboarding → reach login
3. ✅ Can login or continue as guest
4. ✅ Home screen displays
5. ✅ Can tap location → see services
6. ✅ Can join queue → get ticket
7. ✅ Active ticket displays with token
8. ✅ Can navigate all 4 tabs (Home, Tickets, History, Profile)

If all 8 pass → **App is working!** ✅
