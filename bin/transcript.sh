#!/usr/bin/env bash
#
# transcript.sh — Extrait l'audio d'un fichier et le transcrit en texte (français).
#
# Usage :
#   transcript "reunion.mp4"                  # mode normal (recette par défaut)
#   transcript "reunion.mp4" --aggressive     # mode anti-boucle renforcé
#   transcript "reunion.mp4" --split-silence  # découpe sur les silences puis recolle
#   transcript "reunion.mp4" --turbo          # modèle large-v3-turbo (plus rapide)
#   transcript "reunion.mp4" --keep-wav       # garde le WAV intermédiaire
#
# Les options se combinent, dans n'importe quel ordre :
#   transcript "reunion.mp4" --split-silence --turbo
#
# --split-silence : à utiliser quand un fichier part en boucle ("Merci."/phrase
# répétée) à cause d'un blanc en milieu de réunion. Le script détecte les silences,
# découpe l'audio en blocs, transcrit chaque bloc séparément (Whisper repart à zéro
# après chaque blanc, donc plus de boucle qui se propage), puis recolle le tout.
#
# Sortie : un fichier .txt à côté du fichier d'entrée.
# Dépendances : ffmpeg, whisper-cli (brew install ffmpeg whisper-cpp)

set -euo pipefail

# --- Configuration -----------------------------------------------------------

MODELS_DIR="${HOME}/whisper-models"
MODEL_DEFAULT="ggml-large-v3.bin"
MODEL_TURBO="ggml-large-v3-turbo.bin"

# Paramètres de détection de silence (mode --split-silence) :
#   SILENCE_DB     : seuil en dB sous lequel c'est considéré comme du silence
#   SILENCE_MIN    : durée minimale d'un silence pour déclencher une découpe (s)
SILENCE_DB="-30dB"
SILENCE_MIN="2.0"

# --- Analyse des arguments ---------------------------------------------------

if [[ $# -lt 1 ]]; then
  echo "Usage : $0 \"fichier.mp4\" [--aggressive] [--split-silence] [--turbo] [--keep-wav]" >&2
  exit 1
fi

INPUT="$1"
shift

USE_TURBO=false
AGGRESSIVE=false
KEEP_WAV=false
SPLIT_SILENCE=false

for arg in "$@"; do
  case "$arg" in
    --turbo)         USE_TURBO=true ;;
    --aggressive)    AGGRESSIVE=true ;;
    --keep-wav)      KEEP_WAV=true ;;
    --split-silence) SPLIT_SILENCE=true ;;
    *) echo "Option inconnue : $arg" >&2; exit 1 ;;
  esac
done

if [[ ! -f "$INPUT" ]]; then
  echo "Erreur : fichier introuvable : $INPUT" >&2
  exit 1
fi

# --- Choix du modèle ---------------------------------------------------------

if $USE_TURBO; then
  MODEL_NAME="$MODEL_TURBO"
else
  MODEL_NAME="$MODEL_DEFAULT"
fi
MODEL_FILE="${MODELS_DIR}/${MODEL_NAME}"
MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/${MODEL_NAME}"

if [[ ! -f "$MODEL_FILE" ]]; then
  echo "Modèle absent, téléchargement de ${MODEL_NAME}..."
  mkdir -p "$MODELS_DIR"
  curl -L -o "$MODEL_FILE" "$MODEL_URL"
fi

# --- Options de transcription selon le mode ----------------------------------

if $AGGRESSIVE; then
  WHISPER_OPTS=(-nf -et 2.4 --no-speech-thold 0.7)
else
  WHISPER_OPTS=(-et 2.4 -mc 64 --no-speech-thold 0.6)
fi

BASE="${INPUT%.*}"
EXT="${INPUT##*.}"

# --- Préparation du WAV ------------------------------------------------------

if [[ "$EXT" == "wav" ]]; then
  WAV="$INPUT"
  WAV_IS_SOURCE=true
else
  WAV="${BASE}.wav"
  WAV_IS_SOURCE=false
  echo "Extraction audio (WAV 16 kHz mono)..."
  ffmpeg -y -i "$INPUT" -ar 16000 -ac 1 -c:a pcm_s16le "$WAV" \
    -hide_banner -loglevel error
fi

OUT_TXT="${BASE}.txt"

# =============================================================================
# MODE SPLIT-SILENCE
# =============================================================================
if $SPLIT_SILENCE; then
  echo "Mode : découpe sur silences (seuil ${SILENCE_DB}, durée min ${SILENCE_MIN}s)"

  WORKDIR="$(mktemp -d)"
  trap 'rm -rf "$WORKDIR"' EXIT

  # 1) Détecter les silences. ffmpeg silencedetect écrit sur stderr des lignes
  #    "silence_start: X" et "silence_end: Y | silence_duration: Z".
  echo "Détection des silences..."
  DETECT_LOG="${WORKDIR}/silence.log"
  ffmpeg -i "$WAV" -af "silencedetect=noise=${SILENCE_DB}:d=${SILENCE_MIN}" \
    -f null - 2> "$DETECT_LOG" || true

  # Durée totale (secondes) pour borner le dernier segment.
  DURATION="$(ffprobe -v error -show_entries format=duration \
    -of default=noprint_wrappers=1:nokey=1 "$WAV")"

  # 2) Construire les points de coupe : le milieu de chaque silence détecté.
  #    On lit chaque paire start/end et on coupe à (start+end)/2.
  CUTPOINTS=()
  while IFS= read -r line; do
    if [[ "$line" =~ silence_start:\ ([0-9.]+) ]]; then
      S_START="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ silence_end:\ ([0-9.]+) ]]; then
      S_END="${BASH_REMATCH[1]}"
      MID="$(awk "BEGIN{printf \"%.3f\", ($S_START + $S_END)/2}")"
      CUTPOINTS+=("$MID")
    fi
  done < "$DETECT_LOG"

  if [[ ${#CUTPOINTS[@]} -eq 0 ]]; then
    echo "Aucun silence détecté avec ces réglages — transcription en un seul bloc."
    whisper-cli -m "$MODEL_FILE" -l fr -f "$WAV" -otxt "${WHISPER_OPTS[@]}"
    [[ -f "${WAV}.txt" ]] && mv "${WAV}.txt" "$OUT_TXT"
  else
    echo "${#CUTPOINTS[@]} point(s) de découpe détecté(s). Transcription par blocs..."

    # 3) Construire la liste des bornes : 0, chaque cutpoint, durée totale.
    BOUNDS=(0 "${CUTPOINTS[@]}" "$DURATION")

    : > "$OUT_TXT"   # vide le fichier de sortie
    N=$(( ${#BOUNDS[@]} - 1 ))
    for (( i=0; i<N; i++ )); do
      START="${BOUNDS[i]}"
      END="${BOUNDS[i+1]}"
      DUR="$(awk "BEGIN{printf \"%.3f\", $END - $START}")"

      # Ignore les blocs minuscules (< 0.5s)
      TOO_SHORT="$(awk "BEGIN{print ($DUR < 0.5) ? 1 : 0}")"
      [[ "$TOO_SHORT" == "1" ]] && continue

      SEG="${WORKDIR}/seg_${i}.wav"
      ffmpeg -y -i "$WAV" -ss "$START" -t "$DUR" \
        -ar 16000 -ac 1 -c:a pcm_s16le "$SEG" -hide_banner -loglevel error

      echo "  Bloc $((i+1))/$N  (${START}s → ${END}s)"
      whisper-cli -m "$MODEL_FILE" -l fr -f "$SEG" -otxt "${WHISPER_OPTS[@]}" \
        -np > /dev/null 2>&1 || true

      # Recolle le texte du bloc, en réécrivant l'offset de temps en tête de bloc.
      if [[ -f "${SEG}.txt" ]]; then
        OFFSET="$(awk "BEGIN{printf \"%d:%02d\", int($START/60), int($START)%60}")"
        echo "[~${OFFSET}]" >> "$OUT_TXT"
        cat "${SEG}.txt" >> "$OUT_TXT"
        echo "" >> "$OUT_TXT"
      fi
    done
  fi

else
  # =============================================================================
  # MODE NORMAL / AGGRESSIVE
  # =============================================================================
  if $AGGRESSIVE; then
    echo "Mode : anti-boucle renforcé"
  else
    echo "Mode : normal"
  fi
  echo "Transcription (français)..."
  whisper-cli -m "$MODEL_FILE" -l fr -f "$WAV" -otxt "${WHISPER_OPTS[@]}"
  # whisper-cli écrit FICHIER.wav.txt — on renomme proprement.
  [[ -f "${WAV}.txt" ]] && mv "${WAV}.txt" "$OUT_TXT"
fi

# --- Nettoyage ---------------------------------------------------------------

if ! $KEEP_WAV && ! $WAV_IS_SOURCE; then
  rm -f "$WAV"
elif ! $WAV_IS_SOURCE; then
  echo "WAV conservé : $WAV"
fi

echo ""
echo "✅ Terminé : ${OUT_TXT}"