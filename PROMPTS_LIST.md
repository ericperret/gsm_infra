# PROMPTS — Opérateur téléphonie mobile Polynésie
## 27 prompts — ordre d'exécution

---

## PHASE 1 — OSMOCOM 2G (6 prompts)

### PROMPT 1 — Préparation système
```
Install Osmocom 2G sur Ubuntu x86_64.
Étape 1/6 : mise à jour système + ajout dépôt sysmocom officiel + dépendances communes.
Commence par me demander : version Ubuntu exacte et adresse IP du PC.
Toutes les commandes en blocs bash. Stop après vérification dépôt OK.
```

### PROMPT 2 — Installation composants
```
Install Osmocom 2G sur Ubuntu x86_64. Dépôt sysmocom déjà configuré.
Étape 2/6 : installer dans l'ordre OsmoSTP, OsmoHLR, OsmoMGW, OsmoMSC, OsmoSGSN, OsmoBSC, OsmoCBC.
Commandes bash uniquement. Stop après vérification que tous les paquets sont installés.
```

### PROMPT 3 — Configuration
```
Install Osmocom 2G sur Ubuntu x86_64. Composants installés.
Étape 3/6 : configurer chaque composant pour MCC=547 MNC=PLACEHOLDER.
Un fichier de configuration complet par composant. Stop après écriture des fichiers.
```

### PROMPT 4 — Démarrage services
```
Install Osmocom 2G sur Ubuntu x86_64. Composants configurés.
Étape 4/6 : activer et démarrer tous les services systemd dans l'ordre.
Vérifier que chaque service est actif avant de passer au suivant. Bash uniquement.
```

### PROMPT 5 — Configuration OsmoBSC
```
Install Osmocom 2G sur Ubuntu x86_64. Services actifs.
Étape 5/6 : configurer OsmoBSC pour sysmoBTS 2100 Abis-over-IP, 3 secteurs 120°.
ARFCN et puissance en PLACEHOLDER. Bash + fichier de config complet.
```

### PROMPT 6 — Vérification finale
```
Install Osmocom 2G sur Ubuntu x86_64. OsmoBSC configuré.
Étape 6/6 : vérifier que tous les services communiquent, port Abis 3003 ouvert, VTY actif.
Lister les commandes de test. Stop quand le système est prêt à recevoir le sysmoBTS 2100.
```

---

## PHASE 2 — OPEN5GS (5 prompts)

### PROMPT 7-1 — Dépôt et installation
```
Install Open5GS 4G LTE sur Ubuntu x86_64. Osmocom 2G déjà opérationnel.
Étape 1/5 : ajout dépôt Open5GS officiel + installation tous les composants.
Commence par me demander : version Ubuntu exacte et adresse IP du PC.
Bash uniquement. Stop après vérification paquets installés.
```

### PROMPT 7-2 — Configuration MME/SGW/PGW
```
Install Open5GS 4G LTE sur Ubuntu x86_64. Composants installés.
Étape 2/5 : configurer MME, SGW, PGW pour MCC=547 MNC=PLACEHOLDER IP=PLACEHOLDER Band 28 (700 MHz).
Fichiers de configuration complets. Stop après écriture fichiers.
```

### PROMPT 7-3 — HSS et abonnés
```
Install Open5GS 4G LTE sur Ubuntu x86_64. MME/SGW/PGW configurés.
Étape 3/5 : configurer HSS, créer un abonné test IMSI=PLACEHOLDER.
Bash uniquement. Stop après vérification HSS actif.
```

### PROMPT 7-4 — Démarrage services
```
Install Open5GS 4G LTE sur Ubuntu x86_64. Composants configurés.
Étape 4/5 : activer et démarrer tous les services systemd dans l'ordre.
Vérifier chaque service avant de passer au suivant. Bash uniquement.
```

### PROMPT 7-5 — Vérification finale
```
Install Open5GS 4G LTE sur Ubuntu x86_64. Services actifs.
Étape 5/5 : vérifier communication entre composants, port S1AP ouvert pour RRU Band 28.
Lister commandes de test. Stop quand prêt à recevoir le BBU.
```

---

## PHASE 3 — SIM PHYSIQUE (3 prompts)

### PROMPT 8-1 — Installation pySIM
```
Install pySIM sur Ubuntu x86_64 pour gravure SIM sysmoISIM-SJA2.
Étape 1/3 : installation pySIM depuis gitea.osmocom.org + lecteur SCR3310 USB.
Commence par me demander la version Ubuntu. Bash uniquement. Stop après vérification lecteur détecté.
```

### PROMPT 8-2 — Gravure première SIM
```
pySIM installé sur Ubuntu x86_64. Lecteur SCR3310 détecté. SIM sysmoISIM-SJA2 insérée.
Étape 2/3 : graver IMSI, Ki, OPC, ICCID, MCC=547, MNC=PLACEHOLDER sur la SIM.
Commence par me demander les valeurs IMSI Ki OPC ICCID. Bash uniquement.
```

### PROMPT 8-3 — Vérification SIM
```
SIM sysmoISIM-SJA2 gravée via pySIM.
Étape 3/3 : lire et vérifier le contenu de la SIM gravée, comparer avec les valeurs attendues.
Bash uniquement. Stop après confirmation SIM valide.
```

---

## PHASE 4 — IMS + WiFi CALLING (5 prompts)

### PROMPT 9-1 — strongSwan Osmocom fork
```
Install strongSwan fork Osmocom sur Ubuntu x86_64 IP=10.0.0.1.
Étape 1/5 : compiler depuis gitea.osmocom.org/ims-volte-vowifi/strongswan-epdg,
activer plugin CEIA osmo_epdg, patcher P-CSCF et DNS hardcodés → 10.0.0.1.
OsmoHLR déjà actif sur GSUP :4222. Pas de DNS — IP directe 10.0.0.1 partout.
Bash uniquement. Stop après service actif.
```

### PROMPT 9-2 — osmo-epdg
```
strongSwan actif sur Ubuntu x86_64 IP=10.0.0.1.
Étape 2/5 : installer et configurer osmo-epdg, lien vers strongSwan et OsmoHLR GSUP :4222.
MCC=547 MNC=PLACEHOLDER. Bash uniquement. Stop après service actif.
```

### PROMPT 9-3 — Kamailio IMS
```
osmo-epdg + strongSwan actifs sur Ubuntu x86_64 IP=10.0.0.1.
Étape 3/5 : installer Kamailio IMS, configurer pour appels locaux inter-abonnés.
Lien vers OsmoHLR GSUP :4222 et OsmoMSC. MCC=547 MNC=PLACEHOLDER.
Bash uniquement. Stop après service actif.
```

### PROMPT 9-4 — Lien Kamailio → OsmoMSC
```
Kamailio IMS actif sur Ubuntu x86_64 IP=10.0.0.1.
Étape 4/5 : configurer lien SIP entre Kamailio IMS et OsmoMSC pour appels sortants WAN.
Si WAN disponible → WireGuard → serveur central → OVH. Fichiers de config complets.
```

### PROMPT 9-5 — Vérification WiFi Calling
```
Stack complète WiFi Calling sur Ubuntu x86_64 IP=10.0.0.1.
Étape 5/5 : vérifier tunnel IKEv2 depuis téléphone Android test, appel local inter-abonnés,
appel sortant WAN si disponible. Bash uniquement. Stop après confirmation opérationnel.
```

---

## PHASE 5 — FREESWITCH (4 prompts)

### PROMPT 10-1 — Installation
```
Install FreeSWITCH sur Ubuntu x86_64 serveur central IP fixe.
Étape 1/4 : ajout dépôt FreeSWITCH officiel, installation.
Commence par me demander la version Ubuntu et l'IP publique. Bash uniquement.
```

### PROMPT 10-2 — SIP trunk OVH
```
FreeSWITCH installé sur Ubuntu x86_64.
Étape 2/4 : configurer SIP trunk OVH Telecom, authentification SIP, codec G711.
Commence par me demander login SIP OVH et IP OVH. Fichier de config complet.
```

### PROMPT 10-3 — Routage par profil
```
FreeSWITCH installé, SIP trunk OVH configuré.
Étape 3/4 : configurer routage appels sortants par profil abonné (standard/autorisé/VIP).
Destinations : Nouvelle-Calédonie, Tahiti, Métropole. Fichier dialplan complet.
```

### PROMPT 10-4 — Urgences
```
FreeSWITCH configuré avec routage par profil.
Étape 4/4 : configurer routage prioritaire QoS max pour 15, 17, 18, 112 vers PSAP Polynésie.
Toujours disponible quel que soit le profil. Fichier dialplan complet. Bash uniquement.
```

---

## PHASE 6 — WIREGUARD (3 prompts)

### PROMPT 11-1 — Serveur central
```
Install WireGuard sur Ubuntu x86_64 serveur central IP fixe.
Étape 1/3 : installer WireGuard, générer clés serveur, configurer interface wg0 hub central.
Commence par me demander l'IP publique fixe et le nombre de sites. Bash uniquement.
```

### PROMPT 11-2 — Configuration site
```
WireGuard serveur central opérationnel.
Étape 2/3 : configurer un site insulaire (Starlink IP dynamique) comme peer WireGuard.
Commence par me demander la clé publique du site et son sous-réseau. Bash uniquement.
```

### PROMPT 11-3 — Vérification multi-sites
```
WireGuard configuré serveur central + sites insulaires.
Étape 3/3 : vérifier connectivité entre tous les sites, ping inter-sites, handshake actif.
Bash uniquement. Stop après confirmation tunnel opérationnel.
```

---

## PHASE 7 — NAGIOS (3 prompts)

### PROMPT 12-1 — Installation
```
Install Nagios Core sur Ubuntu x86_64.
Étape 1/3 : installation Nagios Core depuis les sources officielles nagios.org.
Commence par me demander la version Ubuntu et l'IP du PC. Bash uniquement.
```

### PROMPT 12-2 — Sondes réseau
```
Nagios Core installé sur Ubuntu x86_64.
Étape 2/3 : configurer sondes pour sysmoBTS x2, RRU x3, BBU, Starlink, OsmoMSC, Open5GS, FreeSWITCH.
Commence par me demander les IPs des équipements. Fichiers de configuration complets.
```

### PROMPT 12-3 — Alertes SMS
```
Nagios Core configuré avec toutes les sondes.
Étape 3/3 : configurer alertes SMS vers numéro administrateur via OsmoMSC local.
Commence par me demander le numéro administrateur. Bash uniquement.
```

---

## PHASE 8 — BSS (3 prompts)

### PROMPT 13-1 — Base PostgreSQL
```
Install PostgreSQL sur Ubuntu x86_64 pour BSS opérateur téléphonie mobile MCC=547.
Étape 1/3 : installer PostgreSQL, créer base bss_operateur, créer les tables :
ABONNES, SIMS, NUMEROS, PROFILS, EVENEMENTS, ALERTES_CBS, OPERATEURS.
Schéma complet avec types, contraintes, index. Bash + SQL uniquement.
```

### PROMPT 13-2 — API REST
```
Base PostgreSQL BSS opérateur téléphonie mobile prête sur Ubuntu x86_64.
Étape 2/3 : développer API REST en JavaScript (Node.js) sans framework externe.
Endpoints : CRUD abonnés, CRUD SIM, attribution numéros, gestion profils, log événements.
Fichiers complets avec cartouche nom/date/version en commentaire.
```

### PROMPT 13-3 — Interface administration
```
API REST BSS opérateur téléphonie mobile prête sur Ubuntu x86_64.
Étape 3/3 : interface administration HTML/CSS/JavaScript sans librairie externe.
Pages : dashboard, abonnés, SIM, numéros, profils, FR-ALERT, rapports.
Service SMS numéro court interne pour abonnés (SOLDE, NUMERO, SIM, AIDE).
Cartouche nom/date/version en commentaire dans chaque fichier.
```

---

## RÉSUMÉ

- **Total prompts** : 27
- **Phases** : 8
- **Durée estimée** : 1 800 à 2 400 heures de développement + délais matériel
- **Ordre d'exécution** : strict (dépendances entre phases)

Chaque prompt doit être exécuté dans une **conversation séparée et neuve**.
