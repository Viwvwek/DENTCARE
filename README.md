# DENTCARE

<div align="center">

### Mobile Dental Assistance Platform

A scalable **mobile healthcare application** designed to improve access to dental services, streamline patient interaction, and simplify appointment management.

<p>

<img src="https://img.shields.io/badge/Flutter-Mobile%20App-blue?logo=flutter"/>
<img src="https://img.shields.io/badge/FastAPI-Backend-green?logo=fastapi"/>
<img src="https://img.shields.io/badge/Python-API-yellow?logo=python"/>
<img src="https://img.shields.io/badge/License-MIT-orange"/>
<img src="https://img.shields.io/badge/Status-Active-success"/>

</p>

</div>

---

## Table of Contents

1. Overview
2. Features
3. Architecture
4. Technology Stack
5. Project Structure
6. Installation
7. Running the Application
8. API Documentation
9. Screenshots
10. Roadmap
11. Contributing
12. License
13. Author

---

## Overview

**DENTCARE** is a mobile-first dental care platform designed to bridge the gap between patients and dental services. The application provides a streamlined digital interface that enables patients to access dental services, interact with dental professionals, and manage appointments efficiently.

The system follows a modern **client–server architecture** using **Flutter** for the mobile application and **FastAPI** for backend services.

---

## Features

### Patient Features

| Feature                | Description                         |
| ---------------------- | ----------------------------------- |
| User Registration      | Secure user sign-up and login       |
| Dental Services        | Browse available dental services    |
| Appointment Management | Book and manage dental appointments |
| Mobile Experience      | Optimized mobile user interface     |

### System Features

| Feature              | Description                               |
| -------------------- | ----------------------------------------- |
| REST API Backend     | FastAPI based RESTful architecture        |
| Modular Backend      | Structured and scalable backend modules   |
| Secure Communication | Client-server communication via REST APIs |
| Scalable Design      | Designed for future cloud deployment      |

---

## System Architecture

```
              Mobile Application
                  (Flutter)
                       |
                       | REST API
                       v
                FastAPI Backend
                       |
                       | Data Processing
                       v
                    Database
```

The application uses a client-server model where the Flutter mobile application communicates with backend services through REST APIs.

---

## Technology Stack

| Layer         | Technology      |
| ------------- | --------------- |
| Frontend      | Flutter, Dart   |
| Backend       | Python, FastAPI |
| Server        | Uvicorn         |
| Communication | REST APIs, JSON |

---

## Project Structure

```
DENTCARE
│
├── mobile_app
│   ├── lib
│   ├── assets
│   └── pubspec.yaml
│
├── backend
│   ├── app.py
│   ├── models
│   ├── routes
│   └── requirements.txt
│
├── docs
│   └── architecture.md
│
└── README.md
```

---

## Installation

Clone the repository:

```bash
git clone https://github.com/Viwvwek/DENTCARE-.git
```

Navigate to the project directory:

```bash
cd DENTCARE
```

---

## Backend Setup

Install backend dependencies:

```bash
pip install -r requirements.txt
```

Run the backend server:

```bash
python -m uvicorn app:app --host 0.0.0.0 --port 8000
```

Backend will be available at:

```
http://localhost:8000
```

---

## Mobile App Setup

Install Flutter dependencies:

```bash
flutter pub get
```

Run the mobile application:

```bash
flutter run
```

---

## API Documentation

FastAPI automatically generates interactive API documentation.

| Tool       | URL                                                        |
| ---------- | ---------------------------------------------------------- |
| Swagger UI | [http://localhost:8000/docs](http://localhost:8000/docs)   |
| ReDoc      | [http://localhost:8000/redoc](http://localhost:8000/redoc) |

Example API request:

```
GET /services
```

Example response:

```json
{
  "services": [
    "Dental Checkup",
    "Teeth Cleaning",
    "Root Canal"
  ]
}
```

---

## Screenshots

Screenshots demonstrating the application interface can be added in the `docs/images` directory.

Example:

```
docs/images/login.png
docs/images/appointments.png
```

Markdown example:

```markdown
![Application Screenshot](docs/images/app.png)
```

---

## Roadmap

Planned future improvements include:

| Feature                | Description                        |
| ---------------------- | ---------------------------------- |
| Appointment Scheduling | Advanced booking system            |
| Push Notifications     | Reminders for appointments         |
| Doctor Dashboard       | Interface for dental professionals |
| Cloud Database         | Migration to cloud-based storage   |
| Payment Integration    | Online payment gateway             |
| AI Assistant           | AI-based dental consultation       |

---

## Contributing

Contributions are welcome. Please follow the steps below:

1. Fork the repository
2. Create a new branch
3. Commit your changes
4. Submit a pull request

---

## License

This project is distributed under the **MIT License**.

---

## Author

**Vivek Vinod**
Computer Science Engineer
Full Stack Developer | Mobile Developer

GitHub: [https://github.com/Viwvwek](https://github.com/Viwvwek)
