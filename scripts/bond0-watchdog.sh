!/bin/bash
# bond0-watchdog.sh
#
# WHAT IT DOES
#   Auto-detects and auto-fixes a "stuck interface" bug on the Security Onion
#   sensor. bond0 is the monitor bond (onboard NIC enp4s0 receiving the switch
#   SPAN mirror, plus a GRE tunnel carrying mirrored Proxmox VM traffic).
#   Every run it reads bond0's RX packet counter. If the counter has not moved
#   for 2 consecutive checks, it bounces enp4s0 (down, 2 s, up), waits 5 s, and
#   logs whether RX traffic resumed.
#
# WHY IT EXISTS
#   enp4s0 periodically stops receiving: the RX counter freezes while the
#   interface still reports state UP. No carrier loss, kernel, or
#   NetworkManager link-down event is ever logged, so link-state monitoring
#   cannot catch it. The sensor silently goes blind (no Zeek/Suricata data)
#   until someone notices. Manual fix was `ip link set enp4s0 down && up`;
#   after the 4th occurrence this script automated it.
#
# ASSUMPTIONS / LIMITATIONS
#   - The mirror port always carries traffic, so a frozen RX counter means a
#     fault, not an idle link. Do not reuse this on a link that can be quiet.
#   - Recovery is checked only ~7 s after the bounce; a slow recovery can be
#     logged as WARNING even if traffic resumes shortly after.
#   - Root cause of the NIC/driver hang is not fixed, only detected and cleared.
#
# INSTALL (root crontab, runs every minute -> stuck for ~2 min triggers a bounce)
#   sudo install -m 755 bond0-watchdog.sh /usr/local/bin/bond0-watchdog.sh
#   sudo crontab -e
#     * * * * * /usr/local/bin/bond0-watchdog.sh
#
# LOG
#   /var/log/bond0-watchdog.log  (STUCK DETECTED / RECOVERED / WARNING / ERROR)
#
# Full write-up: see docs/ in this repo.
 
IFACE="bond0"
SLAVE="enp4s0"
STATE_FILE="/tmp/bond0_watchdog_last_rx"
LOG_FILE="/var/log/bond0-watchdog.log"
 
# Pull current RX packet count for bond0
# Full path to ip used because cron runs with a minimal PATH that may not include it
current_rx=$(/usr/sbin/ip -s link show "$IFACE" | awk '/RX:/{getline; print $2}')
 
if [ -z "$current_rx" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR: could not read RX packet count for $IFACE - skipping this check, not touching state" >> "$LOG_FILE"
    exit 1
fi
 
if [ -f "$STATE_FILE" ]; then
    last_rx=$(cat "$STATE_FILE")
    stuck_count_file="/tmp/bond0_watchdog_stuck_count"
    stuck_count=$(cat "$stuck_count_file" 2>/dev/null || echo 0)
 
    if [ "$current_rx" -eq "$last_rx" ]; then
        stuck_count=$((stuck_count + 1))
        echo "$stuck_count" > "$stuck_count_file"
 
        if [ "$stuck_count" -ge 2 ]; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') STUCK DETECTED: $IFACE RX count frozen at $current_rx for $stuck_count consecutive checks. Bouncing $SLAVE." >> "$LOG_FILE"
            /usr/sbin/ip link set "$SLAVE" down
            sleep 2
            /usr/sbin/ip link set "$SLAVE" up
            sleep 5
 
            new_rx=$(/usr/sbin/ip -s link show "$IFACE" | awk '/RX:/{getline; print $2}')
            if [ "$new_rx" -gt "$current_rx" ]; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') RECOVERED: $IFACE RX count now $new_rx, fix worked." >> "$LOG_FILE"
            else
                echo "$(date '+%Y-%m-%d %H:%M:%S') WARNING: $IFACE RX count still $new_rx after bounce, fix may not have worked. Manual check needed." >> "$LOG_FILE"
            fi
 
            echo 0 > "$stuck_count_file"
            current_rx="$new_rx"
        fi
    else
        # Traffic is moving, reset the stuck counter
        echo 0 > "$stuck_count_file"
    fi
fi
 
echo "$current_rx" > "$STATE_FILE"
 
