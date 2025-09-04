
# Favorite Service App

A Flutter demo application that:

- Fetches a paginated list of services from an dummy API.

- Allows users to mark services as favorites.

- Persists favorites locally using Hive.

- Uses Riverpod for state management.

## 🚀 Features

- All Services Tab – Fetches services with **infinite scroll pagination**.

- Favorites Tab – Displays only **favorite services** (synced with Hive).

- Persistent Storage – Favorites remain saved even after app restart.

- Clean Architecture – Domain, Data, and Presentation layers + comments.

- Tests – Unit, widget, and integration tests for reliability.

## 🛠️ Tech Stack

- Flutter

- Riverpod
(state management)

- Hive
(local persistence)

- Hive Flutter
(storage path resolution)

- Mockito / Mocktail
for testing

- integration_test

## 📦 Setup
### 1️⃣ Clone the repo
```bash
git clone https://github.com/Ksuthar28/favorite_service.git
cd favorite_service
```

### 2️⃣ Install dependencies
```bash
flutter pub get
```

### 3️⃣ Run app
```bash
flutter run
```

## 🧪 Running Tests
### Unit & Widget Tests
```bash
flutter test
```


We have tests for:

- Widget tests → pagination loader, toggle favorites

- Notifier tests → service fetching, state updates

### Integration Tests
Unit & Widget Tests
```bash
flutter test integration_test
```

## 🔗 API Setup

Creates 2 endpoints in (https://jsonplaceholder.typicode.com/posts):

### 1. posts
**Endpoint:** `/posts`  
**Sample:**
```json
[
  { "id": "1", "title": "Wdsf", "body": "fddfdf" },
  { "id": "2", "title": "dfs", "body": "dffd" }
]
```


## 📂 Project Structure
```
lib/
├── core/          # Constants, helpers
├── data/          # Repository implementations & API clients
├── domain/        # Entities & UseCases
├── presentation/  # UI (Pages, Providers, Widgets)
└── main.dart      # App entrypoint
```
