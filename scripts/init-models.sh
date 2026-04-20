#!/usr/bin/env bash

# Script interactif d'installation des modèles Ollama
# Support Docker/Podman avec sélection personnalisée

set -e

# Configuration
CONTAINER_NAME="${OLLAMA_CONTAINER:-ollama}"
RUNTIME=""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Fonctions d'affichage
info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
title() { echo -e "\n${CYAN}═══════════════════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}\n"; }
prompt() { echo -e "${BLUE}➤${NC} $1"; }

# Détection du runtime
detect_runtime() {
    if command -v podman &> /dev/null; then
        RUNTIME="podman"
    elif command -v docker &> /dev/null; then
        RUNTIME="docker"
    else
        error "Ni Docker ni Podman n'est installé"
        exit 1
    fi
    info "Runtime détecté: $RUNTIME"
}

# Vérification du conteneur
check_container() {
    if ! $RUNTIME ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        error "Le conteneur $CONTAINER_NAME n'est pas en cours d'exécution"
        echo "💡 Démarrez-le avec: $RUNTIME-compose up -d"
        exit 1
    fi
    info "Conteneur $CONTAINER_NAME trouvé"
}

# Vérifier si un modèle est déjà installé
is_model_installed() {
    local model="$1"
    $RUNTIME exec $CONTAINER_NAME ollama list 2>/dev/null | grep -q "^$model"
    return $?
}

# Afficher les modèles avec leur statut
show_models() {
    echo -e "\n${YELLOW}📋 Modèles disponibles:${NC}\n"
    printf "%-5s %-25s %-15s %-40s\n" "" "MODELE" "TAILLE" "DESCRIPTION"
    printf "%-5s %-25s %-15s %-40s\n" "" "-----" "-----" "-----------"
    
    local i=1
    for model in "${!MODELS[@]}"; do
        local status=""
        if is_model_installed "$model"; then
            status="${GREEN}[✓ INSTALLÉ]${NC}"
        else
            status="${RED}[ ] NON INSTALLÉ${NC}"
        fi
        
        printf "%-5s %-25s %-15s %-40s\n" \
            "[$i]" "$model" "${SIZES[$model]}" "${MODELS[$model]}"
        printf "      %-80s\n" "$status"
        ((i++))
    done
}

# Installation d'un modèle
install_model() {
    local model="$1"
    local description="$2"
    
    if is_model_installed "$model"; then
        warn "$description ($model) déjà installé"
        return 0
    fi
    
    echo -n "📥 Installation de $description ($model)... "
    if $RUNTIME exec -it $CONTAINER_NAME ollama pull "$model"; then
        info "installé avec succès"
        return 0
    else
        error "échec de l'installation"
        return 1
    fi
}

# Installation en arrière-plan
install_model_bg() {
    local model="$1"
    local description="$2"
    
    if is_model_installed "$model"; then
        return 0
    fi
    
    echo "📥 Installation de $description ($model) en arrière-plan..."
    $RUNTIME exec $CONTAINER_NAME ollama pull "$model" > /dev/null 2>&1 &
}

# Définition des modèles
declare -A MODELS
declare -A SIZES
declare -A CATEGORIES

# === CHAT GÉNÉRAL ===
MODELS["llama3.2:3b"]="Modèle de chat général léger"
SIZES["llama3.2:3b"]="~2 GB"
CATEGORIES["llama3.2:3b"]="chat"

MODELS["llama3.2:latest"]="Modèle de chat général récent"
SIZES["llama3.2:latest"]="~4.7 GB"
CATEGORIES["llama3.2:latest"]="chat"

MODELS["phi:latest"]="Modèle très léger de Microsoft"
SIZES["phi:latest"]="~1.5 GB"
CATEGORIES["phi:latest"]="chat"

MODELS["phi4:latest"]="Version améliorée de phi"
SIZES["phi4:latest"]="~2.5 GB"
CATEGORIES["phi4:latest"]="chat"

MODELS["mistral:7b"]="Modèle équilibré qualité/performance"
SIZES["mistral:7b"]="~4.1 GB"
CATEGORIES["mistral:7b"]="chat"

MODELS["gemma3:9b"]="Modèle Google récent"
SIZES["gemma3:9b"]="~5.5 GB"
CATEGORIES["gemma3:9b"]="chat"

MODELS["qwen2.5:7b"]="Modèle chinois performant"
SIZES["qwen2.5:7b"]="~4.4 GB"
CATEGORIES["qwen2.5:7b"]="chat"

# === CODE & RAISONNEMENT ===
MODELS["deepseek-coder-v2"]="Modèle spécialisé pour le code"
SIZES["deepseek-coder-v2"]="~6.7 GB"
CATEGORIES["deepseek-coder-v2"]="code"

MODELS["codellama:7b"]="Modèle Meta pour le code"
SIZES["codellama:7b"]="~3.8 GB"
CATEGORIES["codellama:7b"]="code"

MODELS["deepseek-r1:7b"]="Raisonnement avancé"
SIZES["deepseek-r1:7b"]="~4.5 GB"
CATEGORIES["deepseek-r1:7b"]="reasoning"

# === RAG & EMBEDDINGS ===
MODELS["nomic-embed-text:latest"]="Embeddings pour RAG (obligatoire)"
SIZES["nomic-embed-text:latest"]="~274 MB"
CATEGORIES["nomic-embed-text:latest"]="rag"

MODELS["all-minilm:latest"]="Alternative légère pour embeddings"
SIZES["all-minilm:latest"]="~120 MB"
CATEGORIES["all-minilm:latest"]="rag"

# === MULTIMODAL ===
MODELS["llava:13b"]="Modèle vision (analyse d'images)"
SIZES["llava:13b"]="~7.5 GB"
CATEGORIES["llava:13b"]="multimodal"

MODELS["bakllava:7b"]="Modèle vision plus léger"
SIZES["bakllava:7b"]="~4.1 GB"
CATEGORIES["bakllava:7b"]="multimodal"

# === GRANDS MODÈLES ===
MODELS["llama3.3:70b"]="Grand modèle pour résultats premium"
SIZES["llama3.3:70b"]="~45 GB"
CATEGORIES["llama3.3:70b"]="large"

# === SPÉCIALISÉS ===
MODELS["mixtral:8x7b"]="Modèle à mélange d'experts"
SIZES["mixtral:8x7b"]="~26 GB"
CATEGORIES["mixtral:8x7b"]="specialized"

MODELS["command-r:latest"]="Modèle Cohere pour RAG"
SIZES["command-r:latest"]="~12 GB"
CATEGORIES["command-r:latest"]="rag"

# Packs prédéfinis
declare -A PACKS
declare -A PACK_DESCRIPTIONS
declare -A PACK_MODELS

PACKS["basic"]="Basique - Pour usage léger"
PACK_MODELS["basic"]="phi:latest,nomic-embed-text:latest"

PACKS["standard"]="Standard - Recommandé pour la plupart des usages"
PACK_MODELS["standard"]="llama3.2:3b,phi:latest,mistral:7b,nomic-embed-text:latest"

PACKS["advanced"]="Avancé - Tous les modèles de chat et RAG"
PACK_MODELS["advanced"]="llama3.2:3b,llama3.2:latest,phi:latest,phi4:latest,mistral:7b,gemma3:9b,nomic-embed-text:latest,deepseek-coder-v2,llava:13b"

PACKS["full"]="Complet - Tous les modèles (attention à l'espace disque)"
PACK_MODELS["full"]="llama3.2:3b,llama3.2:latest,phi:latest,phi4:latest,mistral:7b,gemma3:9b,qwen2.5:7b,deepseek-coder-v2,codellama:7b,deepseek-r1:7b,nomic-embed-text:latest,all-minilm:latest,llava:13b,bakllava:7b"

PACKS["rag"]="RAG uniquement - Pour la recherche documentaire"
PACK_MODELS["rag"]="nomic-embed-text:latest,all-minilm:latest,command-r:latest"

PACKS["code"]="Développement - Pour la programmation"
PACK_MODELS["code"]="deepseek-coder-v2,codellama:7b,llama3.2:3b,nomic-embed-text:latest"

# Sélection du pack
select_pack() {
    title "📦 SÉLECTION DU PACK DE MODÈLES"
    
    echo "Choisissez un pack prédéfini ou une sélection personnalisée:\n"
    
    local i=1
    declare -a pack_list
    for pack in basic standard advanced full rag code; do
        echo -e "${CYAN}[$i]${NC} ${pack^^} - ${PACKS[$pack]}"
        pack_list[$i]=$pack
        ((i++))
    done
    echo -e "${CYAN}[$i]${NC} CUSTOM - Sélection personnalisée des modèles"
    
    echo ""
    prompt "Votre choix (1-$((i))) : "
    read -r choice
    
    if [[ $choice -ge 1 && $choice -lt $i ]]; then
        SELECTED_PACK="${pack_list[$choice]}"
        INSTALL_MODE="pack"
    elif [[ $choice -eq $i ]]; then
        INSTALL_MODE="custom"
    else
        error "Choix invalide"
        exit 1
    fi
}

# Sélection personnalisée des modèles
select_models_custom() {
    title "🎯 SÉLECTION PERSONNALISÉE DES MODÈLES"
    
    echo "Sélectionnez les modèles à installer (séparés par des virgules ou espaces):\n"
    
    # Afficher par catégorie
    local current_category=""
    local i=1
    declare -a model_list
    
    for model in "${!MODELS[@]}"; do
        local category="${CATEGORIES[$model]}"
        if [[ "$category" != "$current_category" ]]; then
            current_category="$category"
            echo -e "\n${YELLOW}─── ${current_category^^} ───${NC}"
        fi
        
        local status=""
        if is_model_installed "$model"; then
            status="${GREEN}[✓]${NC}"
        else
            status="${RED}[ ]${NC}"
        fi
        
        printf "  ${CYAN}%-3s${NC} %-25s %-15s %-40s %s\n" \
            "[$i]" "$model" "${SIZES[$model]}" "${MODELS[$model]}" "$status"
        
        model_list[$i]="$model"
        ((i++))
    done
    
    echo ""
    prompt "Entrez les numéros des modèles à installer (ex: 1,3,5-8,10) : "
    read -r selection
    
    # Parser la sélection
    SELECTED_MODELS=()
    
    # Convertir les virgules en espaces
    selection=$(echo "$selection" | tr ',' ' ')
    
    for part in $selection; do
        if [[ $part =~ ^[0-9]+$ ]]; then
            # Numéro simple
            if [[ -n "${model_list[$part]}" ]]; then
                SELECTED_MODELS+=("${model_list[$part]}")
            fi
        elif [[ $part =~ ^([0-9]+)-([0-9]+)$ ]]; then
            # Range
            start=${BASH_REMATCH[1]}
            end=${BASH_REMATCH[2]}
            for ((j=start; j<=end; j++)); do
                if [[ -n "${model_list[$j]}" ]]; then
                    SELECTED_MODELS+=("${model_list[$j]}")
                fi
            done
        fi
    done
    
    # Supprimer les doublons
    SELECTED_MODELS=($(echo "${SELECTED_MODELS[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))
    
    if [[ ${#SELECTED_MODELS[@]} -eq 0 ]]; then
        error "Aucun modèle sélectionné"
        exit 1
    fi
    
    info "${#SELECTED_MODELS[@]} modèle(s) sélectionné(s)"
}

# Installation des modèles
install_models() {
    title "📥 INSTALLATION DES MODÈLES"
    
    local models_to_install=()
    
    if [[ "$INSTALL_MODE" == "pack" ]]; then
        IFS=',' read -ra models_to_install <<< "${PACK_MODELS[$SELECTED_PACK]}"
        echo "Pack sélectionné: ${SELECTED_PACK^^}"
        echo "Modèles à installer: ${#models_to_install[@]}"
    else
        models_to_install=("${SELECTED_MODELS[@]}")
    fi
    
    echo ""
    local failed=0
    local installed=0
    
    for model in "${models_to_install[@]}"; do
        if install_model "$model" "${MODELS[$model]}"; then
            ((installed++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    title "📊 RÉSUMÉ DE L'INSTALLATION"
    echo -e "${GREEN}✓ Installés: $installed${NC}"
    if [[ $failed -gt 0 ]]; then
        echo -e "${RED}✗ Échecs: $failed${NC}"
    fi
    
    # Afficher les modèles installés
    echo -e "\n${YELLOW}Modèles actuellement disponibles:${NC}"
    $RUNTIME exec $CONTAINER_NAME ollama list
}

# Menu principal
main_menu() {
    title "🦙 OLLAMA - INSTALLATEUR INTERACTIF DE MODÈLES"
    
    echo -e "${GREEN}Bienvenue dans l'installateur de modèles Ollama!${NC}\n"
    echo "Cet outil vous permet d'installer les modèles nécessaires"
    echo "pour les démonstrations d'Open WebUI.\n"
    
    detect_runtime
    check_container
    
    echo ""
    echo -e "${YELLOW}📊 Statistiques actuelles:${NC}"
    local installed_count=$($RUNTIME exec $CONTAINER_NAME ollama list 2>/dev/null | tail -n +2 | wc -l)
    echo "  Modèles installés: $installed_count"
    echo "  Espace utilisé: $(du -sh ./data/ollama 2>/dev/null | cut -f1 || echo "inconnu")"
    
    select_pack
    
    if [[ "$INSTALL_MODE" == "custom" ]]; then
        select_models_custom
    fi
    
    echo ""
    prompt "Confirmer l'installation ? (O/n) "
    read -r confirm
    
    if [[ "$confirm" =~ ^[OoYy]$ || -z "$confirm" ]]; then
        install_models
    else
        info "Installation annulée"
        exit 0
    fi
    
    echo ""
    info "Installation terminée !"
    echo ""
    echo "💡 Pour tester: $RUNTIME exec -it $CONTAINER_NAME ollama run llama3.2:3b 'Bonjour !'"
}

# Version non-interactive (pour scripting)
non_interactive() {
    local pack="$1"
    
    detect_runtime
    check_container
    
    if [[ -n "$pack" ]] && [[ -n "${PACK_MODELS[$pack]}" ]]; then
        IFS=',' read -ra models <<< "${PACK_MODELS[$pack]}"
        for model in "${models[@]}"; do
            install_model "$model" "${MODELS[$model]}"
        done
    else
        error "Pack invalide: $pack"
        echo "Packs disponibles: basic, standard, advanced, full, rag, code"
        exit 1
    fi
}

# Aide
show_help() {
    cat << EOF
Utilisation: $0 [OPTIONS]

Options:
  -h, --help              Afficher cette aide
  -n, --non-interactive   Mode non-interactif (nécessite --pack)
  -p, --pack PACK         Installer un pack prédéfini (basic, standard, advanced, full, rag, code)
  -l, --list              Lister tous les modèles disponibles
  -c, --container NAME    Nom du conteneur Ollama (défaut: ollama)

Exemples:
  $0                      Mode interactif
  $0 -n -p standard       Installer le pack standard en mode non-interactif
  $0 -l                   Lister les modèles disponibles
EOF
}

# Main
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    -l|--list)
        detect_runtime
        check_container
        show_models
        exit 0
        ;;
    -n|--non-interactive)
        shift
        while [[ $# -gt 0 ]]; do
            case "$1" in
                -p|--pack)
                    pack="$2"
                    shift 2
                    ;;
                -c|--container)
                    CONTAINER_NAME="$2"
                    shift 2
                    ;;
                *)
                    error "Option inconnue: $1"
                    show_help
                    exit 1
                    ;;
            esac
        done
        non_interactive "$pack"
        ;;
    *)
        main_menu
        ;;
esac