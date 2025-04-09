
# 🌟 Sahayak - A Digital Companion for Senior Citizens

Sahayak is an empathetic, AI-powered Flutter app designed specifically for senior citizens. It combines essential services, emergency support, entertainment, memory tools, communities, and a multi-language AI chatbot — all within a simple, accessible interface.

---

## 🔗 Live Demo & Releases

- 🌐 **Live App**: [sahayak-34321.web.app](https://sahayak-34321.web.app)  
- 📦 **Latest Release**: [GitHub Releases](https://github.com/sumanthd032/Sahayak/releases/tag/v1.0.0)

---

## 🛠️ Built With

- 💙 **Frontend**: [Flutter](https://flutter.dev/)
- ☁️ **Backend**: [Firebase Auth, Firestore, Hosting](https://firebase.google.com/)
- 🧠 **AI Integration**: [Gemini API](https://ai.google.dev/)
- 📦 **Hosting**: Firebase Hosting
- 🎤 **TTS/STT**: Speech-to-Text and Text-to-Speech packages for accessibility

---

## 📱 App Overview

### 🏠 Home Tab
- **Pension Tracker**: Add pension amount, name, helpline — track monthly receipts.
- **Emergency Help**: Quick dial buttons (family, police, fire, senior helpline).
- **Memory Vault**: Add notes to remember; mark sensitive items.
- **FunZone**: Play games like Tic Tac Toe.
- **StoryZone**: Generate stories in preferred language using Gemini API (TTS enabled).
- **Order Things**: Search Amazon, Flipkart, Swiggy, Zomato — redirect to buy directly.

### 👥 Communities Tab
- Create or join public/private communities.
- Chat with members to share experiences and stay connected.

### 💬 ChatZone Tab
- Gemini-powered AI Chat with the following modes:
  - Travel, Wellness, Normal, Religious, Knowledge
  - ✨ Custom Mode: Create your own AI behavior!
- Chat responds in user's selected language.
- Full **Text-to-Speech (TTS)** and **Speech-to-Text (STT)** support.

### 👤 Profile Tab
- View/edit user info: name, language, emergency contact, etc.
- App settings: Change language, family contact, and logout.
- About Sahayak section.

---

## 🌍 Accessibility-Centered UX

- 👀 Large fonts and simple layouts
- 🎤 Voice support with TTS/STT
- 🌐 Language customization (at signup and in settings)
- 🧓 Designed from the perspective of elderly users


---

## 🔧 Setup Instructions

### 1. 📥 Clone the Repo

```bash
git clone https://github.com/your-username/sahayak.git
cd sahayak
```

### 2. 🔐 Set Up API Keys

Create a file named `lib/utils/secrets.dart`:

```dart
const apiKey = "your_api_key"
```

### 3. 🔨 Install Dependencies

```bash
flutter pub get
```

### 4. ▶️ Run the App

```bash
flutter run
```

Make sure you have an emulator running or device connected.

### 5. 🌐 Firebase Setup

Ensure Firebase is properly set up:

- Firebase Auth: for login/sign-up
- Firestore: for storing user data, communities, notes, etc.
- Firebase Hosting: (if deploying)

> You’ll need to connect your Firebase project using `flutterfire configure` or Firebase Console.

---

## 🚀 Deployment (Web)

To deploy using Firebase Hosting:

```bash
flutter build web
firebase deploy
```

Ensure `firebase.json` and `.firebaserc` are configured correctly.

---

## 💡 Future Enhancements

- Medication & health reminders
- Offline emergency and memory access
- Voice-activated full app navigation
- Family dashboard for caregivers
- New games and exercises for mental fitness

---

## 🤝 Contributing

We love contributions! Here’s how you can help:

1. Fork the repo  
2. Create a feature branch  
3. Commit your changes  
4. Push and open a PR  

---

## 🛡 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🙏 Credits

Developed using:
- Flutter
- Firebase
- Gemini API
- Speech packages for accessibility

> “Sahayak” means *Helper*. This app strives to be just that — a trusted companion for senior citizens in the digital world.
> Developed by Team NOVA
