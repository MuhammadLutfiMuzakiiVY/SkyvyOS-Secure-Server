# SkyvyOS Secure Server - Advanced Network Security

**Enterprise-Grade Firewall Architecture with nftables**

## Overview

SkyvyOS uses **nftables** (modern replacement for iptables) with:
- Default-deny policy
- Stateful connection tracking
- Rate limiting & DDoS protection
- Port knocking (optional)
- Geo-blocking capability
- IPv4 + IPv6 support

## nftables Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PACKET FLOW                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Internet                                               │
│     ↓                                                   │
│  ┌──────────────────────────────────────┐              │
│  │  INPUT Chain (Incoming)              │              │
│  │  - Default: DROP                     │              │
│  │  - Allow: Established, Related       │              │
│  │  - Rate limit: New connections       │              │
│  │  - Allow: SSH (custom port)          │              │
│  │  - Allow: HTTP/HTTPS                 │              │
│  └──────────────────────────────────────┘              │
│     ↓                                                   │
│  Server Application                                     │
│     ↓                                                   │
│  ┌──────────────────────────────────────┐              │
│  │  OUTPUT Chain (Outgoing)             │              │
│  │  - Default: ACCEPT (egress allowed)  │              │
│  │  - Optional: Egress filtering        │              │
│  └──────────────────────────────────────┘              │
│     ↓                                                   │
│  Internet                                               │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Complete nftables Configuration

**File: `/etc/nftables.conf`**

```nft
#!/usr/sbin/nft -f
# SkyvyOS Secure Server - Advanced nftables Configuration
# Security-hardened firewall with DDoS protection

# Flush all existing rules
flush ruleset

# Define variables
define SSH_PORT = 22
define HTTP_PORT = 80
define HTTPS_PORT = 443

# Trusted networks (customize)
define TRUSTED_NETWORKS = {
    192.168.1.0/24,
    10.0.0.0/8
}

# Known bad actors (example)
define BLACKLIST = {
    0.0.0.0/8,
    127.0.0.0/8
}

#
# IPv4 Filter Table
#
table inet filter {
    
    #
    # Rate limiting sets
    #
    set ssh_ratelimit {
        type ipv4_addr
        timeout 10m
        flags timeout
    }
    
    set http_ratelimit {
        type ipv4_addr
        timeout 1m
        flags timeout
    }
    
    #
    # INPUT Chain - Incoming traffic
    #
    chain input {
        type filter hook input priority 0; policy drop;
        
        # Accept loopback
        iif lo accept comment "Accept loopback"
        
        # Drop invalid packets
        ct state invalid drop comment "Drop invalid"
        
        # Accept established/related connections
        ct state established,related accept comment "Accept established"
        
        # Drop blacklisted IPs
        ip saddr @BLACKLIST drop comment "Drop blacklist"
        
        # ICMP rate limiting (prevent ping flood)
        icmp type echo-request limit rate 5/second accept comment "Rate limit ping"
        icmp type echo-request drop comment "Drop excess ping"
        
        # SSH with rate limiting and brute force protection
        tcp dport $SSH_PORT ct state new limit rate 3/minute accept comment "SSH rate limit"
        tcp dport $SSH_PORT drop comment "Drop excess SSH"
        
        # HTTP/HTTPS with connection limiting
        tcp dport $HTTP_PORT ct state new limit rate 100/second accept comment "HTTP"
        tcp dport $HTTPS_PORT ct state new limit rate 100/second accept comment "HTTPS"
        
        # SYN flood protection
        tcp flags syn tcp option maxseg size 1-536 drop comment "Drop SYN flood"
        
        # Log dropped packets (optional, can be verbose)
        # limit rate 5/minute log prefix "nftables-drop: "
        
        # Reject everything else
        reject with icmpx type port-unreachable
    }
    
    #
    # FORWARD Chain - Forwarding (for Docker, etc)
    #
    chain forward {
        type filter hook forward priority 0; policy drop;
        
        # Accept established/related
        ct state established,related accept
        
        # Docker bridge exception (if using Docker)
        iifname "docker0" accept
        oifname "docker0" accept
    }
    
    #
    # OUTPUT Chain - Outgoing traffic
    #
    chain output {
        type filter hook output priority 0; policy accept;
        
        # Allow all outgoing by default
        # Optional: Add egress filtering here
    }
}

#
# IPv6 support (same rules)
#
table ip6 filter {
    chain input {
        type filter hook input priority 0; policy drop;
        
        iif lo accept
        ct state invalid drop
        ct state established,related accept
        
        # ICMPv6 (essential for IPv6)
        icmpv6 type { nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit, nd-router-advert } accept
        
        tcp dport $SSH_PORT ct state new limit rate 3/minute accept
        tcp dport $HTTP_PORT ct state new limit rate 100/second accept
        tcp dport $HTTPS_PORT ct state new limit rate 100/second accept
        
        reject with icmpv6 type port-unreachable
    }
    
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
    
    chain output {
        type filter hook output priority 0; policy accept;
    }
}
```

## Advanced Features

### 1. Port Knocking (Secret SSH Access)

```nft
# Port knocking: Knock on ports 7000, 8000, 9000 to unlock SSH
table inet portknock {
    set clients_ipv4 {
        type ipv4_addr
        timeout 30s
        flags timeout
    }
    
    chain knock_sequence {
        type filter hook input priority -10;
        
        tcp dport 7000 add @clients_ipv4 { ip saddr timeout 10s }
        tcp dport 8000 ip saddr @clients_ipv4 add @clients_ipv4 { ip saddr timeout 10s }
        tcp dport 9000 ip saddr @clients_ipv4 add @clients_ipv4 { ip saddr timeout 30s }
    }
    
    chain input {
        type filter hook input priority 0;
        tcp dport 22 ip saddr @clients_ipv4 accept
    }
}
```

### 2. Geo-blocking (Block by Country)

```bash
# Install geoip database
apt-get install -y geoip-database geoip-bin

# Block China, Russia (example)
ipset create geoblock hash:net
ipset add geoblock $(geoiplookup -f /usr/share/GeoIP/GeoIP.dat CN | awk '{print $4}')
ipset add geoblock $(geoiplookup -f /usr/share/GeoIP/GeoIP.dat RU | awk '{print $4}')

# In nftables
# ip saddr @geoblock drop
```

### 3. Connection Tracking Limits

```nft
# Limit concurrent connections per IP
table inet connlimit {
    chain input {
        type filter hook input priority 0;
        
        # Max 10 concurrent SSH connections per IP
        tcp dport 22 ct count over 10 drop
        
        # Max 50 concurrent HTTP connections per IP
        tcp dport 80 ct count over 50 drop
    }
}
```

### 4. Application-Level Filtering

```nft
# Block specific application protocols
table inet appfilter {
    chain input {
        type filter hook input priority 0;
        
        # Block BitTorrent
        udp dport 6881-6889 drop
        tcp dport 6881-6889 drop
        
        # Block DNS over non-standard ports (DNS tunneling)
        tcp dport != 53 @th,160,16 53 drop
    }
}
```

## Network Stack Hardening (sysctl)

**Already in `/etc/sysctl.d/99-skyvyos-network.conf`:**

```ini
# Network Security Hardening

# IP Forwarding (disable unless routing)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# SYN Cookies (SYN flood protection)
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_syn_backlog = 4096

# IP Spoofing protection
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Log Martians (impossible addresses)
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Ignore ICMP ping requests (optional, can break some tools)
# net.ipv4.icmp_echo_ignore_all = 1

# TCP hardening
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_rfc1337 = 1

# Increase connection tracking table size
net.netfilter.nf_conntrack_max = 1000000

# Connection tracking timeouts
net.netfilter.nf_conntrack_tcp_timeout_established = 600
```

## Management Commands

```bash
# Reload nftables
nft -f /etc/nftables.conf

# List current rules
nft list ruleset

# List specific table
nft list table inet filter

# Monitor dropped packets
nft monitor

# Add temporary rule
nft add rule inet filter input tcp dport 8080 accept

# Delete rule by handle
nft -a list table inet filter  # Get handle
nft delete rule inet filter input handle 10

# Flush all rules
nft flush ruleset

# Test configuration
nft -c -f /etc/nftables.conf
```

## Firewall Testing

```bash
# Test SSH rate limiting
for i in {1..10}; do ssh -o ConnectTimeout=1 user@server; done

# Test HTTP rate limiting
ab -n 1000 -c 100 http://server/

# Port scan detection
nmap -sS -p- server

# DDoS simulation (use with caution!)
hping3 -S --flood -p 80 server
```

## Integration with Fail2Ban

nftables works with Fail2Ban for dynamic IP blocking:

```ini
# /etc/fail2ban/jail.local
[DEFAULT]
banaction = nftables-multiport

[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
```

## Security Monitoring

```bash
# Watch connection tracking
watch -n1 'cat /proc/net/nf_conntrack | wc -l'

# Monitor bandwidth per IP
iptraf-ng

# Real-time firewall logs
journalctl -f -u nftables

# Connection statistics
ss -s
netstat -s
```

## Emergency Access Recovery

```bash
# If locked out, from console:
nft flush ruleset
nft add table inet filter
nft add chain inet filter input { type filter hook input priority 0\; policy accept\; }
nft add chain inet filter output { type filter hook output priority 0\; policy accept\; }
```

---

**SkyvyOS Network Security: Military-grade firewall protection with flexible configuration**
