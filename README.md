# Rancher RKE2 Hardened Deployment Playbook

Production-grade Ansible playbook for deploying a hardened Rancher server via RKE2 across any Linux distribution.

## Supported Distributions

- **Debian-based**: Ubuntu 20.04+, Debian 11+
- **RedHat-based**: RHEL 8+, AlmaLinux 8+, Rocky Linux 8+, CentOS Stream 8+
- **SUSE-based**: openSUSE Leap 15+, SUSE Linux Enterprise 15+

## Requirements

- **ansible-core**: 2.20.5+
- **Python**: 3.10+
- **SSH access** to target servers with sudo privileges
- **Network access**: Outbound HTTPS for package and container downloads

## Quick Start

### 1. Bootstrap Ansible

```bash
chmod +x bootstrap.sh
sudo ./bootstrap.sh
```

Detects your OS and installs `ansible-core` 2.20.5 automatically.

### 2. Configure Inventory

Edit `hosts` file with your server IPs:

```ini
[rancher_servers]
rancher-01 ansible_host=192.168.1.100 ansible_user=root
```

### 3. Configure Deployment Variables

Edit `group_vars/all.yml` to customize your deployment:

```yaml
hostname: rancher-server
rancher_domain: rancher.example.com
static_ip_enabled: true
static_ip: 192.168.1.100
gateway: 192.168.1.1
ssh_auth_mode: key
ssh_public_key: "ssh-rsa AAAA..."
ssl_enabled: true
ssl_mode: letsencrypt
```

### 4. Run Playbook

```bash
ansible-playbook -i hosts site.yml
```

Or run specific roles:

```bash
ansible-playbook -i hosts site.yml --tags system,firewall
```

Or run only SSL configuration:

```bash
ansible-playbook -i hosts site.yml --tags ssl
```

## Configuration Reference

### group_vars/all.yml

#### Basic Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `hostname` | string | rancher-server | Server hostname |
| `system_update_enabled` | bool | true | Update system packages |
| `install_tools` | list | [curl, wget, git, ...] | Tools to install |

#### Network Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `static_ip_enabled` | bool | false | Use static IP |
| `network_interface` | string | eth0 | Network interface name |
| `static_ip` | string | 192.168.1.100 | Static IP address |
| `gateway` | string | 192.168.1.1 | Default gateway |
| `dns_servers` | list | [8.8.8.8, 8.8.4.4] | DNS servers |

#### SSH Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ssh_port` | int | 22 | SSH port |
| `ssh_max_auth_tries` | int | 3 | Max auth attempts |
| `ssh_auth_mode` | string | password | Auth method: password or key |
| `ssh_public_key` | string | "" | SSH public key (required if auth_mode=key) |

#### Firewall Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `firewall_ssh_source_cidrs` | list | [0.0.0.0/0] | SSH source CIDR blocks |
| `firewall_additional_ports` | list | [] | Additional ports to open |

#### RKE2 Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `rke2_version` | string | latest | RKE2 version |
| `rke2_mode` | string | server | server or agent |
| `rke2_cluster_cidr` | string | 10.42.0.0/16 | Pod CIDR |
| `rke2_service_cidr` | string | 10.43.0.0/16 | Service CIDR |
| `rke2_disable_components` | list | [] | Components to disable |
| `rke2_agent_server_url` | string | "" | Server URL (for agent mode) |

#### Rancher Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `rancher_mode` | string | local | local or agent |
| `rancher_domain` | string | rancher.example.com | Rancher domain |
| `rancher_version` | string | stable | Rancher version |
| `rancher_replicas` | int | 1 | Deployment replicas |

#### SSL/TLS Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ssl_enabled` | bool | false | Enable SSL |
| `ssl_mode` | string | letsencrypt | letsencrypt or secret |
| `ssl_tls_crt_path` | string | "" | Path to TLS certificate |
| `ssl_tls_key_path` | string | "" | Path to TLS key |
| `ssl_ca_path` | string | "" | Path to CA certificate |

#### Security Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `selinux_mode` | string | enforcing | SELinux mode (RedHat) |
| `fail2ban_enabled` | bool | true | Enable fail2ban |
| `fail2ban_ssh_maxretry` | int | 5 | Max SSH retries |
| `fail2ban_ssh_bantime` | int | 3600 | Ban duration (seconds) |

## Role Details

### hostname
Sets system hostname and updates /etc/hosts.

### system_update
Updates OS packages. Controlled by `system_update_enabled`.

### network
Configures static IP via NetworkManager. Skipped if `static_ip_enabled: false`.

### system
Installs base packages and disables swap permanently.

### ssh
Hardens SSH configuration:
- Disables root login with password
- Supports public key authentication
- Configurable port and max auth tries
- Validates configuration before applying

### firewall
Configures native firewall:
- **Debian**: ufw
- **RedHat**: firewalld
- **SUSE**: firewalld

Opens ports:
- SSH (configurable)
- HTTP (80)
- HTTPS (443)
- Kubernetes API (6443)
- RKE2 nodes (9345)
- Flannel/Calico CNI (8472, 51820, 51821 UDP)

### security
Applies security hardening:
- Detects and configures MAC (SELinux/AppArmor)
- Applies kernel hardening parameters
- Sets system resource limits

### fail2ban
Installs and configures fail2ban for SSH intrusion protection.

### tools
Installs common utilities: curl, wget, git, tar, unzip, netcat, jq, vim.

### rke2
Installs RKE2 via official installer:
- Server or agent mode
- Configurable CIDR ranges
- Creates kubectl/helm symlinks
- Validates installation

### cert_manager
Installs cert-manager via Helm:
- Adds jetstack Helm repository
- Enables CRD installation
- Waits for deployment readiness

### rancher
Installs Rancher via Helm:
- **Local mode**: Full Rancher server
- **Agent mode**: Cluster registration only
- Uses Nginx ingress
- Displays bootstrap credentials

### ssl
Configures TLS/SSL:
- **Let's Encrypt**: Automatic cert provisioning
- **Secret**: Custom certificate from files
- Optional custom CA certificate
- Run independently with `--tags ssl`

## Usage Examples

### Basic deployment with defaults

```bash
ansible-playbook -i hosts site.yml
```

### Deploy with static IP

```yaml
# group_vars/all.yml
static_ip_enabled: true
static_ip: 192.168.1.100
gateway: 192.168.1.1
dns_servers:
  - 1.1.1.1
  - 8.8.8.8
```

### Deploy with SSH key authentication

```yaml
# group_vars/all.yml
ssh_auth_mode: key
ssh_public_key: |
  ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC...
```

### Deploy with Let's Encrypt SSL

```yaml
# group_vars/all.yml
ssl_enabled: true
ssl_mode: letsencrypt
rancher_domain: rancher.example.com
```

### Deploy agent mode

```yaml
# group_vars/all.yml
rke2_mode: agent
rancher_mode: agent
rke2_agent_server_url: https://rancher-server.example.com:6443
rke2_token: "shared-secret-token"
```

### Configure firewall rules

```yaml
# group_vars/all.yml
firewall_ssh_source_cidrs:
  - 203.0.113.0/24
firewall_additional_ports:
  - 8080
  - 9090
```

## Idempotency

All tasks are idempotent and safe to run multiple times. The playbook can be executed repeatedly without side effects.

## Troubleshooting

### Check SSH connection

```bash
ansible -i hosts rancher_servers -m ping
```

### Run in verbose mode

```bash
ansible-playbook -i hosts site.yml -vvv
```

### Run specific role

```bash
ansible-playbook -i hosts site.yml --tags system
```

### Validate playbook syntax

```bash
ansible-playbook -i hosts site.yml --syntax-check
```

### Check Kubernetes status

After deployment, on the server:

```bash
/var/lib/rancher/rke2/bin/kubectl --kubeconfig=/etc/rancher/rke2/rke2.yaml get nodes
/var/lib/rancher/rke2/bin/kubectl --kubeconfig=/etc/rancher/rke2/rke2.yaml get pods -A
```

### Access Rancher UI

After SSL setup:

```
https://rancher.example.com
```

## Ansible Semaphore Integration

To use with Semaphore:

1. Create new project
2. Add repository from this playbook
3. Create inventory with your hosts
4. Create template:
   - Playbook: `site.yml`
   - Inventory: Select your inventory
5. In template variables, override `group_vars/all.yml` values:

```yaml
hostname: my-rancher
rancher_domain: my-rancher.com
static_ip: 192.168.1.100
ssl_enabled: true
```

## File Structure

```
rancher-rke2-playbook/
├── site.yml                    # Main playbook
├── hosts                       # Inventory
├── bootstrap.sh               # Ansible installer
├── group_vars/
│   └── all.yml               # Global variables
├── roles/
│   ├── hostname/
│   ├── system_update/
│   ├── network/
│   ├── system/
│   ├── ssh/
│   ├── firewall/
│   ├── security/
│   ├── fail2ban/
│   ├── tools/
│   ├── rke2/
│   ├── cert_manager/
│   ├── rancher/
│   └── ssl/
└── README.md
```

## Production Recommendations

1. **Use SSH key authentication**
2. **Restrict SSH source IPs** via firewall
3. **Enable SSL with Let's Encrypt or custom certs**
4. **Set strong RKE2 token** in variables
5. **Use static IPs** for stability
6. **Configure backup procedures** for etcd
7. **Monitor cluster health** with Kubernetes metrics
8. **Keep RKE2 updated** regularly

## License

MIT

## Support

For issues or questions, refer to official documentation:
- [RKE2 Documentation](https://docs.rke2.io)
- [Rancher Documentation](https://rancher.com/docs)
- [Ansible Documentation](https://docs.ansible.com)
