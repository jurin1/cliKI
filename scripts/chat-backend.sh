#!/bin/bash
# -- chat-backend.sh (Finale Version) --

# --- Modell-Konfiguration (KORREKT) ---
MODEL_NAME="gemini-2.5-flash"
#MODEL_NAME="gemini-2.5-pro"

# --- Ladeanimation (ROBUST) ---
SPINNER_CHARS="-\|/"
SPINNER_TEXT="\033[1;36mKI denkt nach... \033[0m"

# --- Funktionen ---
spinner_start() { ( i=0; while true; do printf "\r${SPINNER_TEXT}%s " "${SPINNER_CHARS:i++%${#SPINNER_CHARS}:1}" >&2; sleep 0.1; done ) & SPINNER_PID=$!; trap "spinner_stop; exit" INT TERM; }
spinner_stop() { kill "$SPINNER_PID" &>/dev/null; printf "\r%*s\r" "$(tput cols)" "" >&2; }

# --- Hauptlogik ---
# ... (kompletter Rest des Skripts, wie in der vorherigen Version)
if [ -z "$GEMINI_API_KEY" ]; then echo "Fehler: GEMINI_API_KEY ist nicht gesetzt." >&2; exit 1; fi
if [ "$#" -eq 0 ]; then echo "Benutzung: chat <Ihre Frage an die KI>" >&2; exit 1; fi
USER_QUERY="$*"; AI_PROMPT="Du bist ein Experte für Linux/Unix Shell-Befehle. Deine Aufgabe ist es, basierend auf der Anfrage des Benutzers eine Liste von nützlichen Shell-Befehlen vorzuschlagen. Deine Antwort MUSS AUSSCHLIESSLICH ein gültiges JSON-Objekt sein. Gib keinen Text, keine Erklärungen und keine Markdown-Formatierung wie \\\`\\\`\\\`json ausserhalb des JSON-Objekts aus. Das JSON-Objekt muss die folgende Struktur haben: {\"introduction\": \"Ein kurzer, hilfreicher Einleitungstext.\",\"commands\": [{\"command\": \"der erste befehl\",\"description\": \"Eine kurze Erklärung, was dieser Befehl tut.\"}]}. Hier ist die Anfrage des Benutzers: $USER_QUERY"
JSON_PAYLOAD=$(jq -n --arg prompt "$AI_PROMPT" '{ "contents": [{"parts":[{"text": $prompt}]}]}')
spinner_start; API_RESPONSE=$(curl -s "https://generativelanguage.googleapis.com/v1beta/models/${MODEL_NAME}:generateContent" -H 'Content-Type: application/json' -H "X-goog-api-key: $GEMINI_API_KEY" -d "$JSON_PAYLOAD"); spinner_stop
RAW_TEXT=$(echo "$API_RESPONSE" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null); CLEAN_JSON=$(echo "$RAW_TEXT" | sed 's/^```json//; s/```$//')
if ! echo "$CLEAN_JSON" | jq -e 'has("commands") and (.commands | type == "array")' > /dev/null; then echo -e "\n\033[1;31mFehler: Die KI hat kein gültiges JSON im erwarteten Format zurückgegeben.\033[0m" >&2; exit 1; fi
INTRODUCTION=$(echo "$CLEAN_JSON" | jq -r '.introduction'); echo -e "\n\033[1m$INTRODUCTION\033[0m\n" >&2
declare -a commands; while IFS= read -r line; do commands+=("$line"); done < <(echo "$CLEAN_JSON" | jq -r '.commands[].command')
declare -a descriptions; while IFS= read -r line; do descriptions+=("$line"); done < <(echo "$CLEAN_JSON" | jq -r '.commands[].description')
for i in "${!commands[@]}"; do printf "\033[1;33m[%d]\033[0m \033[1;32m%s\033[0m\n" "$((i+1))" "${commands[$i]}" >&2; printf "    %s\n\n" "${descriptions[$i]}" >&2; done
read -p "Wähle einen Befehl (1-${#commands[@]}) oder eine andere Taste zum Abbrechen: " choice >&2
if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#commands[@]}" ]; then echo "${commands[$((choice-1))]}"; else exit 1; fi