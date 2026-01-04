# SkyvyOS Secure Server - Access Control & User Management

**Enterprise Role-Based Access Control (RBAC) Implementation**

## I. USER MODEL & PHILOSOPHY

### Core Principles

1. **Least Privilege**: Users only get permissions they absolutely need
2. **Role Separation**: Different roles for different responsibilities
3. **Non-Root Default**: Normal operations never require root
4. **Audit Everything**: All privilege escalations are logged
5. **Time-Bound Access**: Temporary elevation, not permanent root

### User Categories

```
┌────────────────────────────────────────────────────┐
│            USER HIERARCHY                          │
├────────────────────────────────────────────────────┤
│                                                    │
│  Level 0: root (EMERGENCY ONLY)                   │
│           └─ Direct login DISABLED                │
│              Console access only with audit       │
│                                                    │
│  Level 1: Admin Users (sysadmin group)            │
│           └─ Full sudo access (with audit)        │
│              Can manage system, users, services   │
│                                                    │
│  Level 2: Service Operators (operators group)     │
│           └─ Limited sudo (restart services)      │
│              Can manage applications, not system  │
│                                                    │
│  Level 3: Application Users (developers group)    │
│           └─ No sudo access                       │
│              Can deploy apps, view logs           │
│                                                    │
│  Level 4: Service Accounts (system users)         │
│           └─ No login shell                       │
│              Run services only (nginx, docker)    │
│                                                    │
└────────────────────────────────────────────────────┘
```

## II. USER CREATION & MANAGEMENT

### Admin User Creation

```bash
#!/bin/bash
# create-admin-user.sh - Create privileged admin user

USERNAME="$1"
FULLNAME="$2"

if [ -z "$USERNAME" ] || [ -z "$FULLNAME" ]; then
    echo "Usage: $0 <username> <fullname>"
    exit 1
fi

# Create user with secure defaults
useradd -m \
    -s /bin/bash \
    -c "$FULLNAME" \
    -G sysadmin,sudo,adm,systemd-journal \
    "$USERNAME"

# Set password expiry
chage -M 90 -m 7 -W 14 "$USERNAME"  # Max 90 days, min 7 days, warn 14 days

# Force password change on first login
chage -d 0 "$USERNAME"

# Setup SSH directory
mkdir -p /home/$USERNAME/.ssh
chmod 700 /home/$USERNAME/.ssh
touch /home/$USERNAME/.ssh/authorized_keys
chmod 600 /home/$USERNAME/.ssh/authorized_keys
chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

# Setup audit logging for this user
echo "admin_user=$USERNAME" >> /etc/audit/rules.d/admin-users.rules
augenrules --load

echo "✓ Admin user $USERNAME created"
echo "⚠ Add SSH public key to /home/$USERNAME/.ssh/authorized_keys"
echo "⚠ User must change password on first login"
```

### Operator User Creation

```bash
#!/bin/bash
# create-operator-user.sh - Create service operator user

USERNAME="$1"
SERVICES="$2"  # Comma-separated service list

useradd -m \
    -s /bin/bash \
    -c "Service Operator - $SERVICES" \
    -G operators,docker \
    "$USERNAME"

# Password expiry (longer for operators)
chage -M 180 -m 7 -W 30 "$USERNAME"

# Add to sudoers with specific commands only
cat > /etc/sudoers.d/$USERNAME <<EOF
# Operator: $USERNAME
# Services: $SERVICES
$USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl restart $SERVICES
$USERNAME ALL=(ALL) NOPASSWD: /bin/systemctl status *
$USERNAME ALL=(ALL) NOPASSWD: /bin/journalctl *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/docker ps *
$USERNAME ALL=(ALL) NOPASSWD: /usr/bin/docker logs *
EOF

chmod 440 /etc/sudoers.d/$USERNAME

echo "✓ Operator user $USERNAME created for services: $SERVICES"
```

### Service Account Creation

```bash
#!/bin/bash
# create-service-account.sh - Create non-login service account

SERVICE_NAME="$1"
SERVICE_DIR="$2"

# Create system user (UID < 1000, no login)
useradd --system \
    --no-create-home \
    --shell /usr/sbin/nologin \
    --comment "Service Account for $SERVICE_NAME" \
    "$SERVICE_NAME"

# Create service-specific directory
if [ -n "$SERVICE_DIR" ]; then
    mkdir -p "$SERVICE_DIR"
    chown $SERVICE_NAME:$SERVICE_NAME "$SERVICE_DIR"
    chmod 750 "$SERVICE_DIR"
fi

echo "✓ Service account $SERVICE_NAME created"
```

## III. GRANULAR SUDO CONFIGURATION

### /etc/sudoers.d/skyvyos-policy

```bash
# SkyvyOS Secure Server - Sudo Policy
# File: /etc/sudoers.d/skyvyos-policy
# Permissions: 440 (r--r-----)

# Default settings
Defaults    env_reset
Defaults    mail_badpass
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults    use_pty                    # Prevent some attacks
Defaults    logfile="/var/log/sudo.log"
Defaults    log_year, log_host, log_input, log_output

# Timeout settings
Defaults    timestamp_timeout=15        # Require password after 15 min
Defaults    passwd_timeout=5            # 5 min to enter password
Defaults    passwd_tries=3              # Max 3 password attempts

# Security features
Defaults    requiretty                  # Must be on TTY
Defaults    !visiblepw                  # Never allow visible password
Defaults    always_set_home             # Set $HOME
Defaults    env_keep += "SSH_AUTH_SOCK" # Keep SSH agent

# Audit settings
Defaults    syslog=authpriv
Defaults    syslog_goodpri=notice
Defaults    syslog_badpri=alert

#
# USER PRIVILEGE SPECIFICATION
#

# Root (for reference, normally never used)
root    ALL=(ALL:ALL) ALL

#
# SYSADMIN GROUP - Full System Access
#
%sysadmin ALL=(ALL:ALL) ALL

# But still require password for sensitive operations
%sysadmin ALL=(ALL) PASSWD: /bin/rm -rf /, /sbin/fdisk, /sbin/mkfs*

#
# OPERATORS GROUP - Limited Service Management
#
%operators ALL=(ALL) NOPASSWD: /bin/systemctl start *
%operators ALL=(ALL) NOPASSWD: /bin/systemctl stop *
%operators ALL=(ALL) NOPASSWD: /bin/systemctl restart *
%operators ALL=(ALL) NOPASSWD: /bin/systemctl reload *
%operators ALL=(ALL) NOPASSWD: /bin/systemctl status *
%operators ALL=(ALL) NOPASSWD: /bin/journalctl *

# Docker management for operators
%operators ALL=(ALL) NOPASSWD: /usr/bin/docker ps *
%operators ALL=(ALL) NOPASSWD: /usr/bin/docker logs *
%operators ALL=(ALL) NOPASSWD: /usr/bin/docker stats *
%operators ALL=(ALL) NOPASSWD: /usr/bin/docker restart *
%operators ALL=(ALL) NOPASSWD: /usr/bin/docker stop *
%operators ALL=(ALL) NOPASSWD: /usr/bin/docker start *

# Log viewing
%operators ALL=(ALL) NOPASSWD: /bin/cat /var/log/* *
%operators ALL=(ALL) NOPASSWD: /usr/bin/tail /var/log/* *
%operators ALL=(ALL) NOPASSWD: /usr/bin/less /var/log/* *

# Explicitly deny dangerous commands for operators
%operators ALL=(ALL) !ALL
%operators ALL=(ALL) !/bin/su
%operators ALL=(ALL) !/usr/bin/sudo -i
%operators ALL=(ALL) !/usr/bin/passwd root

#
# DEVELOPERS GROUP - Read-Only System Access
#
%developers ALL=(ALL) NOPASSWD: /bin/systemctl status *
%developers ALL=(ALL) NOPASSWD: /bin/journalctl -u *
%developers ALL=(ALL) NOPASSWD: /usr/bin/tail /var/log/* *

# Docker read-only
%developers ALL=(ALL) NOPASSWD: /usr/bin/docker ps *
%developers ALL=(ALL) NOPASSWD: /usr/bin/docker logs *

#
# COMMAND ALIASES for easier management
#
Cmnd_Alias WEB_SERVICE = /bin/systemctl * nginx, /bin/systemctl * php*-fpm
Cmnd_Alias DB_SERVICE = /bin/systemctl * mysql, /bin/systemctl * postgresql
Cmnd_Alias LOG_READ = /bin/cat /var/log/*, /usr/bin/tail /var/log/*, /usr/bin/less /var/log/*

# Example: Give specific user web service control
# webadmin ALL=(ALL) NOPASSWD: WEB_SERVICE
```

### Advanced Sudo Rules Examples

```bash
# Time-based restrictions (business hours only)
Defaults:john timestamp_timeout=0  # Always ask password
Defaults:john lecture=always        # Always show lecture

# Session recording
Defaults:admin log_input, log_output
Defaults:admin iolog_dir=/var/log/sudo-io/%{user}

# Command path restrictions
Defaults:operator secure_path="/usr/local/sbin:/usr/sbin:/sbin"

# Prevent privilege escalation via sudo
Defaults:untrusted !root_sudo
Defaults:untrusted !command_pause

# User-specific time restrictions (requires pam_time)
# In /etc/security/time.conf:
# sudo;*;operators;!Al0800-1800
```

## IV. AUTHENTICATION HARDENING

### SSH Key-Only Authentication

**File: /etc/ssh/sshd_config.d/99-skyvyos-auth.conf**
```ssh
# SkyvyOS SSH Authentication Hardening

# Authentication methods
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Key types (only secure algorithms)
PubkeyAcceptedKeyTypes ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,ecdsa-sha2-nistp521,rsa-sha2-256,rsa-sha2-512

# Root login
PermitRootLogin no

# User restrictions
AllowUsers admin operator1 operator2
DenyUsers root nobody

# Group restrictions (alternative to AllowUsers)
# AllowGroups sysadmin operators

# Login grace time
LoginGraceTime 30

# Max auth tries
MaxAuthTries 3
MaxSessions 10

# Host-based authentication (disabled)
HostbasedAuthentication no
IgnoreRhosts yes
```

### Password Policy (PAM)

**File: /etc/security/pwquality.conf**
```ini
# SkyvyOS Password Quality Requirements

# Minimum length
minlen = 14

# Required character classes
dcredit = -1    # At least 1 digit
ucredit = -1    # At least 1 uppercase
lcredit = -1    # At least 1 lowercase
ocredit = -1    # At least 1 special char

# Complexity
minclass = 4    # All 4 classes required
maxrepeat = 3   # No more than 3 consecutive same chars
maxsequence = 3 # No sequences like "abc" or "123"

# Dictionary check
dictcheck = 1

# User info check (prevent password = username, etc)
usercheck = 1
enforcing = 1

# History (prevent password reuse)
# Set in /etc/pam.d/common-password:
# password required pam_pwhistory.so remember=24 use_authtok
```

**File: /etc/login.defs (additions)**
```bash
# Password aging controls
PASS_MAX_DAYS   90
PASS_MIN_DAYS   7
PASS_WARN_AGE   14

# Account expiry
INACTIVE_DAYS   30  # Lock after 30 days of inactivity

# Minimum UID/GID for normal users
UID_MIN         1000
UID_MAX         60000
GID_MIN         1000
GID_MAX         60000

# System accounts
SYS_UID_MIN     100
SYS_UID_MAX     999

# Password encryption
ENCRYPT_METHOD  SHA512

# Umask for user file creation
UMASK           027

# Create home with mode 750
CREATE_HOME     yes
```

### Account Lockout (PAM)

**File: /etc/pam.d/common-auth**
```pam
# Account lockout after failed attempts
auth required pam_faillock.so preauth silent audit deny=5 unlock_time=1800
auth [default=die] pam_faillock.so authfail audit deny=5 unlock_time=1800
auth sufficient pam_unix.so nullok try_first_pass
auth requisite pam_deny.so
auth required pam_permit.so
auth required pam_faillock.so authsucc audit deny=5 unlock_time=1800

# Unlock manually with: faillock --user <username> --reset
```

## V. PRIVILEGE ESCALATION AUDIT

### Sudo Logging Configuration

**File: /etc/rsyslog.d/20-sudo.conf**
```bash
# Log all sudo commands
auth,authpriv.*     /var/log/sudo.log

# Alert on sudo to root
:msg, contains, "sudo" -/var/log/sudo.log
& stop

# Send critical sudo events to remote syslog (optional)
# auth,authpriv.crit  @@remote-syslog-server:514
```

### Audit Rules for Privilege Escalation

**File: /etc/audit/rules.d/10-privileged-commands.rules**
```bash
# Audit sudo execution
-w /usr/bin/sudo -p x -k sudo_execution
-w /etc/sudoers -p wa -k sudoers_changes
-w /etc/sudoers.d/ -p wa -k sudoers_changes

# Audit su usage
-w /bin/su -p x -k su_execution

# Audit passwd changes
-w /usr/bin/passwd -p x -k passwd_changes
-w /etc/passwd -p wa -k passwd_file
-w /etc/shadow -p wa -k shadow_file

# Audit user/group changes
-w /usr/sbin/useradd -p x -k user_addition
-w /usr/sbin/userdel -p x -k user_deletion
-w /usr/sbin/usermod -p x -k user_modification
-w /usr/sbin/groupadd -p x -k group_addition
-w /usr/sbin/groupdel -p x -k group_deletion
-w /usr/sbin/groupmod -p x -k group_modification

# Audit SSH key changes
-w /home/*/.ssh -p wa -k ssh_key_changes
```

## VI. ROLE SEPARATION IMPLEMENTATION

### Example: Web Application Deployment

```
Developer (developers group)
    ↓ SSH with key
    ↓ Deploy code to /srv/app (owned by developers group)
    ↓ No sudo access
    
Operator (operators group)
    ↓ SSH with key
    ↓ sudo systemctl restart myapp
    ↓ sudo docker restart myapp-container
    ↓ View logs: sudo journalctl -u myapp
    
Admin (sysadmin group)
    ↓ SSH with key
    ↓ Full sudo access
    ↓ System configuration
    ↓ User management
    ↓ Audit log review
```

### Filesystem Permissions

```bash
# Application directory structure
/srv/app/
├── code/          (775, developers:developers) - writable by devs
├── logs/          (750, www-data:operators) - readable by ops
├── config/        (750, root:operators) - read-only for ops
└── secrets/       (700, root:root) - admin only

# Service files
/etc/systemd/system/myapp.service  # 644, root:root
/etc/nginx/sites-available/myapp   # 644, root:root

# Runtime data
/var/run/myapp/    # 755, myapp-user:myapp-user
```

## VII. MONITORING & ALERTS

### Failed Login Monitoring

```bash
# /usr/local/bin/check-failed-logins.sh
#!/bin/bash

THRESHOLD=5
LOGFILE="/var/log/auth.log"
ALERT_EMAIL="security@example.com"

FAILED_COUNT=$(grep "Failed password" $LOGFILE | grep "$(date +%b\ %d)" | wc -l)

if [ $FAILED_COUNT -gt $THRESHOLD ]; then
    echo "ALERT: $FAILED_COUNT failed login attempts today!" | \
        mail -s "Security Alert: Failed Logins" $ALERT_EMAIL
fi
```

### Unauthorized Sudo Attempts

```bash
# /usr/local/bin/check-sudo-violations.sh
#!/bin/bash

# Check for unauthorized sudo attempts in last hour
ausearch -k sudo_execution -ts recent | \
    grep "denied" | \
    mail -s "Sudo Violation Detected" security@example.com
```

## VIII. COMPLIANCE MAPPING

| Control | Requirement | Implementation |
|---------|-------------|----------------|
| AC-2 | Account Management | Role-based user creation scripts |
| AC-3 | Access Enforcement | Granular sudo rules |
| AC-7 | Unsuccessful Login Attempts | PAM faillock (5 attempts, 30 min lockout) |
| AC-11 | Session Lock | Sudo timeout (15 min) |
| IA-2 | Identification & Authentication | SSH key-only |
| IA-5 | Authenticator Management | 14+ chars, complexity, 90-day expiry |
| AU-2 | Audit Events | auditd rules for all privilege escalation |

---

**Summary**: Defense-in-depth access control with role separation, least privilege, and comprehensive audit logging for maximum security and accountability.
