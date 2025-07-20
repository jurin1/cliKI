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

# Schritt 1: Abhängigkeiten
echo -e "\n${YELLOW}Schritt 1: Prüfe und installiere Abhängigkeiten (curl, jq)...${NC}"
if command -v apt-get &>/dev/null; then sudo apt-get -y install curl jq; elif command -v dnf &>/dev/null; then sudo dnf -y install curl jq; elif command -v yum &>/dev/null; then sudo yum -y install curl jq; elif command -v pacman &>/dev/null; then sudo pacman -S --noconfirm curl jq; fi >/dev/null 2>&1
echo -e "${GREEN}Abhängigkeiten sind installiert.${NC}"

# Schritt 2: API-Schlüssel
# Der intelligente API-Key-Block bleibt unverändert
echo -e "\n${YELLOW}Schritt 2: Konfiguriere Gemini API-Schlüssel...${NC}"
# (Hier fügen wir den intelligenten Block von vorher ein, der leere und volle Keys prüft)
CONFIG_FILE_FOR_KEY=""
if [ -f "$HOME/.bashrc" ]; then CONFIG_FILE_FOR_KEY="$HOME/.bashrc"; elif [ -f "$HOME/.zshrc" ]; then CONFIG_FILE_FOR_KEY="$HOME/.zshrc"; fi
if [ -n "$CONFIG_FILE_FOR_KEY" ]; then if grep -q "export GEMINI_API_KEY" "$CONFIG_FILE_FOR_KEY"; then CURRENT_KEY=$(grep "export GEMINI_API_KEY" "$CONFIG_FILE_FOR_KEY" | sed -n 's/.*GEMINI_API_KEY="\([^"]*\)".*/\1/p'); if [ -z "$CURRENT_KEY" ]; then echo -e "${YELLOW}Leerer API-Schlüssel-Eintrag gefunden.${NC}"; while true; do read -p "Bitte API-Schlüssel eingeben: " new_api_key < /dev/tty; if [ -n "$new_api_key" ]; then sed -i "s|export GEMINI_API_KEY=\"\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$CONFIG_FILE_FOR_KEY"; echo -e "${GREEN}API-Schlüssel eingetragen.${NC}"; break; else echo "Eingabe darf nicht leer sein."; fi; done; else LAST_CHARS=$(echo "$CURRENT_KEY" | tail -c 5); echo -e "${GREEN}API-Schlüssel (endet auf ...$LAST_CHARS) vorhanden.${NC}"; read -p "Möchten Sie ihn ersetzen? (j/N) " r_choice < /dev/tty; if [[ "$r_choice" =~ ^[jJ]$ ]]; then while true; do read -p "Bitte NEUEN API-Schlüssel eingeben: " new_api_key < /dev/tty; if [ -n "$new_api_key" ]; then sed -i "s|export GEMINI_API_KEY=\".*\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$CONFIG_FILE_FOR_KEY"; echo -e "${GREEN}API-Schlüssel ersetzt.${NC}"; break; else echo "Eingabe darf nicht leer sein."; fi; done; else echo "Schlüssel wird beibehalten."; fi; fi; else echo -e "${YELLOW}Kein API-Schlüssel gefunden.${NC}"; while true; do read -p "Bitte API-Schlüssel eingeben: " api_key < /dev/tty; if [ -n "$api_key" ]; then echo "" >> "$CONFIG_FILE_FOR_KEY"; echo "# Für das Chat-CLI-Tool hinzugefügt" >> "$CONFIG_FILE_FOR_KEY"; echo "export GEMINI_API_KEY=\"$api_key\"" >> "$CONFIG_FILE_FOR_KEY"; echo -e "${GREEN}API-Schlüssel hinzugefügt.${NC}"; break; else echo "Eingabe darf nicht leer sein."; fi; done; fi; fi

# --- NEUER, ULTIMATIVER FUNKTIONS-BLOCK ---
echo -e "\n${YELLOW}Schritt 3: Füge die 'chat' Funktion(en) hinzu...${NC}"

# Konfiguration für BASH
if [ -f "$HOME/.bashrc" ]; then
    if grep -q "# Funktion für das KI-gestützte Chat-CLI-Tool" "$HOME/.bashrc"; then
        echo -e "${GREEN}Bash-Funktion ist bereits vorhanden. Wird übersprungen.${NC}"
    else
        echo -e "${BLUE}Installiere Funktion für Bash (~/.bashrc)...${NC}"
        cat <<'EOF' >> "$HOME/.bashrc"

# Funktion für das KI-gestützte Chat-CLI-Tool (BASH-Version)
function chat() {
  local selected_command
  selected_command=$(chat-backend "$@" < /dev/tty)
  if [ -n "$selected_command" ]; then
    history -s "$selected_command"
    echo -e "\n\033[1;32mBefehl zur History hinzugefügt. Drücken Sie [Pfeil nach oben] und Enter.\033[0m"
  fi
}
EOF
        echo -e "${GREEN}Bash-Funktion erfolgreich hinzugefügt.${NC}"
        CONFIGURED_FILES+="$HOME/.bashrc "
    fi
fi

# Konfiguration für ZSH
if [ -f "$HOME/.zshrc" ]; then
    if grep -q "# Funktion für das KI-gestützte Chat-CLI-Tool" "$HOME/.zshrc"; then
        echo -e "${GREEN}Zsh-Funktion ist bereits vorhanden. Wird übersprungen.${NC}"
    else
        echo -e "${BLUE}Installiere Funktion für Zsh (~/.zshrc)...${NC}"
        cat <<'EOF' >> "$HOME/.zshrc"

# Funktion für das KI-gestützte Chat-CLI-Tool (ZSH-Version)
function chat() {
  local selected_command
  selected_command=$(chat-backend "$@" < /dev/tty)
  if [ -n "$selected_command" ]; then
    print -z "$selected_command"
  fi
}
EOF
        echo -e "${GREEN}Zsh-Funktion erfolgreich hinzugefügt.${NC}"
        CONFIGURED_FILES+="$HOME/.zshrc "
    fi
fi
# --- ENDE NEUER FUNKTIONS-BLOCK ---


# Schritt 4: Backend-Skript herunterladen
echo -e "\n${YELLOW}Schritt 4: Installiere das Backend-Skript...${NC}"
if [ -f "$BACKEND_DEST" ]; then read -p "Backend-Skript existiert. Überschreiben? (j/N) " choice < /dev/tty; if [[ ! "$choice" =~ ^[jJ]$ ]]; then DL_SKIP="true"; fi; fi
if [ "$DL_SKIP" != "true" ]; then sudo curl -fsSL "$BACKEND_SCRIPT_URL" -o "$BACKEND_DEST"; sudo chmod +x "$BACKEND_DEST"; echo -e "${GREEN}Backend-Skript installiert.${NC}"; else echo "Download übersprungen."; fi

# Schritt 5: Modell auswählen
echo -e "\n${YELLOW}Schritt 5: Wähle das Standard-KI-Modell aus...${NC}"
PS3="Geben Sie die Zahl für das Modell ein (z.B. 1): "
{ select opt in "${MODELS[@]}"; do if [[ -n $opt ]]; then sudo sed -i 's/^MODEL_NAME=/#MODEL_NAME=/' "$BACKEND_DEST"; sudo sed -i "s/^#MODEL_NAME=\"$opt\"/MODEL_NAME=\"$opt\"/" "$BACKEND_DEST"; echo -e "${GREEN}$opt als Standard festgelegt.${NC}"; break; else echo "Ungültige Auswahl."; fi; done; } < /dev/tty

# Finale Ausgabe
echo -e "\n${GREEN}--- Installation abgeschlossen! ---${NC}"
echo -e "Bitte starten Sie Ihr Terminal neu oder führen Sie den folgenden Befehl aus:"
echo -e "\`${YELLOW}source ${CONFIGURED_FILES}\`${NC}"
echo -e "Danach können Sie das Tool mit \`${YELLOW}chat 'Ihre Frage'\`${NC} verwenden."