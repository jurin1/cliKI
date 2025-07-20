#!/bin-bash
# Farben
GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

# Repo-Informationen
GITHUB_REPO="jurin1/cliKi"
BACKEND_SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/scripts/chat-backend.sh"
BACKEND_DEST="/usr/local/bin/chat-backend"
MODELS=("gemini-2.5-flash" "gemini-2.5-pro")

echo -e "${BLUE}--- Willkommen beim Installer für das Chat-CLI-Tool ---${NC}"

# Schritt 1: Abhängigkeiten
echo -e "\n${YELLOW}Schritt 1: Prüfe und installiere Abhängigkeiten (curl, jq)...${NC}"
if command -v apt-get &>/dev/null; then sudo apt-get -y install curl jq; elif command -v dnf &>/dev/null; then sudo dnf -y install curl jq; elif command -v yum &>/dev/null; then sudo yum -y install curl jq; elif command -v pacman &>/dev/null; then sudo pacman -S --noconfirm curl jq; fi >/dev/null 2>&1
echo -e "${GREEN}Abhängigkeiten sind installiert.${NC}"

# Schritt 2: API-Schlüssel (unverändert)
echo -e "\n${YELLOW}Schritt 2: Konfiguriere Gemini API-Schlüssel...${NC}"
CONFIG_FILE_FOR_KEY=""; if [ -f "$HOME/.bashrc" ]; then CONFIG_FILE_FOR_KEY="$HOME/.bashrc"; elif [ -f "$HOME/.zshrc" ]; then CONFIG_FILE_FOR_KEY="$HOME/.zshrc"; fi; if [ -n "$CONFIG_FILE_FOR_KEY" ]; then if grep -q "export GEMINI_API_KEY" "$CONFIG_FILE_FOR_KEY"; then CURRENT_KEY=$(grep "export GEMINI_API_KEY" "$CONFIG_FILE_FOR_KEY" | sed -n 's/.*GEMINI_API_KEY="\([^"]*\)".*/\1/p'); if [ -z "$CURRENT_KEY" ]; then echo -e "${YELLOW}Leerer API-Schlüssel-Eintrag gefunden.${NC}"; read -p "Bitte API-Schlüssel eingeben: " new_api_key < /dev/tty; sed -i "s|export GEMINI_API_KEY=\"\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$CONFIG_FILE_FOR_KEY"; else echo -e "${GREEN}API-Schlüssel vorhanden.${NC}"; fi; else read -p "Bitte API-Schlüssel eingeben: " api_key < /dev/tty; echo -e "\n# Für Chat-CLI\nexport GEMINI_API_KEY=\"$api_key\"" >> "$CONFIG_FILE_FOR_KEY"; fi; fi

# Schritt 3: Funktionen für Bash und Zsh (ZSH-FUNKTION KORRIGIERT)
echo -e "\n${YELLOW}Schritt 3: Füge die 'chat' Funktion(en) hinzu...${NC}"
CONFIGURED_FILES=""

# Installation für BASH (Diese ist korrekt und bleibt unverändert)
if [ -f "$HOME/.bashrc" ]; then
    if ! grep -q "# Funktion für das KI-gestützte Chat-CLI-Tool" "$HOME/.bashrc"; then
        echo -e "${BLUE}Installiere Funktion für Bash (~/.bashrc)...${NC}"
        cat <<'EOF' >> "$HOME/.bashrc"

# Funktion für das KI-gestützte Chat-CLI-Tool (BASH-Version)
function chat() {
  local all_commands; all_commands=$(chat-backend "$@" < /dev/tty)
  if [ -n "$all_commands" ]; then
    while IFS= read -r line; do history -s "$line"; done <<< "$all_commands"
    echo -e "\n\033[1;32mBefehle zur History hinzugefügt. Drücken Sie [Pfeil nach oben].\033[0m"
  fi
}
EOF
        CONFIGURED_FILES+="$HOME/.bashrc "
    fi
fi

# Installation für ZSH (JETZT KORREKT UND IDIOMATISCH)
if [ -f "$HOME/.zshrc" ]; then
    if ! grep -q "# Funktion für das KI-gestützte Chat-CLI-Tool" "$HOME/.zshrc"; then
        echo -e "${BLUE}Installiere Funktion für Zsh (~/.zshrc)...${NC}"
        cat <<'EOF' >> "$HOME/.zshrc"

# Funktion für das KI-gestützte Chat-CLI-Tool (ZSH-Version)
function chat() {
  # 1. Hole alle Befehle vom Backend. Der ausgewählte ist am Ende.
  local all_commands
  all_commands=$(chat-backend "$@" < /dev/tty)

  # 2. Prüfe, ob überhaupt etwas zurückkam
  if [ -n "$all_commands" ]; then
    # 3. Hole den ausgewählten Befehl (die letzte Zeile)
    local selected_command
    selected_command=$(echo "$all_commands" | tail -n 1)

    # 4. Hole alle ANDEREN Befehle (alle Zeilen außer der letzten)
    local history_commands
    history_commands=$(echo "$all_commands" | head -n -1)
    
    # 5. Füge die "anderen" Befehle mit einer robusten `while`-Schleife zur History hinzu.
    #    Genau wie in der funktionierenden Bash-Version.
    if [ -n "$history_commands" ]; then
      while IFS= read -r line; do
        print -s "$line"
      done <<< "$history_commands"
    fi
    
    # 6. Füge den ausgewählten Befehl in den Prompt ein.
    print -z "$selected_command"
  fi
}
EOF
        CONFIGURED_FILES+="$HOME/.zshrc "
    fi
fi

# Schritt 4: Backend-Skript herunterladen
echo -e "\n${YELLOW}Schritt 4: Installiere das Backend-Skript...${NC}"
if [ -f "$BACKEND_DEST" ]; then read -p "Backend-Skript existiert. Überschreiben? (j/N) " choice < /dev/tty; if [[ ! "$choice" =~ ^[jJ]$ ]]; then DL_SKIP="true"; fi; fi
if [ "$DL_SKIP" != "true" ]; then sudo curl -fsSL "$BACKEND_SCRIPT_URL" -o "$BACKEND_DEST"; sudo chmod +x "$BACKEND_DEST"; echo -e "${GREEN}Backend-Skript installiert.${NC}"; else echo "Download übersprungen."; fi

# Schritt 5: Modell auswählen
echo -e "\n${YELLOW}Schritt 5: Wähle das Standard-KI-Modell aus...${NC}"
PS3="Geben Sie die Zahl für das Modell ein (z.B. 1): "
{ select opt in "${MODELS[@]}"; do if [[ -n $opt ]]; then sudo sed -i 's/^MODEL_NAME=/#MODEL_NAME=/' "$BACKEND_DEST"; sudo sed -i "s/^#MODEL_NAME=\"$opt\"/MODEL_NAME=\"$opt\"/" "$BACKEND_DEST"; echo -e "${GREEN}$opt als Standard festgelegt.${NC}"; break; else echo "Ungültige Auswahl."; fi; done; } < /dev/tty

# Finale Ausgabe
echo -e "Bitte starten Sie Ihr Terminal neu oder führen Sie den folgenden Befehl aus:"
echo -e "\`${YELLOW}source ${CONFIGURED_FILES}\`${NC}"
echo -e "\n${GREEN}--- Installation abgeschlossen! ---${NC}"