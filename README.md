# 🎓 VoiceNote Mobile Application

## 📌 Overview

VoiceNote is a cross-platform mobile application designed to solve the problem of fragmented academic workflows among university students and lecturers.

The system integrates:

* Lecture recording 🎙️
* Timetable management 📅
* Module-based file organization 📂
* Notes and resources 🧠

into a **single unified platform**.

---

## 🚀 Features

### 🔐 Authentication System

* Email/password login
* Role-based access (Student / Lecturer)
* Secure user data storage (Firebase)

### 📊 Timetable & Exam Management

* Import timetable via Excel
* Display weekly schedule
* Show upcoming exams

### 🧠 Smart Lecture Logic

* Detect current/next lectures
* 30-minute post-lecture detection
* Auto-suggest module for recordings

### 🎙️ Voice Recording

* Record lectures
* Upload to Firebase Storage
* Save with module metadata

### 📂 Module-Based File System

Each module contains:

* Recordings
* Notes
* Resources

### 📝 Notes System

* Add/edit/delete notes
* Organized per module
* Easy retrieval

---

## 🏗️ Tech Stack

* **Frontend:** Flutter
* **Backend:** Firebase

  * Firebase Auth
  * Firestore Database
  * Firebase Storage

---

## 👥 Team Responsibilities

| Member           | Responsibility                      |
| ---------------- | ----------------------------------- |
| Madhuka Methsara | Authentication + System Integration |
| Member 2         | Excel Import + Database Upload      |
| Member 3         | Timetable UI + Exam Display         |
| Member 4         | Lecture Time Logic                  |
| Member 5         | Voice Recording + Storage           |
| Member 6         | Module File Management + Notes      |

---

## 🔄 Git Workflow

```bash
# Clone repository
git clone https://github.com/madhukamethsara/Voice-note-

# Create a new branch
git checkout -b feature-name

# Add changes
git add .

# Commit
git commit -m "Your message"

# Push
git push origin feature-name
```

### 📌 Important Rules

* Always work in a **separate branch**
* Never push directly to `main`
* Create a **Pull Request (PR)** for review

---

## 🎨 UI/UX Design

Figma Design:
👉 https://www.figma.com/design/6vLSPs0Ik0e5TjiYRp3N9k/Untitled

---

## 📂 Project Structure (Concept)

```
users/
modules/
timetables/
exams/
recordings/
notes/
```

---

## 🎯 Future Improvements

* AI transcription (Whisper)
* AI-generated summaries
* Flashcards & revision system
* Real-time collaboration features

---

## 💡 Vision

VoiceNote aims to become a **complete academic assistant**, helping students manage lectures, notes, and exams efficiently in one place.
