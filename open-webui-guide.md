# Open WebUI — Guide d'installation & Suivi de présentation

> **Branche Git :** `prenom-nom/open-webui-use-cases`  
> **Structure :** `docs/` · `schema/` · `slides/` · `demo/`

---

## Table des matières

1. [Prérequis](#1-prérequis)
2. [Installation rapide (Docker)](#2-installation-rapide-docker)
3. [Installation alternative (pip)](#3-installation-alternative-pip)
4. [Installation avancée (Helm / Kubernetes)](#4-installation-avancée-helm--kubernetes)
5. [Premier démarrage & configuration](#5-premier-démarrage--configuration)
6. [Installer et choisir un modèle](#6-installer-et-choisir-un-modèle)
7. [Démonstration — Génération, Résumé, Q&A](#7-démonstration--génération-résumé-qa)
8. [Démonstration — RAG (base de connaissances)](#8-démonstration--rag-base-de-connaissances)
9. [Fonctionnalités avancées](#9-fonctionnalités-avancées)
10. [Sécurisation pour la production](#10-sécurisation-pour-la-production)
11. [Comparatif & choix de solution](#11-comparatif--choix-de-solution)
12. [Ressources](#12-ressources)

---

## 1. Prérequis

| Composant | Minimum | Recommandé |
|-----------|---------|------------|
| **RAM** | 8 Go | 16 Go+ |
| **CPU** | 4 cœurs | 8 cœurs |
| **GPU** | Optionnel | NVIDIA (CUDA) / Apple Silicon (Metal) |
| **Stockage** | 10 Go libres | 50 Go+ (modèles) |
| **OS** | Linux, macOS, Windows (WSL2) | Ubuntu 22.04 LTS |
| **Docker** | ≥ 24.0 | dernière version |
| **Python** | 3.11+ (si pip) | 3.12 |

### Vérifier Docker

```bash
docker --version        # Docker version 24+
docker compose version  # Docker Compose v2+
```

### Installer Ollama (moteur LLM local)

```bash
# Linux / macOS
curl -fsSL https://ollama.com/install.sh | sh

# Vérifier
ollama --version
ollama serve   # démarre le serveur (port 11434)
```

---

## 2. Installation rapide (Docker)

### Option A — Open WebUI seul (Ollama sur l'hôte)

```bash
docker run -d \
  -p 3000:8080 \
  --add-host=host.docker.internal:host-gateway \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:main
```

> **Accès :** http://localhost:3000

### Option B — Open WebUI + Ollama intégrés (tout-en-un)

```bash
docker run -d \
  -p 3000:8080 \
  -v ollama:/root/.ollama \
  -v open-webui:/app/backend/data \
  --name open-webui \
  --restart always \
  ghcr.io/open-webui/open-webui:ollama
```

> Cette image embarque Ollama — aucune installation séparée nécessaire.

### Option C — Docker Compose (recommandé pour la prod)

Créez un fichier `docker-compose.yml` :

```yaml
version: "3.8"

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    volumes:
      - ollama:/root/.ollama
    ports:
      - "11434:11434"
    restart: unless-stopped

  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    depends_on:
      - ollama
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
      - WEBUI_AUTH=true
    volumes:
      - open-webui:/app/backend/data
    ports:
      - "3000:8080"
    restart: unless-stopped

volumes:
  ollama:
  open-webui:
```

```bash
docker compose up -d
docker compose logs -f open-webui   # suivre les logs
```

### Mise à jour

```bash
docker pull ghcr.io/open-webui/open-webui:main
docker stop open-webui && docker rm open-webui
# relancer la commande docker run ci-dessus
```

---

## 3. Installation alternative (pip)

```bash
# Créer un environnement virtuel (recommandé)
python3 -m venv venv
source venv/bin/activate       # Linux/macOS
# venv\Scripts\activate        # Windows

# Installer
pip install open-webui

# Démarrer
open-webui serve

# Accès : http://localhost:8080
```

> **Note :** Nécessite Python 3.11+. Ollama doit tourner séparément (`ollama serve`).

---

## 4. Installation avancée (Helm / Kubernetes)

```bash
# Ajouter le repo Helm
helm repo add open-webui https://helm.openwebui.com
helm repo update

# Installer avec valeurs par défaut
helm install open-webui open-webui/open-webui \
  --namespace open-webui \
  --create-namespace

# Personnaliser (exemple values.yaml)
helm install open-webui open-webui/open-webui \
  --namespace open-webui \
  -f values.yaml
```

Exemple `values.yaml` minimal :

```yaml
replicaCount: 2

ingress:
  enabled: true
  host: "open-webui.exemple.com"
  tls:
    enabled: true

ollama:
  enabled: true

persistence:
  enabled: true
  size: 10Gi
```

---

## 5. Premier démarrage & configuration

### Étapes initiales

1. Ouvrir **http://localhost:3000**
2. Cliquer **"Sign up"** → le **premier compte créé devient admin**
3. Renseigner : nom, email, mot de passe

### Configuration admin essentielle

Accéder au **Admin Panel** (icône en bas à gauche) :

| Section | Paramètre | Valeur recommandée |
|---------|-----------|-------------------|
| General | Default Model | llama3.2:3b |
| General | Enable Community Sharing | Off (prod) |
| Users | Default User Role | pending (prod) |
| Connections | Ollama API URL | http://localhost:11434 |
| Documents | Embedding Model | nomic-embed-text |

### Variables d'environnement utiles

```bash
# Désactiver l'inscription publique
ENABLE_SIGNUP=false

# Forcer l'authentification
WEBUI_AUTH=true

# URL publique (si reverse proxy)
WEBUI_URL=https://open-webui.exemple.com

# Clé secrète JWT (générer avec openssl rand -hex 32)
WEBUI_SECRET_KEY=votre_clé_secrète_très_longue

# Activer OpenAI
OPENAI_API_KEY=sk-...
OPENAI_API_BASE_URL=https://api.openai.com/v1
```

---

## 6. Installer et choisir un modèle

### Via l'interface (recommandé)

1. Admin Panel → **Models** → champ "Pull a model"
2. Taper le nom du modèle, ex : `llama3.2:3b`
3. Cliquer le bouton de téléchargement

### Via la ligne de commande

```bash
# Modèles recommandés par cas d'usage
ollama pull llama3.2:3b          # Chat général léger (2 Go)
ollama pull llama3.3:70b         # Chat général qualité (45 Go)
ollama pull deepseek-r1:7b       # Raisonnement / maths
ollama pull deepseek-coder-v2    # Code
ollama pull nomic-embed-text     # Embeddings pour RAG (obligatoire)
ollama pull llava:13b            # Vision (analyse d'images)
ollama pull phi4                 # Petit modèle très performant (Microsoft)

# Lister les modèles installés
ollama list

# Tester en CLI
ollama run llama3.2:3b "Bonjour, tu es capable de quoi ?"
```

### Guide de sélection par RAM disponible

| RAM disponible | Modèle conseillé | Taille |
|----------------|------------------|--------|
| 4 Go | phi4:3.8b, qwen2.5:3b | ~2-3 Go |
| 8 Go | llama3.2:3b, mistral:7b | ~4-5 Go |
| 16 Go | llama3.1:8b, gemma3:9b | ~8-10 Go |
| 32 Go | llama3.3:70b-q4_K_M | ~25 Go |
| 64 Go+ | llama3.3:70b (fp16) | ~45 Go |

---

## 7. Démonstration — Génération, Résumé, Q&A

> **Slide de référence :** Slide 6

### 7.1 Génération de contenu

Essayez ce prompt dans un nouveau chat :

```
Rédige un email professionnel pour reporter une réunion de projet au vendredi prochain.
Contexte : réunion de revue sprint avec l'équipe dev, reportée pour cause de déplacement.
Ton : formel, bienveillant. Longueur : 3 paragraphes maximum. Langue : français.
```

**Points à montrer :**
- Streaming en temps réel (les tokens arrivent au fur et à mesure)
- Bouton **"Copy"** pour copier la réponse
- Bouton **"Regenerate"** pour une nouvelle version
- Changer de modèle dans le sélecteur en haut et comparer

### 7.2 Résumé de document

1. Cliquer l'icône **trombone** (📎) dans la barre de saisie
2. Uploader un PDF (article, rapport, présentation)
3. Utiliser ce prompt :

```
Résume ce document en exactement 5 points clés, chacun sur une ligne.
Format : "• Point clé : explication courte (1 phrase)"
```

### 7.3 Q&A technique

```
Tu es un expert Python senior. Explique la différence entre @staticmethod et @classmethod.
Fournis :
1. Une définition claire de chacun
2. Un exemple de code concret pour chaque
3. Un tableau comparatif
4. Le cas d'usage idéal pour choisir l'un ou l'autre
```

### 7.4 Génération de code

```
Écris une fonction Python qui :
- Prend en entrée une liste de dictionnaires avec les clés "nom", "note" (0-20)
- Calcule la moyenne, la note min, la note max
- Retourne un rapport formaté en markdown
- Inclut des tests unitaires avec pytest
```

---

## 8. Démonstration — RAG (base de connaissances)

> **Slide de référence :** Slide 7

### Étape 1 : Créer une Knowledge Base

1. **Workspace** (menu gauche) → **Knowledge** → bouton **"+"**
2. Nommer la base : `Documentation Technique`
3. Cliquer **"Add Content"** → uploader un ou plusieurs fichiers

**Formats supportés :** PDF, DOCX, TXT, MD, CSV, XLSX
**Ou ajouter une URL :** coller une URL de page web → elle est crawlée automatiquement

### Étape 2 : Configurer les embeddings (une seule fois)

Admin Panel → **Documents** :
- **Embedding Model :** `nomic-embed-text` (local, gratuit)
- **Chunk Size :** 1000 tokens
- **Chunk Overlap :** 100 tokens
- **Top K :** 5

### Étape 3 : Utiliser le RAG en chat

```
# Dans la barre de saisie, taper # pour sélectionner la knowledge base
# Puis poser une question précise sur le document
```

Exemple de prompt RAG :

```
En te basant uniquement sur les documents fournis, explique :
1. Quelle est la procédure décrite pour X ?
2. Quelles sont les contraintes mentionnées ?
3. Y a-t-il des exceptions ou cas particuliers ?
Cite les sources pour chaque point.
```

**Points à montrer :**
- Les **sources citées** apparaissent sous la réponse (cliquer pour voir le chunk)
- Comparer une réponse **avec** et **sans** RAG activé
- Montrer que le modèle dit "Je ne sais pas" si l'info n'est pas dans les docs

---

## 9. Fonctionnalités avancées

> **Slide de référence :** Slide 8

### 9.1 Créer un assistant personnalisé (Model)

1. **Workspace** → **Models** → **"+"**
2. Renseigner :
   - **Nom :** "Assistant Juridique"
   - **Modèle de base :** llama3.3:70b
   - **System Prompt :**

```
Tu es un assistant juridique spécialisé en droit français des contrats.
Tu analyses les documents avec précision et signales toujours les clauses à risque.
Tu ne donnes jamais d'avis définitif — tu recommandes toujours de consulter un avocat.
Tu réponds en français, de façon structurée avec des titres markdown.
```
   - Attacher une **Knowledge Base** de documents juridiques
3. Sauvegarder → l'assistant apparaît dans le sélecteur de modèle

### 9.2 Activer la recherche web

1. Admin Panel → **Settings** → **Web Search**
2. Choisir le moteur : **SearXNG** (auto-hébergé) ou **DuckDuckGo**
3. Dans un chat, activer l'icône 🌐 dans la barre de saisie

```
[Avec recherche web activée]
Quelles sont les dernières nouveautés d'Open WebUI publiées cette semaine ?
```

### 9.3 Ajouter une fonction Python

1. **Workspace** → **Functions** → **"+"**
2. Coller cette fonction exemple :

```python
"""
title: Horloge
description: Retourne la date et l'heure actuelles
"""

def get_current_datetime(timezone: str = "Europe/Paris") -> str:
    """
    Retourne la date et l'heure actuelles dans le fuseau horaire donné.
    :param timezone: Fuseau horaire (ex: Europe/Paris, UTC)
    """
    from datetime import datetime
    import pytz
    
    tz = pytz.timezone(timezone)
    now = datetime.now(tz)
    return now.strftime(f"📅 %A %d %B %Y | ⏰ %H:%M:%S ({timezone})")
```

3. Activer la fonction → elle devient disponible comme outil dans les chats

### 9.4 Raccourcis clavier utiles

| Raccourci | Action |
|-----------|--------|
| `Ctrl + Shift + N` | Nouvelle conversation |
| `/` dans la barre | Accès aux prompts partagés |
| `#` dans la barre | Sélectionner une knowledge base |
| `@` dans la barre | Mentionner un modèle spécifique |
| `Ctrl + Enter` | Envoyer le message |
| `Escape` | Arrêter la génération |

---

## 10. Ressources

| Ressource | URL |
|-----------|-----|
| 📖 Documentation officielle | https://docs.openwebui.com |
| 🐙 GitHub | https://github.com/open-webui/open-webui |
| 🔧 Fonctions & plugins | https://openwebui.com/functions |
| 🦙 Bibliothèque Ollama | https://ollama.com/library |
| 💬 Discord communauté | https://discord.gg/5rJgQTnV4s |
| 🐦 Mises à jour | https://github.com/open-webui/open-webui/releases |

### Commandes de diagnostic utiles

```bash
# Vérifier que les conteneurs tournent
docker ps

# Logs Open WebUI
docker logs open-webui -f

# Logs Ollama
docker logs ollama -f

# Espace disque utilisé par les volumes
docker system df -v

# Redémarrer proprement
docker compose restart

# Sauvegarder les données
docker run --rm \
  -v open-webui:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/open-webui-backup-$(date +%Y%m%d).tar.gz /data
```