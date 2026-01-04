# SkyvyOS Secure Server - Package Policy & Management

**Enterprise Package Management Strategy for Security-Hardened Systems**

## Philosophy: Whitelist-Only Approach

> **Core Principle**: "If it's not explicitly needed and justified, it doesn't get installed."

### Why Whitelist vs Blacklist?

- **Security**: Smaller attack surface → fewer vulnerabilities
- **Maintenance**: Less packages → less patching required
- **Performance**: Minimal bloat → better resource utilization
- **Auditability**: Every package has a documented purpose

## Package Selection Criteria

Every package must pass ALL of these criteria:

### 1. Necessity Test
```
Question: Is this package absolutely required for core functionality?
- YES → Proceed to next test
- NO → REJECT (can it be containerized instead?)
```

### 2. Security Audit
```
Question: Has this package been security-audited recently?
- Check: Debian security tracker
- Check: CVE database
- Check: Last security update date
```

### 3. Maintenance Status
```
Question: Is this package actively maintained?
- Active upstream development
- Regular security updates
- Not deprecated
```

### 4. Alternative Analysis
```
Question: Is there a more secure or minimal alternative?
Example: Use 'doas' instead of 'sudo' (smaller codebase)
Example: Use 'chrony' instead of 'ntpd' (better security)
```

### 5. Justification Documentation
```
Every package must have:
- Purpose statement
- Security justification
- Alternative consideration
- Update policy
```

## Base System Packages (Tier 0 - Critical)

These packages form the absolute minimum required system:

### Core System
```
apt-transport-https      # Secure package transport (HTTPS repos)
ca-certificates          # TLS certificate validation
debian-archive-keyring   # Package signature verification
systemd                  # Init system (security features)
systemd-sysv            # SysV compatibility
udev                     # Device management
```

**Justification**: Required for basic system operation and package management security.

### Networking (Essential)
```
iproute2                 # Modern network configuration
iputils-ping            # Network diagnostics (minimal)
netbase                 # Network infrastructure files
```

**Justification**: Basic network functionality for server operations.

**NOT INCLUDED** (commonly bundled but unnecessary):
- ❌ `avahi-daemon` - mDNS not needed for server
- ❌ `network-manager` - Too complex, use systemd-networkd
- ❌ `wpasupplicant` - WiFi not needed on server

## Security Packages (Tier 1 - Essential)

### Access Control
```
openssh-server           # Remote access (hardened config)
sudo                     # Privilege escalation with audit
libpam-pwquality        # Password quality enforcement
libpam-tmpdir           # Per-user /tmp directories
```

**Justification**: Required for secure remote access and privilege management.

### Firewall & IPS
```
nftables                 # Modern firewall (replaces iptables)
fail2ban                # Intrusion prevention
```

**Justification**: Essential for network security and brute-force protection.

### Audit & Monitoring
```
auditd                   # Kernel-level audit framework
aide                     # File integrity monitoring
logwatch                # Log analysis and reporting (optional)
```

**Justification**: Required for forensic readiness and intrusion detection.

### Encryption
```
gnupg                    # GPG for package verification
cryptsetup              # Disk encryption support (if needed)
```

**Justification**: Package signature verification and optional encryption.

## Utility Packages (Tier 2 - Operational)

### System Administration
```
vim-tiny                 # Text editor (minimal, no GUI deps)
  Alternative: nano (easier but larger)
  
tmux                     # Terminal multiplexer
  Alternative: screen (older, simpler)
  
htop                     # Process viewer
  Alternative: top (built-in but less features)
  
curl                     # HTTP client (scripting)
wget                     # HTTP client (downloads)
  Justification: Different use cases, both minimal
```

### System Tools
```
rsync                    # Efficient file transfer
tar                      # Archive management
gzip, bzip2, xz-utils   # Compression tools
lsof                     # List open files (debugging)
strace                   # System call tracing (debugging)
```

**Justification**: Essential for system administration and troubleshooting.

## Server Applications (Tier 3 - Service)

### Web Server
```
nginx                    # HTTP server
  Alternative: Apache (bulkier, more features)
  Chosen: Nginx for performance and minimal footprint
  
certbot                  # Let's Encrypt automation
python3-certbot-nginx   # Nginx integration
```

**Justification**: Production web serving with automated TLS.

### Container Platform
```
docker-ce                # Container runtime
docker-ce-cli           # CLI tools
containerd.io           # Container daemon
docker-compose-plugin   # Orchestration
```

**Justification**: Application isolation and modern deployment.

**Security Considerations**:
- Use rootless mode where possible
- AppArmor profile enforced
- User namespaces enabled
- Seccomp profiles active

### Development Runtimes

**Node.js**
```
nodejs                   # JavaScript runtime
npm                      # Package manager
```
**Justification**: Backend development and modern web apps.
**Security**: Install from NodeSource (more secure than Debian repos for Node).

**Python**
```
python3                  # Python 3 interpreter
python3-pip             # Package installer
python3-venv            # Virtual environments
```
**Justification**: Scripting, automation, many modern applications.
**Security**: Use venv for isolation, never pip install as root.

**PHP** (Optional)
```
php8.2-fpm              # PHP FastCGI Process Manager
php8.2-cli              # Command line
php8.2-common           # Common extensions
```
**Justification**: Only if hosting PHP applications.
**Security**: FPM isolation, disable dangerous functions.

## Monitoring & Logging (Tier 4 - Observability)

```
rsyslog                  # System logging daemon
logrotate               # Log rotation
sysstat                 # System statistics (sar, iostat)
  
# Optional but recommended:
prometheus-node-exporter # Metrics collection
grafana-agent           # Observability agent (if using Grafana)
```

**Justification**: Required for operational visibility and troubleshooting.

## Explicitly EXCLUDED Packages

### Development Tools (Security Risk)
```
❌ gcc, g++, make              # Compiler toolchain
❌ build-essential             # Development packages
❌ git                         # Version control
```

**Rationale**: 
- Compilers can be used by attackers to compile exploits
- Not needed on production servers
- If needed, use containers or dedicated build servers

**Exception**: Can be temporarily installed for specific needs, then removed.

### GUI & Desktop
```
❌ xorg, x11                   # X Window System
❌ Any *-desktop packages      # Desktop environments
❌ firefox, chromium           # Browsers
```

**Rationale**: Server = CLI only. GUI = massive attack surface.

### Unnecessary Network Services
```
❌ avahi-daemon                # mDNS/Zeroconf
❌ cups                        # Printing system
❌ bluetooth                   # Bluetooth stack
❌ telnet                      # Insecure remote access
❌ rsh, rlogin                 # Legacy insecure tools
```

**Rationale**: Not needed for server operations, increase attack surface.

### Redundant or Insecure Tools
```
❌ ftp, ftpd                   # FTP (insecure, use SFTP)
❌ nfs-common                  # NFS (unless explicitly needed)
❌ samba                       # SMB (unless explicitly needed)
❌ nis                         # NIS (deprecated, insecure)
```

**Rationale**: Modern alternatives exist (SFTP, scp, rsync).

## Package Update Policy

### Automatic Security Updates

```bash
# unattended-upgrades configuration
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};

# Only install security updates automatically
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false"; // Manual reboot preferred
```

### Manual Review for Major Updates

- **Security updates**: Automatic
- **Point releases**: Weekly review
- **Major version upgrades**: Planned maintenance window
- **Kernel updates**: Require reboot, schedule appropriately

### Package Verification

```bash
# Always verify package signatures
apt-get -o "APT::Get::AllowUnauthenticated=false" install <package>

# Check package integrity before install
debsums -c <package>

# Verify package source
apt-cache policy <package>
```

## Third-Party Repository Policy

### Allowed Repositories

1. **Debian Official**
   - `deb.debian.org` (main, security, updates)
   - Priority: 1 (highest trust)

2. **Docker Official**
   - `download.docker.com/linux/debian`
   - GPG key verification required
   - Priority: 2

3. **NodeSource**
   - `deb.nodesource.com`
   - GPG key verification required
   - Priority: 2

### Repository Security Requirements

- ✅ HTTPS transport mandatory
- ✅ GPG signature verification
- ✅ Regular security monitoring
- ✅ Documented trust basis

### PROHIBITED Repositories

- ❌ PPA (Personal Package Archives) - Ubuntu-specific, untrusted
- ❌ Random GitHub repositories without vetting
- ❌ Any HTTP (non-HTTPS) repositories

## Package Installation Workflow

```bash
# 1. Review package need
echo "Why do we need this package?"

# 2. Check security status
apt-cache policy <package>
apt-cache show <package> | grep -i security

# 3. Check dependencies (avoid bloat)
apt-cache depends <package>

# 4. Verify signature
apt-get download <package>
dpkg-sig --verify <package.deb>

# 5. Install with documentation
apt-get install <package>
echo "Installed <package> for <reason>" >> /var/log/package-install.log

# 6. Harden service if applicable
systemctl edit <service>  # Add security directives

# 7. Document in version control
git add /etc/<service>/
git commit -m "Add <service> for <reason>"
```

## Package Removal Workflow

```bash
# Identify unused packages
apt-get autoremove --dry-run
deborphan  # Find orphaned packages

# Remove package completely
apt-get purge <package>

# Clean up
apt-get autoclean
apt-get clean

# Document removal
echo "Removed <package> - no longer needed" >> /var/log/package-remove.log
```

## Compliance Mapping

### CIS Debian Benchmark

| Control | Requirement | Implementation |
|---------|-------------|----------------|
| 1.6.1.1 | Ensure core dumps are restricted | Package: `systemd` (configured) |
| 1.6.1.2 | Ensure address space randomization | Kernel parameter |
| 2.1.x | Disable unnecessary services | Minimal package install |
| 2.2.1.1 | Ensure time sync configured | Package: `chrony` |
| 5.2.1 | Ensure permissions on /etc/ssh/sshd_config | Automated hardening |

### NIST 800-53

| Control | Description | Package Strategy |
|---------|-------------|------------------|
| CM-7 | Least Functionality | Whitelist-only packages |
| SI-2 | Flaw Remediation | Automatic security updates |
| AU-2 | Audit Events | auditd, rsyslog packages |

## Package Inventory

Track all installed packages:

```bash
#!/bin/bash
# Generate package inventory with justification

dpkg-query -W -f='${Package}\t${Version}\t${Priority}\n' | \
  sort > /var/log/package-inventory-$(date +%Y%m%d).txt

# Compare with previous inventory
diff /var/log/package-inventory-*.txt | grep "^>"
```

## Summary: SkyvyOS Package Count

| Category | Package Count | Justification |
|----------|---------------|---------------|
| Base System | ~20 | Absolute minimum |
| Security | ~10 | Essential protection |
| Utilities | ~15 | Administration |
| Server Apps | ~10-20 | Based on use case |
| **Total** | **~55-65** | vs Debian default ~400+ |

**Attack Surface Reduction**: ~85% fewer packages than standard Debian installation

---

**Philosophy**: "Every package is a potential vulnerability. Only install what you can justify and monitor."
