# CardioGuardian AI

CardioGuardian AI is a clinical-grade health monitoring ecosystem designed for precision cardiovascular tracking. It integrates advanced machine learning for heart disease risk assessment, secure data persistence via a hybrid local/remote architecture, and an intelligent clinical analytics dashboard.

## Features

- **ML Risk Prediction** — RandomForest classifier trained on 13 UCI Heart Disease biomarkers
- **Patient Management** — Register, view, update, and delete patient records
- **Visit Scheduling** — Track appointments with pending/completed status
- **AI Health Assistant** — Context-aware chatbot with live system data
- **Excel Database** — All actions auto-logged to `health_database.xlsx` with CSV backup
- **Real-time Analytics** — Risk timeline, age/gender distribution, vital averages
- **Vitals Logging** — BP, weight, meals, lab results saved to database
- **Live Dashboard** — Connection status, patient stats, risk distribution

## Tech Stack

| Layer    | Technology                          |
|----------|-------------------------------------|
| Frontend | Flutter (Dart)                      |
| Backend  | FastAPI (Python)                    |
| ML Model | scikit-learn RandomForest           |
| Database | Excel (openpyxl) + CSV backup       |
| State    | Provider (ChangeNotifier)           |

## Getting Started

### Backend

```bash
cd backend
pip install -r requirements.txt
python train_model.py
python main.py
```

The server will print its network IP. Use this IP in the app's Settings screen.

### Flutter App

```bash
flutter pub get
flutter run
```

### Connect App to Backend

1. Start the backend server
2. Open the app → Dashboard → Tap the gear icon (⚙)
3. Enter the backend URL shown in the terminal (e.g., `http://192.168.1.7:8000`)
4. Tap "Test Connection" → "Save & Reconnect"

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── api_service.dart
│   └── app_theme.dart
├── providers/
│   └── health_provider.dart
├── screens/
│   ├── splash_screen.dart
│   ├── main_navigation.dart
│   ├── dashboard/
│   ├── patients/
│   ├── visits/
│   ├── prediction/
│   ├── assistant/
│   ├── analytics/
│   ├── monitoring/
│   ├── doctor/
│   ├── emergency/
│   └── settings/
└── widgets/
    └── glass_container.dart

backend/
├── main.py
├── train_model.py
├── requirements.txt
├── start_server.bat
└── models/
    ├── heart_disease_model.pkl
    └── feature_names.pkl
```

## API Endpoints

| Method | Endpoint                    | Description                |
|--------|-----------------------------|----------------------------|
| GET    | `/`                         | Server status              |
| GET    | `/patients`                 | List all patients          |
| POST   | `/patients/add`             | Register a patient         |
| PUT    | `/patients/{id}`            | Update patient info        |
| DELETE | `/patients/{id}`            | Delete a patient           |
| GET    | `/visits`                   | List all visits            |
| POST   | `/visits/add`               | Schedule a visit           |
| PUT    | `/visits/{id}/status`       | Update visit status        |
| POST   | `/predict`                  | Run ML risk prediction     |
| POST   | `/reports/save`             | Save ML report to Excel    |
| GET    | `/reports`                  | Get all saved reports      |
| POST   | `/vitals/log`               | Log a vital entry          |
| GET    | `/dashboard/stats`          | Live dashboard statistics  |
| GET    | `/analytics/summary`        | Analytics data for charts  |
| POST   | `/assistant/chat`           | AI health assistant chat   |
| GET    | `/excel/data`               | View raw Excel database    |

## License

This project is for educational and research purposes.
