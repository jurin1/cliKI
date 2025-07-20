#!/bin/bash
# -- chat-backend.sh (mit Multi-History-Logik) --

# --- Konfiguration ---
MODEL_NAME="gemini-2.5-flash"
#MODEL_NAME="gemini-2.5-pro"
SPINNER_CHARS="-\|/"
SPINNER_TEXT="\033[1;36mKI denkt nach... \033[0m"

# --- Funktionen (unverändert) ---
spinner_start() { ( i=0; while true; do printf "\r${SPINNER_TEXT}%s " "${SPINNER_CHARS:i++%${#SPINNER_CHARS}:1}" >&2; sleep 0.1; done ) & SPINNER_PID=$!; trap "spinner_stop; exit" INT TERM; }
spinner_stop() { kill "$SPINNER_PID" &>/dev/null; printf "\r%*s\r" "$(tput cols)" "" >&2; }

# --- Hauptlogik ---
if [ -z "$GEMINI_API_KEY" ]; then exit 1; fi
if [ "$#" -eq 0 ]; then exit 1; fi

# ... (API-Aufruf bleibt gleich)
USER_QUERY="$*"; AI_PROMPT="Du bist ein Experte für Linux/Unix Shell-Befehle. Deine Aufgabe ist es, basierend auf der Anfrage des Benutzers eine Liste von nützlichen Shell-Befehlen vorzuschlagen. Deine Antwort MUSS AUSSCHLIESSLICH ein gültiges JSON-Objekt sein. Das JSON-Objekt muss die folgende Struktur haben: {\"introduction\": \"Ein kurzer, hilfreicher Einleitungstext.\",\"commands\": [{\"command\": \"der erste befehl\",\"description\": \"Eine kurze Erklärung, was dieser Befehl tut.\"}]}. Hier ist die Anfrage des Benutzers: $USER_QUERY"
spinner_start; API_RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent" -H 'Content-Type: application/json' -H "X-goog-api-key: $GEMINI_API_KEY" -d "$(jq -n --arg prompt "$AI_PROMPT" '{ "contents": [{"parts":[{"text": $prompt}]}]}')"); spinner_stop
RAW_TEXT=$(echo "$API_RESPONSE" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null); CLEAN_JSON=$(echo "$RAW_TEXT" | sed 's/^```json//; s/```$//'); if ! echo "$CLEAN_JSON" | jq -e '.commands' > /dev/null; then exit 1; fi

# --- NEUE LOGIK FÜR DIE HISTORY ---
# 1. Alle Befehle in ein Bash-Array einlesen
declare -a commands; while IFS= read -r line; do commands+=("$line"); done < <(echo "$CLEAN_JSON" | jq -r '.commands[].command')
declare -a descriptions; while IFS= read -r line; do descriptions+=("$line"); done < <(echo "$CLEAN_JSON" | jq -r '.commands[].description')

# 2. Dem Benutzer die Auswahl anzeigen (auf dem Fehlerkanal, damit es nicht vom Frontend aufgefangen wird)
echo -e "\n$(echo "$CLEAN_JSON" | jq -r '.introduction')\n" >&2
for i in "${!commands[@]}"; do
    printf "\033[1;33m[%d]\033[0m \033[1;32m%s\033[0m\n" "$((i+1))" "${commands[$i]}" >&2
    printf "    %s\n\n" "${descriptions[$i]}" >&2
done
read -p "Wähle einen Befehl (1-${#commands[@]}) oder eine andere Taste zum Abbrechen: " choice >&2

# 3. Den ausgewählten Befehl ermitteln
if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#commands[@]}" ]; then
    selected_command_index=$((choice-1))
    selected_command="${commands[$selected_command_index]}"

    # 4. Alle ANDEREN Befehle zuerst ausgeben
    for i in "${!commands[@]}"; do
        if [ "$i" -ne "$selected_command_index" ]; then
            echo "${commands[$i]}"
        fi
    done
    # 5. Den ausgewählten Befehl GANZ ZUM SCHLUSS ausgeben
    echo "$selected_command"
else
    # Wenn der Benutzer abbricht, gib nichts aus
    exit 1
fi