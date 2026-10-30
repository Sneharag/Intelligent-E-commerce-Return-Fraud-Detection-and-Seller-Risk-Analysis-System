# 🛡️ E-commerce Return Fraud Detection & Risk Analysis

A full-stack application designed to detect and analyze fraudulent product returns. This project uses a **Django REST API** for the backend and machine learning, paired with a **Flutter** mobile app for a seamless user experience.

## 🚀 Features
- **User Authentication:** Secure login and registration using JWT.
- **Return Request Submission:** Users can submit return requests via the Flutter app.
- **ML Fraud Scoring:** Automated risk analysis of return requests using a trained machine learning model.
- **Admin Dashboard:** Backend API to review flagged returns and risk scores.
- **Cross-Platform:** Flutter app runs on Android, iOS, and Web.

## 🛠️ Tech Stack
**Backend (Django):**
- Python / Django
- Django REST Framework (DRF)
- Scikit-learn / Pandas (Machine Learning)
- SQLite (Development Database)

**Frontend (Flutter):**
- Dart / Flutter
- HTTP / Dio (API Integration)

## 📂 Project Structure
```text
return-fraud-detection/
│
├── Django/                 # Django Backend & ML Models
│   ├── manage.py
│   ├── requirements.txt
│   ├── myapp/              # Core app logic
│   ├── ml/                 # Machine learning models & logic
│   └── templates/
│
├── Flutter/                # Flutter Mobile Application
│   ├── pubspec.yaml
│   ├── lib/                # Dart source code
│   └── assets/
│
└── README.md