# Shecan DNS CLI

A shell-based CLI utility to configure [Shecan](https://shecan.ir) DNS servers on Fedora Linux systems.  
Supports global DNS override using `systemd-resolved` as well as custom domain-based overrides using `dnsmasq`.

## Features

- Enable/disable Shecan DNS globally
- Add/remove per-domain DNS rules using `dnsmasq`
- Backup and restore original DNS configuration
- Status inspection of current DNS setup
- Basic error handling and dependency checks

## Usage
### Commands
```bash
shecan start
shecan stop
shecan status
shecan custom add <domain>
shecan custom remove <domain>
shecan custom list
shecan help
```

## Requirements

- `bash`
- `systemd-resolved`
- `dnsmasq` (for per-domain routing)

## Installation

### System-wide (recommended)

```bash
git clone https://github.com/ariadev/shecan.git
cd shecan
chmod +x shecan.sh
sudo mv shecan.sh /usr/local/bin/shecan
