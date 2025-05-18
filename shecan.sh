#!/bin/bash

# Configuration
SERVICE_NAME="shecan-dns"
DNS_SERVERS="185.51.200.2 178.22.122.100"
CONFIG_FILE="/etc/systemd/resolved.conf"
BACKUP_FILE="/etc/systemd/resolved.conf.bak"
CUSTOM_DNS_FILE="/etc/dnsmasq.d/shecan-custom.conf"
DNSMASQ_SERVICE="dnsmasq"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}Error: Requires root. Use sudo.${NC}" >&2
        exit 1
    fi
}

ensure_dnsmasq_installed() {
    if ! command -v dnsmasq &>/dev/null; then
        echo -e "${RED}Error: 'dnsmasq' is not installed.${NC}"
        echo -e "${YELLOW}Please install it using: sudo dnf install dnsmasq${NC}"
        exit 1
    fi
}

backup_config() {
    if [ ! -f "$BACKUP_FILE" ]; then
        cp "$CONFIG_FILE" "$BACKUP_FILE" 2>/dev/null || true
    fi
}

restore_config() {
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$CONFIG_FILE"
    else
        cat <<EOF > "$CONFIG_FILE"
[Resolve]
#DNS=
#FallbackDNS=
#Domains=
#LLMNR=
#MulticastDNS=
#DNSSEC=
#DNSOverTLS=
#Cache=
#DNSStubListener=
EOF
    fi
}

start() {
    check_root
    backup_config

    echo "[Resolve]" > "$CONFIG_FILE"
    echo "DNS=$DNS_SERVERS" >> "$CONFIG_FILE"
    echo "FallbackDNS=1.1.1.1 8.8.8.8" >> "$CONFIG_FILE"
    echo "Domains=~." >> "$CONFIG_FILE"
    echo "DNSOverTLS=no" >> "$CONFIG_FILE"

    systemctl restart systemd-resolved
    echo -e "${GREEN}Shecan DNS has been started with servers: $DNS_SERVERS${NC}"
}

stop() {
    check_root
    restore_config
    systemctl restart systemd-resolved
    echo -e "${YELLOW}Shecan DNS has been stopped. Original DNS settings restored.${NC}"
}

status() {
    current_dns=$(grep -E '^DNS=' "$CONFIG_FILE" 2>/dev/null || echo "DNS=Not configured")
    current_doh=$(grep -E '^DNSOverTLS=' "$CONFIG_FILE" 2>/dev/null || echo "DNSOverTLS=Not configured")

    echo -e "Current DNS Configuration:"
    echo -e "  ${current_dns}"
    echo -e "  ${current_doh}"

    if [[ "$current_dns" == *"185.51.200.2"* ]] && [[ "$current_dns" == *"178.22.122.100"* ]]; then
        echo -e "${GREEN}Status: Shecan DNS is active${NC}"
    else
        echo -e "${YELLOW}Status: Shecan DNS is not active${NC}"
    fi
}

custom_add() {
    check_root
    ensure_dnsmasq_installed

    domain="$1"
    if [ -z "$domain" ]; then
        echo -e "${RED}Error: No domain provided.${NC}"
        exit 1
    fi

    mkdir -p "$(dirname "$CUSTOM_DNS_FILE")"
    echo "server=/$domain/185.51.200.2" >> "$CUSTOM_DNS_FILE"
    echo "server=/$domain/178.22.122.100" >> "$CUSTOM_DNS_FILE"
    systemctl restart $DNSMASQ_SERVICE
    echo -e "${GREEN}Custom DNS rule added for domain: $domain${NC}"
}

custom_remove() {
    check_root
    ensure_dnsmasq_installed

    domain="$1"
    if [ -z "$domain" ]; then
        echo -e "${RED}Error: No domain provided.${NC}"
        exit 1
    fi

    sed -i "/$domain/d" "$CUSTOM_DNS_FILE"
    systemctl restart $DNSMASQ_SERVICE
    echo -e "${YELLOW}Custom DNS rule removed for domain: $domain${NC}"
}

custom_list() {
    if [ -f "$CUSTOM_DNS_FILE" ]; then
        echo -e "${GREEN}Custom DNS entries:${NC}"
        cat "$CUSTOM_DNS_FILE"
    else
        echo -e "${YELLOW}No custom DNS entries found.${NC}"
    fi
}

show_help() {
    echo -e "${GREEN}Shecan DNS Manager${NC}"
    echo "Usage: shecan-dns <command> [options]"
    echo
    echo "Commands:"
    echo "  start              - Enable Shecan DNS servers"
    echo "  stop               - Disable Shecan DNS and restore original settings"
    echo "  status             - Show current DNS configuration status"
    echo "  custom add <url>   - Add custom domain to resolve via Shecan DNS (uses dnsmasq)"
    echo "  custom remove <url>- Remove custom domain rule"
    echo "  custom list        - List all custom DNS domains"
    echo "  help               - Show this help message"
    echo
    echo "Note: Custom DNS needs 'dnsmasq'. Run 'sudo dnf install dnsmasq' if missing."
}

# Main dispatcher
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    custom)
        case "$2" in
            add)
                custom_add "$3"
                ;;
            remove)
                custom_remove "$3"
                ;;
            list)
                custom_list
                ;;
            *)
                echo -e "${RED}Unknown subcommand for custom: '$2'${NC}"
                show_help
                exit 1
                ;;
        esac
        ;;
    help|--help|-h|"")
        show_help
        ;;
    *)
        echo -e "${RED}Unknown command: '$1'${NC}"
        show_help
        exit 1
        ;;
esac

exit 0
