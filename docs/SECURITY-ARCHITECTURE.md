# SkyvyOS Secure Server - System Philosophy & Architecture

**Enterprise-Grade Security-Hardened Debian-Based Server Operating System**

## I. FILOSOFI & PRINSIP DESAIN SISTEM

### 1.1 Core Principles

#### Secure by Default
- **Zero Trust Architecture**: Tidak ada komponen yang dipercaya secara default
- **Least Privilege**: Setiap proses hanya memiliki permission minimal yang dibutuhkan
- **Defense in Depth**: Multiple layers of security controls
- **Fail Secure**: Sistem gagal ke state yang aman, bukan terbuka

#### Minimalism & Performance
- **Minimal Attack Surface**: Hanya install package yang benar-benar diperlukan
- **No Bloatware**: Tidak ada GUI, tools development yang tidak perlu
- **Resource Efficient**: Optimized untuk production 24/7
- **Fast Boot**: Minimal services untuk quick recovery

#### Immutable Mindset
- **Configuration as Code**: Semua config di-version control
- **Reproducible Builds**: Instalasi dapat di-reproduce secara konsisten
- **Infrastructure as Code**: Template-based deployment
- **Stateless Where Possible**: Separate configuration dari data

#### Automation-First
- **Automated Hardening**: Script otomatis untuk security hardening
- **Automated Updates**: Security patches apply otomatis
- **Automated Monitoring**: Self-monitoring dan alerting
- **Automated Recovery**: Self-healing capabilities

### 1.2 Design Decisions

| Aspek | Pilihan | Rationale |
|-------|---------|-----------|
| Base OS | Debian Stable | Long-term support, security focus, predictable |
| Init System | systemd | Modern, security features (sandboxing, etc) |
| Firewall | nftables/UFW | Modern, performant, easier syntax |
| SSH | OpenSSH | Industry standard, well-audited |
| Container | Docker | Wide adoption, good isolation |
| Web Server | Nginx | High performance, small footprint |
| IDS | Fail2Ban + auditd | Lightweight, effective |

## II. THREAT MODEL & ATTACK SURFACE ANALYSIS

### 2.1 Threat Actors

#### External Attackers
- **Skill Level**: Script kiddies → Advanced Persistent Threats (APT)
- **Motivation**: Financial gain, data theft, disruption, botnet recruitment
- **Capabilities**: Automated scanning, exploit frameworks, social engineering

#### Internal Threats
- **Compromised Accounts**: Stolen credentials, weak passwords
- **Malicious Insiders**: Legitimate users with malicious intent
- **Accidental Misuse**: Configuration errors, human mistakes

#### Supply Chain Attacks
- **Compromised Packages**: Malicious code in upstream packages
- **Dependency Attacks**: Vulnerable dependencies
- **Backdoored Images**: Compromised container images

### 2.2 Attack Vectors

```
┌─────────────────────────────────────────────────────┐
│                 ATTACK SURFACE                      │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Network Layer                                      │
│  ├─ SSH (Port 22) ⚠️ HIGH VALUE TARGET             │
│  ├─ HTTP/HTTPS (80/443) ⚠️ WEB EXPLOITS            │
│  ├─ DNS Queries → MITM, Cache Poisoning            │
│  └─ ICMP → DDoS amplification                      │
│                                                     │
│  Application Layer                                  │
│  ├─ Web Server ⚠️ Code injection, RCE              │
│  ├─ Application Code → Logic bugs                  │
│  ├─ Dependencies → Known CVEs                      │
│  └─ Docker Containers → Container escape           │
│                                                     │
│  Authentication Layer                               │
│  ├─ SSH Keys → Stolen/compromised keys             │
│  ├─ Sudo → Privilege escalation                    │
│  └─ User Accounts → Brute force attempts           │
│                                                     │
│  System Layer                                       │
│  ├─ Kernel → Exploits for privilege escalation     │
│  ├─ Systemd → Service exploitation                 │
│  ├─ Filesystem → Data exfiltration                 │
│  └─ Processes → Memory attacks                     │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 2.3 Risk Assessment Matrix

| Threat | Likelihood | Impact | Risk | Mitigation |
|--------|-----------|--------|------|------------|
| SSH Brute Force | HIGH | HIGH | 🔴 CRITICAL | Fail2Ban, key-only auth, rate limiting |
| Web Server Exploit | MEDIUM | HIGH | 🟠 HIGH | WAF, secure headers, regular updates |
| Container Escape | LOW | HIGH | 🟡 MEDIUM | AppArmor, capability dropping, user namespaces |
| Kernel Exploit | LOW | CRITICAL | 🟠 HIGH | Auto updates, sysctl hardening, SELinux/AppArmor |
| DoS/DDoS | HIGH | MEDIUM | 🟠 HIGH | Rate limiting, SYN cookies, connection limits |
| Data Exfiltration | MEDIUM | HIGH | 🟠 HIGH | File integrity monitoring, egress filtering |
| Supply Chain | LOW | HIGH | 🟡 MEDIUM | Package verification, minimal dependencies |
| Insider Threat | LOW | HIGH | 🟡 MEDIUM | Audit logging, role separation, least privilege |

### 2.4 Attack Surface Reduction Strategy

#### Minimize Network Exposure
```
Default State: ALL PORTS CLOSED
Only Open Explicitly:
  - SSH (custom port, key-only)
  - HTTP/HTTPS (if web server needed)
  - Application-specific (documented & justified)
```

#### Minimize Running Services
```
Running Services Audit:
✅ REQUIRED:
  - sshd (remote access)
  - systemd core services
  - rsyslog (logging)
  - cron (scheduled tasks)
  
❌ REMOVED:
  - avahi-daemon (not needed)
  - cups (no printing)
  - bluetooth (server)
  - any GUI services
```

#### Minimize Installed Packages
```
Package Philosophy:
  If not explicitly needed → Don't install
  If installed but unused → Remove
  If can be containerized → Use container instead
```

## III. ARSITEKTUR SISTEM

### 3.1 System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    USER SPACE (Unprivileged)                │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Application Layer                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Web App      │  │ Bot Services │  │ API Services │     │
│  │ (Container)  │  │ (Container)  │  │ (Container)  │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│         ↓                  ↓                  ↓             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Docker Daemon (rootless mode)               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    SYSTEM SERVICES                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  Nginx   │  │  Fail2Ban│  │  auditd  │  │  AIDE    │   │
│  │ (www-data│  │  (root)  │  │  (root)  │  │  (root)  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    SECURITY LAYER                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ nftables/UFW Firewall (kernel-level filtering)      │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ AppArmor (Mandatory Access Control)                 │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Seccomp (System call filtering)                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                    KERNEL SPACE                             │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ Linux Kernel (hardened with sysctl parameters)      │  │
│  │ - ASLR, DEP, Stack Canaries                         │  │
│  │ - Namespace isolation                                │  │
│  │ - Capability system                                  │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### 3.2 Security Boundaries

#### Boundary 1: Network Firewall
- **Purpose**: Block unauthorized network access
- **Implementation**: nftables with default-deny
- **Controls**: Port filtering, rate limiting, geo-blocking

#### Boundary 2: Authentication
- **Purpose**: Verify identity before access
- **Implementation**: SSH key-only, 2FA optional
- **Controls**: Fail2Ban, account lockout, strong policies

#### Boundary 3: Authorization (systemd)
- **Purpose**: Limit what authenticated users can do
- **Implementation**: Sudo rules, systemd security features
- **Controls**: Capability bounding, filesystem restrictions

#### Boundary 4: Process Isolation
- **Purpose**: Prevent process interference
- **Implementation**: Containers, namespaces, cgroups
- **Controls**: Resource limits, network isolation

#### Boundary 5: Mandatory Access Control
- **Purpose**: Enforce security policy at kernel level
- **Implementation**: AppArmor profiles
- **Controls**: File access, network access, capabilities

### 3.3 Service Isolation Strategy

```
High-Privilege Services    Medium-Privilege         Low-Privilege
(Root Required)             (Service Accounts)       (Containers)
┌──────────────┐           ┌──────────────┐         ┌──────────────┐
│ sshd         │           │ nginx        │         │ Web Apps     │
│ systemd      │           │ (www-data)   │         │ (uid 1000+)  │
│ auditd       │───────────┤              │─────────┤              │
│ fail2ban     │  Monitor  │ docker       │ Provide │ API Services │
│ firewall     │           │              │ Service │              │
└──────────────┘           └──────────────┘         └──────────────┘
       │                          │                        │
       └──────────────────────────┴────────────────────────┘
                          Audit Trail
```

#### Systemd Hardening per Service

**Example: Nginx Unit Hardening**
```ini
[Service]
# User isolation
User=www-data
Group=www-data

# Filesystem protection
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/log/nginx /var/lib/nginx
PrivateTmp=true

# Network
RestrictAddressFamilies=AF_INET AF_INET6

# Capabilities
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_BIND_SERVICE

# Security
NoNewPrivileges=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictNamespaces=true
LockPersonality=true

# System calls
SystemCallFilter=@system-service
SystemCallFilter=~@privileged @resources
```

### 3.4 Filesystem Hierarchy - SkyvyOS Specific

```
/
├── bin/          → /usr/bin (standard binaries)
├── boot/         Linux kernel, initrd (immutable)
├── dev/          Device files
├── etc/          Configuration (version controlled)
│   ├── skyvyos/  ⭐ SkyvyOS-specific configs
│   │   ├── security/
│   │   │   ├── hardening.conf
│   │   │   ├── firewall-rules.nft
│   │   │   └── audit.rules
│   │   ├── monitoring/
│   │   └── policies/
│   ├── ssh/      SSH configuration (hardened)
│   ├── nginx/    Web server config
│   └── systemd/  Service units
├── home/         User directories (encrypted recommended)
│   └── [user]/   User home (nodev, nosuid)
├── opt/          Optional software (3rd party)
├── root/         Root home (encrypted)
├── run/          Runtime data (tmpfs)
├── srv/          Service data
│   └── www/      Web content (noexec, nosuid)
├── tmp/          Temporary files (noexec, nosuid, nodev)
├── usr/          User programs
│   ├── local/    Local admin installs
│   └── share/    Shared data
└── var/          Variable data
    ├── log/      Logs (append-only where possible)
    │   └── audit/  Audit logs (immutable)
    ├── lib/      Application state
    │   └── docker/ Container data
    └── tmp/      More temp (noexec, nosuid, nodev)
```

#### Filesystem Mount Options

| Partition | Mount Options | Purpose |
|-----------|---------------|---------|
| `/` | `defaults,noatime` | Base system |
| `/tmp` | `nodev,nosuid,noexec` | Prevent execution from temp |
| `/var/tmp` | `nodev,nosuid,noexec` | Prevent execution from var temp |
| `/home` | `nodev,nosuid` | User directories |
| `/var/log` | `nodev,nosuid,noexec` | Log files |

### 3.5 Trust Model

```
TRUST LEVELS:

Level 0: Kernel Space
   ↓ (syscall boundary)
Level 1: Root Processes (systemd, sshd, auditd)
   ↓ (privilege separation)
Level 2: Service Accounts (www-data, nginx)
   ↓ (container boundary)
Level 3: Containerized Applications
   ↓ (network boundary)
Level 4: External Network (UNTRUSTED)

Trust Flow: Never trust data from lower trust level
Verification: Always validate before privilege escalation
```

## IV. SECURITY CONTROL MATRIX

| Control Type | Implementation | Coverage |
|--------------|----------------|----------|
| **Preventive** | Firewall, Authentication, Encryption | Block unauthorized access |
| **Detective** | IDS, Logging, AIDE | Detect intrusions |
| **Corrective** | Fail2Ban, Automated patching | Respond to incidents |
| **Recovery** | Backups, Snapshots | Restore from attacks |

---

**Design Philosophy**: "Every line of code, every package, every port is a potential vulnerability. Only include what is absolutely necessary, and harden everything that remains."
