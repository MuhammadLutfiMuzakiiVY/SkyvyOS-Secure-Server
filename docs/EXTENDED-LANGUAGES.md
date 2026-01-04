# Additional Programming Languages - Extended Support

**SkyvyOS Extended Polyglot Support - 20+ Languages**

Beyond the core 12 languages, SkyvyOS supports additional modern and specialized languages:

## 🎯 JVM Languages

### Kotlin (Modern Java alternative)
```bash
# Install via SDKMAN
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install kotlin

# Verify
kotlin -version
kotlinc -version

# Quick start
kotlinc hello.kt -include-runtime -d hello.jar
java -jar hello.jar
```

### Scala (Functional + OOP)
```bash
# Install via SDKMAN
sdk install scala

# Verify
scala -version

# REPL
scala

# Compile
scalac HelloWorld.scala
scala HelloWorld
```

### Groovy (Dynamic JVM)
```bash
sdk install groovy
groovy --version
```

---

## 🌟 Functional Languages

### Haskell (Pure functional)
```bash
# Install GHC (Glasgow Haskell Compiler)
apt-get install -y haskell-platform ghc cabal-install

# Verify
ghc --version
cabal --version

# Interactive REPL
ghci

# Compile
ghc HelloWorld.hs
./HelloWorld
```

### Elixir (Erlang VM, Phoenix framework)
```bash
# Add Erlang repository
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
dpkg -i erlang-solutions_2.0_all.deb
apt-get update

# Install Erlang + Elixir
apt-get install -y esl-erlang elixir

# Verify
elixir --version
iex --version

# Interactive shell
iex

# Run script
elixir script.exs
```

### Clojure (Lisp on JVM)
```bash
# Install via SDKMAN or manual
curl -O https://download.clojure.org/install/linux-install-1.11.1.1347.sh
chmod +x linux-install-1.11.1.1347.sh
./linux-install-1.11.1.1347.sh

# Verify
clojure --version

# REPL
clj
```

### F# (Functional .NET)
```bash
# Already installed with .NET SDK
dotnet new console -lang F# -o MyFSharpApp
cd MyFSharpApp
dotnet run
```

---

## 📱 Mobile/Systems Languages

### Swift (iOS, macOS, Linux)
```bash
# Download Swift for Linux
wget https://download.swift.org/swift-5.9-release/ubuntu2204/swift-5.9-RELEASE/swift-5.9-RELEASE-ubuntu22.04.tar.gz
tar xzf swift-5.9-RELEASE-ubuntu22.04.tar.gz
mv swift-5.9-RELEASE-ubuntu22.04 /usr/share/swift

# Add to PATH
echo 'export PATH=/usr/share/swift/usr/bin:$PATH' >> /etc/profile.d/swift.sh
source /etc/profile.d/swift.sh

# Verify
swift --version

# REPL
swift

# Build
swiftc hello.swift
./hello
```

### Dart (Flutter, web, server)
```bash
# Add Dart repository
apt-get install -y apt-transport-https
wget -qO- https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/dart.gpg
echo 'deb [signed-by=/usr/share/keyrings/dart.gpg arch=amd64] https://storage.googleapis.com/download.dartlang.org/linux/debian stable main' | tee /etc/apt/sources.list.d/dart_stable.list

apt-get update
apt-get install -y dart

# Verify
dart --version

# Create project
dart create myapp
cd myapp
dart run
```

### Nim (Systems programming, Python-like syntax)
```bash
# Install Nim
curl https://nim-lang.org/choosenim/init.sh -sSf | sh
echo 'export PATH=$HOME/.nimble/bin:$PATH' >> ~/.bashrc

# Verify
nim --version

# Compile
nim c hello.nim
./hello
```

### Zig (Modern C replacement)
```bash
# Download Zig
wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz
tar xf zig-linux-x86_64-0.11.0.tar.xz
mv zig-linux-x86_64-0.11.0 /usr/local/zig

# Add to PATH
echo 'export PATH=/usr/local/zig:$PATH' >> /etc/profile.d/zig.sh
source /etc/profile.d/zig.sh

# Verify
zig version

# Build
zig build-exe hello.zig
./hello
```

---

## 🔧 Scripting & Shell

### Bash (Already installed)
```bash
bash --version
```

### Zsh (Modern shell)
```bash
apt-get install -y zsh
zsh --version

# Oh My Zsh (optional)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Fish (Friendly shell)
```bash
apt-get install -y fish
fish --version
```

### PowerShell (Cross-platform)
```bash
# Install PowerShell
wget https://github.com/PowerShell/PowerShell/releases/download/v7.4.0/powershell_7.4.0-1.deb_amd64.deb
dpkg -i powershell_7.4.0-1.deb_amd64.deb
apt-get install -f

# Verify
pwsh --version

# Interactive
pwsh
```

---

## 📊 Data Science & Scientific

### Julia (High-performance scientific)
```bash
# Download Julia
wget https://julialang-s3.julialang.org/bin/linux/x64/1.9/julia-1.9.4-linux-x86_64.tar.gz
tar xzf julia-1.9.4-linux-x86_64.tar.gz
mv julia-1.9.4 /usr/local/julia

# Add to PATH
echo 'export PATH=/usr/local/julia/bin:$PATH' >> /etc/profile.d/julia.sh
source /etc/profile.d/julia.sh

# Verify
julia --version

# REPL
julia
```

### Octave (MATLAB alternative)
```bash
apt-get install -y octave
octave --version

# Interactive
octave
```

---

## 🎮 Game Development

### GDScript (Godot Engine)
```bash
# Install Godot
wget https://downloads.tuxfamily.org/godotengine/4.2/Godot_v4.2-stable_linux.x86_64.zip
unzip Godot_v4.2-stable_linux.x86_64.zip -d /opt/godot
ln -s /opt/godot/Godot_v4.2-stable_linux.x86_64 /usr/local/bin/godot

# Verify (headless for server)
godot --version
```

---

## 🌐 Web Assembly

### AssemblyScript (TypeScript to WASM)
```bash
npm install -g assemblyscript

# Create project
npm init assemblyscript myapp

# Build
npm run asbuild
```

---

## Complete Language List (20+)

| # | Language | Type | Use Case | Status |
|---|----------|------|----------|--------|
| 1 | Python | Interpreted | Web, AI/ML, Scripting | ✅ Core |
| 2 | JavaScript/Node.js | Interpreted | Web, Backend | ✅ Core |
| 3 | PHP | Interpreted | Web | ✅ Core |
| 4 | Java | Compiled (JVM) | Enterprise, Android | ✅ Core |
| 5 | Go | Compiled | Systems, Cloud | ✅ Core |
| 6 | Rust | Compiled | Systems, Performance | ✅ Core |
| 7 | Ruby | Interpreted | Web (Rails) | ✅ Core |
| 8 | Perl | Interpreted | Text processing | ✅ Core |
| 9 | Lua | Interpreted | Embedded, Gaming | ✅ Core |
| 10 | C/C++ | Compiled | Systems, Performance | ✅ Core |
| 11 | C# (.NET) | Compiled (CLR) | Enterprise, Games | ✅ Core |
| 12 | R | Interpreted | Statistics, Data | ✅ Core |
| 13 | Kotlin | Compiled (JVM) | Android, Backend | ✅ Extended |
| 14 | Scala | Compiled (JVM) | Big Data, Functional | ✅ Extended |
| 15 | Swift | Compiled | iOS, macOS, Server | ✅ Extended |
| 16 | Dart | Compiled/JIT | Flutter, Web | ✅ Extended |
| 17 | Elixir | Interpreted (BEAM) | Distributed systems | ✅ Extended |
| 18 | Haskell | Compiled | Functional, Research | ✅ Extended |
| 19 | Julia | JIT | Scientific computing | ✅ Extended |
| 20 | Zig | Compiled | Systems | ✅ Extended |
| 21 | Nim | Compiled | Systems | ✅ Extended |
| 22 | F# | Compiled (CLR) | Functional .NET | ✅ Extended |
| 23 | Clojure | Interpreted (JVM) | Functional, Data | ✅ Extended |
| 24 | PowerShell | Scripting | Automation | ✅ Extended |

**Total: 24 programming languages!**

---

## Quick Installation Script

```bash
#!/bin/bash
# Install ALL extended languages

# JVM languages
sdk install kotlin scala groovy

# Functional
apt-get install -y haskell-platform elixir

# Mobile/Systems
# (Swift, Dart, Nim, Zig - see individual instructions)

# Scientific
# Julia, Octave

# Total: 20+ languages ready!
```

---

**SkyvyOS: The Ultimate Polyglot Server Platform** 🌍
