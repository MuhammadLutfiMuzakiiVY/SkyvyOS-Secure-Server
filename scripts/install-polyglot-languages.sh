#!/bin/bash

################################################################################
# SkyvyOS Polyglot Install - Programming Languages Setup
#
# Installs comprehensive programming language support
# For developers, DevOps, and polyglot environments
#
# Usage: sudo ./install-polyglot-languages.sh
################################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  SkyvyOS Polyglot Programming Languages Installer        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run as root: sudo $0${NC}"
    exit 1
fi

# ============================================================================
# PYTHON 3 (Already installed, enhance it)
# ============================================================================
echo -e "${GREEN}[1/12] Configuring Python 3...${NC}"
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    python3-setuptools \
    python3-wheel

# Popular Python packages
pip3 install --break-system-packages \
    requests \
    numpy \
    pandas \
    flask \
    fastapi \
    uvicorn \
    pytest

python3 --version

# ============================================================================
# NODE.JS 20.x LTS
# ============================================================================
echo -e "${GREEN}[2/12] Installing Node.js 20.x LTS...${NC}"
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Global npm packages
npm install -g \
    pm2 \
    yarn \
    pnpm \
    typescript \
    ts-node \
    nodemon

node --version
npm --version

# ============================================================================
# PHP 8.2
# ============================================================================
echo -e "${GREEN}[3/12] Installing PHP 8.2...${NC}"
apt-get install -y \
    php8.2 \
    php8.2-cli \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-pgsql \
    php8.2-sqlite3 \
    php8.2-curl \
    php8.2-gd \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    php8.2-bcmath \
    php8.2-intl \
    php8.2-redis

# Install Composer
curl -sS https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer
chmod +x /usr/local/bin/composer

php --version
composer --version

# ============================================================================
# JAVA (OpenJDK 17 LTS)
# ============================================================================
echo -e "${GREEN}[4/12] Installing Java (OpenJDK 17)...${NC}"
apt-get install -y \
    openjdk-17-jdk \
    openjdk-17-jre \
    maven \
    gradle

# Set JAVA_HOME
echo 'export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64' >> /etc/profile.d/java.sh
echo 'export PATH=$PATH:$JAVA_HOME/bin' >> /etc/profile.d/java.sh

java --version
javac --version
mvn --version
gradle --version

# ============================================================================
# GO (Golang) 1.21+
# ============================================================================
echo -e "${GREEN}[5/12] Installing Go...${NC}"
GO_VERSION="1.21.5"
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz"
rm -rf /usr/local/go
tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"
rm "go${GO_VERSION}.linux-amd64.tar.gz"

# Setup Go environment
cat >> /etc/profile.d/go.sh <<'EOF'
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
EOF

source /etc/profile.d/go.sh
go version

# ============================================================================
# RUST (Latest stable)
# ============================================================================
echo -e "${GREEN}[6/12] Installing Rust...${NC}"
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Make rust available system-wide
cat >> /etc/profile.d/rust.sh <<'EOF'
export PATH="$HOME/.cargo/bin:$PATH"
EOF

source $HOME/.cargo/env
rustc --version
cargo --version

# ============================================================================
# RUBY 3.1+
# ============================================================================
echo -e "${GREEN}[7/12] Installing Ruby...${NC}"
apt-get install -y \
    ruby \
    ruby-dev \
    ruby-bundler

# Install gems
gem install \
    rails \
    sinatra \
    puma

ruby --version
gem --version
bundle --version

# ============================================================================
# PERL 5.36+
# ============================================================================
echo -e "${GREEN}[8/12] Installing Perl...${NC}"
apt-get install -y \
    perl \
    cpanminus \
    libperl-dev

# Install CPAN modules
cpanm --notest \
    Mojolicious \
    Dancer2 \
    DBI \
    DBD::mysql \
    DBD::Pg

perl --version

# ============================================================================
# LUA 5.4
# ============================================================================
echo -e "${GREEN}[9/12] Installing Lua...${NC}"
apt-get install -y \
    lua5.4 \
    luarocks

# Install rocks
luarocks install luasocket
luarocks install lpeg

lua -v

# ============================================================================
# C/C++ Build Tools
# ============================================================================
echo -e "${GREEN}[10/12] Installing C/C++ Development Tools...${NC}"
apt-get install -y \
    build-essential \
    gcc \
    g++ \
    gdb \
    make \
    cmake \
    autoconf \
    automake \
    libtool \
    pkg-config

gcc --version
g++ --version
cmake --version

# ============================================================================
# .NET 8.0 SDK
# ============================================================================
echo -e "${GREEN}[11/12] Installing .NET 8.0...${NC}"
wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0 --install-dir /usr/share/dotnet
rm dotnet-install.sh

# Add to PATH
cat >> /etc/profile.d/dotnet.sh <<'EOF'
export DOTNET_ROOT=/usr/share/dotnet
export PATH=$PATH:$DOTNET_ROOT
EOF

source /etc/profile.d/dotnet.sh
dotnet --version

# ============================================================================
# R (Statistical Computing)
# ============================================================================
echo -e "${GREEN}[12/12] Installing R...${NC}"
apt-get install -y \
    r-base \
    r-base-dev

# Install common R packages
R -e "install.packages(c('ggplot2', 'dplyr', 'tidyr', 'shiny'), repos='https://cloud.r-project.org/')"

R --version

# ============================================================================
# ADDITIONAL TOOLS & DATABASE CLIENTS
# ============================================================================
echo -e "${GREEN}Installing additional tools...${NC}"

# Database clients
apt-get install -y \
    mariadb-client \
    postgresql-client \
    sqlite3 \
    redis-tools

# DevOps tools
apt-get install -y \
    jq \
    yq \
    xmlstarlet \
    pandoc

# Text processing
apt-get install -y \
    dos2unix \
    unix2dos

# ============================================================================
# VERIFICATION
# ============================================================================
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   Language Installation Complete!${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Installed Programming Languages:${NC}"
echo ""

# Verify each language
echo "✓ Python:   $(python3 --version 2>&1)"
echo "✓ Node.js:  $(node --version 2>&1)"
echo "✓ PHP:      $(php --version 2>&1 | head -n1)"
echo "✓ Java:     $(java --version 2>&1 | head -n1)"
echo "✓ Go:       $(go version 2>&1)"
echo "✓ Rust:     $(rustc --version 2>&1)"
echo "✓ Ruby:     $(ruby --version 2>&1)"
echo "✓ Perl:     $(perl --version 2>&1 | grep -oP 'v\d+\.\d+\.\d+')"
echo "✓ Lua:      $(lua -v 2>&1)"
echo "✓ GCC:      $(gcc --version 2>&1 | head -n1)"
echo "✓ .NET:     $(/usr/share/dotnet/dotnet --version 2>&1)"
echo "✓ R:        $(R --version 2>&1 | head -n1)"

echo ""
echo -e "${YELLOW}Package Managers:${NC}"
echo "  pip3, npm, composer, maven, gradle, cargo, gem, cpanm, luarocks, dotnet"

echo ""
echo -e "${GREEN}SkyvyOS is now a complete polyglot development server!${NC}"
echo ""
echo -e "${BLUE}Documentation: /usr/local/share/doc/skyvyos/PROGRAMMING-LANGUAGES.md${NC}"
echo ""

# Create quick reference
cat > /usr/local/bin/skyvyos-languages <<'EOF'
#!/bin/bash
# SkyvyOS - List installed programming languages

echo "SkyvyOS Installed Programming Languages"
echo "========================================"
echo ""
echo "Python:   $(python3 --version 2>&1)"
echo "Node.js:  $(node --version 2>&1)"
echo "PHP:      $(php --version 2>&1 | head -n1)"
echo "Java:     $(java --version 2>&1 | head -n1)"
echo "Go:       $(go version 2>&1)"
echo "Rust:     $(rustc --version 2>&1)"
echo "Ruby:     $(ruby --version 2>&1)"
echo "Perl:     $(perl --version 2>&1 | grep -oP 'v\d+\.\d+\.\d+')"
echo "Lua:      $(lua -v 2>&1)"
echo "GCC/G++:  $(gcc --version 2>&1 | head -n1)"
echo ".NET:     $(dotnet --version 2>&1)"
echo "R:        $(R --version 2>&1 | head -n1)"
echo ""
echo "Total: 12+ programming languages"
echo "Documentation: man skyvyos-languages"
EOF

chmod +x /usr/local/bin/skyvyos-languages

echo -e "${YELLOW}Run 'skyvyos-languages' to view installed languages${NC}"
