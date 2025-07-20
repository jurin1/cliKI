#!/bin/bash

# Farben für die Ausgabe
GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

# Repo-Informationen
GITHUB_REPO="jurin1/cliKi"
BACKEND_SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/scripts/chat-backend.sh"
BACKEND_DEST="/usr/local/bin/chat-backend"

# verfügbare Modelle (JETZT KORREKT)
MODELS=("gemini-2.5-flash" "gemini-2.5-pro")

echo -e "${BLUE}--- Willkommen beim Installer für das Chat-CLI-Tool ---${NC}"

# Schritt 1: Abhängigkeiten
echo -e "\n${YELLOW}Schritt 1: Prüfe und installiere Abhängigkeiten (curl, jq)...${NC}"
if command -v apt-get &>/dev/null; then sudo apt-get -y install curl jq; elif command -v dnf &>/dev/null; then sudo dnf -y install curl jq; elif command -v yum &>/dev/null; then sudo yum -y install curl jq; elif command -v pacman &>/dev/null; then sudo pacman -S --noconfirm curl jq; fi
echo -e "${GREEN}Abhängigkeiten sind installiert.${NC}"

# Schritt 2: Shell-Konfiguration
SHELL_CONFIG=""; if [ -f "$HOME/.zshrc" ]; then SHELL_CONFIG="$HOME/.zshrc"; elif [ -f "$HOME/.bashrc" ]; then SHELL_CONFIG="$HOME/.bashrc"; fi
read -p "Konfigurationsdatei: '$SHELL_CONFIG'. Ist das korrekt? (J/n) " choice < /dev/tty
if [[ "$choice" =~ ^[nN]$ ]]; then read -p "Bitte Pfad zur Konfigurationsdatei angeben: " SHELL_CONFIG < /dev/tty; fi
if [ ! -f "$SHELL_CONFIG" ]; then echo "Datei nicht gefunden. Abbruch."; exit 1; fi

# Schritt 3: API-Schlüssel
echo -e "\n${YELLOW}Schritt 2: Konfiguriere Gemini API-Schlüssel...${NC}"
if grep -q "export GEMINI_API_KEY" "$SHELL_CONFIG"; then
    CURRENT_KEY=$(grep "export GEMINI_API_KEY" "$SHELL_CONFIG" | sed -n 's/.*GEMINI_API_KEY="\([^"]*\)".*/\1/p')
    if [ -z "$CURRENT_KEY" ]; then
        echo -e "${YELLOW}Leerer API-Schlüssel-Eintrag gefunden.${NC}"; read -p "Bitte API-Schlüssel eingeben: " new_api_key < /dev/tty
        sed -i "s|export GEMINI_API_KEY=\"\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$SHELL_CONFIG"; echo -e "${GREEN}API-Schlüssel eingetragen.${NC}"
    else
        echo -e "${GREEN}Vorhandener API-Schlüssel gefunden.${NC}"; read -p "Möchten Sie ihn ersetzen? (j/N) " r_choice < /dev/tty
        if [[ "$r_choice" =~ ^[jJ]$ ]]; then read -p "Bitte NEUEN API-Schlüssel eingeben: " new_api_key < /dev/tty; sed -i "s|export GEMINI_API_KEY=\".*\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$SHELL_CONFIG"; echo -e "${GREEN}API-Schlüssel ersetzt.${NC}"; fi
    fi
else
    read -p "Bitte API-Schlüssel eingeben: " api_key < /dev/tty
    echo -e "\n# Für das Chat-CLI-Tool hinzugefügt" >> "$SHELL_CONFIG"; echo "export GEMINI_API_KEY=\"$api_key\"" >> "$SHELL_CONFIG"; echo -e "${GREEN}API-Schlüssel hinzugefügt.${NC}"
fi

# Schritt 4: chat-Funktion hinzufügen (JETZT KORRIGIERT)
echo -e "\n${YELLOW}Schritt 3: Füge die 'chat' Funktion zur Shell hinzu...${NC}"
if grep -q "# Funktion für das KI-gestützte Chat-CLI-Tool" "$SHELL_CONFIG"; then
    echo -e "${GREEN}'chat'-Funktion ist bereits vorhanden. Wird übersprungen.${NC}"
else
    # Wir benutzen read -e -i für Bash als robusten Fallback.
    cat <<'EOF' >> "$SHELL_CONFIG"

# Funktion für das KI-gestützte Chat-CLI-Tool
function chat() {
  local selected_command
  selected_command=$(chat-backend "$@" < /dev/tty)
  if [ -n "$selected_command" ]; then
    if [ -n "$ZSH_VERSION" ]; then
      # Die perfekte Methode für Zsh
      print -z "$selected_command"
    else
      # Robuste Methode für Bash und andere Shells:
      # Fügt den Befehl zur Bearbeitung in den `read`-Prompt ein.
      # Der Benutzer muss einmal extra Enter drücken, aber es funktioniert immer.
      read -e -i "$selected_command"
    fi
  fi
}
EOF
    echo -e "${GREEN}'chat'-Funktion wurde zu '$SHELL_CONFIG' hinzugefügt.${NC}"
fi

# Schritt 5: Backend-Skript herunterladen
echo -e "\n${YELLOW}Schritt 4: Installiere das Backend-Skript...${NC}"
if [ -f "$BACKEND_DEST" ]; then read -p "Backend-Skript existiert. Überschreiben? (j/N) " choice < /dev/tty; if [[ "$choice" =~ ^[jJ]$ ]]; then DL_SKIP="false"; else DL_SKIP="true"; fi; fi
if [ "$DL_SKIP" != "true" ]; then sudo curl -fsSL "$BACKEND_SCRIPT_URL" -o "$BACKEND_DEST"; sudo chmod +x "$BACKEND_DEST"; echo -e "${GREEN}Backend-Skript installiert.${NC}"; fi

# Schritt 6: Modell auswählen
echo -e "\n${YELLOW}Schritt 5: Wähle das Standard-KI-Modell aus...${NC}"
PS3="Geben Sie die Zahl für das Modell ein (z.B. 1): "
{ select opt in "${MODELS[@]}"; do if [[ -n $opt ]]; then sudo sed -i 's/^MODEL_NAME=/#MODEL_NAME=/' "$BACKEND_DEST"; sudo sed -i "s/^#MODEL_NAME=\"$opt\"/MODEL_NAME=\"$opt\"/" "$BACKEND_DEST"; echo -e "${GREEN}$opt als Standard festgelegt.${NC}"; break; else echo "Ungültige Auswahl."; fi; done; } < /dev/tty

echo -e "\n${GREEN}--- Installation abgeschlossen! ---${NC}"
echo -e "Bitte starten Sie Ihr Terminal neu oder führen Sie \`${YELLOW}source $SHELL_CONFIG\` aus, um das Tool zu verwenden."