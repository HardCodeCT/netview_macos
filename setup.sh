#!/bin/bash
# setup.sh
# One-command setup script for NetView macOS development

set -e

echo "🚀 NetView macOS - Quick Setup Script"
echo "======================================"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check OS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}❌ This script requires macOS${NC}"
    exit 1
fi

echo -e "${BLUE}Checking prerequisites...${NC}"

# Check Xcode
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${YELLOW}⚠️  Xcode not found${NC}"
    echo ""
    echo "Please install Xcode from the App Store:"
    echo "  1. Open App Store"
    echo "  2. Search for 'Xcode'"
    echo "  3. Click 'Get' / 'Install'"
    echo "  4. Wait for installation (this may take a while)"
    echo "  5. Run this script again"
    echo ""
    exit 1
fi

echo -e "${GREEN}✓ Xcode found${NC}"

# Check Xcode CLI tools
if ! xcode-select -p &> /dev/null; then
    echo -e "${YELLOW}⚠️  Installing Xcode Command Line Tools...${NC}"
    xcode-select --install
    echo ""
    echo "Please complete the installation in the dialog, then run this script again."
    exit 0
fi

echo -e "${GREEN}✓ Xcode Command Line Tools installed${NC}"

# Check Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${YELLOW}⚠️  Homebrew not found. Installing...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add to PATH for current session
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    echo -e "${GREEN}✓ Homebrew installed${NC}"
fi

# Install create-dmg
if ! command -v create-dmg &> /dev/null; then
    echo -e "${YELLOW}📦 Installing create-dmg...${NC}"
    brew install create-dmg
    echo -e "${GREEN}✓ create-dmg installed${NC}"
else
    echo -e "${GREEN}✓ create-dmg found${NC}"
fi

# Make build scripts executable
echo -e "${YELLOW}🔧 Setting up build scripts...${NC}"
chmod +x build-dmg.sh
chmod +x build-spm.sh
echo -e "${GREEN}✓ Build scripts ready${NC}"

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Build the app:"
echo -e "     ${YELLOW}./build-dmg.sh${NC}"
echo ""
echo "  2. Or open in Xcode:"
echo -e "     ${YELLOW}open NetView.xcodeproj${NC}"
echo ""
echo "  3. Install the DMG:"
echo "     - Open NetView-macOS.dmg"
echo "     - Drag NetView.app to Applications"
echo ""
echo -e "${BLUE}Troubleshooting:${NC}"
echo "  - If build fails, check: ${YELLOW}TROUBLESHOOTING.md${NC}"
echo "  - For porting details, read: ${YELLOW}PORTING_GUIDE.md${NC}"
echo ""
