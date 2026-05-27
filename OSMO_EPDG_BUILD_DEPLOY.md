% osmo-epdg Build & Deployment Guide
% 2026-05-27 | v1.0

# osmo-epdg : Build et Déploiement

## Vue d'ensemble

osmo-epdg est une implémentation ePDG (Evolved Packet Data Gateway) en Erlang/OTP pour VoWiFi. Ce document couvre la chaîne complète : build sur une machine de développement et déploiement sur Ubuntu x86_64.

## Prérequis

### Machine de build

- **OS** : Ubuntu 22.04 LTS ou supérieur (x86_64)
- **Erlang/OTP** : 25.2.3 minimum (obligatoire pour gen_statem et features OTP)
- **rebar3** : dernier version
- **Dépendances système** :
  ```bash
  sudo apt install libpcap-dev build-essential erlang
  ```

**Note importante** : Erlang doit être >= 25.2.3. Ubuntu 22.04 livre OTP 24 en paquet apt — compiler OTP 25+ depuis source ou utiliser kerl.

### Machine cible

- **OS** : Ubuntu 22.04 LTS (x86_64)
- **Erlang/OTP** : 25.2.3 minimum
- **Services externes requis** :
  - OsmoHLR actif (GSUP sur port 4222)
  - strongSwan configuré (IKEv2/IPSec pour VoWiFi)
  - PGW accessible (GTPv2-C)

## Étape 1 : Récupération du source

```bash
mkdir -p ~/Downloads/Erlang
cd ~/Downloads/Erlang
git clone https://gerrit.osmocom.org/erlang/osmo-epdg
cd osmo-epdg
```

Le dépôt est sur Gerrit. Authentification : aucune requise pour clonage en lecture.

## Étape 2 : Préparation rebar.config

Deux modifications obligatoires dans `rebar.config` :

### 2.1 — Nom de release sans tiret

**Ligne actuelle** (problématique) :
```erlang
{relx,
 [{release, {"osmo-epdg", "0.1.1"}, [osmo_epdg]},
```

**Correction** — remplacer le tiret par underscore (les atoms Erlang n'acceptent pas de tiret) :
```erlang
{relx,
 [{release, {osmo_epdg, "0.1.1"}, [osmo_epdg]},
```

**Script awk** :
```bash
awk '{gsub(/\{release, \{"osmo-epdg"/, "{release, {osmo_epdg")}1' rebar.config > rebar.config.tmp && mv rebar.config.tmp rebar.config
```

### 2.2 — Désactiver dev_mode (pour une release autonome)

**Ligne actuelle** :
```erlang
{dev_mode, true},
```

**Correction** :
```erlang
{dev_mode, false},
```

**Script awk** :
```bash
awk '{gsub(/\{dev_mode, true\}/, "{dev_mode, false}")}1' rebar.config > rebar.config.tmp && mv rebar.config.tmp rebar.config
```

**Raison** : En `dev_mode: true`, rebar3 crée des symlinks vers `_build/default/lib/` au lieu de copier les fichiers. La release ne serait pas portable.

## Étape 3 : Compilation

### 3.1 — Compiler les dépendances et le projet

```bash
cd ~/Downloads/Erlang/osmo-epdg
rebar3 compile
```

**Temps estimé** : 3-5 minutes selon la machine.

**Sortie attendue** : zéro erreur, environ 1000 warnings (normal, code legacy).

**Dépendances résolues automatiquement** (téléchargées depuis GitHub/Gerrit) :
- `lager` — logging
- `gtplib` — protocole GTP
- `gtp_u_kmod` — tunnel GTP-U (module kernel)
- `osmo_ss7` — protocole SS7 (gros projet, ~500 modules)
- `osmo_gsup` — protocole GSUP (branche `osmocom/epdg`)

### 3.2 — Assembler la release

```bash
rebar3 release
```

**Sortie attendue** :
```
Release successfully assembled: _build/default/rel/osmo_epdg
```

**Note** : Le warning "Missing application sasl" est sans conséquence (nécessaire uniquement pour upgrades à chaud).

## Étape 4 : Vérification de la release

```bash
du -sh ~/Downloads/Erlang/osmo-epdg/_build/default/rel/osmo_epdg/
```

**Taille attendue** : ~40 Mo (contient tous les modules compilés, pas de symlinks).

Structure :
```
osmo_epdg/
  bin/        → scripts de démarrage (start, stop, console)
  lib/        → modules compilés (osmo_epdg + dépendances)
  releases/   → metadata release (version, config)
```

## Étape 5 : Packaging pour déploiement

### 5.1 — Créer l'archive

```bash
cd ~/Downloads/Erlang/osmo-epdg/_build/default/rel
tar czf ~/osmo_epdg_release-0.1.1.tar.gz osmo_epdg/
```

### 5.2 — Vérifier l'archive

```bash
du -sh ~/osmo_epdg_release-0.1.1.tar.gz
```

**Taille attendue** : ~10 Mo (compressée).

## Étape 6 : Déploiement sur la cible

### 6.1 — Transfert vers la machine cible

```bash
scp ~/osmo_epdg_release-0.1.1.tar.gz user@10.0.0.1:/opt/
```

### 6.2 — Extraction et préparation

```bash
ssh user@10.0.0.1
cd /opt
tar xzf osmo_epdg_release-0.1.1.tar.gz
cd osmo_epdg
```

### 6.3 — Configuration (sys.config)

Adapter les paramètres réseau dans `releases/0.1.1/sys.config` :

| Paramètre | Valeur par défaut | À adapter | Exemple |
|---|---|---|---|
| `gsup_local_ip` | `"0.0.0.0"` | Interface d'écoute GSUP | `"10.0.0.1"` |
| `gsup_local_port` | `4222` | Port GSUP (doit matcher OsmoHLR) | `4222` |
| `dia_swx_remote_ip` | `"127.0.0.1"` | IP du HSS (SWx Diameter) | `"10.0.0.10"` |
| `dia_swx_remote_port` | `3868` | Port Diameter SWx | `3868` |
| `dia_s6b_local_ip` | `"127.0.0.10"` | IP locale S6b (PGW) | `"10.0.0.1"` |
| `gtpc_local_ip` | `"127.0.0.2"` | IP locale GTP-C | `"10.0.0.1"` |
| `gtpc_remote_ip` | `"127.0.0.1"` | IP du PGW | `"10.0.0.2"` |
| `gtp_u_kmod` socket IP | `127.0.0.2` | IP locale GTP-U (tunnel) | `"10.0.0.1"` |

**Exemple complet** pour 10.0.0.1 (ePDG) vers 10.0.0.10 (HSS) et 10.0.0.2 (PGW) :

```erlang
{osmo_epdg,
 [
   {gsup_local_ip, "10.0.0.1"},
   {gsup_local_port, 4222},
   {dia_swx_remote_ip, "10.0.0.10"},
   {dia_swx_remote_port, 3868},
   {dia_s6b_local_ip, "10.0.0.1"},
   {dia_s6b_local_port, 3868},
   {gtpc_local_ip, "10.0.0.1"},
   {gtpc_local_port, 2123},
   {gtpc_remote_ip, "10.0.0.2"},
   {gtpc_remote_port, 2123}
 ]},
 {gtp_u_kmod, [
   {sockets, [{gtp0, [{ip, {10,0,0,1}}, {role, sgsn}, freebind]}]}
 ]}
```

### 6.4 — Démarrage

```bash
./bin/osmo_epdg start
```

ou en foreground (debug) :

```bash
./bin/osmo_epdg foreground
```

### 6.5 — Vérification

```bash
# Logs
tail -f log/*.log

# Vérifier les connexions
netstat -tlnp | grep erl
```

**Connexions attendues** :
- Port 4222 TCP (écoute GSUP d'OsmoHLR)
- Port 2123 UDP (client GTP-C vers PGW)
- Port 3868 SCTP/TCP (client Diameter SWx vers HSS)

## Architecture en production

```
strongSwan (IKEv2 VoWiFi)
    ↓ GSUP/IPA TCP 4222
osmo-epdg (10.0.0.1)
    ↓ GTPv2-C UDP 2123
PGW (10.0.0.2)
    ↓ Diameter SWx SCTP 3868
HSS (10.0.0.10)
```

## Troubleshooting

| Symptôme | Cause | Solution |
|---|---|---|
| `fatal error: pcap.h: No such file or directory` | Lib pcap manquante au build | `sudo apt install libpcap-dev` |
| `badarg` en relx (release phase) | Tiret dans nom release | Vérifier `rebar.config` : `{release, {osmo_epdg, ...}` |
| Symlinks dans release | `dev_mode: true` | Vérifier `rebar.config` : `{dev_mode, false}` |
| GSUP connection refused | OsmoHLR pas actif sur 4222 | Vérifier OsmoHLR startup |
| Diameter SWx timeout | HSS pas accessible | Vérifier IP/port HSS dans `sys.config` |
| GTP-U tunnel down | gtp_u_kmod pas chargé | `lsmod | grep gtp` (module kernel doit être présent) |

## Notes de sécurité et documentation

- **Logs** : osmo-epdg crée des logs dans `log/` (debug.log, error.log)
- **IMSI dans les logs** : sensitive — restreindre l'accès aux logs en production
- **Fichiers de config** : `sys.config` contient les IPs et credentials — ne pas versionner
- **Firewall** : Ouvrir ports 4222 (GSUP), 2123 (GTP), 3868 (Diameter)
- **Redémarrage** : Les sessions UE en cours seront perdues (pas de persistence)

## Références

- 3GPP TS 29.273 — ePDG/AAA interfaces (SWm, SWx, S6b)
- 3GPP TS 29.274 — GTPv2-C
- osmocom.org — osmo-epdg wiki et gerrit
