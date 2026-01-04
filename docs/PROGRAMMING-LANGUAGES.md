# SkyvyOS Secure Server - Programming Languages Support

**Complete Polyglot Development Environment**

SkyvyOS Secure Server includes comprehensive support for all major programming languages and development tools.

## Installed Programming Languages

### 🐍 Python 3.11+
```bash
# Verify installation
python3 --version
pip3 --version

# Virtual environments
python3 -m venv myproject
source myproject/bin/activate

# Popular packages pre-installed
python3 -m pip list | grep -E "requests|numpy|pandas"
```

**Included:**
- Python 3.11+ interpreter
- pip (package manager)
- venv (virtual environments)
- Development headers
- Popular libraries: requests, numpy, pandas

**Management:**
```bash
# Install packages (in venv)
pip install flask django fastapi

# System-wide (not recommended)
sudo pip3 install --break-system-packages package-name
```

---

### 📦 Node.js 20.x LTS
```bash
# Verify installation
node --version
npm --version

# Package managers
npx --version
```

**Included:**
- Node.js 20.x LTS runtime
- npm (package manager)
- npx (package runner)

**Management:**
```bash
# Install packages globally
sudo npm install -g pm2 yarn pnpm

# Project packages
npm install express fastify

# Alternative: Use nvm for version management
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

---

### 🐘 PHP 8.2+
```bash
# Verify installation
php --version
php-fpm8.2 --version
composer --version
```

**Included:**
- PHP 8.2+ CLI & FPM
- Composer (package manager)
- Extensions: MySQL, PostgreSQL, SQLite, cURL, GD, mbstring, XML, JSON

**Management:**
```bash
# Install packages
composer require laravel/framework

# PHP extensions
sudo apt install php-redis php-memcached
```

---

### ☕ Java (OpenJDK) 17+
```bash
# Verify installation
java --version
javac --version
mvn --version
gradle --version
```

**Included:**
- OpenJDK 17 LTS (JRE + JDK)
- Maven (build tool)
- Gradle (build tool)

**Management:**
```bash
# Compile Java
javac HelloWorld.java
java HelloWorld

# Maven project
mvn archetype:generate

# Gradle project
gradle init
```

---

### 🦀 Rust (Latest Stable)
```bash
# Verify installation
rustc --version
cargo --version
```

**Installed via rustup:**
```bash
# Installation script
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Verify
source $HOME/.cargo/env
rustc --version
cargo --version
```

**Management:**
```bash
# Update Rust
rustup update

# Create project
cargo new myproject
cd myproject
cargo build
cargo run
```

---

### 🐹 Go (Golang) 1.21+
```bash
# Verify installation
go version
```

**Included:**
- Go 1.21+ compiler & tools
- Standard library

**Management:**
```bash
# Environment setup (auto-configured)
echo $GOPATH  # /home/user/go
echo $GOROOT  # /usr/lib/go

# Create module
mkdir myproject && cd myproject
go mod init myproject

# Install packages
go get github.com/gin-gonic/gin
go build
```

---

### 💎 Ruby 3.1+
```bash
# Verify installation
ruby --version
gem --version
bundle --version
```

**Included:**
- Ruby 3.1+ interpreter
- RubyGems (package manager)
- Bundler (dependency manager)

**Management:**
```bash
# Install gems
gem install rails sinatra

# Bundler
bundle init
bundle install
```

---

### 🐪 Perl 5.36+
```bash
# Verify installation
perl --version
cpanm --version
```

**Included:**
- Perl 5.36+ interpreter
- CPAN Minus (package manager)

**Management:**
```bash
# Install modules
cpanm Mojolicious
cpanm DBI DBD::mysql
```

---

### 🌙 Lua 5.4
```bash
# Verify installation
lua -v
luarocks --version
```

**Included:**
- Lua 5.4 interpreter
- LuaRocks (package manager)

**Management:**
```bash
# Install rocks
luarocks install luasocket
luarocks install lpeg
```

---

### 🔵 .NET 8.0 (C#, F#)
```bash
# Install .NET SDK
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh --channel 8.0

# Verify
dotnet --version
```

**Management:**
```bash
# Create console app
dotnet new console -o MyApp
cd MyApp
dotnet run

# Create web app
dotnet new web -o MyWebApp
```

---

### 📊 R (Statistical Computing)
```bash
# Verify installation
R --version
Rscript --version
```

**Included:**
- R base
- R development tools

**Management:**
```R
# Install packages
install.packages("ggplot2")
install.packages("dplyr")
```

---

## Build Tools & Compilers

### C/C++ Development
```bash
# GCC/G++
gcc --version
g++ --version

# Tools
make --version
cmake --version
gdb --version
```

**Complete toolchain:**
- GCC 12+ (C compiler)
- G++ 12+ (C++ compiler)
- Make, CMake (build systems)
- GDB (debugger)
- Autotools (autoconf, automake, libtool)

---

## Database Clients

```bash
# MariaDB/MySQL
mysql --version

# PostgreSQL
psql --version

# SQLite
sqlite3 --version

# Redis
redis-cli --version
```

---

## Version Control

```bash
# Git
git --version

# Others
svn --version    # Subversion
hg --version     # Mercurial
```

---

## Text Processing & DevOps Tools

```bash
# JSON/YAML
jq --version
yq --version

# XML
xmlstarlet --version

# Markdown
pandoc --version

# Others
dos2unix --version
```

---

## Language Version Managers (Optional)

### pyenv (Python)
```bash
curl https://pyenv.run | bash
pyenv install 3.12.0
pyenv global 3.12.0
```

### nvm (Node.js)
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 20
nvm use 20
```

### rbenv (Ruby)
```bash
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'eval "$(~/.rbenv/bin/rbenv init -)"' >> ~/.bashrc
rbenv install 3.2.0
```

### gvm (Go)
```bash
bash < <(curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer)
gvm install go1.21
gvm use go1.21 --default
```

---

## Language Support Summary

| Language | Version | Package Manager | Status |
|----------|---------|-----------------|--------|
| Python | 3.11+ | pip | ✅ Pre-installed |
| Node.js | 20.x LTS | npm | ✅ Pre-installed |
| PHP | 8.2+ | composer | ✅ Pre-installed |
| Java | 17 LTS | maven/gradle | ✅ Pre-installed |
| Go | 1.21+ | go modules | ✅ Pre-installed |
| Rust | Latest | cargo | ✅ Pre-installed |
| Ruby | 3.1+ | gem/bundler | ✅ Pre-installed |
| Perl | 5.36+ | cpanm | ✅ Pre-installed |
| Lua | 5.4 | luarocks | ✅ Pre-installed |
| C/C++ | GCC 12+ | - | ✅ Pre-installed |
| .NET | 8.0 | dotnet | ⚙️ Post-install |
| R | 4.3+ | CRAN | ✅ Pre-installed |

**Total: 12+ programming languages ready to use!**

---

## Quick Start Examples

### Python Web Server
```bash
python3 -m venv venv
source venv/bin/activate
pip install flask
cat > app.py <<EOF
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello(): return 'Hello from SkyvyOS!'
if __name__ == '__main__': app.run(host='0.0.0.0')
EOF
python app.py
```

### Node.js Express
```bash
npm init -y
npm install express
cat > server.js <<EOF
const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Hello from SkyvyOS!'));
app.listen(3000);
EOF
node server.js
```

### Go HTTP Server
```bash
cat > main.go <<EOF
package main
import ("fmt"; "net/http")
func main() {
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        fmt.Fprintf(w, "Hello from SkyvyOS!")
    })
    http.ListenAndServe(":8080", nil)
}
EOF
go run main.go
```

---

**SkyvyOS = True Polyglot Development Server** 🚀

Semua bahasa pemrograman major + tools lengkap untuk development, testing, dan deployment!
