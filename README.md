# Open WebUI Stack

> Interface web IA locale, souveraine et extensible — propulsée par Ollama, SearXNG et Docker.

## ⚡ Démarrage rapide

### 1. Prérequis

```bash
docker --version        # ≥ 24.0
docker compose version  # v2+
```

> **RAM recommandée :** 8 Go minimum, 16 Go+ pour les grands modèles. GPU optionnel (CUDA / Metal / ROCm).

### 2. Cloner & configurer

```bash
git clone <votre-repo>
cd open-webui-demo

# Générer des clés secrètes
echo "WEBUI_SECRET_KEY=$(openssl rand -hex 32)" > .env
echo "SEARXNG_SECRET_KEY=$(openssl rand -hex 32)" >> .env
```

### 3. Démarrer les services

```bash
docker compose up -d
```

### 4. Installer les modèles

```bash
chmod +x scripts/init-models.sh
./scripts/init-models.sh
```

### 5. Ouvrir l'interface

=> **http://localhost:3000** — le premier compte créé devient administrateur.

---

## Structure du projet

```
open-webui-demo/
├── docker-compose.yml          # Orchestration des services
├── .env                        # Variables d'environnement (secrets)
├── .gitignore                  # Exclut data/ du dépôt
├── searxng/
│   └── settings.yml            # Configuration SearXNG
├── scripts/
│   ├── init-models.sh          # Installateur interactif de modèles
│   └── demo-functions.py       # Exemple de fonction Python (météo)
└── data/                       # Volumes persistants (ignoré par git)
    ├── ollama/                  # Modèles téléchargés
    └── open-webui/              # Base de données & uploads
```

---

## 🧠 Choisir un modèle

### Modèles locaux via Ollama

| RAM dispo | Modèle conseillé | Taille |
|-----------|------------------|--------|
| 4 Go | `phi4:latest` | ~2.5 Go |
| 8 Go | `llama3.2:3b` | ~2 Go |
| 16 Go | `mistral:7b` | ~4.1 Go |
| 32 Go | `llama3.3:70b-q4_K_M` | ~25 Go |

### Modèles essentiels

```bash
# Chat général (léger)
ollama pull llama3.2:3b

# Embeddings pour le RAG (obligatoire si vous utilisez les knowledge bases)
ollama pull nomic-embed-text

# Code
ollama pull deepseek-coder-v2

# Vision (analyse d'images)
ollama pull llava:13b
```

L'installateur interactif `./scripts/init-models.sh` propose des **packs prédéfinis** (basic, standard, advanced, rag, code) et une sélection personnalisée.

### APIs Cloud supportées

- OpenAI GPT-4o, o1, o3
- Anthropic Claude 3.5 Sonnet / Opus
- Google Gemini 2.0 Flash
- Mistral API, Groq, Together et toute API compatible OpenAI

## Fonctionnalités clés

### RAG — Base de connaissances

1. **Workspace → Knowledge → `+`** pour créer une base documentaire
2. Importer vos fichiers : PDF, DOCX, TXT, MD, CSV, XLSX — ou coller une URL (crawl automatique)
3. Dans le chat, taper `#` pour sélectionner la base et poser des questions ciblées

**Sources supportées :** PDF, DOCX, TXT, MD, URLs, YouTube (transcription auto), Google Drive, Notion.

**Moteurs vectoriels :** ChromaDB (défaut, embarqué), Milvus, Qdrant, OpenSearch, PGVector, Pinecone, Weaviate.

> Configurez le modèle d'embedding dans **Admin Panel → Documents** : `nomic-embed-text`.

**Paramètres RAG configurés dans le stack :**

| Paramètre | Valeur |
|-----------|--------|
| Chunk size | 500 tokens |
| Chunk overlap | 50 tokens |
| Top-k | 5 |
| Hybrid search | BM25 + dense |

### Assistants personnalisés

Créez des modèles avec un **system prompt** dédié, une knowledge base attachée et un comportement spécifique via **Workspace → Models**.

### Recherche web

Activez l'icône 🌐 dans la barre de saisie pour enrichir les réponses avec des résultats SearXNG en temps réel.

### Fonctions & Plugins Python

Ajoutez des outils métier dans **Workspace → Functions** (exemple inclus : `scripts/demo-functions.py`). Supporte aussi : exécution de code Python sandbox, vision/multimodal, Text-to-Speech (ElevenLabs, OpenAI TTS, Kokoro local).

### Gestion multi-utilisateurs

Comptes locaux ou OAuth/LDAP/SSO. Rôles Admin/User avec contrôle par modèle et par groupe (RBAC).

### Raccourcis utiles

| Raccourci | Action |
|-----------|--------|
| `Ctrl+Shift+N` | Nouvelle conversation |
| `/` | Accès aux prompts partagés |
| `#` | Sélectionner une knowledge base |
| `@` | Mentionner un modèle |
| `Ctrl+Enter` | Envoyer |
| `Escape` | Stopper la génération |

## ⚠️ Limites & points de vigilance

**Ressources matérielles**
- LLM 7B+ nécessitent 16 Go RAM minimum
- Llama 3.3 70B → ~45 Go RAM ou GPU 40 Go VRAM
- Latence élevée en CPU-only : 2–5 tokens/sec

**Sécurité & production**
- Reverse proxy HTTPS obligatoire (Nginx / Caddy)
- Secrets API à externaliser (Vault, variables d'environnement)
- Audit logging limité sans plugin supplémentaire

**Limites fonctionnelles**
- Pas d'app mobile native (PWA uniquement)
- RAG limité sur très grands corpus (>100k documents)
- Mises à jour fréquentes → breaking changes possibles

## Commandes utiles

```bash
# Statut des services
docker compose ps

# Logs en temps réel
docker compose logs -f open-webui
docker compose logs -f ollama

# Redémarrer
docker compose restart

# Espace disque
docker system df -v

# Sauvegarder les données
docker run --rm \
  -v open-webui:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/open-webui-backup-$(date +%Y%m%d).tar.gz /data

# Mise à jour de l'image
docker compose pull && docker compose up -d
```
## Ressources

- [Documentation officielle](https://docs.openwebui.com)
- [GitHub Open WebUI](https://github.com/open-webui/open-webui)
- [Bibliothèque de modèles Ollama](https://ollama.com/library)
- [Fonctions & plugins communautaires](https://openwebui.com/functions)
- [Releases & changelog](https://github.com/open-webui/open-webui/releases)
- [Discord communauté](https://discord.gg/5rJgQTnV4s)