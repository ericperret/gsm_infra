<!--
  Name     : README.md
  Purpose  : overview of the gsm_infra repository (island mobile operator, MCC 547)
  Author   : Eric PERRET
  Date     : 2026-10-27
  Version  : 1.1
  License  : CC BY-NC 4.0 — commercial use forbidden without the author's written permission (eperret@azs.fr)
-->

# gsm_infra — island mobile operator, MCC 547 (French Polynesia)

🇫🇷 [Version française : LISEZMOI.md](LISEZMOI.md)

A complete open-source infrastructure for an island mobile network operator:
2G GSM (Osmocom) + 4G LTE (Open5GS) + VoWiFi (strongSwan / osmo-epdg / Kamailio) + BSS.

Documents are in French.

## Files in this repository

### Documentation

| File | Content |
|---|---|
| `OSMO_EPDG_BUILD_DEPLOY.md` | Build and deployment of the Osmocom strongSwan fork + osmo-epdg (Erlang) |
| `osmocom_open5gs_complet_v2.docx` | Summary document — full Osmocom 2G + Open5GS 4G stack |
| `vowifi_stack_doc.docx` | VoWiFi stack: strongSwan, osmo-epdg, Kamailio IMS |
| `stack_operateur_polynesie.docx` | Overall operator architecture |
| `operateur_polynesie_v3.docx` | Business case v3.0 — architecture + budget |
| `bss_sync_guide.docx` | BSS: sync topology, operations, conflict handling |
| `BSS_MCC547_Document_Maitre_v1_0.docx` | BSS master document — schema, API, admin interface |
| `BSS_MCC547_Master_Site_v1_1.docx` | Island site master document — variables, installation phases |

### Installation scripts (in the zip archives)

**`install-bss-db.zip`** — BSS database
- `01_install_postgresql.sh` — PostgreSQL 16 installation + database creation
- `02_bss_schema.sql` — full schema (7 tables: ABONNES subscribers, SIMS, NUMEROS numbers, PROFILS profiles, EVENEMENTS events, ALERTES_CBS cell broadcast alerts, OPERATEURS operators)

**`mise-a-jour_DB.zip`** — multi-site sync
- `03_bss_sync_schema.sql` — SITES / SYNC_QUEUE / SYNC_LOG tables
- `04_install_sync.sh` — sync daemon installation
- `server.js` — Node.js REST API (12 routes, no framework)
- `sync-daemon.js` — WireGuard hub-and-spoke sync daemon

### Other files

| File | Content |
|---|---|
| `sys.config` | Erlang/OTP configuration for osmo-epdg |
| `osmo_epdg_release.tar.gz` | Compiled osmo-epdg binary (Erlang OTP 26, Ubuntu 24.04 x86_64) |
| `lpda_uhf(1).html` | UHF LPDA antenna calculator (standalone HTML tool) |

---

## Architecture summary

```
Island site (10.0.0.1)             Central server (10.0.0.250)
─────────────────────────          ────────────────────────────
Osmocom 2G (OsmoSTP/HLR/           FreeSWITCH + OVH SIP trunk
MSC/MGW/SGSN/BSC/CBC)              WireGuard hub
Open5GS 4G (MME/SGW/PGW/           Central PostgreSQL BSS
HSS/PCRF/SMF/UPF)
strongSwan (Osmocom fork)   ←────  Starlink (fixed IP)
osmo-epdg (Erlang OTP)
Kamailio IMS
Local PostgreSQL BSS
WireGuard spoke
Starlink (dynamic IP)
```

Key principle: **each site runs on its own** (local calls, VoWiFi) without the central server. The central server only provides WAN / PSTN access.

---

## PLACEHOLDERs — to replace before going live

| Token | What is needed | Priority |
|---|---|---|
| `PLACEHOLDER` (MNC) | MNC assigned by the DGPT (Papeete) | **CRITICAL** |
| `SITE_LOCAL_IP` | LAN IP of the site PC (10.0.0.x) | **CRITICAL** |
| `PLACEHOLDER_ARFCN_S1/S2/S3` | Sector ARFCNs — regulator | Radio |
| `PLACEHOLDER_PWR_DBM` | TRX power in dBm | Radio |
| `PLACEHOLDER_KI` / `PLACEHOLDER_OPC` | 128-bit SIM keys | Per SIM |

⚠ Nothing works while MNC = PLACEHOLDER.

---

## Technical stack

- **OS**: Ubuntu 24.04 LTS x86_64
- **2G**: Osmocom (sysmocom repository), sysmoBTS 2100, Band 28 700 MHz
- **4G**: Open5GS, eNodeB, Band 28 FDD
- **VoWiFi**: strongSwan `osmo-epdg` fork, Erlang/OTP 26, Kamailio IMS
- **Core**: FreeSWITCH, OVH SIP trunk
- **VPN**: WireGuard hub-and-spoke
- **BSS**: PostgreSQL 16, Node.js (`pg` only), vanilla HTML/CSS/JS
- **SIM**: sysmoISIM-SJA2, SCR3310, pySIM
- **Monitoring**: Nagios Core
- **Backhaul**: Starlink (dynamic IP on sites, fixed IP at the central server)

## License

**Free for non-commercial use** — [CC BY-NC 4.0](https://creativecommons.org/licenses/by-nc/4.0/), with mandatory credit of the source and the author:

> gsm_infra — Eric PERRET — https://github.com/ericperret/gsm_infra

Any commercial use is forbidden without the author's written permission, requested by e-mail: **eperret@azs.fr**.
Third-party software shipped here (the compiled osmo-epdg binary, AGPL-3.0) remains under its own license.
Full terms (French / English): [LICENSE](LICENSE).

## Author

**Eric PERRET** — [GitHub](https://github.com/ericperret)
