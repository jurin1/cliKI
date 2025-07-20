#!/bin/bash

# Farben für die Ausgabe
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[0;34m"
NC="\033[0m" # No Color

# Repo-Informationen
GITHUB_REPO="jurin1/cliKi"
BACKEND_SCRIPT_URL="https://raw.githubusercontent.com/${GITHUB_REPO}/main/scripts/chat-backend.sh"
BACKEND_DEST="/usr/local/bin/chat-backend"

# verfügbare Modelle
MODELS=("gemini-1.5-flash" "gemini-1.5-pro")

echo -e "${BLUE}--- Willkommen beim Installer für das Chat-CLI-Tool ---${NC}"

# Schritt 1: Abhängigkeiten installieren
echo -e "\n${YELLOW}Schritt 1: Prüfe und installiere Abhängigkeiten (curl, jq)...${NC}"
# ... (Dieser Block bleibt unverändert)
if command -v apt-get &> /dev/null; then sudo apt-get update > /dev/null; sudo apt-get install -y curl jq; elif command -v dnf &> /dev/null; then sudo dnf install -y curl jq; elif command -v yum &> /dev/null; then sudo yum install -y curl jq; elif command -v pacman &> /dev/null; then sudo pacman -S --noconfirm curl jq; else echo "Konnte den Paketmanager nicht erkennen. Bitte installieren Sie 'curl' und 'jq' manuell."; exit 1; fi
echo -e "${GREEN}Abhängigkeiten sind installiert.${NC}"

# Schritt 2: Shell-Konfiguration auswählen
SHELL_CONFIG=""
if [ -f "$HOME/.zshrc" ]; then SHELL_CONFIG="$HOME/.zshrc"; echo -e "\n${YELLOW}Zsh-Konfiguration (~/.zshrc) gefunden.${NC}"; elif [ -f "$HOME/.bashrc" ]; then SHELL_CONFIG="$HOME/.bashrc"; echo -e "\n${YELLOW}Bash-Konfiguration (~/.bashrc) gefunden.${NC}"; fi
read -p "Soll die Konfiguration in '$SHELL_CONFIG' geschrieben werden? (J/n) " choice < /dev/tty
case "$choice" in n|N) read -p "Bitte geben Sie den Pfad zu Ihrer Shell-Konfigurationsdatei an: " SHELL_CONFIG < /dev/tty;; *) ;; esac
if [ ! -f "$SHELL_CONFIG" ]; then echo "Die angegebene Datei '$SHELL_CONFIG' existiert nicht. Abbruch."; exit 1; fi

# --- NEUER, INTELLIGENTER API-KEY-BLOCK ---
echo -e "\n${YELLOW}Schritt 2: Konfiguriere Gemini API-Schlüssel...${NC}"

# Prüfen, ob die Zeile existiert
if grep -q "export GEMINI_API_KEY" "$SHELL_CONFIG"; then
    # Zeile existiert. Jetzt den Inhalt prüfen.
    CURRENT_KEY=$(grep "export GEMINI_API_KEY" "$SHELL_CONFIG" | sed -n 's/.*GEMINI_API_KEY="\([^"]*\)".*/\1/p')

    if [ -z "$CURRENT_KEY" ]; then
        # Fall 1: Der Schlüssel-Eintrag ist vorhanden, aber leer.
        echo -e "${YELLOW}Ein leerer API-Schlüssel-Eintrag wurde gefunden.${NC}"
        while true; do
            read -p "Bitte geben Sie Ihren gültigen Google Gemini API-Schlüssel ein: " new_api_key < /dev/tty
            if [ -n "$new_api_key" ]; then
                # Ersetze die leere Zeile mit dem neuen Schlüssel
                sed -i "s|export GEMINI_API_KEY=\"\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$SHELL_CONFIG"
                echo -e "${GREEN}API-Schlüssel wurde erfolgreich eingetragen.${NC}"
                break
            else
                echo "Die Eingabe darf nicht leer sein. Bitte erneut versuchen."
            fi
        done
    else
        # Fall 2: Ein Schlüssel existiert bereits.
        LAST_CHARS=$(echo "$CURRENT_KEY" | tail -c 5)
        echo -e "${GREEN}Ein API-Schlüssel (endet auf ...$LAST_CHARS) ist bereits vorhanden.${NC}"
        read -p "Möchten Sie ihn ersetzen? (j/N) " replace_choice < /dev/tty
        if [[ "$replace_choice" =~ ^[jJ]$ ]]; then
            while true; do
                read -p "Bitte geben Sie den NEUEN API-Schlüssel ein: " new_api_key < /dev/tty
                if [ -n "$new_api_key" ]; then
                    # Ersetze den alten Schlüssel mit dem neuen.
                    sed -i "s|export GEMINI_API_KEY=\".*\"|export GEMINI_API_KEY=\"$new_api_key\"|" "$SHELL_CONFIG"
                    echo -e "${GREEN}API-Schlüssel wurde ersetzt.${NC}"
                    break
                else
                    echo "Die Eingabe darf nicht leer sein. Bitte erneut versuchen."
                fi
            done
        else
            echo "Der vorhandene API-Schlüssel wird beibehalten."
        fi
    fi
else
    # Fall 3: Der Schlüssel-Eintrag existiert überhaupt nicht (Erste Installation).
    echo -e "${YELLOW}Es wurde kein API-Schlüssel gefunden. Bitte richten Sie einen ein.${NC}"
    while true; do
        read -p "Bitte geben Sie Ihren Google Gemini API-Schlüssel ein: " api_key < /dev/tty
        if [ -n "$api_key" ]; then
            echo "" >> "$SHELL_CONFIG"
            echo "# Für das Chat-CLI-Tool hinzugefügt" >> "$SHELL_CONFIG"
            echo "export GEMINI_API_KEY=\"$api_key\"" >> "$SHELL_CONFIG"
            echo -e "${GREEN}API-Schlüssel wurde zu '$SHELL_CONFIG' hinzugefügt.${NC}"
            break
        else
            echo "Die Eingabe darf nicht leer sein. Bitte erneut versuchen."
        fi
    done
fi
# --- ENDE DES NEUEN BLOCKS ---


# Schritt 4: chat-Funktion hinzufügen
echo -e "\n${YELLOW}Schritt 3: Füge die 'chat' Funktion zur Shell hinzu...${NC}"
# ... (Dieser Block bleibt unverändert)
if grep -q "function chat()" "$SHELL_CONFIG"; then echo -e "${GREEN}'chat'-Funktion ist bereits vorhanden. Wird übersprungen.${NC}"; else cat <<'EOF' >> "$SHELL_CONFIG"

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
echo -e "${GREEN}'chat'-Funktion wurde zu '$SHELL_CONFIG' hinzugefügt.${NC}"; fi


# Schritt 5: Backend-Skript herunterladen
echo -e "\n${YELLOW}Schritt 4: Installiere das Backend-Skript...${NC}"
# ... (Dieser Block bleibt unverändert, nur die Zeile mit "read" wird angepasst)
DL_SKIP="false"
if [ -f "$BACKEND_DEST" ]; then
    read -p "Das Backend-Skript existiert bereits. Erneut herunterladen und überschreiben? (j/N) " choice < /dev/tty
    case "$choice" in j|J) ;; *) echo "Download wird übersprungen."; DL_SKIP="true";; esac
fi
if [ "$DL_SKIP" != "true" ]; then
    echo "Lade Backend-Skript herunter..."; sudo curl -fsSL "$BACKEND_SCRIPT_URL" -o "$BACKEND_DEST"; sudo chmod +x "$BACKEND_DEST"
    echo -e "${GREEN}Backend-Skript wurde nach '$BACKEND_DEST' heruntergeladen und ausführbar gemacht.${NC}"
fi


# Schritt 6: Modell auswählen
echo -e "\n${YELLOW}Schritt 5: Wähle das Standard-KI-Modell aus...${NC}"
# ... (Dieser Block bleibt unverändert)
PS3="Geben Sie die Zahl für das gewünschte Modell ein (z.B. 1): "
{ select opt in "${MODELS[@]}"; do if [[ -n $opt ]]; then echo "Aktiviere $opt..."; sudo sed -i 's/^\(MODEL_NAME=.*\)/#\1/' "$BACKEND_DEST"; sudo sed -i "s/^#\(MODEL_NAME=\"$opt\"\)/\1/" "$BACKEND_DEST"; echo -e "${GREEN}$opt wurde als Standardmodell festgelegt.${NC}"; break; else echo "Ungültige Auswahl. Bitte geben Sie nur eine Zahl aus der Liste ein."; fi; done; } < /dev/tty


echo -e "\n${GREEN}--- Installation abgeschlossen! ---${NC}"
echo -e "Bitte starten Sie Ihr Terminal neu oder führen Sie \`${YELLOW}source $SHELL_CONFIG\` aus, um die Änderungen zu laden."
echo -e "Danach können Sie das Tool mit \`${YELLOW}chat 'Ihre Frage'\` verwenden."