# 1. Cloner la structure
mkdir -p open-webui-demo/{data/{ollama,open-webui,documents},searxng,scripts,nginx}
cd open-webui-demo

# 2. Créer les fichiers (copier les contenus ci-dessus)
# - docker-compose.yml
# - .env
# - searxng/settings.yml
# - scripts/init-models.sh
# - scripts/init-knowledge.sh
# - scripts/demo-functions.py

# 3. Rendre les scripts exécutables
chmod +x scripts/*.sh

# 4. Générer les clés secrètes
echo "WEBUI_SECRET_KEY=$(openssl rand -hex 32)" > .env
echo "SEARXNG_SECRET_KEY=$(openssl rand -hex 32)" >> .env

# 5. Démarrer tous les services
docker compose up -d

# 6. Attendre que les services soient prêts
sleep 30

# 7. Installer les modèles
./scripts/init-models.sh

# 8. Vérifier que tout fonctionne
docker compose ps
docker compose logs --tail=20