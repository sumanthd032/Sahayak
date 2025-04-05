# 📱 Sahayak App

**Sahayak** is a smart, AI-powered, and senior-friendly Flutter mobile application designed to empower users—especially the elderly—with essential services like emergency support, memory assistance, storytelling, and real-time chat zones.

---

## ✨ Features

### 🏠 Home Screen
- Greets the user by name.
- Beautiful banner with dynamic fit (`home_banner.jpeg` 3:2 aspect ratio).
- Grid menu offering access to all major sections.
- Integrated bottom navigation for:
  - Home
  - Community
  - ChatZone
  - Profile

### 📞 Emergency Section
- Five emergency buttons:
  - 👨‍👩‍👧‍👦 Family – calls number saved in profile.
  - 🚓 Police – dials **100**
  - 🚑 Ambulance – dials **108**
  - 🔥 Fire – dials **101**
  - 👴 Senior Citizen – dials **14567**
- Intuitive square cards with icons and labels.
- Uses `url_launcher` to dial emergency numbers.

### 💬 ChatZone
- Real-time communication support.
- Elder-friendly UI for seamless chatting.

### 📖 StoryZone (Gemini Integration)
- Users can **type a story prompt** and get AI-generated stories using **Google Gemini API**.
- Input box styled with modern UI.
- Response displayed below the prompt box in an elegant format.

### 🧠 Memory Notes
- Save, edit, and delete personal memory notes.
- Designed for elderly users to remember important things.

### 📜 Pension Tracker
- Keeps track of pension updates.
- Visual and accessible layout for ease of use.

### 🛒 Order Essentials
- Order daily necessities like groceries or medicines.
- Intuitive shopping interface.

### 🎉 FunZone
- Offers fun and engaging content for the elderly.
- Games, jokes, and entertainment content.

### 👥 Contacts
- Save and manage emergency contacts.
- Designed with accessibility in mind.

### 👤 Profile
- Update user details (name, emergency number, etc.)
- Firebase Auth integrated.

---

## 🔐 Firebase Integration

- **Authentication** using FirebaseAuth.
- Firebase initialized during app startup.
- User data used throughout the app.

---

