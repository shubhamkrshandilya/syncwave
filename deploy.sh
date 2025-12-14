#!/bin/bash

echo "🎵 SyncWave Deployment Script"
echo "=============================="
echo ""

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Clean previous build
echo -e "${BLUE}🧹 Cleaning previous build...${NC}"
flutter clean
echo ""

# Get dependencies
echo -e "${BLUE}📦 Getting dependencies...${NC}"
flutter pub get
echo ""

# Build for web
echo -e "${BLUE}🔨 Building for web (profile mode)...${NC}"
flutter build web --profile
echo ""

# Check if build was successful
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Build successful!${NC}"
    echo ""
    
    # Show build size
    echo -e "${BLUE}📊 Build size:${NC}"
    du -sh build/web
    echo ""
    
    # Ask for deployment platform
    echo -e "${BLUE}🚀 Choose deployment platform:${NC}"
    echo "1) Firebase Hosting"
    echo "2) Test locally (http-server)"
    echo "3) Skip deployment"
    read -p "Enter choice (1-3): " choice
    
    case $choice in
        1)
            echo ""
            echo -e "${BLUE}🚀 Deploying to Firebase...${NC}"
            firebase deploy --only hosting
            
            if [ $? -eq 0 ]; then
                echo ""
                echo -e "${GREEN}✅ Deployment complete!${NC}"
                echo -e "${GREEN}🌐 Your app is live!${NC}"
            else
                echo ""
                echo -e "${RED}❌ Deployment failed${NC}"
                echo "Make sure Firebase CLI is installed and configured:"
                echo "  npm install -g firebase-tools"
                echo "  firebase login"
                echo "  firebase init hosting"
            fi
            ;;
        2)
            echo ""
            echo -e "${BLUE}🌐 Starting local server...${NC}"
            echo "Open http://localhost:8000 in your browser"
            echo "Press Ctrl+C to stop"
            echo ""
            cd build/web && python3 -m http.server 8000
            ;;
        3)
            echo ""
            echo -e "${BLUE}ℹ️  Build files are in: build/web/${NC}"
            echo "You can deploy manually using the instructions in DEPLOYMENT.md"
            ;;
        *)
            echo ""
            echo -e "${RED}Invalid choice${NC}"
            ;;
    esac
else
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✨ Done!${NC}"
