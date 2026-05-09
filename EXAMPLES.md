# Example Configuration Files

This directory contains example configurations for different deployment scenarios.

## Production Single Server with Let's Encrypt

```yaml
---
# group_vars/all.yml
hostname: rancher-prod
system_update_enabled: true

# Network
static_ip_enabled: true
network_interface: eth0
static_ip: "192.168.1.100"
gateway: "192.168.1.1"
dns_servers:
  - "1.1.1.1"
  - "1.0.0.1"

# SSH
ssh_port: 2222
ssh_max_auth_tries: 3
ssh_auth_mode: key
ssh_public_key: |
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...

# Firewall
firewall_ssh_source_cidrs:
  - "203.0.113.0/24"

# Security
fail2ban_enabled: true

# RKE2
rke2_version: v1.28.0
rke2_mode: server
rke2_cluster_cidr: "10.42.0.0/16"
rke2_service_cidr: "10.43.0.0/16"
rke2_disable_components: []

# Rancher
rancher_mode: local
rancher_domain: rancher.example.com
rancher_version: stable
rancher_replicas: 3

# SSL
ssl_enabled: true
ssl_mode: letsencrypt
```

## High Availability Cluster

```yaml
---
# group_vars/all.yml
hostname: rancher-ha-{{ inventory_hostname }}
system_update_enabled: true

static_ip_enabled: true
network_interface: eth0

ssh_auth_mode: key
ssh_port: 22

fail2ban_enabled: true

rke2_version: latest
rke2_mode: server
rke2_token: "generate-strong-random-token-here"

rancher_mode: local
rancher_domain: rancher.ha.example.com
rancher_replicas: 3

ssl_enabled: true
ssl_mode: letsencrypt
```

Then for inventory:

```ini
[rancher_servers]
rancher-ha-01 ansible_host=10.0.1.10
rancher-ha-02 ansible_host=10.0.1.11
rancher-ha-03 ansible_host=10.0.1.12
```

## Agent Node Connected to External Rancher

```yaml
---
# group_vars/all.yml
hostname: rancher-agent-{{ inventory_hostname }}
system_update_enabled: true

static_ip_enabled: true
network_interface: eth0

ssh_auth_mode: password

fail2ban_enabled: true

rke2_version: latest
rke2_mode: agent
rke2_token: "shared-token-from-rancher-server"
rke2_agent_server_url: "https://rancher.example.com:6443"

rancher_mode: agent
```

## Development/Testing Setup

```yaml
---
# group_vars/all.yml
hostname: rancher-dev
system_update_enabled: true

static_ip_enabled: false

ssh_port: 22
ssh_auth_mode: password

firewall_ssh_source_cidrs:
  - "0.0.0.0/0"

fail2ban_enabled: false

rke2_version: latest
rke2_mode: server

rancher_mode: local
rancher_domain: rancher.local
rancher_replicas: 1

ssl_enabled: false
```

## SUSE Linux Enterprise Edition

```yaml
---
# group_vars/all.yml
hostname: rancher-suse
system_update_enabled: true

static_ip_enabled: true
network_interface: eth0
static_ip: "192.168.1.100"
gateway: "192.168.1.1"
dns_servers:
  - "8.8.8.8"

ssh_auth_mode: key

fail2ban_enabled: true

rke2_version: stable
rke2_mode: server

rancher_mode: local
rancher_domain: rancher.suse.local

ssl_enabled: true
ssl_mode: secret
ssl_tls_crt_path: /path/to/cert.crt
ssl_tls_key_path: /path/to/key.key
ssl_ca_path: /path/to/ca.crt
```

## RedHat with SELinux

```yaml
---
# group_vars/all.yml
hostname: rancher-rhel
system_update_enabled: true

static_ip_enabled: true
network_interface: eth0

ssh_auth_mode: key

fail2ban_enabled: true

selinux_mode: enforcing

rke2_version: latest
rke2_mode: server
rke2_disable_components: []

rancher_mode: local
rancher_domain: rancher.example.com
rancher_replicas: 1

ssl_enabled: true
ssl_mode: letsencrypt
```

## Custom Ports and Firewall

```yaml
---
# group_vars/all.yml
hostname: rancher-custom
system_update_enabled: true

static_ip_enabled: true
network_interface: eth0

ssh_port: 2222
ssh_auth_mode: key

firewall_ssh_source_cidrs:
  - "10.0.0.0/8"
  - "172.16.0.0/12"

firewall_additional_ports:
  - 8080
  - 9090
  - 10250

fail2ban_enabled: true

rke2_version: latest
rke2_mode: server

rancher_mode: local
rancher_domain: rancher.custom.local

ssl_enabled: true
ssl_mode: letsencrypt
```

## Usage

Replace the values in `group_vars/all.yml` with the example configuration that matches your use case.

### Run with specific configuration:

```bash
# Ensure inventory is correct
vim hosts

# Configure variables
cp group_vars/all.yml group_vars/all.yml.backup
vim group_vars/all.yml

# Run playbook
ansible-playbook -i hosts site.yml -v

# Configure SSL (if not done during initial run)
ansible-playbook -i hosts site.yml --tags ssl
```

### For Semaphore:

1. Create new project
2. Import this repository
3. Create Inventory with your hosts
4. Create Template with Site: `site.yml`
5. In "Extra CLI args" or "Extra vars", override values:

```
--extra-vars "rancher_domain=my-rancher.com ssl_enabled=true"
```

Or paste into template variables field:

```yaml
rancher_domain: my-rancher.com
ssl_enabled: true
ssl_mode: letsencrypt
static_ip_enabled: true
static_ip: 192.168.1.100
```
