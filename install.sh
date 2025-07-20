#!/bin/bash

# Farben für die Ausgabe
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Repo-Informationen (passen Sie dies an, wenn Ihr GitHub-Repo anders heißt)
GITHUB_REPO="jurin1/cliKi"
BACKEND_SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/scripts/chat-backend.sh"
BACKEND_DEST="/usr/local/bin/chat-backend"

# verfügbare Modelle
MODELS=("gemini-2.5-flash" "gemini-2.5-pro")

echo -e "${BLUE}--- Willkommen beim Installer für das Chat-CLI-Tool ---${NC}"

# Schritt 1: Abhängigkeiten installieren
echo -e "\n${YELLOW}Schritt 1: Prüfe und installiere Abhängigkeiten (curl, jq)...${NC}"
if command -v apt-get &> /dev/null; then
    sudo apt-get update > /dev/null
    sudo apt-get install -y curl jq
elif command -v dnf &> /dev/null; then
    sudo dnf install -y curl jq
elif command -v yum &> /dev/null; then
    sudo yum install -y curl jq
elif command -v pacman &> /dev/null; then
    sudo pacman -S --noconfirm curl jq
else
    echo "Konnte den Paketmanager nicht erkennen. Bitte installieren Sie 'curl' und 'jq' manuell."
    exit 1
fi
echo -e "${GREEN}Abhängigkeiten sind installiert.${NC}"

# Schritt 2: Shell-Konfiguration auswählen
SHELL_CONFIG=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
    echo -e "\n${YELLOW}Zsh-Konfiguration (~/.zshrc) gefunden.${NC}"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_CONFIG="$HOME/.bashrc"
    echo -e "\n${YELLOW}Bash-Konfiguration (~/.bashrc) gefunden.${NC}"
fi

read -p "Soll die Konfiguration in '$SHELL_CONFIG' geschrieben werden? (J/n) " choice
case "$choice" in
  n|N ) read -p "Bitte geben Sie den Pfad zu Ihrer Shell-Konfigurationsdatei an: " SHELL_CONFIG;;
  * ) ;;
esac

if [ ! -f "$SHELL_CONFIG" ]; then
    echo "Die angegebene Datei existiert nicht. Abbruch."
    exit 1
fi

# Schritt 3: API-Schlüssel konfigurieren
echo -e "\n${YELLOW}Schritt 2: Konfiguriere Gemini API-Schlüssel...${NC}"
if grep -q "export GEMINI_API_KEY" "$SHELL_CONFIG"; then
    echo -e "${GREEN}API-Schlüssel ist bereits in '$SHELL_CONFIG' vorhanden. Wird übersprungen.${NC}"
else
    read -p "Bitte geben Sie Ihren Google Gemini API-Schlüssel ein: " api_key
    echo -e "\n# Für das Chat-CLI-Tool hinzugefügt" >> "$SHELL_CONFIG"
    echo "export GEMINI_API_KEY=\"$api_key\"" >> "$SHELL_CONFIG"
    echo -e "${GREEN}API-Schlüssel wurde zu '$SHELL_CONFIG' hinzugefügt.${NC}"
fi

# Schritt 4: chat-Funktion hinzufügen
echo -e "\n${YELLOW}Schritt 3: Füge die 'chat' Funktion zur Shell hinzu...${NC}"
if grep -q "function chat()" "$SHELL_CONFIG"; then
    echo -e "${GREEN}'chat'-Funktion ist bereits vorhanden. Wird übersprungen.${NC}"
else
    # HEREDOC mit 'EOF' in Anführungszeichen, um Variablenexpansion zu verhindern
    cat <<'EOF' >> "$SHELL_CONFIG"

# Funktion für das KI-gestützte Chat-CLI-Tool
function chat() {
  local selected_command
  selected_command=$(chat-backend "$@" < /dev/tty)
  if [ -n "$selected_command" ]; then
    if [ -n "$BASH_VERSION" ]; then
      READLINE_LINE="$selected_command"; READLINE_POINT="${#READLINE_LINE}"
    elif [ -n "$ZSH_VERSION" ]; then
      print -z "$selected_command"
    fi
  fi
}
EOF
    echo -e "${GREEN}'chat'-Funktion wurde zu '$SHELL_CONFIG' hinzugefügt.${NC}"
fi

# Schritt 5: Backend-Skript herunterladen
echo -e "\n${YELLOW}Schritt 4: Installiere das Backend-Skript...${NC}"
if [ -f "$BACKEND_DEST" ]; then
    read -p "Das Backend-Skript existiert bereits. Erneut herunterladen und überschreiben? (j/N) " choice
    case "$choice" in
      j|J ) ;;
      * ) echo "Download wird übersprungen."; DL_SKIP="true";;
    esac
fi

if [ "$DL_SKIP" != "true" ]; then
    echo "Lade Backend-Skript herunter..."
    sudo curl -fsSL "$BACKEND_SCRIPT_URL" -o "$BACKEND_DEST"
    sudo chmod +x "$BACKEND_DEST"
    echo -e "${GREEN}Backend-Skript wurde nach '$BACKEND_DEST' heruntergeladen und ausführbar gemacht.${NC}"
fi

# Schritt 6: Modell auswählen
echo -e "\n${YELLOW}Schritt 5: Wähle das Standard-KI-Modell aus...${NC}"
PS3="Bitte wählen Sie das zu aktivierende Modell: "
select opt in "${MODELS[@]}"; do
    if [[ -n $opt ]]; then
        echo "Aktiviere $opt..."
        # Zuerst alle Modellzeilen auskommentieren
        sudo sed -i 's/^\(MODEL_NAME=.*\)/#\1/' "$BACKEND_DEST"
        # Dann die ausgewählte Zeile wieder aktivieren (das # entfernen)
        sudo sed -i "s/^#\(MODEL_NAME=\"$opt\"\)/\1/" "$BACKEND_DEST"
        echo -e "${GREEN}$opt wurde als Standardmodell festgelegt.${NC}"
        break
    else
        echo "Ungültige Auswahl."
    fi
done

echo -e "\n${GREEN}--- Installation abgeschlossen! ---${NC}"
echo -e "Bitte starten Sie Ihr Terminal neu oder führen Sie \`${YELLOW}source $SHELL_CONFIG\` aus, um die Änderungen zu laden."
echo -e "Danach können Sie das Tool mit \`${YELLOW}chat 'Ihre Frage'\` verwenden."