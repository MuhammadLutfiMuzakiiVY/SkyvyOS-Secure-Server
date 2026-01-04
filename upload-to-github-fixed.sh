#!/bin/bash

################################################################################
# SkyvyOS GitHub Upload - FIXED VERSION
# URL dan username sudah diperbaiki
################################################################################

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# URL YANG BENAR
GITHUB_REPO="https://github.com/MuhammadLutfiMuzakiYY/SkyvyOS-Secure-Server.git"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     SkyvyOS GitHub Upload (FIXED)                           ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Create .gitignore
echo -e "${GREEN}[1/7] Creating .gitignore...${NC}"
cat > .gitignore <<'EOF'
build/
*.iso
*.log
__pycache__/
*.pyc
.vscode/
.idea/
EOF

# Initialize git
if [ ! -d .git ]; then
    echo -e "${GREEN}[2/7] Initializing git...${NC}"
    git init
    git branch -M main
fi

# Configure git
echo -e "${GREEN}[3/7] Configuring git...${NC}"
git config user.name "MuhammadLutfiMuzakiYY"
git config user.email "muhammadlutfimuzaki2@gmail.com"

# Add files
echo -e "${GREEN}[4/7] Adding files...${NC}"
git add .

# Commit
echo -e "${GREEN}[5/7] Creating commit...${NC}"
git commit -m "🚀 SkyvyOS Secure Server v1.0.0

Complete enterprise-grade security-hardened server OS

Features:
- 24+ programming languages
- AI-powered anomaly detection
- Automated incident response
- Kubernetes templates
- Advanced security hardening
- 400+ pages documentation" || echo "Nothing new to commit"

# Setup remote
echo -e "${GREEN}[6/7] Setting up remote...${NC}"
if git remote | grep -q origin; then
    git remote set-url origin "$GITHUB_REPO"
else
    git remote add origin "$GITHUB_REPO"
fi

# Push
echo -e "${GREEN}[7/7] Pushing to GitHub...${NC}"
echo ""
echo -e "${YELLOW}Enter your credentials:${NC}"
echo -e "${YELLOW}Username: MuhammadLutfiMuzakiYY${NC}"
echo -e "${YELLOW}Password: [paste your token]${NC}"
echo ""

if git push -u origin main; then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║              ✅ SUCCESS! ✅                                   ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Repository: https://github.com/MuhammadLutfiMuzakiYY/SkyvyOS-Secure-Server"
    echo ""
else
    echo ""
    echo -e "${RED}Failed! Check your credentials.${NC}"
fi
