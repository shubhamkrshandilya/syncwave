# 🚀 Quick Start Deployment

## One-Command Deploy

```bash
./deploy.sh
```

Choose your platform when prompted!

---

## Platform Commands

### Firebase Hosting
```bash
flutter build web --profile
firebase deploy --only hosting
```

### Vercel
```bash
vercel --prod
```

### Netlify
```bash
flutter build web --profile
netlify deploy --prod
```

### Test Locally
```bash
cd build/web
python3 -m http.server 8000
# Open http://localhost:8000
```

---

## First Time Setup

### Firebase
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
# Public directory: build/web
# Single-page app: Yes
```

### Vercel
```bash
npm install -g vercel
vercel login
```

### Netlify
```bash
npm install -g netlify-cli
netlify login
```

---

## Configuration Files

✅ `firebase.json` - Firebase Hosting config (ready)  
✅ `deploy.sh` - Automated deployment script (ready)  
✅ `web/manifest.json` - PWA manifest (ready)  
✅ `web/index.html` - Loading screen (ready)  

📝 `.firebaserc` - Copy from `.firebaserc.template` and add your project ID

---

## Build Location

Production files: `build/web/`

Contains:
- index.html
- flutter_service_worker.js
- manifest.json
- assets/
- All compiled Flutter app code

---

## Support

Full guide: [DEPLOYMENT.md](DEPLOYMENT.md)

---

**Your app is ready to go live! 🎉**
