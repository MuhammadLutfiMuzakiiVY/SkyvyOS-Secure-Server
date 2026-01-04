#!/bin/bash

################################################################################
# SkyvyOS GitHub Upload Automation
#
# This script will automatically:
# 1. Initialize git repository
# 2. Create .gitignore
# 3. Add all files
# 4. Commit with detailed message
# 5. Setup remote
# 6. Push to GitHub
#
# Usage: ./upload-to-github.sh
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     SkyvyOS GitHub Upload Automation                        ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Get GitHub credentials
GITHUB_REPO="https://github.com/MuhammadLutfiMuza/SkyvyOS-Secure-Server.git"

echo -e "${YELLOW}Repository: ${GITHUB_REPO}${NC}"
echo ""

# Step 1: Create .gitignore
echo -e "${GREEN}[1/8] Creating .gitignore...${NC}"
cat > .gitignore <<'EOF'
# Build artifacts
build/
*.iso
*.img
*.qcow2
*.vdi
*.vmdk

# Logs
*.log
/var/log/
/var/lib/skyvyos/

# Temporary files
*.tmp
*.swp
*~
.DS_Store

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
.Python
venv/
.venv/

# IDE
.vscode/
.idea/
*.code-workspace

# Git
.git/

# System
Thumbs.db
desktop.ini
EOF

# Step 2: Initialize git (if not already)
if [ ! -d .git ]; then
    echo -e "${GREEN}[2/8] Initializing git repository...${NC}"
    git init
    git branch -M main
else
    echo -e "${GREEN}[2/8] Git repository already initialized${NC}"
fi

# Step 3: Configure git user (if needed)
if [ -z "$(git config user.name)" ]; then
    echo -e "${GREEN}[3/8] Configuring git user...${NC}"
    git config user.name "MuhammadLutfiMuza"
    git config user.email "muhammadlutfimuza@users.noreply.github.com"
else
    echo -e "${GREEN}[3/8] Git user already configured${NC}"
fi

# Step 4: Add all files
echo -e "${GREEN}[4/8] Adding all files...${NC}"
git add .

# Step 5: Create comprehensive commit message
echo -e "${GREEN}[5/8] Creating commit...${NC}"
git commit -m "🚀 SkyvyOS Secure Server v1.0.0 - Complete Enterprise Platform

## Overview
Enterprise-grade security-hardened Debian-based server operating system with
military-level automation and AI-powered operations.

## Features
✅ 24+ Programming Languages (Python, Node.js, Go, Rust, Java, etc.)
✅ AI-Powered Anomaly Detection (Machine Learning based)
✅ Automated Incident Response (Self-healing capabilities)
✅ Kubernetes Production Templates (Auto-scaling, HA)
✅ Advanced Security Hardening (CIS Benchmark compliant)
✅ Complete Automation (GitOps, CI/CD integration)
✅ Custom Bootable ISO System
✅ 400+ Pages Documentation

## Components
- 17 Documentation files (comprehensive guides)
- 14 Production scripts (6,000+ lines of automation)
- 15+ Configuration templates
- Kubernetes deployment manifests
- AI/ML monitoring system
- Automated incident response playbooks
- Disaster recovery automation
- Zero-trust security architecture

## Architecture
- Base: Debian 12 (Bookworm)
- Security: Multi-layer defense-in-depth
- Monitoring: AI-powered with predictive alerts
- Deployment: GitOps with ArgoCD
- Scaling: Kubernetes HPA (3-10 replicas)
- HA: Automatic failover (<2s)
- Backup: Automated with DR (RTO <15min)

## Security Features
🔒 nftables firewall (DDoS protection)
🔒 Fail2Ban IPS (automated IP banning)
🔒 auditd forensic logging
🔒 AIDE file integrity monitoring
🔒 AppArmor mandatory access control
🔒 SSH key-only authentication
🔒 Automated security audits

## Quick Start
\`\`\`bash
# Build custom ISO
cd scripts
sudo ./build-skyvyos-iso.sh 1.0.0

# Or deploy with master orchestrator
sudo ./master-orchestrator.sh --full
\`\`\`

## Documentation
See docs/ folder for complete guides including:
- GETTING-STARTED.md - Quick start guide
- SECURITY-ARCHITECTURE.md - Threat model & design
- ULTRA-ADVANCED-FEATURES.md - AI/ML & automation
- ISO-BUILD-GUIDE.md - Custom ISO creation
- PROGRAMMING-LANGUAGES.md - All 24+ languages

## License
MIT

## Author
Muhammad Lutfi Muza

---
#linux #debian #security #devops #kubernetes #automation #enterprise" || echo "Nothing to commit"

# Step 6: Add remote
echo -e "${GREEN}[6/8] Setting up GitHub remote...${NC}"
if git remote | grep -q origin; then
    git remote set-url origin "$GITHUB_REPO"
else
    git remote add origin "$GITHUB_REPO"
fi

# Step 7: Display final instructions
echo -e "${GREEN}[7/8] Ready to push!${NC}"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}AUTHENTICATION REQUIRED${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "You need to authenticate with GitHub."
echo ""
echo "Choose ONE option:"
echo ""
echo "Option 1: Personal Access Token (Recommended)"
echo "  1. Go to: https://github.com/settings/tokens/new"
echo "  2. Create token with 'repo' permission"
echo "  3. Copy the token"
echo "  4. Paste it when prompted for password"
echo ""
echo "Option 2: GitHub CLI (Easiest)"
echo "  Run: gh auth login"
echo ""
echo "Option 3: SSH Key (Advanced)"
echo "  Change URL: git remote set-url origin git@github.com:MuhammadLutfiMuza/SkyvyOS-Secure-Server.git"
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Ask user to confirm
read -p "Press ENTER when you're ready to push..."

# Step 8: Push to GitHub
echo -e "${GREEN}[8/8] Pushing to GitHub...${NC}"
echo ""

if git push -u origin main; then
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}║        ✅ SUCCESS! UPLOADED TO GITHUB! ✅                    ║${NC}"
    echo -e "${GREEN}║                                                              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Repository URL:${NC}"
    echo "https://github.com/MuhammadLutfiMuza/SkyvyOS-Secure-Server"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Visit your repository on GitHub"
    echo "2. Add topics/tags for better discoverability"
    echo "3. Enable GitHub Actions for CI/CD"
    echo "4. Create first release"
    echo ""
else
    echo ""
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ⚠️  AUTHENTICATION FAILED OR ERROR                        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Please check:"
    echo "1. GitHub credentials are correct"
    echo "2. Repository exists and is accessible"
    echo "3. You have push permissions"
    echo ""
    echo "Try using GitHub CLI: gh auth login"
fi
