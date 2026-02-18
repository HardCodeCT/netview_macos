#!/bin/bash
# build-dmg.sh
# Script to build NetView.app and create a DMG installer for macOS

set -e

echo "🚀 Building NetView for macOS..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}❌ This script must be run on macOS${NC}"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}❌ Xcode is not installed. Please install Xcode from the App Store.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Xcode found${NC}"

# Check if create-dmg is installed
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}⚠️  create-dmg not found. Installing via Homebrew...${NC}"
    
    if ! command -v brew &> /dev/null; then
        echo -e "${RED}❌ Homebrew is not installed. Please install from https://brew.sh${NC}"
        exit 1
    fi
    
    brew install create-dmg
    echo -e "${GREEN}✓ create-dmg installed${NC}"
else
    echo -e "${GREEN}✓ create-dmg found${NC}"
fi

# Clean previous builds
echo -e "${YELLOW}🧹 Cleaning previous builds...${NC}"
rm -rf build
rm -rf dist
rm -f NetView-macOS.dmg

# Build the app
echo -e "${YELLOW}🔨 Building NetView.app...${NC}"
xcodebuild -project NetView.xcodeproj \
    -scheme NetView \
    -configuration Release \
    -derivedDataPath ./build \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    | xcpretty || true

if [ ! -d "build/Build/Products/Release/NetView.app" ]; then
    echo -e "${RED}❌ Build failed. NetView.app not found.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build completed successfully${NC}"

# Create distribution directory
echo -e "${YELLOW}📦 Preparing distribution...${NC}"
mkdir -p dist
cp -R build/Build/Products/Release/NetView.app dist/

# Create DMG
echo -e "${YELLOW}💿 Creating DMG installer...${NC}"
create-dmg \
    --volname "NetView Installer" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "NetView.app" 175 120 \
    --hide-extension "NetView.app" \
    --app-drop-link 425 120 \
    --no-internet-enable \
    "NetView-macOS.dmg" \
    "dist/" 2>/dev/null || true

if [ ! -f "NetView-macOS.dmg" ]; then
    echo -e "${RED}❌ DMG creation failed${NC}"
    exit 1
fi

# Get DMG size
DMG_SIZE=$(du -h NetView-macOS.dmg | cut -f1)

echo ""
echo -e "${GREEN}✅ Build completed successfully!${NC}"
echo ""
echo -e "${GREEN}📦 DMG created: NetView-macOS.dmg${NC}"
echo -e "${GREEN}📏 Size: ${DMG_SIZE}${NC}"
echo ""
echo -e "${YELLOW}📝 To install:${NC}"
echo "   1. Open NetView-macOS.dmg"
echo "   2. Drag NetView.app to the Applications folder"
echo "   3. Open NetView from Applications"
echo ""
echo -e "${YELLOW}🔒 If you see a security warning:${NC}"
echo "   1. Go to System Settings > Privacy & Security"
echo "   2. Click 'Open Anyway' next to the NetView warning"
echo ""
