# 🚀 SyncWave Deployment Guide

Complete guide for deploying SyncWave to production.

---

## 📦 Build Output

The production build is located in: `build/web/`

This directory contains all the files needed to deploy your app.

---

## 🌐 Deployment Options

### 1. Firebase Hosting (Recommended)

**Setup:**
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
cd /Users/shubham/Desktop/github/syncwave
firebase init hosting

# Select options:
# - Use existing project or create new one
# - Public directory: build/web
# - Single-page app: Yes
# - Set up automatic builds: No
# - Overwrite index.html: No
```

**Deploy:**
```bash
# Build the app
flutter build web --profile

# Deploy to Firebase
firebase deploy --only hosting
```

**Custom Domain:**
```bash
firebase hosting:channel:deploy live
```

Your app will be available at: `https://your-project.web.app`

---

### 2. Vercel

**Setup:**
```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login
```

**Deploy:**
```bash
# From project root
cd /Users/shubham/Desktop/github/syncwave
vercel

# Follow prompts
# - Set up and deploy: Yes
# - Scope: Your account
# - Link to existing project: No
# - Project name: syncwave
# - Directory: ./
# - Override settings: Yes
# - Build command: flutter build web --profile
# - Output directory: build/web
# - Development command: flutter run -d chrome
```

**Production Deploy:**
```bash
vercel --prod
```

---

### 3. Netlify

**Option A: Netlify CLI**
```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login
netlify login

# Deploy
cd /Users/shubham/Desktop/github/syncwave
flutter build web --profile
netlify deploy

# For production
netlify deploy --prod
```

**Option B: Drag & Drop**
1. Build: `flutter build web --profile`
2. Go to [Netlify Drop](https://app.netlify.com/drop)
3. Drag `build/web` folder
4. Done!

**netlify.toml** (optional):
```toml
[build]
  command = "flutter build web --profile"
  publish = "build/web"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200
```

---

### 4. GitHub Pages

**Setup:**
```bash
cd /Users/shubham/Desktop/github/syncwave

# Build with base href
flutter build web --profile --base-href "/syncwave/"

# Create gh-pages branch
git checkout -b gh-pages

# Copy build files
cp -r build/web/* .

# Commit and push
git add .
git commit -m "Deploy to GitHub Pages"
git push origin gh-pages
```

**Enable GitHub Pages:**
1. Go to repository settings
2. Pages → Source → gh-pages branch
3. Save

Your app will be at: `https://username.github.io/syncwave/`

---

### 5. AWS S3 + CloudFront

**Setup S3:**
```bash
# Install AWS CLI
brew install awscli

# Configure AWS
aws configure

# Create S3 bucket
aws s3 mb s3://syncwave-app

# Enable static website hosting
aws s3 website s3://syncwave-app --index-document index.html

# Upload files
cd /Users/shubham/Desktop/github/syncwave
flutter build web --profile
aws s3 sync build/web/ s3://syncwave-app --acl public-read
```

**CloudFront (CDN):**
1. Create CloudFront distribution
2. Origin: Your S3 bucket
3. Default root object: index.html
4. SSL certificate: Request via ACM
5. Custom domain: Your domain

---

### 6. Docker + Any Cloud

**Dockerfile:**
```dockerfile
FROM nginx:alpine

# Copy built web app
COPY build/web /usr/share/nginx/html

# Nginx config
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf:**
```nginx
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    server {
        listen 80;
        server_name localhost;
        root /usr/share/nginx/html;
        index index.html;

        location / {
            try_files $uri $uri/ /index.html;
        }

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

**Build & Run:**
```bash
# Build Flutter app
flutter build web --profile

# Build Docker image
docker build -t syncwave:latest .

# Run locally
docker run -p 8080:80 syncwave:latest

# Push to registry
docker tag syncwave:latest your-registry/syncwave:latest
docker push your-registry/syncwave:latest
```

---

## 🔧 Build Commands

### Development Build
```bash
flutter build web
```
- Fast build
- Includes debug info
- Larger file size
- ~10-20 MB

### Profile Build (Recommended)
```bash
flutter build web --profile
```
- Balanced performance
- Some optimizations
- Performance profiling enabled
- ~5-10 MB

### Release Build (Production)
```bash
flutter build web --release
```
- Fully optimized
- Minified code
- Smallest size
- ~3-5 MB

### With CanvasKit
```bash
flutter build web --profile --web-renderer canvaskit
```
- Better performance
- Consistent rendering
- Larger initial load

### With HTML Renderer
```bash
flutter build web --profile --web-renderer html
```
- Faster initial load
- Smaller bundle size
- May have rendering differences

---

## 📊 Build Optimization

### Reduce Bundle Size
```bash
# Tree-shake icons (enabled by default)
flutter build web --profile

# Skip icons tree-shaking (if needed)
flutter build web --profile --no-tree-shake-icons

# Use HTML renderer for smaller size
flutter build web --profile --web-renderer html
```

### Improve Performance
```bash
# Use CanvasKit for better performance
flutter build web --profile --web-renderer canvaskit

# Enable Skwasm (experimental)
flutter build web --profile --wasm
```

---

## 🌍 Environment Variables

Create `.env` file:
```env
API_URL=https://api.syncwave.app
WS_URL=wss://sync.syncwave.app
SENTRY_DSN=your-sentry-dsn
ANALYTICS_ID=your-analytics-id
```

Use in app:
```dart
// lib/config/env.dart
class Env {
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000',
  );
}
```

Build with env:
```bash
flutter build web --profile --dart-define=API_URL=https://api.syncwave.app
```

---

## 🔐 Security Headers

Add to your server configuration:

**Nginx:**
```nginx
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "no-referrer-when-downgrade" always;
add_header Content-Security-Policy "default-src 'self' https: data: 'unsafe-inline' 'unsafe-eval';" always;
```

**Firebase hosting.json:**
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "headers": [
      {
        "source": "**",
        "headers": [
          {
            "key": "X-Frame-Options",
            "value": "SAMEORIGIN"
          },
          {
            "key": "X-Content-Type-Options",
            "value": "nosniff"
          }
        ]
      }
    ]
  }
}
```

---

## 📈 Performance Monitoring

### Add Google Analytics
```bash
flutter pub add firebase_analytics
```

### Add Sentry
```bash
flutter pub add sentry_flutter
```

---

## ✅ Pre-Deployment Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Test on multiple browsers
- [ ] Test responsive design
- [ ] Check all features work
- [ ] Optimize images
- [ ] Configure security headers
- [ ] Set up SSL certificate
- [ ] Configure CDN
- [ ] Test PWA functionality
- [ ] Set up error tracking
- [ ] Configure analytics
- [ ] Test offline functionality
- [ ] Optimize loading time
- [ ] Set up monitoring

---

## 🚀 Quick Deploy Script

Create `deploy.sh`:
```bash
#!/bin/bash

echo "🎵 SyncWave Deployment Script"
echo "=============================="

# Clean previous build
echo "🧹 Cleaning previous build..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build for web
echo "🔨 Building for web..."
flutter build web --profile

# Deploy to Firebase (example)
echo "🚀 Deploying to Firebase..."
firebase deploy --only hosting

echo "✅ Deployment complete!"
echo "🌐 Your app is live!"
```

Make executable and run:
```bash
chmod +x deploy.sh
./deploy.sh
```

---

## 📱 Current Build Location

Your production-ready app is in:
```
/Users/shubham/Desktop/github/syncwave/build/web/
```

Files included:
- `index.html` - Entry point
- `flutter_service_worker.js` - PWA service worker
- `manifest.json` - PWA manifest
- `assets/` - App assets
- `canvaskit/` - CanvasKit files
- `icons/` - App icons

---

## 🌐 Test Locally

```bash
# Option 1: Python
cd build/web
python3 -m http.server 8000

# Option 2: Node.js
npx serve build/web

# Option 3: PHP
cd build/web
php -S localhost:8000
```

Then open: `http://localhost:8000`

---

## 📞 Support & Resources

- [Flutter Web Deployment Docs](https://docs.flutter.dev/deployment/web)
- [Firebase Hosting Docs](https://firebase.google.com/docs/hosting)
- [Vercel Docs](https://vercel.com/docs)
- [Netlify Docs](https://docs.netlify.com)

---

**Your SyncWave app is production-ready! 🎉**

Choose your deployment platform and go live!
