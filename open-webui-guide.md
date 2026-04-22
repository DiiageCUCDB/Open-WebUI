# Open WebUI — Guide d'installation & Suivi de présentation

## Table des matières

1. [Prérequis](#1-prérequis)
2. [Installation rapide (Docker)](#2-installation-rapide-docker)
3. [Installation alternative (pip)](#3-installation-alternative-pip)
4. [Installation avancée (Helm / Kubernetes)](#4-installation-avancée-helm--kubernetes)
5. [Architecture](#5-architecture)
6. [Premier démarrage & configuration](#6-premier-démarrage--configuration)
7. [Installer et choisir un modèle](#7-installer-et-choisir-un-modèle)
8. [Démonstration — Génération, Résumé, Q&A](#8-démonstration--génération-résumé-qa)
9. [Démonstration — RAG (base de connaissances)](#9-démonstration--rag-base-de-connaissances)
10. [Fonctionnalités avancées](#10-fonctionnalités-avancées)
11. [Limites & points de vigilance](#11-limites--points-de-vigilance)
12. [Ressources](#12-ressources)

## 1. Prérequis

| Composant | Minimum | Recommandé |
|-----------|---------|------------|
| **RAM** | 8 Go | 16 Go+ |
| **CPU** | 4 cœurs | 8 cœurs |
| **GPU** | Optionnel | NVIDIA (CUDA) / Apple Silicon (Metal) / AMD (ROCm) |
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

## 4. Installation avancée (Helm / Kubernetes)

```bash
# Ajouter le repo Helm
helm repo add open-webui https://helm.openwebui.com
helm repo update

# Installer avec valeurs par défaut
helm install open-webui open-webui/open-webui \
  --namespace open-webui \
  --create-namespace
```

## 5. Architecture

> **Slide de référence :** Slide 4

Open WebUI est structuré en couches découplées :

| Couche | Technologie | Rôle |
|--------|-------------|------|
| **Frontend** | SvelteKit / PWA | Interface conversationnelle, markdown, code highlight |
| **Backend** | FastAPI (Python) | WebSockets, Auth, RBAC, API REST |
| **Stockage** | SQLite / PostgreSQL + ChromaDB | Données applicatives + index vectoriel RAG |
| **Moteurs LLM** | Ollama, OpenAI, Anthropic, Azure, Groq… | Inférence locale ou distante |
| **Middleware** | Pipelines Python | Filtres, transformations, intégrations custom |

La communication navigateur ↔ backend s'effectue en HTTP/WebSockets. Le backend expose une API REST unifiée vers tous les moteurs LLM, qu'ils soient locaux (Ollama) ou cloud.

---

## 6. Premier démarrage & configuration

### Étapes initiales

1. Ouvrir **http://localhost:3000**
2. Cliquer **"Sign up"** → le **premier compte créé devient admin**
3. Renseigner : nom, email, mot de passe

---

## 7. Installer et choisir un modèle

> **Slide de référence :** Slide 5

### Via l'interface (recommandé)

1. Admin Panel → **Models** → champ "Pull a model"
2. Taper le nom du modèle, ex : `llama3.2:3b`
3. Cliquer le bouton de téléchargement

### Via la ligne de commande

```bash
# === CHAT GÉNÉRAL ===
ollama pull llama3.2:3b          # Chat général léger (~2 Go) ← point de départ conseillé
ollama pull llama3.3:70b         # Chat général qualité production (~45 Go)
ollama pull mistral:7b           # Équilibré qualité/performance (~4.1 Go)
ollama pull gemma3:9b            # Modèle Google récent (~5.5 Go)
ollama pull phi4:latest          # Très performant, léger — Microsoft (~2.5 Go)
ollama pull qwen2.5:7b           # Modèle performant (~4.4 Go)

# === CODE & RAISONNEMENT ===
ollama pull deepseek-coder-v2    # Code spécialisé (~6.7 Go)
ollama pull deepseek-r1:7b       # Raisonnement avancé / maths (~4.5 Go)
ollama pull codellama:7b         # Code — Meta (~3.8 Go)

# === RAG (obligatoire pour les knowledge bases) ===
ollama pull nomic-embed-text     # Embeddings — léger et efficace (~274 Mo)

# === VISION ===
ollama pull llava:13b            # Analyse d'images (~7.5 Go)

# Lister les modèles installés
ollama list

# Tester en CLI
ollama run llama3.2:3b "Bonjour, tu es capable de quoi ?"
```

### Guide de sélection par RAM disponible

| RAM disponible | Modèle conseillé | Taille |
|----------------|------------------|--------|
| 4 Go | `phi4:latest`, `qwen2.5:3b` | ~2–3 Go |
| 8 Go | `llama3.2:3b`, `mistral:7b` | ~2–4 Go |
| 16 Go | `llama3.1:8b`, `gemma3:9b` | ~8–10 Go |
| 32 Go | `llama3.3:70b-q4_K_M` | ~25 Go |
| 64 Go+ | `llama3.3:70b` (fp16) | ~45 Go |

> 💡 Commencer avec `llama3.2:3b` pour tester, passer ensuite à `llama3.3:70b-q4_K_M`. Toujours installer `nomic-embed-text` si vous utilisez le RAG.

### APIs Cloud configurables

En plus des modèles locaux, Open WebUI supporte directement : OpenAI GPT-4o / o1 / o3, Anthropic Claude 3.5 Sonnet / Opus, Google Gemini 2.0 Flash, Mistral API, Groq, Together AI et toute API compatible OpenAI.

---

## 8. Démonstration — Génération, Résumé, Q&A

> **Slide de référence :** Slide 6

### 8.1 Génération de contenu

Essayez ce prompt dans un nouveau chat :

```
Rédige un email professionnel pour reporter une réunion de projet au vendredi prochain.
Contexte : réunion de revue sprint avec l'équipe dev, reportée pour cause de déplacement.
Ton : formel, bienveillant. Longueur : 3 paragraphes maximum. Langue : français.
```

### 8.2 Résumé de document

1. Cliquer l'icône **trombone** (📎) dans la barre de saisie
2. Uploader un PDF (article, rapport, présentation)
3. Utiliser ce prompt :

```
Résume ce document en exactement 5 points clés, chacun sur une ligne.
Format : "• Point clé : explication courte (1 phrase)"
```

**Autres cas :** synthèse de longues réunions, extraction des points clés, rapport de veille automatique.

### 8.3 Q&A technique

```
Tu es un expert Python senior. Explique la différence entre @staticmethod et @classmethod.
Fournis :
1. Une définition claire de chacun
2. Un exemple de code concret pour chaque
3. Un tableau comparatif
4. Le cas d'usage idéal pour choisir l'un ou l'autre
```

### 8.4 Génération de code

```
Écris une fonction Python qui :
- Prend en entrée une liste de dictionnaires avec les clés "nom", "note" (0-20)
- Calcule la moyenne, la note min, la note max
- Retourne un rapport formaté en markdown
- Inclut des tests unitaires avec pytest
```

---

## 9. Démonstration — RAG (base de connaissances)

> **Slide de référence :** Slide 7

Le RAG (Retrieval-Augmented Generation) permet au modèle de répondre en s'appuyant sur vos propres documents. Le flux est : **Document → Chunking & Indexing → Recherche Sémantique → LLM + Contexte → Réponse fondée**.

### Étape 1 : Créer une Knowledge Base

1. **Workspace** (menu gauche) → **Knowledge** → bouton **"+"**
2. Nommer la base : `Documentation Technique`
3. Cliquer **"Add Content"** → uploader un ou plusieurs fichiers

**Formats supportés :** PDF, DOCX, TXT, MD, CSV, XLSX
**Ou ajouter une URL :** la page est crawlée automatiquement
**Autres sources :** YouTube (transcription automatique), Google Drive, Notion

### Étape 2 : Utiliser le RAG en chat

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
- Les **sources citées** apparaissent sous la réponse (cliquer pour voir le chunk exact)
- Comparer une réponse **avec** et **sans** RAG activé
- Montrer que le modèle répond "Je ne sais pas" si l'info n'est pas dans les docs
- Le reranking (CrossEncoder) améliore la pertinence des chunks sélectionnés

---

## 10. Fonctionnalités avancées

> **Slide de référence :** Slide 8

### 10.1 Gestion des conversations

Historique persistant avec tags, dossiers et export JSON/MD. Partage par lien. Conversations épinglées.

### 10.2 Multi-utilisateurs & RBAC

Comptes locaux ou OAuth/LDAP/SSO. Rôles Admin/User avec contrôle d'accès par modèle et par groupe.

### 10.3 Personnalisation UI

Thèmes clair/sombre, personas (system prompts), prompts partagés, banners admin.

### 10.4 Créer un assistant personnalisé (Model)

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

### 10.5 Plugins & outils intégrés

| Type | Description |
|------|-------------|
| **Fonctions Python** | Outils, filtres, actions en Python pur |
| **Outils Web** | Recherche (SearXNG, Google PSE, Brave), météo, calculatrice |
| **Code Interpreter** | Exécution Python sandbox in-chat |
| **Vision / Multimodal** | Analyse d'images, OCR, graphiques |
| **Text-to-Speech** | ElevenLabs, OpenAI TTS, Kokoro (local) |
| **Web Search** | SearXNG auto-hébergé, Google PSE, Brave Search |

### 10.6 Activer la recherche web

3. Dans un chat, activer l'icône 🌐 dans la barre de saisie

```
Quelles sont les dernières nouveautés d'Open WebUI publiées cette semaine ?
```

### 10.7 Ajouter une fonction Python

1. **Workspace** → **Tools** → **"+"**
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

---

## 11. Limites & points de vigilance

> **Slide de référence :** Slide 10

### Ressources matérielles

- LLM 7B+ nécessitent **16 Go RAM minimum**
- Llama 3.3 70B → **~45 Go RAM** ou GPU 40 Go VRAM
- Latence élevée en CPU-only : **2–5 tokens/sec**

### Sécurité & production

- Reverse proxy HTTPS **obligatoire** (Nginx / Caddy)
- Secrets API à externaliser (Vault, variables d'environnement)
- Audit logging limité sans plugin supplémentaire

### Limites fonctionnelles

- Pas d'app mobile native (PWA uniquement)
- RAG limité sur très grands corpus (>100k documents)
- Mises à jour fréquentes → breaking changes possibles

---

## 12. Ressources

| Ressource | URL |
|-----------|-----|
| 📖 Documentation officielle | https://docs.openwebui.com |
| 🐙 GitHub | https://github.com/open-webui/open-webui |
| 🔧 Fonctions & plugins | https://openwebui.com/functions |
| 🦙 Bibliothèque Ollama | https://ollama.com/library |
| 🚀 Releases & changelog | https://github.com/open-webui/open-webui/releases |
| 💬 Discord communauté | https://discord.gg/5rJgQTnV4s |

### Commandes de diagnostic utiles

```bash
# Vérifier que les conteneurs tournent
docker compose ps

# Logs Open WebUI
docker compose logs -f open-webui

# Logs Ollama
docker compose logs -f ollama

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