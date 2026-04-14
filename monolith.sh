#!/bin/sh
# shellcheck shell=sh
# ==============================================================================
# OpenWrt Monolith Restoration Script (Version 31.1 - PRODUCTION)
# Target  : OpenWrt 25.12.x / ASUS RT-AX53U (MT7621AT SoC)
# Style   : Google Shell Style Guide (2-space indent, local vars, readonly)
#
# OVERVIEW:
#   This script completely rebuilds the router from a factory state into a
#   highly tuned, lag-free, and secure network. It applies hardware-specific
#   fixes, isolates a guest network ("Dad's network"), enforces ad-blocking
#   via NextDNS, and eliminates bufferbloat using Cake SQM and Airtime
#   Queue Limits (AQL).
#
# BOOTSTRAP STRATEGY:
#   A freshly flashed router has no packages and may have no internet. In
#   PROD mode the WAN requires VLAN 300 tagging (Odido fiber), which only
#   works when physically connected to the ONT — not during initial setup
#   at the workbench. The script solves this by always bringing up a
#   temporary bare-WAN (no VLAN, plain DHCP) connection first to download
#   and install all required packages. After installation succeeds the
#   temporary network is torn down and the real configuration (PROD or DEV)
#   is applied. The user can run the script in PROD mode from their desk
#   connected to any DHCP-capable network, and the final VLAN config only
#   takes effect after the shutdown when the router is moved to the ONT.
#
# DNS ARCHITECTURE:
#   Your devices  -> dnsmasq :53 -> dnsproxy 127.0.0.1:5354 -> NextDNS
#   Dad's devices -> DNAT :53->:5355 -> dnsproxy DAD_LAN_IP:5355 -> NextDNS
#
#   Dad's dnsproxy MUST bind to DAD_LAN_IP (not 127.0.0.1) because the
#   firewall DNAT rule rewrites the destination address to DAD_LAN_IP in
#   PREROUTING. If dnsproxy only listens on loopback the rewritten packet
#   finds no listener and DNS fails silently. Binding to the real interface
#   address makes the DNAT target and the listener match and eliminates the
#   need for the dangerous route_localnet sysctl.
#
# PITFALLS TO AVOID:
#   - Never set txqueuelen or shrink ring buffers on eth0/br-lan. AQL queue
#     shrinking is a Wi-Fi-only concept; applying it to Ethernet causes
#     packet drops under burst load.
#   - Never enable route_localnet. It allows routing to 127.0.0.0/8 across
#     interfaces, which is a security risk. Bind services to real IPs.
#   - Never enable igmp/mld snooping on ANY bridge. MT7621 DSA has known
#     multicast table corruption bugs causing intermittent packet loss. On
#     Dad's bridge specifically, snooping also breaks Chromecast discovery
#     because mDNS multicast (224.0.0.251 / ff02::fb) may be silently
#     dropped if the Chromecast does not send IGMP/MLD membership reports.
#   - Never re-enable GRO on eth0. GRO coalesces packets into 64KB blobs
#     that Cake cannot schedule per-flow, destroying SQM fairness.
#   - Never point Dad's DNAT at 127.0.0.1. Cross-zone loopback DNAT
#     requires route_localnet and is fragile. Use the real subnet IP.
#   - Never keep Ethernet flow control enabled when using SQM. PAUSE frames
#     create a hidden hardware queue that Cake cannot see or manage, adding
#     uncontrolled latency spikes to all flows on the paused link.
# ==============================================================================

# --- SESSION RESILIENCE ---
trap '' HUP

# ==============================================================================
# SECTION 1 — GLOBAL CONFIGURATION (CONSTANTS)
# ==============================================================================

readonly ROOT_PASSWORD='8Qp9kfPA3y2tDm6q4VG#'

# Internet connection (Odido Fiber VLAN 300).
readonly WAN_PHYSICAL_DEVICE='wan'
readonly WAN_VLAN_ID='300'

# MAC cloning (crucial for Odido/Fiber connections).
# If a 5-minute ONT power cycle does not get you online, enter the
# Odido/Zyxel router's MAC address here (e.g., '12:34:56:78:90:ab').
readonly WAN_MAC_CLONE=''

# Traffic shaping (Cake SQM) prevents lag when the network is busy.
# Set these to approximately 92% of your actual speedtest results.
# Example: 250 Mbps plan -> 230000 down / 230000 up.
readonly SQM_DOWNLOAD='80000'
readonly SQM_UPLOAD='90000'

# SQM overhead calculation:
#   PROD: 38 bytes PPPoE/VDSL base + 4 bytes VLAN 802.1Q tag = 42 bytes.
#   DEV:  38 bytes base with no VLAN tag present.
readonly SQM_OVERHEAD_PROD='42'
readonly SQM_OVERHEAD_DEV='38'
readonly SQM_MPU='84'

# Primary network addressing.
readonly LAN_IP='192.168.69.1'
readonly LAN_NETMASK='255.255.255.0'
readonly LAN_DHCP_START='100'
readonly LAN_DHCP_LIMIT='100'

# Primary Wi-Fi credentials.
readonly WIFI_2G_SSID='スノウドロップ'
readonly WIFI_2G_KEY='%y$p#3u7env6MkP^'
readonly WIFI_5G_SSID='レイシア'
readonly WIFI_5G_KEY='eV7d^k#R*qKxQD7@'

# Dad's isolated network.
readonly DAD_SSID='TMNL-86207B'
readonly DAD_KEY='GV3U9H5PGTUHKQRE'
readonly DAD_LAN_IP='192.168.70.1'
readonly DAD_LAN_NETMASK='255.255.255.0'
readonly DAD_DHCP_START='100'
readonly DAD_DHCP_LIMIT='50'

# Wireless channel selection.
# 5 GHz channel 100: high-power DFS channel for maximum wall penetration.
# 2.4 GHz channel 13: least congested channel in the NL/EU regulatory domain.
readonly WIFI_2G_CHAN='13'
readonly WIFI_5G_CHAN='100'

# NextDNS profiles (block ads, trackers, and malicious domains at the DNS
# resolver level before traffic ever reaches the device).
readonly NEXTDNS_ID='8753a1'
readonly DAD_NEXTDNS_ID='5414da'
readonly NEXTDNS_IP1='45.90.28.236'
readonly NEXTDNS_IP2='45.90.30.236'

# Static device reservation. Ensures the phone always receives the same
# internal IP address regardless of DHCP lease expiry.
# CRITICAL: the phone must use "Use device MAC" in Android Wi-Fi settings.
readonly PHONE_10_IP='192.168.69.50'
readonly PHONE_10_MAC='b0:d5:fb:99:17:ad'

# ==============================================================================
# SECTION 2 — CORE UTILITIES
# ==============================================================================

DEV_MODE='false'

# Prints a green-highlighted informational message to stdout.
log() {
  printf '\033[1;32m>>>\033[0m \033[1m%s\033[0m\n' "$1"
}

# Prints a red error message to stderr.
err() {
  printf '\033[1;31m!!! %s\033[0m\n' "$1" >&2
}

# Ensures a UCI section exists, creating it if absent. Handles both named
# sections and anonymous (@-prefixed) section types.
ensure_uci_section() {
  local cfg="$1"
  local sec="$2"
  local typ="$3"

  if echo "${sec}" | grep -q '@'; then
    if ! uci -q get "${cfg}.${sec}" >/dev/null; then
      uci add "${cfg}" "${typ}" >/dev/null
    fi
  else
    if ! uci -q get "${cfg}.${sec}" >/dev/null; then
      uci set "${cfg}.${sec}=${typ}"
    fi
  fi
}

# Searches UCI config for a section where a given option matches a value.
# Returns the fully qualified section identifier (e.g., "firewall.cfg0e1d").
find_uci_section() {
  local cfg="$1"
  local opt="$2"
  local val="$3"

  uci -q show "${cfg}" \
    | grep "\.${opt}=" \
    | grep -w "${val}" \
    | cut -d. -f1,2 \
    | head -n1
}

# Returns the average ping latency in milliseconds to a given HTTPS URL's
# hostname. Returns 9999 if the host is unreachable.
_ping_ms() {
  local url="$1"
  local host rtt

  host="${url#https://}"
  host="${host%%/*}"
  rtt=$(ping -c 3 -W 2 "${host}" 2>/dev/null \
    | awk -F'/' '/rtt|round-trip/ { print int($5) }')

  printf '%s' "${rtt:-9999}"
}

# Fetches the latest OpenWrt release JSON from the GitHub API. Tries
# uclient-fetch first (IPv4-only, then dual-stack), then falls back to
# curl with the same strategy.
_fetch_openwrt_release_json() {
  local url='https://api.github.com/repos/openwrt/openwrt/releases/latest'
  local out=''

  if command -v uclient-fetch >/dev/null 2>&1; then
    out=$(uclient-fetch -4 --no-proxy --no-check-certificate -q -O - -T 30 \
      --user-agent='OpenWrt-Monolith' "${url}" 2>/dev/null) || out=''
    [ -n "${out}" ] && { printf '%s' "${out}"; return 0; }

    out=$(uclient-fetch --no-proxy --no-check-certificate -q -O - -T 30 \
      --user-agent='OpenWrt-Monolith' "${url}" 2>/dev/null) || out=''
    [ -n "${out}" ] && { printf '%s' "${out}"; return 0; }
  fi

  if command -v curl >/dev/null 2>&1; then
    out=$(curl -fsSL --connect-timeout 10 --max-time 30 -4 \
      -A 'OpenWrt-Monolith' --noproxy '*' "${url}" 2>/dev/null) || out=''
    [ -n "${out}" ] && { printf '%s' "${out}"; return 0; }

    out=$(curl -fsSL --connect-timeout 10 --max-time 30 \
      -A 'OpenWrt-Monolith' --noproxy '*' "${url}" 2>/dev/null) || out=''
    [ -n "${out}" ] && { printf '%s' "${out}"; return 0; }
  fi

  return 1
}

# Executes a command with a timeout in seconds. Returns 124 if the command
# exceeds the time limit, otherwise returns the command's exit code.
_timeout() {
  local limit="$1"
  shift

  "$@" &
  local pid=$!
  local count=0

  while [ "${count}" -lt "${limit}" ]; do
    if ! kill -0 "${pid}" 2>/dev/null; then
      wait "${pid}"
      return $?
    fi
    sleep 1
    count=$((count + 1))
  done

  kill -TERM "${pid}" 2>/dev/null
  sleep 1
  kill -9 "${pid}" 2>/dev/null
  return 124
}

# Returns the effective WAN interface name based on the current mode.
# PROD returns "wan.300" (VLAN-tagged for Odido fiber).
# DEV returns "wan" (bare device for bench testing behind any DHCP source).
_wan_iface() {
  if [ "${DEV_MODE}" = 'true' ]; then
    printf '%s' "${WAN_PHYSICAL_DEVICE}"
  else
    printf '%s' "${WAN_PHYSICAL_DEVICE}.${WAN_VLAN_ID}"
  fi
}

# Parses command-line arguments. Supports -d/--dev for development mode.
parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -d|--dev) DEV_MODE='true'; shift ;;
      *) err "Unknown option: $1"; exit 1 ;;
    esac
  done
}

# ==============================================================================
# SECTION 3 — RESTORATION PHASES
# ==============================================================================

# Phase 0: Brings up a temporary bare-WAN (no VLAN, plain DHCP) network
# so package installation can succeed regardless of the final target mode.
# In PROD mode the final VLAN 300 config only works on the Odido ONT, but
# the user is at their workbench during initial setup. This phase uses
# DEV-style networking just long enough to download packages, then tears
# it down so the real config can be applied cleanly by later phases.
phase_bootstrap() {
  log "Phase 0 | Bootstrapping temporary network for package installation..."

  # Ensure minimal config files exist so UCI operations do not error.
  local cfg
  for cfg in system network wireless dhcp firewall \
             sqm dnsproxy banip dropbear attendedsysupgrade; do
    [ -f "/etc/config/${cfg}" ] || touch "/etc/config/${cfg}"
  done

  # Check if every required package is already present.
  local missing=""
  local pkg
  for pkg in dnsproxy sqm-scripts ethtool jsonfilter kmod-tcp-bbr \
             kmod-sched-core uclient-fetch banip owut \
             luci-app-sqm luci-app-banip luci-app-attendedsysupgrade; do
    apk info -e "${pkg}" >/dev/null 2>&1 || missing="${missing} ${pkg}"
  done

  if [ -z "${missing}" ]; then
    log "  All required packages are already installed."
    return 0
  fi

  log "  Missing packages:${missing}"
  log "  Bringing up temporary bare-WAN network..."

  # Write a minimal temporary network config: bare WAN device (no VLAN),
  # plain DHCP, with ISP-provided DNS enabled. This works behind any DHCP
  # source — the user's desk switch, a spare router, or even the ONT.
  cat << 'TMPNET' > /etc/config/network
config globals 'globals'

config interface 'loopback'
	option device 'lo'
	option proto 'static'
	option ipaddr '127.0.0.1'
	option netmask '255.0.0.0'

config interface 'wan'
	option device 'wan'
	option proto 'dhcp'
	option peerdns '1'
TMPNET

  # Allow dnsmasq to forward to ISP DNS during the bootstrap period by
  # removing noresolv and any explicit server directives.
  uci -q delete dhcp.@dnsmasq[0].noresolv 2>/dev/null
  uci -q delete dhcp.@dnsmasq[0].server 2>/dev/null
  uci commit dhcp 2>/dev/null

  /etc/init.d/network restart 2>/dev/null
  sleep 2
  /etc/init.d/firewall restart 2>/dev/null
  /etc/init.d/dnsmasq restart 2>/dev/null

  # Wait for the temporary WAN to obtain a DHCP lease.
  log "  Waiting for DHCP lease (up to 30 seconds)..."
  local attempt=0
  while [ "${attempt}" -lt 15 ]; do
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
      log "  Temporary network is online (attempt $((attempt + 1)))."
      break
    fi
    attempt=$((attempt + 1))
    sleep 2
  done

  if [ "${attempt}" -ge 15 ]; then
    err "WARNING: No internet after 30 seconds on temporary network."
    err "Connect the WAN port to any DHCP source and re-run the script."
    err "Continuing — pre-installed packages will still be configured."
  fi

  # Install all missing packages.
  apk update >/dev/null 2>&1
  log "  Installing:${missing}"
  # shellcheck disable=SC2086
  apk add --quiet ${missing} >/dev/null 2>&1 \
    || err "WARNING: Some packages failed to install."

  # Verify installation results.
  local still_missing=""
  for pkg in dnsproxy sqm-scripts ethtool jsonfilter kmod-tcp-bbr \
             kmod-sched-core uclient-fetch banip owut \
             luci-app-sqm luci-app-banip luci-app-attendedsysupgrade; do
    apk info -e "${pkg}" >/dev/null 2>&1 \
      || still_missing="${still_missing} ${pkg}"
  done

  if [ -n "${still_missing}" ]; then
    err "WARNING: Still missing after install:${still_missing}"
    err "The script will continue but some features may not work."
  else
    log "  All packages installed successfully."
  fi

  # Tear down the temporary network. The real config is written by
  # phase_cleanup() and phase_network().
  log "  Tearing down temporary bootstrap network..."
  /etc/init.d/network stop 2>/dev/null
  sleep 1
}

# Phase 0.5: Removes all artifacts from previous runs to guarantee an
# idempotent restoration. Resets firewall, SQM, BanIP, wireless, network,
# and DHCP configs to a known-good baseline before any phase writes.
phase_cleanup() {
  log "Phase 0.5 | Clearing old artifacts for a clean slate..."

  local svc
  for svc in irq-tuning gro-fix disable-eee aql-tuning dnsproxy; do
    if [ -x "/etc/init.d/${svc}" ]; then
      "/etc/init.d/${svc}" disable 2>/dev/null
    fi
  done

  rm -f /etc/sysctl.d/99-monolith.conf \
        /etc/init.d/irq-tuning \
        /etc/init.d/disable-eee \
        /etc/init.d/gro-fix \
        /etc/init.d/aql-tuning \
        /etc/init.d/dnsproxy \
        /etc/uci-defaults/99-monolith-finalizer \
        /etc/monolith-brlan-pin

  if [ -f /rom/etc/config/firewall ]; then
    cp /rom/etc/config/firewall /etc/config/firewall
  else
    log "  /rom/etc/config/firewall is missing; writing embedded minimal."
    cat << 'FWBASE' > /etc/config/firewall
config defaults
	option syn_flood '1'
	option input 'ACCEPT'
	option output 'ACCEPT'
	option forward 'REJECT'
	option disable_ipv6 '0'

config zone
	option name 'lan'
	option input 'ACCEPT'
	option output 'ACCEPT'
	option forward 'ACCEPT'
	list network 'lan'

config zone
	option name 'wan'
	option input 'REJECT'
	option output 'ACCEPT'
	option forward 'REJECT'
	option masq '1'
	option mtu_fix '1'
	list network 'wan'
	list network 'wan6'

config forwarding
	option src 'lan'
	option dest 'wan'

config include
	option path '/etc/firewall.user'
	option reload '1'
FWBASE
  fi

  if [ -f /rom/etc/config/sqm ]; then
    cp /rom/etc/config/sqm /etc/config/sqm
  else
    : > /etc/config/sqm
  fi

  if [ -f /rom/etc/config/banip ]; then
    cp /rom/etc/config/banip /etc/config/banip
  else
    : > /etc/config/banip
  fi

  if [ -f /rom/etc/config/attendedsysupgrade ]; then
    cp /rom/etc/config/attendedsysupgrade /etc/config/attendedsysupgrade
  else
    : > /etc/config/attendedsysupgrade
  fi

  : > /etc/config/dnsproxy

  # Enable packet_steering so the kernel can spread softirq load across
  # cores. The IRQ init script created in phase_stability() overrides the
  # RPS masks at START=99 with exact per-interface pinning.
  cat << 'EOF' > /etc/config/network
config globals 'globals'
	option packet_steering '1'
EOF

  # Establish a clean DHCP baseline. The noresolv option is set in
  # phase_dhcp() so dnsmasq never reads /tmp/resolv.conf.auto.
  cat << 'EOF' > /etc/config/dhcp
config dnsmasq
	option domainneeded '1'
	option localise_queries '1'
	option rebind_protection '1'
	option rebind_localhost '1'
	option local '/lan/'
	option domain 'lan'
	option expandhosts '1'
	option authoritative '1'
	option readethers '1'
	option leasefile '/tmp/dhcp.leases'
	option localservice '1'
EOF

  rm -f /etc/config/wireless
  wifi config > /etc/config/wireless
}

# Phase 1: Applies system-level settings including hostname, timezone,
# NTP sources, root password, CPU governor, IRQ/RPS pinning for the
# MT7621 dual-core SoC, kernel sysctl tuning, and LuCI web interface
# binding.
phase_system() {
  log "Phase 1 | Applying system and kernel optimizations..."

  ensure_uci_section system "@system[0]" system
  uci set system.@system[0].hostname='OpenWrt'

  # Amsterdam timezone: CET (UTC+1) in winter, CEST (UTC+2) in summer.
  # M3.5.0 means the last Sunday of March at 02:00.
  # M10.5.0/3 means the last Sunday of October at 03:00.
  uci set system.@system[0].zonename='Europe/Amsterdam'
  uci set system.@system[0].timezone='CET-1CEST,M3.5.0,M10.5.0/3'

  # Reduce the system log to a RAM-only ring buffer. Prevents flash wear
  # from continuous log writes and reduces I/O overhead.
  uci set system.@system[0].log_size='64'
  uci set system.@system[0].log_proto='udp'
  uci -q delete system.@system[0].log_file

  if [ -n "${ROOT_PASSWORD}" ]; then
    printf '%s\n%s\n' "${ROOT_PASSWORD}" "${ROOT_PASSWORD}" \
      | passwd root >/dev/null 2>&1 \
      || err "WARNING: Failed to set root password."
  fi

  # NTP: privacy-respecting EU authoritative sources first, then the
  # OpenWrt volunteer pool as a fallback.
  ensure_uci_section system ntp timeserver
  uci -q delete system.ntp.server
  # SIDN Labs (Stichting Internet Domeinregistratie Nederland) — the
  # registry operator for all .nl domains, located in Arnhem, Netherlands.
  # Stratum 1 source synchronized to GPS and the Dutch national time
  # standard at VSL (Van Swinden Laboratorium).
  uci add_list system.ntp.server='194.171.167.130'
  # PTB (Physikalisch-Technische Bundesanstalt) — Germany's national
  # metrology institute in Braunschweig, Lower Saxony. Maintains the
  # official German time standard UTC(PTB) via caesium fountain clocks.
  # One of the most accurate public NTP sources in Europe.
  uci add_list system.ntp.server='192.53.103.108'
  # OpenWrt community NTP pool (global anycast). Used only as fallback
  # if both European primary sources are unreachable.
  uci add_list system.ntp.server='0.openwrt.pool.ntp.org'
  uci add_list system.ntp.server='1.openwrt.pool.ntp.org'
  uci set system.ntp.enabled='1'
  uci set system.ntp.enable_server='0'

  # Set the CPU frequency governor to schedutil so it ramps to full speed
  # instantly under load (gaming) and drops to save power when idle.
  local gov usb
  for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
    [ -f "${gov}" ] && echo "schedutil" > "${gov}"
  done

  # Enable USB autosuspend to save power on unused USB ports.
  for usb in /sys/bus/usb/devices/usb*/power/control; do
    [ -f "${usb}" ] && echo "auto" > "${usb}" 2>/dev/null
  done

  # Disable irqbalance. The MT7621 only has 4 logical CPUs and manual IRQ
  # pinning produces better cache locality than the daemon's heuristics.
  if [ -f /etc/init.d/irqbalance ]; then
    /etc/init.d/irqbalance disable 2>/dev/null
    /etc/init.d/irqbalance stop   2>/dev/null
  fi

  # --------------------------------------------------------------------------
  # IRQ + RPS PINNING for the MT7621 (2 cores x 2 hardware threads = 4 CPUs):
  #   CPU0 = Core 0, Thread 0 (mask 0x1)
  #   CPU1 = Core 0, Thread 1 (mask 0x2)
  #   CPU2 = Core 1, Thread 0 (mask 0x4)
  #   CPU3 = Core 1, Thread 1 (mask 0x8)
  #
  # Strategy:
  #   Wi-Fi  IRQ -> CPU0 (Core 0): radio processing on Core 0.
  #   Eth    IRQ -> CPU2 (Core 1): wired NAT/SQM on Core 1.
  #   br-lan RPS -> mask 0x6 (CPU1+CPU2): bridge softirq spreads across
  #     both physical cores without L1/L2 cache thrashing.
  # --------------------------------------------------------------------------
  cat << 'IRQEOF' > /etc/init.d/irq-tuning
#!/bin/sh /etc/rc.common
START=99
start() {
  [ -d /proc/irq ] || return

  # Pin Wi-Fi interrupts to CPU0 (Core 0, Thread 0).
  local irq
  for irq in $(awk -F: '/mt7915|mt76/ {print $1}' /proc/interrupts); do
    echo 1 > "/proc/irq/${irq##* }/smp_affinity" 2>/dev/null
  done

  # Pin wired Ethernet interrupts to CPU2 (Core 1, Thread 0).
  for irq in $(awk -F: '/eth0|mtk_eth|mtk_soc_eth/ {print $1}' /proc/interrupts); do
    echo 4 > "/proc/irq/${irq##* }/smp_affinity" 2>/dev/null
  done

  # Keep Ethernet RPS/XPS on Core 1 to match the IRQ affinity.
  if [ -d /sys/class/net/eth0 ]; then
    local q
    for q in /sys/class/net/eth0/queues/rx-*/rps_cpus; do
      echo 4 > "${q}" 2>/dev/null
    done
    for q in /sys/class/net/eth0/queues/tx-*/xps_cpus; do
      echo 4 > "${q}" 2>/dev/null
    done
  fi

  # Spread bridge softirq across CPU1 + CPU2 (one per physical core).
  if [ -d /sys/class/net/br-lan/queues ]; then
    local q
    for q in /sys/class/net/br-lan/queues/rx-*/rps_cpus; do
      echo 6 > "${q}" 2>/dev/null
    done
  fi
}
IRQEOF
  chmod +x /etc/init.d/irq-tuning
  /etc/init.d/irq-tuning enable

  # --------------------------------------------------------------------------
  # KERNEL SYSCTL TUNING
  #
  # Written as a single operation to prevent partial overwrites.
  # --------------------------------------------------------------------------
  cat << 'SYSEOF' > /etc/sysctl.d/99-monolith.conf
# BBR congestion control with fq qdisc. BBR provides higher throughput
# and lower latency than Cubic on paths with any bufferbloat.
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr

# Disable slow start after idle to prevent throughput collapse on
# connections that pause briefly (e.g., web browsing between clicks).
net.ipv4.tcp_slow_start_after_idle=0

# Enable MTU probing to discover the real path MTU and avoid fragmentation.
net.ipv4.tcp_mtu_probing=1

# Reduce FIN-WAIT-2 timeout from 60s to 15s to reclaim sockets faster.
net.ipv4.tcp_fin_timeout=15

# Increase SYN backlog and connection queue for burst handling.
net.ipv4.tcp_max_syn_backlog=2048
net.core.somaxconn=2048

# Enlarge socket buffer limits. The kernel auto-tunes within these bounds;
# higher limits allow TCP to scale to the full link speed.
net.core.rmem_max=8388608
net.core.wmem_max=8388608
net.core.rmem_default=262144
net.core.wmem_default=262144
net.ipv4.tcp_rmem=4096 87380 8388608
net.ipv4.tcp_wmem=4096 65536 8388608

# Increase network device backlog and budget so the CPU can drain incoming
# packets faster during bursts without dropping.
net.core.netdev_max_backlog=4096
net.core.netdev_budget=512
net.core.netdev_budget_usecs=8000

# Lower the TCP not-sent low water mark to reduce transmit latency by
# waking userspace earlier when the send buffer drains.
net.ipv4.tcp_notsent_lowat=16384

# Disable kernel IPv6 on the WAN device. Without IPv6 upstream, this
# stops the kernel from processing neighbor discovery, router solicitation,
# and multicast listener reports on every inbound packet.
net.ipv6.conf.wan.disable_ipv6=1
net.ipv6.conf.wan.autoconf=0
net.ipv6.conf.wan.accept_ra=0
SYSEOF
  sysctl -p /etc/sysctl.d/99-monolith.conf > /dev/null 2>&1

  # Force LuCI to IPv4-only listeners to prevent page load failures when
  # the browser tries IPv6 connections that time out.
  ensure_uci_section uhttpd main uhttpd
  uci set uhttpd.main.rfc1413_ident='0'
  uci -q delete uhttpd.main.listen_http
  uci add_list uhttpd.main.listen_http='0.0.0.0:80'
  uci -q delete uhttpd.main.listen_https
  uci add_list uhttpd.main.listen_https='0.0.0.0:443'
  uci set uhttpd.main.max_requests='10'
  uci set uhttpd.main.max_connections='200'
  uci set uhttpd.main.network_timeout='10'

  uci commit uhttpd
  uci commit system
}

# Phase 1.5: Hardens the Dropbear SSH server. Binds exclusively to the
# LAN interface so it is never exposed to the internet.
phase_dropbear() {
  log "Phase 1.5 | Hardening SSH (Dropbear) security profile..."

  ensure_uci_section dropbear "@dropbear[0]" dropbear
  uci set dropbear.@dropbear[0].PasswordAuth='on'
  uci set dropbear.@dropbear[0].RootPasswordAuth='on'
  uci set dropbear.@dropbear[0].Port='22'
  uci set dropbear.@dropbear[0].IdleTimeout='600'
  uci set dropbear.@dropbear[0].MaxAuthTries='5'

  # Bind only to LAN so SSH is never reachable from the WAN side.
  uci set dropbear.@dropbear[0].DirectInterface='lan'
  uci -q delete dropbear.@dropbear[0].Interface

  uci commit dropbear
}

# Phase 2: Deploys hardware stability fixes for the MT7621 SoC. Creates
# three init.d services at START=99:
#   gro-fix:     Disables GRO so Cake sees individual packets.
#   disable-eee: Disables EEE and flow control on all ports.
#   aql-tuning:  Restricts Wi-Fi airtime queue depth (Wi-Fi only).
phase_stability() {
  log "Phase 2 | Deploying MT7621 hardware stability fixes..."

  # GRO coalesces dozens of small packets into 64KB super-packets before
  # they reach the Cake qdisc. Cake cannot fairly schedule these blobs
  # per-flow, so bufferbloat returns. Disabling GRO and GRO-list forces
  # individual packet delivery to Cake.
  cat << 'GROEOF' > /etc/init.d/gro-fix
#!/bin/sh /etc/rc.common
START=99
start() {
  local etool
  etool=$(command -v ethtool)
  [ -x "${etool}" ] || return 0

  if [ -d /sys/class/net/eth0 ]; then
    "${etool}" -K eth0 gro off 2>/dev/null
    "${etool}" -K eth0 rx-gro-list off 2>/dev/null
  fi
}
GROEOF
  chmod +x /etc/init.d/gro-fix
  /etc/init.d/gro-fix enable

  # EEE (Energy Efficient Ethernet) adds latency spikes during wake-from-
  # sleep transitions that are incompatible with low-latency gaming.
  #
  # Flow control (IEEE 802.3x PAUSE frames) is disabled on ALL ports.
  # When a switch port sends a PAUSE frame it freezes ALL traffic on that
  # link including latency-sensitive gaming packets. This creates a hidden
  # hardware queue that Cake cannot see or manage. At our speeds (~90 Mbps
  # shaped) the MT7621 CPU never saturates its NAT path, so there is no
  # risk of CPU overflow that flow control would protect against. Cake is
  # the sole queue manager for WAN traffic, and LAN-to-LAN transfers are
  # bridged at Layer 2 by the hardware switch without CPU involvement.
  cat << 'EEEEOF' > /etc/init.d/disable-eee
#!/bin/sh /etc/rc.common
START=99
start() {
  local etool
  etool=$(command -v ethtool)
  [ -x "${etool}" ] || return 0

  # Wait for PHY link negotiation to complete after boot.
  sleep 5

  # Disable EEE and flow control on every port.
  local dev
  for dev in wan lan1 lan2 lan3; do
    if [ -d "/sys/class/net/${dev}" ]; then
      "${etool}" --set-eee "${dev}" eee off tx-lpi off 2>/dev/null
      "${etool}" -A "${dev}" rx off tx off 2>/dev/null
    fi
  done
}
EEEEOF
  chmod +x /etc/init.d/disable-eee
  /etc/init.d/disable-eee enable

  # Airtime Queue Limits (AQL) restrict how many bytes can be queued in
  # the Wi-Fi hardware's transmit buffer. Without this the radio buffers
  # hundreds of milliseconds of traffic, causing lag even when Cake shapes
  # the WAN perfectly. Applied to wireless interfaces only — Ethernet has
  # no airtime contention and shrinking its queues causes packet drops.
  cat << 'AQLEOF' > /etc/init.d/aql-tuning
#!/bin/sh /etc/rc.common
START=99
start() {
  local phy_dir phy_name aql_limit ac

  for phy_dir in /sys/kernel/debug/ieee80211/phy*; do
    [ -f "${phy_dir}/aql_txq_limit" ] || continue
    phy_name="${phy_dir##*/}"

    # 2.4 GHz uses a slow shared medium where a strict AQL limit prevents
    # head-of-line blocking. 5 GHz has more available airtime so a looser
    # limit preserves throughput.
    if iw "${phy_name}" info 2>/dev/null | grep -q '2412'; then
      aql_limit=2500
    else
      aql_limit=8000
    fi

    for ac in 0 1 2 3; do
      echo "${ac} ${aql_limit} ${aql_limit}" \
        > "${phy_dir}/aql_txq_limit" 2>/dev/null
    done
  done

  # Shrink the kernel transmit queue on Wi-Fi interfaces only.
  local wlan wlan_name
  for wlan in /sys/class/net/wlan*; do
    [ -d "${wlan}" ] || continue
    wlan_name="${wlan##*/}"
    ip link set dev "${wlan_name}" txqueuelen 512 2>/dev/null
  done
}
AQLEOF
  chmod +x /etc/init.d/aql-tuning
  /etc/init.d/aql-tuning enable
}

# Phase 3: Builds the complete network topology.
#   - Loopback (lo).
#   - br-lan: Primary LAN bridge with all physical LAN ports.
#   - WAN: VLAN 300 tagged (PROD) or bare device (DEV).
#   - wan6: Explicitly disabled to silence firewall zone warnings.
#   - LAN: Static IP, no IPv6 stack (Matter uses kernel link-local).
#   - br-lan_dad: Empty bridge for Dad's isolated Wi-Fi network.
#   - lan_dad: Static IP on Dad's bridge.
phase_network() {
  log "Phase 3 | Rebuilding network and fiber configurations..."

  # Loopback interface.
  uci set network.loopback=interface
  uci set network.loopback.device='lo'
  uci set network.loopback.proto='static'
  uci set network.loopback.ipaddr='127.0.0.1'
  uci set network.loopback.netmask='255.0.0.0'

  # Discover LAN port names from the board definition.
  local ports p
  ports=$(jsonfilter -i /etc/board.json -e "@.network.lan.ports[*]")
  [ -z "${ports}" ] && ports="lan1 lan2 lan3"

  # Primary LAN bridge. Multicast snooping is disabled because the MT7621
  # DSA driver has known table corruption bugs that cause intermittent
  # packet loss. On a small home network multicast flooding costs only a
  # few KB/s. Matter, mDNS, and Chromecast all use multicast and benefit
  # from unrestricted flooding.
  uci set network.br_lan=device
  uci set network.br_lan.name='br-lan'
  uci set network.br_lan.type='bridge'
  uci set network.br_lan.force_link='1'
  uci set network.br_lan.igmp_snooping='0'
  uci set network.br_lan.mld_snooping='0'
  uci -q delete network.br_lan.ports
  for p in ${ports}; do
    uci add_list network.br_lan.ports="${p}"
  done

  # Device entries for each physical LAN port.
  local port_dev
  for port_dev in lan1 lan2 lan3; do
    uci set "network.${port_dev}_dev=device"
    uci set "network.${port_dev}_dev.name=${port_dev}"
  done

  # WAN physical device. MAC cloning is applied at the device layer only,
  # which is the authoritative location for DSA. Setting it on the
  # interface is redundant and ignored by netifd.
  uci set network.wan_dev=device
  uci set network.wan_dev.name="${WAN_PHYSICAL_DEVICE}"
  if [ -n "${WAN_MAC_CLONE}" ]; then
    uci set network.wan_dev.macaddr="${WAN_MAC_CLONE}"
  fi

  # WAN logical interface. Uses the shared _wan_iface() helper so the
  # device name is computed in exactly one place for both this phase and
  # phase_sqm().
  local wan_if
  wan_if=$(_wan_iface)

  uci set network.wan=interface
  uci set network.wan.device="${wan_if}"
  uci set network.wan.proto='dhcp'
  uci set network.wan.hostname='ASUS-Router'
  uci set network.wan.peerdns='0'
  uci set network.wan.ipv6='0'

  if [ "${DEV_MODE}" = 'true' ]; then
    log "  DEV MODE: WAN device set to '${wan_if}' (no VLAN)."
  else
    log "  PRODUCTION: WAN device set to '${wan_if}' (VLAN ${WAN_VLAN_ID})."
  fi

  # wan6: Explicit disabled interface. The default firewall WAN zone lists
  # 'wan6' as a member network. Without this interface existing, nftables
  # logs warnings on every firewall reload.
  uci set network.wan6=interface
  uci set network.wan6.device="${WAN_PHYSICAL_DEVICE}"
  uci set network.wan6.proto='none'

  # Primary LAN. No ULA prefix, RA, or DHCPv6. Matter smart home devices
  # use kernel link-local IPv6 which is always enabled in the Linux kernel
  # without any explicit configuration.
  uci set network.lan=interface
  uci set network.lan.device='br-lan'
  uci set network.lan.proto='static'
  uci set network.lan.ipaddr="${LAN_IP}"
  uci set network.lan.netmask="${LAN_NETMASK}"
  uci set network.lan.delegate='0'

  # Dad's isolated bridge. Has no physical ports — it exists purely as a
  # wireless-only network with its own subnet, DHCP pool, and DNS profile.
  #
  # Multicast snooping MUST be explicitly disabled here too. Without these
  # options the kernel may default to snooping enabled, which silently
  # drops mDNS multicast (224.0.0.251 / ff02::fb) to ports that have not
  # sent IGMP/MLD membership reports. The Google TV Chromecast dongle does
  # not reliably send these reports, so snooping breaks cast discovery
  # even though both devices are on the same bridge.
  uci set network.br_dad=device
  uci set network.br_dad.name='br-lan_dad'
  uci set network.br_dad.type='bridge'
  uci set network.br_dad.bridge_empty='1'
  uci set network.br_dad.igmp_snooping='0'
  uci set network.br_dad.mld_snooping='0'

  uci set network.lan_dad=interface
  uci set network.lan_dad.proto='static'
  uci set network.lan_dad.device='br-lan_dad'
  uci set network.lan_dad.ipaddr="${DAD_LAN_IP}"
  uci set network.lan_dad.netmask="${DAD_LAN_NETMASK}"
  uci set network.lan_dad.delegate='0'

  uci commit network
}

# Phase 4: Configures DHCP for both the primary LAN and Dad's network.
# Puts dnsmasq into noresolv mode so all queries go through dnsproxy,
# filters AAAA responses to prevent IPv6 timeout delays, and creates a
# static lease for the phone.
phase_dhcp() {
  log "Phase 4 | Configuring DHCP and static addressing..."

  ensure_uci_section dhcp "@dnsmasq[0]" dnsmasq

  # noresolv prevents dnsmasq from reading /tmp/resolv.conf.auto. All DNS
  # queries are forwarded exclusively to dnsproxy via the server directive.
  uci set dhcp.@dnsmasq[0].noresolv='1'
  uci set dhcp.@dnsmasq[0].rebind_protection='1'
  uci set dhcp.@dnsmasq[0].localise_queries='1'
  uci set dhcp.@dnsmasq[0].boguspriv='1'
  uci set dhcp.@dnsmasq[0].domainneeded='1'

  # Block AAAA (IPv6 DNS) responses. Matter smart home devices use mDNS
  # directly between devices on link-local IPv6 — they never query dnsmasq
  # for AAAA records. Chromecast discovery also uses mDNS at Layer 2, not
  # dnsmasq DNS lookups. Filtering AAAA prevents apps from trying global
  # IPv6 addresses, timing out, and only then falling back to IPv4.
  uci set dhcp.@dnsmasq[0].filter_aaaa='1'

  # Disable dnsmasq's internal cache. All caching is handled by dnsproxy
  # (8 MB cache with a 300-second minimum TTL).
  uci set dhcp.@dnsmasq[0].cachesize='0'

  # Primary LAN DHCP pool.
  uci set dhcp.lan=dhcp
  uci set dhcp.lan.interface='lan'
  uci set dhcp.lan.start="${LAN_DHCP_START}"
  uci set dhcp.lan.limit="${LAN_DHCP_LIMIT}"
  uci set dhcp.lan.leasetime='12h'
  uci set dhcp.lan.ra='disabled'
  uci set dhcp.lan.dhcpv6='disabled'

  # Static lease: the phone always receives 192.168.69.50. This IP is
  # outside the DHCP pool range and is used in firewall rules to exempt
  # the phone from DNS interception.
  uci set dhcp.pixelpro=host
  uci set dhcp.pixelpro.name='Pixel-10-Pro'
  uci set dhcp.pixelpro.ip="${PHONE_10_IP}"
  uci set dhcp.pixelpro.mac="${PHONE_10_MAC}"

  # Dad's DHCP pool. DHCP option 6 tells Dad's devices to use the router's
  # Dad-subnet IP (192.168.70.1) as their DNS server. Those queries arrive
  # on port 53 and are DNAT'd to port 5355 by the firewall, landing on
  # Dad's dedicated dnsproxy instance bound to that same address.
  uci set dhcp.lan_dad=dhcp
  uci set dhcp.lan_dad.interface='lan_dad'
  uci set dhcp.lan_dad.start="${DAD_DHCP_START}"
  uci set dhcp.lan_dad.limit="${DAD_DHCP_LIMIT}"
  uci set dhcp.lan_dad.leasetime='12h'
  uci set dhcp.lan_dad.ra='disabled'
  uci set dhcp.lan_dad.dhcpv6='disabled'
  uci add_list dhcp.lan_dad.dhcp_option="6,${DAD_LAN_IP}"

  # Disable odhcpd's main DHCP role (dnsmasq handles everything) but keep
  # it enabled so it can be activated later if IPv6 is ever needed.
  ensure_uci_section dhcp odhcpd odhcpd
  uci set dhcp.odhcpd.maindhcp='0'
  uci set dhcp.odhcpd.loglevel='4'
  uci set dhcp.odhcpd.leasefile='/dev/null'

  uci commit dhcp
  /etc/init.d/odhcpd enable 2>/dev/null
}

# Phase 5: Deploys two NextDNS profiles via DNS-over-QUIC using dnsproxy.
#   - Your profile (port 5354 on 127.0.0.1): used by dnsmasq for all LAN.
#   - Dad's profile (port 5355 on DAD_LAN_IP): receives DNAT'd queries
#     from Dad's firewall zone, providing separate ad-blocking rules.
phase_dns() {
  log "Phase 5 | Deploying NextDNS via DNS-over-QUIC..."

  local d_prog
  d_prog=$(command -v dnsproxy)
  [ -z "${d_prog}" ] && d_prog="/usr/bin/dnsproxy"

  # Write the procd init script. The PROG path is expanded at write time;
  # all runtime variables (\$cfg, \$1, etc.) are escaped to survive.
  cat << EOF > /etc/init.d/dnsproxy
#!/bin/sh /etc/rc.common
START=99
USE_PROCD=1
PROG=${d_prog}

start_service() {
  config_load dnsproxy
  config_foreach start_instance dnsproxy
}

start_instance() {
  local cfg="\$1" enabled addr port
  config_get_bool enabled "\$cfg" 'enabled' '0'
  [ "\$enabled" -eq 1 ] || return 0

  config_get addr "\$cfg" 'listen_addr' '127.0.0.1'
  config_get port "\$cfg" 'listen_port' '5354'

  procd_open_instance "\$cfg"
  procd_set_param command "\$PROG"
  procd_append_param command --listen "\$addr"
  procd_append_param command --port "\$port"

  procd_append_param command --cache
  procd_append_param command --cache-size 8388608
  procd_append_param command --cache-min-ttl 300
  procd_append_param command --cache-max-ttl 3600
  procd_append_param command --upstream-mode=parallel
  procd_append_param command --hosts-file-enabled=false
  procd_append_param command --ipv6-disabled

  config_list_foreach "\$cfg" upstream _add_upstream
  config_list_foreach "\$cfg" bootstrap _add_bootstrap

  procd_set_param respawn
  procd_set_param stderr 1
  procd_close_instance
}

_add_upstream()  { procd_append_param command --upstream "\$1"; }
_add_bootstrap() { procd_append_param command --bootstrap "\$1"; }

service_triggers() { procd_add_reload_trigger "dnsproxy"; }
EOF
  chmod +x /etc/init.d/dnsproxy
  /etc/init.d/dnsproxy enable

  # Configure the two dnsproxy instances via UCI.
  touch /etc/config/dnsproxy
  uci -q delete dnsproxy.mine
  uci -q delete dnsproxy.dad

  # Your NextDNS profile. Listens on loopback because only dnsmasq (also
  # running on localhost) forwards queries here.
  uci set dnsproxy.mine=dnsproxy
  uci set dnsproxy.mine.enabled='1'
  uci set dnsproxy.mine.listen_addr='127.0.0.1'
  uci set dnsproxy.mine.listen_port='5354'
  uci add_list dnsproxy.mine.upstream="quic://OpenWrt-${NEXTDNS_ID}.dns.nextdns.io"
  uci add_list dnsproxy.mine.bootstrap="${NEXTDNS_IP1}"
  uci add_list dnsproxy.mine.bootstrap="${NEXTDNS_IP2}"

  # Dad's NextDNS profile. MUST listen on DAD_LAN_IP (not 127.0.0.1)
  # because the firewall DNAT rule rewrites the destination address to
  # DAD_LAN_IP:5355 in PREROUTING. If this listened on loopback the
  # DNAT'd packets would find no listener and DNS would silently fail
  # for Dad's entire network.
  uci set dnsproxy.dad=dnsproxy
  uci set dnsproxy.dad.enabled='1'
  uci set dnsproxy.dad.listen_addr="${DAD_LAN_IP}"
  uci set dnsproxy.dad.listen_port='5355'
  uci add_list dnsproxy.dad.upstream="quic://DadNet-${DAD_NEXTDNS_ID}.dns.nextdns.io"
  uci add_list dnsproxy.dad.bootstrap="${NEXTDNS_IP1}"
  uci add_list dnsproxy.dad.bootstrap="${NEXTDNS_IP2}"

  # Point dnsmasq at your dnsproxy instance for all LAN queries.
  uci -q delete dhcp.@dnsmasq[0].server
  uci add_list dhcp.@dnsmasq[0].server='127.0.0.1#5354'

  uci commit dnsproxy
  uci commit dhcp
}

# Phase 6: Configures all Wi-Fi radios and SSIDs.
#   - 2.4 GHz: Your network (sae-mixed for broad compatibility).
#   - 5 GHz:   Your network (pure WPA3-SAE, maximum security).
#   - 5 GHz:   Dad's network (sae-mixed for Google TV dongle compat).
#
# Dad's network is on 5 GHz only (no 2.4 GHz SSID). Casting between
# Dad's phone and TV dongle works because both are on the same bridge
# (br-lan_dad) with multicast snooping disabled — mDNS/SSDP discovery
# stays at Layer 2 and never touches the firewall.
phase_wireless() {
  log "Phase 6 | Restoring Wi-Fi 6 infrastructure..."

  # Remove all existing wireless interfaces for a clean rebuild.
  while uci -q delete wireless.@wifi-iface[0]; do :; done

  # Detect radio names by band.
  local r2g="" r5g="" devices dev band
  devices=$(uci -q show wireless \
    | grep "=wifi-device" | cut -d. -f2 | cut -d= -f1)

  for dev in ${devices}; do
    band=$(uci -q get "wireless.${dev}.band")
    if [ "${band}" = "2g" ]; then r2g="${dev}"
    elif [ "${band}" = "5g" ]; then r5g="${dev}"; fi
  done

  # In DEV mode, override Dad's credentials with test values so the
  # production SSID does not appear on the bench network.
  local d_ssid="${DAD_SSID}" d_key="${DAD_KEY}"
  if [ "${DEV_MODE}" = 'true' ]; then
    log "  DEV MODE: Overriding Dad's SSID with 'InfraTest'."
    d_ssid='InfraTest'
    d_key='InfraTest'
  fi

  # ---------- 2.4 GHz RADIO ----------
  if [ -n "${r2g}" ]; then
    log "  Configuring 2.4 GHz radio: ${r2g}"

    uci set "wireless.${r2g}.disabled=0"
    uci set "wireless.${r2g}.country=NL"
    uci set "wireless.${r2g}.band=2g"
    uci set "wireless.${r2g}.channel=${WIFI_2G_CHAN}"
    uci set "wireless.${r2g}.htmode=HE20"
    uci -q delete "wireless.${r2g}.he_bss_color"
    uci set "wireless.${r2g}.he_bss_color=1"
    uci -q delete "wireless.${r2g}.hwmode"
    uci set "wireless.${r2g}.noscan=1"
    uci set "wireless.${r2g}.txpower=20"
    uci set "wireless.${r2g}.mu_beamforming=1"
    uci set "wireless.${r2g}.cell_density=0"

    # Your 2.4 GHz network. Uses sae-mixed (WPA2/WPA3 transitional) with
    # PMF optional for maximum device compatibility on the slower band.
    uci set wireless.snowdrop=wifi-iface
    uci set wireless.snowdrop.device="${r2g}"
    uci set wireless.snowdrop.mode='ap'
    uci set wireless.snowdrop.network='lan'
    uci set wireless.snowdrop.ssid="${WIFI_2G_SSID}"
    uci set wireless.snowdrop.encryption='sae-mixed+ccmp'
    uci set wireless.snowdrop.key="${WIFI_2G_KEY}"
    uci set wireless.snowdrop.ieee80211w='1'
    uci set wireless.snowdrop.dtim_period='1'
    uci set wireless.snowdrop.disassoc_low_ack='0'
    uci set wireless.snowdrop.ocv='0'
    uci set wireless.snowdrop.wpa_disable_eapol_key_retries='1'
  fi

  # ---------- 5 GHz RADIO ----------
  if [ -n "${r5g}" ]; then
    log "  Configuring 5 GHz radio: ${r5g}"

    uci set "wireless.${r5g}.disabled=0"
    uci set "wireless.${r5g}.country=NL"
    uci set "wireless.${r5g}.band=5g"
    uci set "wireless.${r5g}.channel=${WIFI_5G_CHAN}"
    uci set "wireless.${r5g}.htmode=HE80"
    uci -q delete "wireless.${r5g}.he_bss_color"
    uci set "wireless.${r5g}.he_bss_color=2"
    uci -q delete "wireless.${r5g}.hwmode"
    uci set "wireless.${r5g}.noscan=1"
    uci set "wireless.${r5g}.mu_beamforming=1"
    uci set "wireless.${r5g}.cell_density=0"

    # Your 5 GHz network. Pure WPA3-SAE with mandatory PMF for maximum
    # security on the primary high-speed band.
    uci set wireless.lacia=wifi-iface
    uci set wireless.lacia.device="${r5g}"
    uci set wireless.lacia.mode='ap'
    uci set wireless.lacia.network='lan'
    uci set wireless.lacia.ssid="${WIFI_5G_SSID}"
    uci set wireless.lacia.encryption='sae'
    uci set wireless.lacia.key="${WIFI_5G_KEY}"
    uci set wireless.lacia.ieee80211w='2'
    uci set wireless.lacia.dtim_period='1'
    uci set wireless.lacia.disassoc_low_ack='0'
    uci set wireless.lacia.ocv='0'
    uci set wireless.lacia.wpa_disable_eapol_key_retries='1'

    # Dad's 5 GHz network. Uses sae-mixed with PMF optional for Google TV
    # HD dongle compatibility. The dongle cannot do pure WPA3-SAE.
    uci set wireless.dad_5g=wifi-iface
    uci set wireless.dad_5g.device="${r5g}"
    uci set wireless.dad_5g.mode='ap'
    uci set wireless.dad_5g.network='lan_dad'
    uci set wireless.dad_5g.ssid="${d_ssid}"
    uci set wireless.dad_5g.encryption='sae-mixed+ccmp'
    uci set wireless.dad_5g.key="${d_key}"
    uci set wireless.dad_5g.ieee80211w='1'
    uci set wireless.dad_5g.dtim_period='1'
    uci set wireless.dad_5g.disassoc_low_ack='0'
    uci set wireless.dad_5g.ocv='0'
    uci set wireless.dad_5g.wpa_disable_eapol_key_retries='1'
  fi

  uci commit wireless
}

# Phase 7: Configures all firewall rules for network isolation, DNS
# interception, and encrypted DNS bypass prevention.
#
# Isolation model:
#   - Dad's zone (lan_dad) can reach the internet but cannot reach the
#     primary LAN or any router management interface.
#   - Dad's DNS queries on port 53 are DNAT'd to port 5355 on DAD_LAN_IP
#     where his dedicated dnsproxy instance listens.
#   - IoT devices on the primary LAN (except the phone) have their DNS
#     queries intercepted and redirected to dnsmasq on LAN_IP.
#   - DoT (port 853) is rejected for both zones to prevent devices from
#     bypassing the NextDNS ad-blocker.
phase_security() {
  log "Phase 7 | Hardening isolation and interception rules..."

  # Harden the default WAN zone to DROP (not REJECT) unsolicited inbound.
  local w_zone
  w_zone=$(find_uci_section firewall name wan)
  if [ -n "${w_zone}" ]; then
    uci set "${w_zone}.input=DROP"
    uci set "${w_zone}.forward=DROP"
    uci set "${w_zone}.mtu_fix=1"
  fi

  # Dad's firewall zone. Input is rejected so Dad cannot reach the router
  # management interface (SSH, LuCI). Output is accepted. Forward to WAN
  # is allowed via an explicit forwarding rule below.
  uci set firewall.dad_zone=zone
  uci set firewall.dad_zone.name='lan_dad'
  uci set firewall.dad_zone.network='lan_dad'
  uci set firewall.dad_zone.input='REJECT'
  uci set firewall.dad_zone.forward='REJECT'
  uci set firewall.dad_zone.output='ACCEPT'

  # Allow DHCP from Dad's zone so devices can obtain an IP address.
  uci set firewall.dad_dhcp=rule
  uci set firewall.dad_dhcp.name='Allow-DHCP-Dad'
  uci set firewall.dad_dhcp.src='lan_dad'
  uci set firewall.dad_dhcp.proto='udp'
  uci set firewall.dad_dhcp.dest_port='67'
  uci set firewall.dad_dhcp.target='ACCEPT'

  # Allow DNS from Dad's zone. Must permit BOTH port 53 (original query)
  # and port 5355 (post-DNAT destination). The DNAT rule rewrites
  # dest_port 53->5355 in PREROUTING, which happens before the INPUT
  # filter evaluates the packet. If only port 53 were allowed here the
  # rewritten packet with dest_port 5355 would be silently REJECTED.
  uci set firewall.dad_dns=rule
  uci set firewall.dad_dns.name='Allow-DNS-Dad'
  uci set firewall.dad_dns.src='lan_dad'
  uci set firewall.dad_dns.proto='tcp udp'
  uci set firewall.dad_dns.dest_port='53 5355'
  uci set firewall.dad_dns.target='ACCEPT'

  # Allow Dad's zone to forward traffic to the internet.
  uci set firewall.dad_wan_forward=forwarding
  uci set firewall.dad_wan_forward.src='lan_dad'
  uci set firewall.dad_wan_forward.dest='wan'

  # DNS interception for IoT devices on the primary LAN. Forces all DNS
  # queries (except from the phone which runs its own private DNS) to go
  # through dnsmasq -> dnsproxy -> NextDNS. Prevents smart TVs and other
  # devices from using hardcoded DNS servers to bypass ad-blocking.
  uci set firewall.dns_intercept=redirect
  uci set firewall.dns_intercept.name='Intercept-DNS-LAN'
  uci set firewall.dns_intercept.src='lan'
  uci set firewall.dns_intercept.src_ip="!${PHONE_10_IP}"
  uci set firewall.dns_intercept.src_dport='53'
  uci set firewall.dns_intercept.dest_ip="${LAN_IP}"
  uci set firewall.dns_intercept.dest_port='53'
  uci set firewall.dns_intercept.proto='tcp udp'
  uci set firewall.dns_intercept.target='DNAT'

  # Dad's DNS interception. All queries from Dad's zone on port 53 are
  # redirected to dnsproxy on DAD_LAN_IP:5355 (Dad's dedicated NextDNS
  # profile). The destination is the router's real IP on Dad's subnet, not
  # 127.0.0.1, because cross-zone loopback DNAT requires the dangerous
  # route_localnet sysctl.
  uci set firewall.dns_intercept_dad=redirect
  uci set firewall.dns_intercept_dad.name='Intercept-DNS-Dad'
  uci set firewall.dns_intercept_dad.src='lan_dad'
  uci set firewall.dns_intercept_dad.src_dport='53'
  uci set firewall.dns_intercept_dad.dest_ip="${DAD_LAN_IP}"
  uci set firewall.dns_intercept_dad.dest_port='5355'
  uci set firewall.dns_intercept_dad.proto='tcp udp'
  uci set firewall.dns_intercept_dad.target='DNAT'

  # Block DNS-over-TLS (port 853) so devices cannot bypass the NextDNS
  # interception by using encrypted DNS directly.
  uci set firewall.reject_dot=rule
  uci set firewall.reject_dot.name='Reject-DoT-LAN'
  uci set firewall.reject_dot.src='lan'
  uci set firewall.reject_dot.src_ip="!${PHONE_10_IP}"
  uci set firewall.reject_dot.dest='wan'
  uci set firewall.reject_dot.proto='tcp udp'
  uci set firewall.reject_dot.dest_port='853'
  uci set firewall.reject_dot.target='REJECT'

  uci set firewall.reject_dot_dad=rule
  uci set firewall.reject_dot_dad.name='Reject-DoT-Dad'
  uci set firewall.reject_dot_dad.src='lan_dad'
  uci set firewall.reject_dot_dad.dest='wan'
  uci set firewall.reject_dot_dad.proto='tcp udp'
  uci set firewall.reject_dot_dad.dest_port='853'
  uci set firewall.reject_dot_dad.target='REJECT'

  uci commit firewall
}

# Phase 8: Configures BanIP to block known malicious IP ranges at the
# firewall level using nftables sets. Feeds are IPv4-only since we do
# not use IPv6 upstream.
phase_banip() {
  log "Phase 8 | Deploying BanIP threat intelligence feeds..."

  ensure_uci_section banip global global

  uci set banip.global.ban_enabled='1'
  uci set banip.global.ban_protov6='0'
  uci set banip.global.ban_blockpolicy='drop'

  uci -q del_list banip.global.ban_ifv4='wan'
  uci add_list banip.global.ban_ifv4='wan'

  local f
  for f in doh firehol1; do
    uci -q del_list banip.global.ban_feed="${f}"
    uci add_list banip.global.ban_feed="${f}"
  done

  uci set banip.global.ban_basedir='/tmp/banIP'
  uci set banip.global.ban_nftpolicy='performance'
  uci set banip.global.ban_synlimit='200'
  uci set banip.global.ban_udplimit='2000'
  uci set banip.global.ban_icmplimit='100'

  uci commit banip
}

# Phase 9: Configures Cake SQM on the WAN interface. When SQM_DOWNLOAD
# is greater than zero, hardware flow offloading is disabled (Cake must
# see every packet). When zero, SQM is disabled and hardware offloading
# is enabled for maximum raw throughput.
phase_sqm() {
  log "Phase 9 | Configuring traffic shaping (Cake SQM)..."

  while uci -q delete sqm.@queue[0]; do :; done

  local wan_if
  wan_if=$(_wan_iface)

  uci set sqm.wan=queue

  if [ "${SQM_DOWNLOAD}" -gt 0 ]; then
    log "  SQM enabled: ${SQM_DOWNLOAD} down / ${SQM_UPLOAD} up Kbps."

    # Disable hardware offloading. Cake must see every packet to schedule
    # flows fairly and prevent bufferbloat.
    ensure_uci_section firewall "@defaults[0]" defaults
    uci set firewall.@defaults[0].flow_offloading='0'
    uci set firewall.@defaults[0].flow_offloading_hw='0'

    uci set sqm.wan.enabled='1'
    uci set sqm.wan.interface="${wan_if}"
    uci set sqm.wan.download="${SQM_DOWNLOAD}"
    uci set sqm.wan.upload="${SQM_UPLOAD}"
    uci set sqm.wan.qdisc='cake'
    uci set sqm.wan.script='piece_of_cake.qos'
    uci set sqm.wan.linklayer='ethernet'
    uci set sqm.wan.mpu="${SQM_MPU}"

    if [ "${DEV_MODE}" = 'true' ]; then
      uci set sqm.wan.overhead="${SQM_OVERHEAD_DEV}"
    else
      uci set sqm.wan.overhead="${SQM_OVERHEAD_PROD}"
    fi

    uci set sqm.wan.ingress_ecn='ECN'
    uci set sqm.wan.egress_ecn='ECN'
  else
    log "  SQM disabled: enabling hardware flow offloading instead."
    uci set sqm.wan.enabled='0'
    ensure_uci_section firewall "@defaults[0]" defaults
    uci set firewall.@defaults[0].flow_offloading='1'
    uci set firewall.@defaults[0].flow_offloading_hw='1'
  fi

  uci commit sqm
  uci commit firewall
}

# Phase 10: Configures the Attended Sysupgrade (ASU) client so firmware
# updates can be built with the current package set preserved.
phase_asu() {
  log "Phase 10 | Configuring Attended Sysupgrade client..."

  uci set attendedsysupgrade.client=client
  uci set attendedsysupgrade.client.login_check_for_upgrades='1'
  uci set attendedsysupgrade.server=server
  uci set attendedsysupgrade.server.url='https://sysupgrade.openwrt.org'

  uci commit attendedsysupgrade
}

# Phase 10.5: Deploys a self-deleting post-boot finalizer that runs once
# via the uci-defaults mechanism on the first boot after restoration. It
# verifies network connectivity and restarts DNS services.
phase_finalizer() {
  log "Phase 10.5 | Deploying post-boot finalizer..."

  cat << 'FINEOF' > /etc/uci-defaults/99-monolith-finalizer
#!/bin/sh
logger -t monolith "Running v31.1 post-boot finalizer..."

if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
  logger -t monolith "Network verified. Restoration successful."
else
  logger -t monolith "Network unreachable. Check fiber/VLAN settings."
fi

/etc/init.d/dnsproxy restart
/etc/init.d/dnsmasq restart

exit 0
FINEOF
  chmod +x /etc/uci-defaults/99-monolith-finalizer
}

# Phase 11: Brings up all services, waits for internet connectivity, and
# offers an interactive firmware upgrade check. In PROD mode the WAN has
# VLAN 300 which only works on the Odido ONT — connectivity will fail at
# the workbench, which is expected and handled gracefully.
phase_activate() {
  log "Phase 11 | Activating all services..."

  /etc/init.d/dnsproxy enable     2>/dev/null
  /etc/init.d/banip enable        2>/dev/null
  /etc/init.d/sqm enable          2>/dev/null
  /etc/init.d/irq-tuning enable   2>/dev/null
  /etc/init.d/gro-fix enable      2>/dev/null
  /etc/init.d/disable-eee enable  2>/dev/null
  /etc/init.d/aql-tuning enable   2>/dev/null

  log "  Step 1: Committing network and firewall (SSH may pause briefly)..."
  /etc/init.d/network reload 2>/dev/null
  sleep 4
  /etc/init.d/firewall restart 2>/dev/null

  log "  Step 2: Starting DNS proxies..."
  /etc/init.d/dnsproxy stop  2>/dev/null
  /etc/init.d/dnsproxy start 2>/dev/null
  sleep 2
  /etc/init.d/dnsmasq restart 2>/dev/null
  sleep 2

  log "  Step 3: Waiting for WAN DHCP lease (up to 30 seconds)..."
  local attempt=0
  while [ "${attempt}" -lt 15 ]; do
    if ping -c 1 -W 2 8.8.8.8 >/dev/null 2>&1; then
      log "  Internet is online (attempt $((attempt + 1)))."
      break
    fi
    attempt=$((attempt + 1))
    sleep 2
  done

  if [ "${attempt}" -ge 15 ]; then
    if [ "${DEV_MODE}" = 'true' ]; then
      err "WARNING: No internet after 30 seconds."
      err "Skipping firmware check."
    else
      log "  No internet — expected in PROD mode at the workbench."
      log "  VLAN 300 requires the Odido ONT. Skipping firmware check."
    fi
    return
  fi

  log "  Step 4: Verifying DNS resolution..."
  if _timeout 10 nslookup openwrt.org 127.0.0.1 >/dev/null 2>&1; then
    log "  DNS resolution verified."
  else
    err "WARNING: DNS resolution failed via dnsproxy. Retrying..."
    /etc/init.d/dnsproxy restart 2>/dev/null
    sleep 2
    /etc/init.d/dnsmasq restart 2>/dev/null
    sleep 2
  fi

  if ! command -v owut >/dev/null 2>&1; then
    err "WARNING: owut is missing. Skipping firmware upgrade check."
    return
  fi

  # ---- Version Check ----
  local current_ver release_json latest_tag release_name
  local release_body latest_ver

  current_ver=$(grep 'DISTRIB_RELEASE=' /etc/openwrt_release 2>/dev/null \
    | cut -d= -f2 | tr -d "\"'")
  log "  Installed firmware: ${current_ver:-unknown}"
  log "  Checking GitHub for newer versions..."

  release_json=$(_fetch_openwrt_release_json 2>/dev/null) || release_json=''

  if [ -z "${release_json}" ]; then
    err "  Could not reach GitHub API. Skipping update check."
    return
  fi

  latest_tag=$(printf '%s' "${release_json}" \
    | jsonfilter -e '@.tag_name' 2>/dev/null)
  release_name=$(printf '%s' "${release_json}" \
    | jsonfilter -e '@.name' 2>/dev/null)
  release_body=$(printf '%s' "${release_json}" \
    | jsonfilter -e '@.body' 2>/dev/null)

  [ -z "${latest_tag}" ] && return
  latest_ver="${latest_tag#v}"

  if [ "${latest_ver}" = "${current_ver}" ]; then
    log "  Firmware is already up to date."
    return
  fi

  log ""
  log "  ============================================================"
  log "  NEW FIRMWARE AVAILABLE"
  log "  ============================================================"
  log "  Installed : ${current_ver:-unknown}"
  log "  Available : ${latest_ver} — ${release_name:-OpenWrt release}"
  log "  ============================================================"
  log "  RELEASE NOTES (first 50 lines):"
  log "  ------------------------------------------------------------"
  if [ -n "${release_body}" ]; then
    printf '%s\n' "${release_body}" | head -n 50 \
      | while IFS= read -r line; do
          log "    ${line}"
        done
  else
    log "    (Could not retrieve release notes.)"
  fi
  log "  ============================================================"
  log ""

  # ---- Interactive Upgrade Prompt ----
  local upgrade_answer=''
  if [ -c /dev/tty ]; then
    printf '\033[1;33m>>> Upgrade to OpenWrt %s? [Y/n]: \033[0m' \
      "${latest_ver}"
    read -r upgrade_answer < /dev/tty
  else
    err "  No interactive terminal detected. Skipping upgrade."
    return
  fi

  case "${upgrade_answer}" in
    n|N|no|NO|nee|Nee|NEE)
      log "  Upgrade skipped."
      return
      ;;
  esac

  log "  Selecting the fastest update mirror..."
  local servers
  servers='https://sysupgrade.openwrt.org https://sysupgrade.guerra24.net https://sysupgrade.antennine.org'
  local pairs='' srv rtt ordered

  for srv in ${servers}; do
    rtt=$(_ping_ms "${srv}")
    log "    ${srv##https://}  ->  ${rtt} ms"
    pairs="$(printf '%s\n%s %s' "${pairs}" "${rtt}" "${srv}")"
  done

  ordered=$(printf '%s' "${pairs}" | sort -n | awk '{print $2}')
  local upgrade_ok='false'

  for srv in ${ordered}; do
    log "  Building firmware from: ${srv}"
    log "  (This takes 1-5 minutes. Please wait...)"

    uci set attendedsysupgrade.server=server
    uci set attendedsysupgrade.server.url="${srv}"
    uci commit attendedsysupgrade

    if _timeout 240 owut upgrade --force; then
      upgrade_ok='true'
      log "  Upgrade successful. The router will reboot automatically."
      break
    else
      local rc=$?
      if [ "${rc}" -eq 124 ]; then
        err "  Server timed out. Trying next mirror..."
      else
        err "  Server returned an error. Trying next mirror..."
      fi
    fi
  done

  if [ "${upgrade_ok}" = 'false' ]; then
    err "  All update servers failed or timed out."
    log "  Proceeding to finalization."
  fi
}

# Prints the final status banner and either reboots (DEV) or shuts down
# (PROD) the router.
finalize() {
  log "=========================================================="
  log "MONOLITH V31.1 — RESTORATION COMPLETE"
  log "=========================================================="
  log ""

  if [ "${DEV_MODE}" = 'true' ]; then
    log "  [DEV MODE] The router will REBOOT in 10 seconds."
    log "  Your SSH session will disconnect — this is normal."
    log "  Wait ~60 seconds, then reconnect to ${LAN_IP}."
    log ""
    sleep 10
    reboot
  else
    log "  [PRODUCTION] The router will SHUT DOWN in 10 seconds."
    log "  Your SSH session will disconnect — this is normal."
    log ""
    log "  NEXT STEPS:"
    log "  1. Wait for all LEDs to stop flashing and the router to power off."
    log "  2. Unplug the power cable."
    log "  3. Move the router to the living room."
    log "  4. Plug the Odido ONT cable into the blue WAN port."
    log "  5. Plug the power back in and turn it on."
    log "  6. Dad's network will be ready automatically."
    log ""
    sleep 10
    poweroff
  fi
}

# ==============================================================================
# MAIN ENTRY POINT
# ==============================================================================

main() {
  parse_args "$@"
  readonly DEV_MODE

  phase_bootstrap
  phase_cleanup
  phase_system
  phase_dropbear
  phase_stability
  phase_network
  phase_dhcp
  phase_dns
  phase_wireless
  phase_security
  phase_banip
  phase_sqm
  phase_asu
  phase_finalizer

  log "======================================================================"
  log "MONOLITH V31.1 — ALL PHASES COMPLETE, ACTIVATING NOW"
  log "======================================================================"

  phase_activate
  finalize
}

main "$@"