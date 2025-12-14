#!/bin/bash

# SyncWave Production Setup Script
# Installs and configures local server + Flutter web app

set -e

echo "🎵 SyncWave Production Setup"
echo "============================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found${NC}"
    echo "Please install Node.js from https://nodejs.org/"
    echo "Recommended version: 18.x or higher"
    exit 1
fi

echo -e "${GREEN}✅ Node.js $(node --version) detected${NC}"

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}⚠️  Flutter not found${NC}"
    echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo -e "${GREEN}✅ Flutter $(flutter --version | head -n 1 | awk '{print $2}') detected${NC}"
echo ""

# Install server dependencies
echo -e "${BLUE}📦 Installing server dependencies...${NC}"
cd server
npm install
cd ..
echo -e "${GREEN}✅ Server dependencies installed${NC}"
echo ""

# Install Flutter dependencies
echo -e "${BLUE}📦 Installing Flutter dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
echo ""

# Build Flutter web app (production)
echo -e "${BLUE}🏗️  Building Flutter web app...${NC}"
flutter build web --release
echo -e "${GREEN}✅ Flutter web app built${NC}"
echo ""

# Create launcher scripts
echo -e "${BLUE}📝 Creating launcher scripts...${NC}"

# macOS/Linux launcher
cat > start.sh << 'EOF'
#!/bin/bash

# SyncWave Launcher
# Starts local server and opens web app in browser

set -e

echo "🎵 Starting SyncWave..."

# Start local server in background
cd server
node server.js &
SERVER_PID=$!
cd ..

echo "⏳ Waiting for server to start..."
sleep 3

# Open web app in default browser
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    open "http://localhost:3456" || open -a "Google Chrome" "http://localhost:3456"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    xdg-open "http://localhost:3456" || google-chrome "http://localhost:3456"
fi

echo "✅ SyncWave is running!"
echo "   Server: http://localhost:3456"
echo "   Web App: http://localhost:PORT (Flutter will auto-open)"
echo ""
echo "Press Ctrl+C to stop"

# Start Flutter web app
flutter run -d chrome --web-port=auto

# Cleanup on exit
trap "kill $SERVER_PID 2>/dev/null || true" EXIT
EOF

chmod +x start.sh

# Windows launcher
cat > start.bat << 'EOF'
@echo off
echo Starting SyncWave...

cd server
start /B node server.js
cd ..

timeout /t 3 /nobreak > nul

start http://localhost:3456

echo SyncWave is running!
echo Press Ctrl+C to stop

flutter run -d chrome --web-port=auto
EOF

echo -e "${GREEN}✅ Launcher scripts created${NC}"
echo ""

# Create config file
echo -e "${BLUE}⚙️  Creating configuration...${NC}"

cat > server/config.json << EOF
{
  "port": 3456,
  "musicDirectories": [
    "$(echo ~)/Music"
  ],
  "audioExtensions": [".mp3", ".m4a", ".flac", ".wav", ".ogg", ".aac", ".opus"],
  "watchForChanges": true,
  "corsOrigins": ["http://localhost:*", "http://127.0.0.1:*"]
}
EOF

echo -e "${GREEN}✅ Configuration created${NC}"
echo ""

# Summary
echo -e "${GREEN}🎉 Setup Complete!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📖 How to Use:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  1️⃣  Start SyncWave:"
echo "     ${BLUE}./start.sh${NC}  (macOS/Linux)"
echo "     ${BLUE}start.bat${NC}  (Windows)"
echo ""
echo "  2️⃣  Server will scan your Music folder automatically"
echo ""
echo "  3️⃣  Web app opens in Chrome - no file uploads needed!"
echo ""
echo "  4️⃣  To add more music folders:"
echo "     Edit server/config.json"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 Manual Commands:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Server only:    ${BLUE}cd server && npm start${NC}"
echo "  Web app only:   ${BLUE}flutter run -d chrome${NC}"
echo "  Rebuild web:    ${BLUE}flutter build web --release${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo -e "${GREEN}Ready to launch! Run: ./start.sh${NC}"
echo ""
