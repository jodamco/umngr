# Micro Manager - Flutter App

The main Flutter application for the Micro Manager project. This app provides a user interface for tracking goals, checkpoints, and events.

## Architecture

This project follows a clean architecture pattern with:

- **lib/core/** - Core functionality (DI, routing, services, theme, utilities)
- **lib/features/** - Feature-based modules (goals, checkpoint-events, etc.)
- **lib/shared/** - Shared code and enums
- **lib/widgets/** - Shared widgets

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── core/
│   ├── di/                  # Dependency injection
│   ├── routing/             # Navigation and routes
│   ├── services/            # Core services (database, etc.)
│   ├── theme/               # Theme configuration
│   └── utils/               # Utility functions
├── features/                # Feature modules
│   ├── checkpoint-events/   # Checkpoint event tracking
│   ├── goals/               # Goal management
│   └── ...
├── shared/                  # Shared enums and constants
└── widgets/                 # Shared UI components
```

## Features

### Goals
- Create and manage long-term goals
- Track progress and milestones

### Checkpoint Events
- Define checkpoints within goals
- Log events associated with checkpoints
- Monitor milestone achievements

## Getting Started

### Prerequisites

- Flutter 3.0+
- Dart 3.0+

### Installation

```bash
flutter pub get
```

### Running

```bash
flutter run
```

### Building

```bash
# Debug
flutter build apk --debug

# Release
flutter build apk --release

# iOS
flutter build ios --release
```

## Development Guidelines

See the project's [coding standards and architectural guidelines](../.instructions.md) for best practices.

### Key Principles

- **Widget Composition**: Use private widget classes instead of build functions
- **Feature-based Structure**: Organize code by features
- **Clean Architecture**: Separate concerns across layers
- **DI Pattern**: Use service locator for dependency management

## Testing

```bash
flutter test
```

## Troubleshooting

### Build Issues

```bash
# Clean build
flutter clean
flutter pub get
flutter pub upgrade
```

### Dependency Issues

```bash
# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

## Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/docs)
