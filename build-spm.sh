#!/bin/bash
# build-spm.sh
# Alternative build using Swift Package Manager (no Xcode project needed)

set -e

echo "🚀 Building NetView using Swift Package Manager..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Swift installation
if ! command -v swift &> /dev/null; then
    echo -e "${RED}❌ Swift not found. Please install Xcode Command Line Tools.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Swift found: $(swift --version | head -n1)${NC}"

# Clean previous build
echo -e "${YELLOW}🧹 Cleaning previous build...${NC}"
swift package clean
rm -rf .build/release/NetView.app
rm -rf dist
rm -f NetView-macOS.dmg

# Build using Swift Package Manager
echo -e "${YELLOW}🔨 Building with Swift Package Manager...${NC}"
swift build -c release

if [ ! -f ".build/release/NetView" ]; then
    echo -e "${RED}❌ Build failed${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Build completed${NC}"

# Create .app bundle manually
echo -e "${YELLOW}📦 Creating .app bundle...${NC}"
mkdir -p dist/NetView.app/Contents/MacOS
mkdir -p dist/NetView.app/Contents/Resources

# Copy executable
cp .build/release/NetView dist/NetView.app/Contents/MacOS/

# Copy Info.plist
cp NetView/Info.plist dist/NetView.app/Contents/

# Create basic icon (optional - requires iconutil)
# For now, we'll skip icon generation

# Make executable
chmod +x dist/NetView.app/Contents/MacOS/NetView

echo -e "${GREEN}✓ App bundle created${NC}"

# Create DMG (if create-dmg is installed)
if command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}💿 Creating DMG...${NC}"
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
    
    if [ -f "NetView-macOS.dmg" ]; then
        DMG_SIZE=$(du -h NetView-macOS.dmg | cut -f1)
        echo -e "${GREEN}✓ DMG created (${DMG_SIZE})${NC}"
    else
        echo -e "${YELLOW}⚠️  DMG creation skipped${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  create-dmg not installed. Skipping DMG creation.${NC}"
    echo -e "   Install with: brew install create-dmg"
fi

echo ""
echo -e "${GREEN}✅ Build completed!${NC}"
echo -e "   App location: dist/NetView.app"
echo ""
