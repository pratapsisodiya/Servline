<div align="center">

<img src="assets/images/splash_logo.png" alt="Servline Logo" width="120" height="120" />

# Servline

**Skip the line. Not the service.**

*A smart virtual queue management app built with Flutter & Appwrite*

<br/>

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?style=flat-square&logo=dart&logoColor=white)](https://dart.dev)
[![Appwrite](https://img.shields.io/badge/Appwrite-Backend-FD366E?style=flat-square&logo=appwrite&logoColor=white)](https://appwrite.io)
[![Riverpod](https://img.shields.io/badge/Riverpod-3.x-7C3AED?style=flat-square)](https://riverpod.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-22C55E?style=flat-square)](LICENSE)

<br/>

</div>

---

## What is Servline?

Servline replaces physical waiting lines with a seamless digital experience. Users scan a venue's QR code, receive a virtual token, and are notified when their turn arrives — no standing around required. Venue operators get a powerful admin dashboard to manage queues, services, and staff in real time.

---

## Features

### For Users

| Feature | Description |
|---|---|
| **QR Join** | Scan any venue QR code to instantly join a queue |
| **Live Queue Tracking** | Watch your position update in real time |
| **Smart Notifications** | Get alerted as your turn approaches |
| **Appointment Scheduling** | Book slots in advance instead of walking in |
| **Nearby Venues** | Discover service locations around you |
| **Visit History** | Review all past queue tickets and appointments |
| **Feedback & Ratings** | Rate your service experience |

### For Admins & Operators

| Feature | Description |
|---|---|
| **Venue Dashboard** | Create and manage multiple venues from one place |
| **Service Management** | Define services with custom wait times and capacity |
| **Queue Operator Panel** | Operators advance queues and mark completions |
| **Venue QR Generator** | Generate printable QR codes for each venue |
| **Real-time Monitoring** | See live queue depth and estimated wait times |

### Platform Features

- **Smooth Onboarding** — animated welcome flow with location & notification setup
- **Dark Splash Screen** — branded native splash with gradient logo
- **OTA Updates** — auto-detects and prompts app updates from GitHub releases
- **Offline-aware** — graceful degradation when connectivity drops
- **Material 3 Design** — clean, accessible UI with custom Poppins + Inter typography

---

## Screenshots

> _Screenshots below show key flows. Run the app locally to experience animations and live data._

### Onboarding & Auth

| Welcome | How It Works | Login | Sign Up |
|:---:|:---:|:---:|:---:|
| ![Welcome](https://placehold.co/180x380/8B5CF6/FFFFFF?text=Welcome&font=montserrat) | ![How It Works](https://placehold.co/180x380/7C3AED/FFFFFF?text=How+It+Works&font=montserrat) | ![Login](https://placehold.co/180x380/F8FAFC/1E293B?text=Login&font=montserrat) | ![Signup](https://placehold.co/180x380/F8FAFC/1E293B?text=Sign+Up&font=montserrat) |

### User Flow

| Home | Nearby Venues | Active Ticket | Your Turn |
|:---:|:---:|:---:|:---:|
| ![Home](https://placehold.co/180x380/F8FAFC/1E293B?text=Home&font=montserrat) | ![Nearby](https://placehold.co/180x380/EDE9FE/7C3AED?text=Nearby&font=montserrat) | ![Ticket](https://placehold.co/180x380/8B5CF6/FFFFFF?text=Active+Ticket&font=montserrat) | ![Your Turn](https://placehold.co/180x380/22C55E/FFFFFF?text=Your+Turn&font=montserrat) |

### Admin Panel

| Dashboard | Services | Queue Operator | Venue QR |
|:---:|:---:|:---:|:---:|
| ![Dashboard](https://placehold.co/180x380/1E293B/FFFFFF?text=Dashboard&font=montserrat) | ![Services](https://placehold.co/180x380/1E293B/FFFFFF?text=Services&font=montserrat) | ![Operator](https://placehold.co/180x380/1E293B/FFFFFF?text=Operator&font=montserrat) | ![QR](https://placehold.co/180x380/1E293B/FFFFFF?text=Venue+QR&font=montserrat) |

---

## Tech Stack

```
Flutter 3.x          — Cross-platform UI framework
Dart 3.5+            — Language
Appwrite             — Backend-as-a-Service (auth, database, real-time)
Riverpod 3.x         — State management (Notifier pattern)
GoRouter             — Declarative navigation
Google Fonts         — Poppins (headings) + Inter (body)
Mobile Scanner       — QR code scanning
QR Flutter           — QR code generation
Geolocator           — Location services
Local Notifications  — Queue alerts
Lottie               — Animated illustrations
Shimmer              — Loading skeletons
```

---

## Color Palette

| Role | Hex | Swatch |
|---|---|---|
| Primary | `#8B5CF6` | ![](https://placehold.co/20x20/8B5CF6/8B5CF6) |
| Primary Dark | `#7C3AED` | ![](https://placehold.co/20x20/7C3AED/7C3AED) |
| Background | `#F8FAFC` | ![](https://placehold.co/20x20/F8FAFC/F8FAFC) |
| Text Primary | `#1E293B` | ![](https://placehold.co/20x20/1E293B/1E293B) |
| Success | `#22C55E` | ![](https://placehold.co/20x20/22C55E/22C55E) |
| Warning | `#F59E0B` | ![](https://placehold.co/20x20/F59E0B/F59E0B) |
| Error | `#EF4444` | ![](https://placehold.co/20x20/EF4444/EF4444) |

---

## Project Structure

```
lib/
├── core/
│   ├── config/         # Appwrite project config
│   ├── services/       # Appwrite client, queue alerts
│   ├── theme/          # Colors, text styles, spacing, shadows
│   └── utils/          # OTA update checker
│
├── models/             # Pure data classes
│   ├── location.dart   # Venue model
│   ├── ticket.dart     # Queue token
│   ├── user.dart
│   └── ...
│
├── providers/          # Riverpod state (Notifier pattern)
│   ├── auth_provider.dart
│   ├── ticket_provider.dart
│   ├── admin_provider.dart
│   └── ...
│
├── repositories/       # Appwrite data layer
│   ├── auth_repository.dart
│   ├── ticket_repository.dart
│   └── ...
│
├── screens/
│   ├── admin/          # Venue dashboard, services, operator panel
│   ├── auth/           # Login, signup, forgot password
│   ├── home/           # Main home with nearby locations
│   ├── onboarding/     # Welcome, how-it-works, permissions
│   ├── queue/          # Register queue flow
│   ├── ticket/         # Active ticket, your turn alert
│   └── ...
│
├── widgets/            # Shared UI components
│   ├── app_button.dart
│   ├── app_card.dart
│   ├── queue_animation_widget.dart
│   └── ...
│
└── router.dart         # GoRouter with auth guards
```

---

## Getting Started

### Prerequisites

- Flutter SDK `^3.5.0`
- Dart SDK `^3.5.0`
- An [Appwrite](https://appwrite.io) instance (cloud or self-hosted)

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/praaatap/Servline.git
cd Servline

# 2. Install dependencies
flutter pub get

# 3. Configure Appwrite
# Edit lib/core/config/appwrite_config.dart with your project credentials

# 4. Run the app
flutter run
```

### Build

```bash
# Android APK
flutter build apk --release

# iOS (macOS required)
flutter build ios --release

# App Bundle
flutter build appbundle --release
```

---

## Architecture

Servline follows a **Repository → Provider → Screen** layered architecture:

```
Screen (UI)
   └─ watches Provider (Riverpod Notifier)
         └─ calls Repository (Appwrite SDK)
               └─ Appwrite Cloud
```

- **Screens** are stateless `ConsumerWidget`s — no business logic.
- **Providers** hold state and expose methods that screens call.
- **Repositories** are the only place that imports the Appwrite SDK.
- **Models** are plain Dart classes with `fromMap` / `toMap` serialization.

---

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you'd like to change.

1. Fork the repo
2. Create a feature branch (`git checkout -b feat/your-feature`)
3. Commit changes (`git commit -m 'feat: add your feature'`)
4. Push and open a PR

---

## License

MIT © [Servline](https://github.com/praaatap/Servline)

---

<div align="center">
  <sub>Built with Flutter · Powered by Appwrite · Designed for real people waiting in real lines</sub>
</div>
