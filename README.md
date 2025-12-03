🌾 CropCareAI – Smart Crop Disease Detection (Flutter Web)

Live Demo:
🔗 https://cropcareai-u7co.onrender.com/

CropCareAI is an AI-powered crop health monitoring web application built using Flutter Web. The app allows farmers and agricultural experts to upload crop images and instantly detect possible diseases using machine-learning models. This project aims to empower farmers with quick, reliable plant diagnostics and actionable insights.

🚀 Features
🔍 AI-Based Crop Disease Detection

Upload images of your crop (leaf/plant).

The system analyzes the image and predicts possible diseases.

Provides confidence score and disease name.

🧠 Deep Learning Integration

The app communicates with a backend model (API) trained for plant disease classification.

Supports popular crops like wheat, rice, maize, and more (based on your model).

🎨 Built with Flutter

Clean UI and smooth UX.

Responsive layout for desktop, tablet, and mobile browsers.

Works without installation — just open the link.

☁️ Hosted on Render

The app is deployed on Render for stable, free web hosting.

Lightweight and optimized for web usage.

📁 Project Structure (Flutter)
lib/
│── main.dart
│── screens/
│     └── home_screen.dart
│── widgets/
│     └── upload_card.dart
│── services/
│     └── api_service.dart
assets/
web/

🔧 How It Works (Flow Diagram)

User uploads image

Flutter Web → sends to ML API

API processes image using trained model

Returns disease prediction + accuracy

Flutter Web displays results to user

🛠️ Tech Stack
Component	Technology
Frontend	Flutter Web
Backend (API)	Python / FastAPI / Flask (your choice)
ML Model	TensorFlow / PyTorch
Hosting	Render.com
Storage	Firebase / Cloudinary / Local API (optional)
▶️ How to Run Locally

Clone repo

git clone <your-repo-url>
cd cropcareai


Install dependencies

flutter pub get


Enable web support

flutter config --enable-web


Run the app

flutter run -d chrome

🌐 Deployment (Render)

Your web app is deployed on Render using:

flutter build web


This generates a /build/web folder, which is uploaded to Render’s static site service.

📸 Screenshots (Optional)

Add screenshots of your UI here.

📞 Contact / Support

If you need help with:

Improving the UI

Deploying the backend model

Making a mobile version (APK)

Adding new crop disease models

Feel free to ask me anytime!
