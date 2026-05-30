# gsm_infra — Opérateur téléphonie mobile MCC=547 (Polynésie française)

Infrastructure complète open-source pour opérateur mobile insulaire :
2G GSM (Osmocom) + 4G LTE (Open5GS) + VoWiFi (strongSwan/osmo-epdg/Kamailio) + BSS.

---

## Par où commencer

Lire **`PROMPTS_LIST.md`** — il contient les 27 prompts d'installation dans l'ordre strict,
organisés en 8 phases. Chaque prompt est conçu pour une conversation séparée avec Claude.

---

## Fichiers de ce dépôt

### Documentation

| Fichier | Contenu |
|---|---|
| `PROMPTS_LIST.md` | 27 prompts d'installation — ordre strict à respecter |
| `OSMO_EPDG_BUILD_DEPLOY.md` | Compilation et déploiement strongSwan fork Osmocom + osmo-epdg Erlang |
| `osmocom_open5gs_complet_v2.docx` | Document de synthèse — stack Osmocom 2G + Open5GS 4G complète |
| `vowifi_stack_doc.docx` | Stack VoWiFi : strongSwan, osmo-epdg, Kamailio IMS |
| `stack_operateur_polynesie.docx` | Architecture générale de l'opérateur |
| `operateur_polynesie_v3.docx` | Note d'opportunité v3.0 — architecture + budget |
| `bss_sync_guide.docx` | BSS : topologie sync, opérations, gestion conflits |
| `BSS_MCC547_Document_Maitre_v1_0.docx` | Document maître BSS — schéma, API, interface admin |
| `BSS_MCC547_Master_Site_v1_1.docx` | Document maître site insulaire — variables, phases install |

### Scripts d'installation (dans les archives zip)

**`install-bss-db.zip`** — Base de données BSS
- `01_install_postgresql.sh` — Installation PostgreSQL 16 + création base
- `02_bss_schema.sql` — Schéma complet (7 tables : ABONNES, SIMS, NUMEROS, PROFILS, EVENEMENTS, ALERTES_CBS, OPERATEURS)

**`mise-a-jour_DB.zip`** — Sync multi-sites
- `03_bss_sync_schema.sql` — Tables SITES / SYNC_QUEUE / SYNC_LOG
- `04_install_sync.sh` — Installation du démon de synchronisation
- `server.js` — API REST Node.js (12 routes, sans framework)
- `sync-daemon.js` — Démon de sync WireGuard hub-and-spoke

### Autres fichiers

| Fichier | Contenu |
|---|---|
| `sys.config` | Configuration Erlang/OTP pour osmo-epdg |
| `osmo_epdg_release.tar.gz` | Binaire osmo-epdg compilé (Erlang OTP 26, Ubuntu 24.04 x86_64) |
| `lpda_uhf(1).html` | Calculateur antenne LPDA UHF (outil HTML autonome) |

---

## Architecture résumée

```
Site insulaire (10.0.0.1)          Serveur central (10.0.0.250)
─────────────────────────          ────────────────────────────
Osmocom 2G (OsmoSTP/HLR/          FreeSWITCH + SIP trunk OVH
MSC/MGW/SGSN/BSC/CBC)             WireGuard hub
Open5GS 4G (MME/SGW/PGW/          PostgreSQL BSS central
HSS/PCRF/SMF/UPF)
strongSwan (fork Osmocom)   ←──── Starlink (IP fixe)
osmo-epdg (Erlang OTP)
Kamailio IMS
PostgreSQL BSS local
WireGuard spoke
Starlink (IP dynamique)
```

Principe clé : **chaque site fonctionne de façon autonome** (appels locaux, VoWiFi)
sans le serveur central. Le central apporte uniquement l'accès WAN/PSTN.

---

## PLACEHOLDERs — à remplacer avant mise en service

| Token | Ce qu'il faut | Priorité |
|---|---|---|
| `PLACEHOLDER` (MNC) | MNC affecté par DGPT Papeete | **CRITIQUE** |
| `SITE_LOCAL_IP` | IP LAN du PC site (10.0.0.x) | **CRITIQUE** |
| `PLACEHOLDER_ARFCN_S1/S2/S3` | ARFCNs secteurs — régulation | Radio |
| `PLACEHOLDER_PWR_DBM` | Puissance TRX en dBm | Radio |
| `PLACEHOLDER_KI` / `PLACEHOLDER_OPC` | Clés SIM 128 bits | Par SIM |

⚠ Rien ne fonctionne tant que MNC = PLACEHOLDER.

---

## Stack technique

- **OS** : Ubuntu 24.04 LTS x86_64
- **2G** : Osmocom (dépôt sysmocom), sysmoBTS 2100, Band 28 700 MHz
- **4G** : Open5GS, eNodeB, Band 28 FDD
- **VoWiFi** : strongSwan fork `osmo-epdg`, Erlang/OTP 26, Kamailio IMS
- **Core** : FreeSWITCH, OVH SIP trunk
- **VPN** : WireGuard hub-and-spoke
- **BSS** : PostgreSQL 16, Node.js (`pg` uniquement), HTML/CSS/JS vanilla
- **SIM** : sysmoISIM-SJA2, SCR3310, pySIM
- **Monitoring** : Nagios Core
- **Backhaul** : Starlink (IP dynamique sur sites, IP fixe au central)
