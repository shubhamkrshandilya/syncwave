#!/bin/bash

# SyncWave - Quick Start Script

echo "🎵 SyncWave Quick Start"
echo "======================="
echo ""

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first."
    echo "Visit: https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo "✅ Flutter detected"
echo ""

# Get dependencies
echo "📦 Installing dependencies..."
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed"
echo ""

# Clean build
echo "🧹 Cleaning previous builds..."
flutter clean

echo "✅ Clean complete"
echo ""

# Show available devices
echo "📱 Available devices:"
flutter devices
echo ""

# Ask user which platform to run
echo "🚀 Ready to launch SyncWave!"
echo ""
echo "Choose a platform:"
echo "1) iOS Simulator"
echo "2) Android Emulator"
echo "3) Chrome (Web)"
echo "4) macOS (Desktop)"
echo "5) Let me choose manually"
echo ""

read -p "Enter your choice (1-5): " choice

case $choice in
    1)
        echo "🍎 Launching on iOS..."
        flutter run -d ios
        ;;
    2)
        echo "🤖 Launching on Android..."
        flutter run -d android
        ;;
    3)
        echo "🌐 Launching on Chrome..."
        flutter run -d chrome
        ;;
    4)
        echo "💻 Launching on macOS..."
        flutter run -d macos
        ;;
    5)
        echo "🎯 Choose your device..."
        flutter run
        ;;
    *)
        echo "❌ Invalid choice. Running default..."
        flutter run
        ;;
esac

echo ""
echo "🎉 Enjoy SyncWave!"
