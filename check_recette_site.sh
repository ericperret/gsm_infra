#!/usr/bin/env bash
# =============================================================================
# Fichier  : check_recette_site.sh
# Projet   : BSS Opérateur MCC=547 — Polynésie française
# Rôle     : Fiche de recette installation — site local
#            Vérifie : services systemd, ports en écoute, ping éléments actifs
# Cible    : Ubuntu 24.04 LTS x86_64 — PC site local (10.0.0.x)
# Usage    : sudo bash check_recette_site.sh
# Date     : 2026-05-27
# Version  : 1.0.0
# Sortie   : OUI/NON par item — score final PASS/FAIL — log /tmp/recette_SITE.log
# =============================================================================

set -uo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
# Détection IP — priorité 10.0.0.x, sinon première IP non-loopback (dev/test)
SITE_IP=$(ip -4 addr show | awk '/inet 10\.0\.0\./{gsub(/\/[0-9]+/,"",$2); print $2}' | head -1)
if [[ -z "$SITE_IP" ]]; then
    SITE_IP=$(ip -4 addr show | awk '/inet /{gsub(/\/[0-9]+/,"",$2); if($2!="127.0.0.1") print $2}' | head -1)
fi
if [[ -z "$SITE_IP" ]]; then
    read -rp "IP locale non détectée — entrez l'IP de ce site (ex: 10.0.0.3) : " SITE_IP
fi
# Avertir si hors réseau opérateur
[[ "$SITE_IP" != 10.0.0.* ]] && echo "⚠  IP=$SITE_IP hors réseau opérateur (10.0.0.x) — checks réseau partiels" 
WG_HUB="10.10.0.1"
LOG="/tmp/recette_${SITE_IP:-unknown}.log"
SCORE_OK=0
SCORE_TOTAL=0
ERRORS=()

# ── Helpers ───────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'; RED='\033[0;31m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo "$*" | tee -a "$LOG"; }
sect() { echo "" | tee -a "$LOG"
         log "$(printf '%s' "${BOLD}${CYAN}══ $* ══${NC}")" ; }

chk() {
    local label="$1" result="$2"
    SCORE_TOTAL=$((SCORE_TOTAL+1))
    if [[ "$result" == "OUI" ]]; then
        SCORE_OK=$((SCORE_OK+1))
        printf "  %-52s ${GREEN}OUI${NC}\n" "$label" | tee -a "$LOG"
    else
        printf "  %-52s ${RED}NON${NC}\n" "$label" | tee -a "$LOG"
        ERRORS+=("$label")
    fi
}

svc_ok()  { systemctl is-active --quiet "$1" 2>/dev/null && echo "OUI" || echo "NON"; }
port_tcp(){ ss -tlnp 2>/dev/null | grep -q ":$1 " && echo "OUI" || echo "NON"; }
port_udp(){ ss -ulnp 2>/dev/null | grep -q ":$1 " && echo "OUI" || echo "NON"; }
port_any(){ { ss -tlnp 2>/dev/null; ss -ulnp 2>/dev/null; } | grep -q ":$1 " && echo "OUI" || echo "NON"; }
ping_ok() { ping -c1 -W2 "$1" &>/dev/null && echo "OUI" || echo "NON"; }
iface_ok(){ ip link show "$1" 2>/dev/null | grep -q "UP" && echo "OUI" || echo "NON"; }

# ── En-tête ───────────────────────────────────────────────────────────────────
> "$LOG"
log "============================================================"
log "  FICHE DE RECETTE — Site BSS MCC=547"
log "  IP locale   : ${SITE_IP:-NON DÉTECTÉE}"
log "  Date        : $(date '+%Y-%m-%d %H:%M:%S')"
log "  Hostname    : $(hostname)"
log "  Kernel      : $(uname -r)"
log "  Ubuntu      : $(lsb_release -ds 2>/dev/null || echo '?')"
log "============================================================"

# ═════════════════════════════════════════════════════════════════
# 1. SERVICES OSMOCOM 2G
# ═════════════════════════════════════════════════════════════════
sect "1. SERVICES OSMOCOM 2G"
chk "osmo-stp    (routage SS7)"          "$(svc_ok osmo-stp)"
chk "osmo-hlr    (registre abonnés)"     "$(svc_ok osmo-hlr)"
chk "osmo-mgw    (passerelle voix)"      "$(svc_ok osmo-mgw)"
chk "osmo-msc    (commutation voix/SMS)" "$(svc_ok osmo-msc)"
chk "osmo-sgsn   (données GPRS)"         "$(svc_ok osmo-sgsn)"
chk "osmo-bsc    (contrôleur BTS)"       "$(svc_ok osmo-bsc)"
chk "osmo-cbc    (FR-ALERT CBS)"         "$(svc_ok osmo-cbc)"

# ═════════════════════════════════════════════════════════════════
# 2. SERVICES OPEN5GS 4G LTE
# ═════════════════════════════════════════════════════════════════
sect "2. SERVICES OPEN5GS 4G LTE"
chk "open5gs-mmed   (MME)"               "$(svc_ok open5gs-mmed)"
chk "open5gs-sgwcd  (SGW-C)"             "$(svc_ok open5gs-sgwcd)"
chk "open5gs-sgwud  (SGW-U)"             "$(svc_ok open5gs-sgwud)"
chk "open5gs-smfd   (SMF/PGW-C)"         "$(svc_ok open5gs-smfd)"
chk "open5gs-upfd   (UPF/PGW-U)"         "$(svc_ok open5gs-upfd)"
chk "open5gs-hssd   (HSS)"               "$(svc_ok open5gs-hssd)"
chk "open5gs-pcrfd  (PCRF)"              "$(svc_ok open5gs-pcrfd)"
chk "open5gs-nrfd   (NRF)"               "$(svc_ok open5gs-nrfd)"
chk "open5gs-scpd   (SCP)"               "$(svc_ok open5gs-scpd)"
chk "open5gs-ausfd  (AUSF)"              "$(svc_ok open5gs-ausfd)"
chk "open5gs-udmd   (UDM)"               "$(svc_ok open5gs-udmd)"
chk "open5gs-udrd   (UDR)"               "$(svc_ok open5gs-udrd)"
chk "open5gs-pcfd   (PCF)"               "$(svc_ok open5gs-pcfd)"
chk "open5gs-nssfd  (NSSF)"              "$(svc_ok open5gs-nssfd)"
chk "open5gs-bsfd   (BSF)"               "$(svc_ok open5gs-bsfd)"
chk "open5gs-amfd   (AMF)"               "$(svc_ok open5gs-amfd)"

# ═════════════════════════════════════════════════════════════════
# 3. SERVICES VoWiFi / IMS
# ═════════════════════════════════════════════════════════════════
sect "3. SERVICES VoWiFi / IMS"
chk "charon-systemd (strongSwan IKEv2)"  "$(svc_ok charon-systemd)"
chk "osmo-epdg      (ePDG Erlang)"       "$(svc_ok osmo-epdg)"
chk "kamailio       (IMS SIP)"           "$(svc_ok kamailio)"
chk "dnsmasq        (DNS ePDG)"          "$(svc_ok dnsmasq)"

# ═════════════════════════════════════════════════════════════════
# 4. SERVICES INFRASTRUCTURE
# ═════════════════════════════════════════════════════════════════
sect "4. SERVICES INFRASTRUCTURE"
chk "postgresql     (base BSS)"          "$(svc_ok postgresql)"
chk "bss-api        (API REST :3000)"    "$(svc_ok bss-api)"
chk "Interface wg0  (WireGuard)"         "$(iface_ok wg0)"
chk "Interface ogstun (Open5GS data)"   "$(iface_ok ogstun)"

# ═════════════════════════════════════════════════════════════════
# 5. PORTS EN ÉCOUTE — OSMOCOM
# ═════════════════════════════════════════════════════════════════
sect "5. PORTS EN ÉCOUTE — OSMOCOM 2G"
chk "TCP 4222  OsmoHLR GSUP"            "$(port_tcp 4222)"
chk "TCP 3003  OsmoBSC Abis-over-IP"    "$(port_tcp 3003)"
chk "TCP 4264  OsmoCBC CBSP"            "$(port_tcp 4264)"
chk "TCP 2905  OsmoSTP M3UA"            "$(port_tcp 2905)"
chk "UDP 23000 GPRS NS (secteur 1)"     "$(port_udp 23000)"
chk "UDP 23001 GPRS NS (secteur 2)"     "$(port_udp 23001)"
chk "UDP 23002 GPRS NS (secteur 3)"     "$(port_udp 23002)"
# VTY (admin) — écoute sur 127.0.0.1
chk "TCP 4239  OsmoSTP VTY"             "$(ss -tlnp 2>/dev/null | grep -q ':4239 ' && echo OUI || echo NON)"
chk "TCP 4258  OsmoHLR VTY"             "$(ss -tlnp 2>/dev/null | grep -q ':4258 ' && echo OUI || echo NON)"
chk "TCP 4245  OsmoMGW VTY"             "$(ss -tlnp 2>/dev/null | grep -q ':4245 ' && echo OUI || echo NON)"
chk "TCP 4254  OsmoMSC VTY"             "$(ss -tlnp 2>/dev/null | grep -q ':4254 ' && echo OUI || echo NON)"
chk "TCP 4242  OsmoSGSN VTY"            "$(ss -tlnp 2>/dev/null | grep -q ':4242 ' && echo OUI || echo NON)"
chk "TCP 4241  OsmoBSC VTY"             "$(ss -tlnp 2>/dev/null | grep -q ':4241 ' && echo OUI || echo NON)"

# ═════════════════════════════════════════════════════════════════
# 6. PORTS EN ÉCOUTE — OPEN5GS
# ═════════════════════════════════════════════════════════════════
sect "6. PORTS EN ÉCOUTE — OPEN5GS 4G"
chk "SCTP 36412 S1AP MME (eNodeB/BBU)"  "$(ss -tlnp 2>/dev/null | grep -qE ':36412|sctp.*36412' && echo OUI || \
                                           ss -ulnp 2>/dev/null | grep -q ':36412 ' && echo OUI || echo NON)"
chk "UDP  2123  GTP-C S11"              "$(port_udp 2123)"
chk "UDP  2152  GTP-U S1-U"             "$(port_udp 2152)"
chk "TCP  3868  Diameter (HSS/PCRF)"    "$(port_tcp 3868)"

# ═════════════════════════════════════════════════════════════════
# 7. PORTS EN ÉCOUTE — VoWiFi / IMS
# ═════════════════════════════════════════════════════════════════
sect "7. PORTS EN ÉCOUTE — VoWiFi / IMS"
chk "UDP 500   IKEv2 (strongSwan)"       "$(port_udp 500)"
chk "UDP 4500  IKEv2 NAT-T"             "$(port_udp 4500)"
chk "TCP 5060  SIP Kamailio"            "$(port_tcp 5060)"
chk "UDP 5060  SIP Kamailio"            "$(port_udp 5060)"
chk "UDP 53    DNS dnsmasq"             "$(port_udp 53)"

# ═════════════════════════════════════════════════════════════════
# 8. PORTS EN ÉCOUTE — INFRASTRUCTURE
# ═════════════════════════════════════════════════════════════════
sect "8. PORTS EN ÉCOUTE — INFRASTRUCTURE"
chk "TCP 5432  PostgreSQL"              "$(port_tcp 5432)"
chk "TCP 3000  BSS API REST"            "$(port_tcp 3000)"
chk "UDP 51820 WireGuard"               "$(port_udp 51820)"

# ═════════════════════════════════════════════════════════════════
# 9. PINGS — ÉLÉMENTS ACTIFS
# ═════════════════════════════════════════════════════════════════
sect "9. PINGS — ÉLÉMENTS ACTIFS"
chk "Ping 127.0.0.1        (loopback)"   "$(ping_ok 127.0.0.1)"
chk "Ping ${SITE_IP:-N/A}            (IP LAN locale)" "$([ -n "${SITE_IP:-}" ] && ping_ok "$SITE_IP" || echo NON)"
chk "Ping 10.10.0.1        (WG central — WAN)" "$(ping_ok $WG_HUB)"

# Ping BSS API locale
API_UP="NON"
if curl -sf --max-time 3 "http://127.0.0.1:3000/api/health" &>/dev/null; then API_UP="OUI"; fi
chk "HTTP 127.0.0.1:3000   (BSS API health)" "$API_UP"

# Résolution DNS ePDG (dnsmasq)
DNS_UP="NON"
if dig +short +time=2 "epdg.epc.mncPLACEHOLDER.mcc547.pub.3gppnetwork.org" @127.0.0.1 2>/dev/null | grep -q "^10\."; then
    DNS_UP="OUI"
fi
chk "DNS @127.0.0.1        (résolution ePDG)" "$DNS_UP"

# Test VTY OsmoHLR
VTY_UP="NON"
if echo "" | nc -w1 127.0.0.1 4258 2>/dev/null | grep -qi "osmo\|hlr\|welcome"; then VTY_UP="OUI"; fi
chk "VTY OsmoHLR :4258     (bannière OK)"     "$VTY_UP"

# ═════════════════════════════════════════════════════════════════
# 10. VÉRIFICATIONS SYSTÈME
# ═════════════════════════════════════════════════════════════════
sect "10. SYSTÈME"
# IP forwarding (requis Open5GS)
FWD=$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)
chk "IP forwarding activé  (Open5GS data)"  "$([[ $FWD == '1' ]] && echo OUI || echo NON)"
# Interface ogstun up
chk "NAT MASQUERADE ogstun (Open5GS)"       "$(iptables -t nat -L POSTROUTING 2>/dev/null | grep -q MASQUERADE && echo OUI || echo NON)"
# MNC non PLACEHOLDER dans sys.config
MNC_SET="NON"
if [[ -f /opt/osmo-epdg/config/sys.config ]] && ! grep -q '"PLACEHOLDER"' /opt/osmo-epdg/config/sys.config 2>/dev/null; then
    MNC_SET="OUI"
fi
chk "MNC défini (pas PLACEHOLDER)"          "$MNC_SET"
# Disk space > 2G
DISK_FREE=$(df / --output=avail 2>/dev/null | tail -1)
chk "Espace disque / > 2 Go"                "$([[ ${DISK_FREE:-0} -gt 2097152 ]] && echo OUI || echo NON)"
# RAM > 2G
MEM_FREE=$(free -m 2>/dev/null | awk '/^Mem/{print $7}')
chk "RAM disponible > 512 Mo"               "$([[ ${MEM_FREE:-0} -gt 512 ]] && echo OUI || echo NON)"

# ═════════════════════════════════════════════════════════════════
# RÉSULTAT FINAL
# ═════════════════════════════════════════════════════════════════
echo "" | tee -a "$LOG"
log "============================================================"
log "  RÉSULTAT : $SCORE_OK / $SCORE_TOTAL checks OK"
POURCENT=$(( SCORE_OK * 100 / SCORE_TOTAL ))
log "  Taux     : ${POURCENT}%"

if [[ $SCORE_OK -eq $SCORE_TOTAL ]]; then
    log "  VERDICT  : ✓ PASS — site opérationnel"
else
    log "  VERDICT  : ✗ FAIL — $((SCORE_TOTAL - SCORE_OK)) anomalie(s)"
    echo "" | tee -a "$LOG"
    log "  Anomalies détectées :"
    for e in "${ERRORS[@]}"; do
        log "    ✗ $e"
    done
fi
log "  Log      : $LOG"
log "============================================================"
