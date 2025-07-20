#!/bin/bash

# Farben für die Ausgabe
GREEN="\033[0;32m"; YELLOW="\033[1;33m"; BLUE="\033[0;34m"; NC="\033[0m"

# Repo-Informationen
GITHUB_REPO="jurin1/cliKi"
BACKEND_SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/scripts/chat-backend.sh"
BACKEND_DEST="/usr/local/bin/chat-backend"

# Korrekte Modellnamen
MODELS=("gemini-2.5-flash" "gemini-2.5-pro")

echo -e "${BLUE}--- Willkommen beim Installer für das Chat-CLI-Tool ---${NC}"

# Schritt 1: Abhängigkeiten (vereinfacht)
echo -e "\n${YELLOW}Schritt 1: Prüfe und installiere Abhängigkeiten (curl, jq)...${NC}"
if command -v apt-get &>/dev/null; then sudo apt-get -y install curl jq; elif command -v dnf &>/dev/null; then sudo dnf -y install curl jq; elif command -v yum &>/dev/null; then sudo yum -y install curl jq; elif command -v pacman &>/dev/null; then sudo pacman -S --noconfirm curl jq; fi
echo -e "${GREEN}Abhängigkeiten sind installiert.${NC}"

# Schritt 2: Shell-Konfiguration
SHELL_RC_FILE=""
SHELL_TYPE=""
if [ -f "$HOME/.zshrc" ]; then
    SHELL_RC_FILE="$HOME/.zshrc"
    SHELL_TYPE="zsh"
    echo -e "\n${YELLOW}Zsh-Shell erkannt. Konfigurationsdatei: ~/.zshrc${NC}"
elif [ -f "$HOME/.bashrc" ]; then
    SHELL_RC_FILE="$HOME/.bashrc"
    SHELL_TYPE="bash"
    echo -e "\n${YELLOW}Bash-Shell erkannt. Konfigurationsdatei: ~/.bashrc${NC}"
else
    echo "Konnte weder ~/.bashrc noch ~/.zshrc finden. Abbruch."
    exit 1
fi
read -p "Ist dies korrekt? (J/n) " choice < /dev/tty
if [[ "$choice" =~ ^[nN]$ ]]; then echo "Abbruch."; exit 1; fi

# Schritt 3: API-Schlüssel (bleibt intelligent)
# ... (der intelligente Block aus der letzten Version bleibt hier unverändert)
echo -e "\n${YELLOW}Schritt 2: Konfiguriere Gemini API-Schlüssel...${NC}"
if grep -q "export GEMINI_API_KEY" "$SHELL_RC_FILE"; then CURRENT_KEY=$(grep "export GEMINI_API_KEY" "$SHELL_RC_FILE" | sed -n 's/.*GEMINI_API_KEY="\([^"]*\)".*/\1/p'); if [ -z "$CURRENT_KEY" ]; then echo -e "${YELLOW}Leerer API-Schlüssel-Eintrag gefunden.${NC}"; while true; do read -p "Bitte API-Schlüssel eingeben: " new_api_key < /dev/tty; if [ -n "$new_api_key" ]; then sed -i "s|export GEMINI_API_KEY=\"\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$SHELL_RC_FILE"; echo -e "${GREEN}API-Schlüssel eingetragen.${NC}"; break; else echo "Eingabe darf nicht leer sein."; fi; done; else LAST_CHARS=$(echo "$CURRENT_KEY" | tail -c 5); echo -e "${GREEN}API-Schlüssel (endet auf ...$LAST_CHARS) vorhanden.${NC}"; read -p "Möchten Sie ihn ersetzen? (j/N) " r_choice < /dev/tty; if [[ "$r_choice" =~ ^[jJ]$ ]]; then while true; do read -p "Bitte NEUEN API-Schlüssel eingeben: " new_api_key < /dev/tty; if [ -n "$new_api_key" ]; then sed -i "s|export GEMINI_API_KEY=\".*\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$SHELL_RC_FILE"; echo -e "${GREEN}API-Schlüssel ersetzt.${NC}"; break; else echo "Eingabe darf nicht leer sein."; fi; done; else echo "Schlüssel wird beibehalten."; fi; fi; else echo -e "${YELLOW}Kein API-Schlüssel gefunden.${NC}"; while true; do read -p "Bitte API-Schlüssel eingeben: " api_key < /dev/tty; if [ -n "$api_key" ]; then echo "" >> "$SHELL_RC_FILE"; echo "# Für das Chat-CLI-Tool hinzugefügt" >> "$SHELL_RC_FILE"; echo "export GEMINI_API_KEY=\"$api_key\"" >> "$SHELL_RC_FILE"; echo -e "${GREEN}API-Schlüssel hinzugefügt.${NC}"; break; else echo "Eingabe darf nicht leer sein."; fi; done; fi

# --- NEUER, INTELLIGENTER FUNKTIONS-BLOCK ---
echo -e "\n${YELLOW}Schritt 3: Füge die 'chat' Funktion zur Shell hinzu...${NC}"
if grep -q "# Funktion für das KI-gestützte Chat-CLI-Tool" "$SHELL_RC_FILE"; then
    echo -e "${GREEN}'chat'-Funktion ist bereits vorhanden. Wird übersprungen.${NC}"
else
    if [ "$SHELL_TYPE" = "zsh" ]; then
        echo -e "${BLUE}Installiere ZSH-Version der Funktion...${NC}"
        cat <<'EOF' >> "$SHELL_RC_FILE"

# Funktion für das KI-gestützte Chat-CLI-Tool (ZSH-Version)
function chat() {
  local selected_command
  selected_command=$(chat-backend "$@" < /dev/tty)
  if [ -n "$selected_command" ]; then
    print -z "$selected_command"
  fi
}
EOF
    elif [ "$SHELL_TYPE" = "bash" ]; then
        echo -e "${BLUE}Installiere BASH-Version der Funktion...${NC}"
        cat <<'EOF' >> "$SHELL_RC_FILE"

# Funktion für das KI-gestützte Chat-CLI-Tool (BASH-Version)
function chat() {
  local selected_command
  selected_command=$(chat-backend "$@" < /dev/tty)
  if [ -n "$selected_command" ]; then
    # Diese Methode ist am robustesten für Bash.
    # Sie fügt den Befehl in einen neuen `read`-Prompt ein.
    # Der User muss Enter drücken, um den Befehl in der Shell zu haben.
    read -e -i "$selected_command"
  fi
}
EOF
    fi
    echo -e "${GREEN}'chat'-Funktion wurde zu '$SHELL_RC_FILE' hinzugefügt.${NC}"
fi
# --- ENDE NEUER FUNKTIONS-BLOCK ---


# Schritt 5: Backend-Skript herunterladen
echo -e "\n${YELLOW}Schritt 4: Installiere das Backend-Skript...${NC}"
# ... (bleibt unverändert)
DL_SKIP="false"; if [ -f "$BACKEND_DEST" ]; then read -p "Backend-Skript existiert. Überschreiben? (j/N) " choice < /dev/tty; if [[ "$choice" =~ ^[jJ]$ ]]; then DL_SKIP="false"; else DL_SKIP="true"; fi; fi
if [ "$DL_SKIP" != "true" ]; then sudo curl -fsSL "$BACKEND_SCRIPT_URL" -o "$BACKEND_DEST"; sudo chmod +x "$BACKEND_DEST"; echo -e "${GREEN}Backend-Skript installiert.${NC}"; fi

# Schritt 6: Modell auswählen
echo -e "\n${YELLOW}Schritt 5: Wähle das Standard-KI-Modell aus...${NC}"
# ... (bleibt unverändert)
PS3="Geben Sie die Zahl für das Modell ein (z.B. 1): "; { select opt in "${MODELS[@]}"; do if [[ -n $opt ]]; then sudo sed -i 's/^MODEL_NAME=/#MODEL_NAME=/' "$BACKEND_DEST"; sudo sed -i "s/^#MODEL_NAME=\"$opt\"/MODEL_NAME=\"$opt\"/" "$BACKEND_DEST"; echo -e "${GREEN}$opt als Standard festgelegt.${NC}"; break; else echo "Ungültige Auswahl."; fi; done; } < /dev/tty

# --- FINALE AUSGABE MIT FARBKORREKTUR ---
echo -e "\n${GREEN}--- Installation abgeschlossen! ---${NC}"
echo -e "Bitte starten Sie Ihr Terminal neu oder führen Sie den folgenden Befehl aus:"
echo -e "\`${YELLOW}source $SHELL_RC_FILE\`${NC}" # NC am Ende hinzugefügt
echo -e "Danach können Sie das Tool mit \`${YELLOW}chat 'Ihre Frage'\`${NC} verwenden." # NC am Ende hinzugefügt