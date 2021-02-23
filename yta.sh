#!/bin/sh
# Author : Stanley <git.io/monesonn>

# Script version
__version="0.2.1"

# General variables

# quiet mode is the default mode
IS_QUIET=''

DEFAULT_DIR="$HOME/Music"
PLAYLIST_DIR="${DEFAULT_DIR}/playlists"
UPLOADER_DIR="${DEFAULT_DIR}/uploader"

OUTPUT='%(uploader)s - %(title)s [%(id)s].%(ext)s'

# Default
AUDIO_EXT='mp3'
BITRATE='128K'
SAMPLE_RATE='48000'
PLAYLIST=false
SOX=false

# Some variables to initialize colors for colorfull echo output
DARK_BLUE='\033[34m'
RED='\033[31m'
BLUE='\033[1;34m'
NC='\033[0m'

_help() {

echo -ne \
"${DARK_BLUE}
 ▀▄▀ ▄▀▄ ▀█▀ ▄▀▄
  █  █▀█  █  █▀█.sh 
${NC}"
echo -e "${BLUE}  Audio download script${NC}"

cat << EOF

  Description: CLI-wrapper for youtube-dl written on Shell
  Usage: $(basename $0) [OPTIONS] -d [URL]
                                                           |OPTIONS|
 +----+------------+-----------+-----------------------------------+
 | -d | --download | download  | Download and convert single video |
 | -p | --playlist | playlist  | Download and convert playlist     |
 | -a | --audio    | audio     | Set audio extension               |
 |    |            |           | [default: mp3; aac, flac...]      |
 | -b | --bitrate  | bitrate   | Set audio bitrate                 |
 |    |            |           | [default: 128K; 256K, 320K]       |
 | -s | --asr      | asr       | Set audio samplerate              |
 |    |            |           | [default: 48000; 44000, 41000]    |
 | -p | --path     | path      | Set path [default: ~/Music/yata]  |
 | -q | --quiet    | quiet     | Turn off quiet mode               |
 | -1 | --sox      | sox       | Merge audio files from playlist   |
 | -v | --version  | version   | Show script version               |
 | -h | --help     | help      | Show this message                 |
 +----+------------+-----------+-----------------------------------+

  Example: yta https://youtu.be/[url]
           yta -p https://www.youtube.com/playlist?list=[url]
           yta -a=aac -s=44000 -b=256 https://youtu.be/[url]

EOF
}

download() {
  [[ ${AUDIO_EXT} = mp3 ]] && local EMBED="--embed-thumbnail" || local EMBED="" 

  echo "[yata] Starting..."
  youtube-dl \
  ${IS_QUIET} \
  --format "bestaudio[asr = ${SAMPLE_RATE}]" \
  --ignore-errors \
  --no-continue \
  --no-overwrites \
  --add-metadata \
  --extract-audio \
  --audio-format ${AUDIO_EXT} \
  --audio-quality ${BITRATE} \
  ${EMBED} \
  --metadata-from-title "(?P<artist>.+?) - (?P<title>.+)" \
  --output "${DEFAULT_DIR}/${AUDIO_EXT}/%(title)s.%(ext)s" \
  --exec 'echo [yata] {} is downloaded.' \
  $1 `# URL` 2>/dev/null
  echo "[yata] All is done."
  exit 0
}

download_playlist() {
  local PLAYLIST_TITLE=`youtube-dl --no-warnings --dump-single-json $1 | jq -r '.title'`

  echo "[yata]: Starting to download playlist \"${PLAYLIST_TITLE}\""
  youtube-dl \
  ${IS_QUIET} \
  --format "bestaudio[asr = ${SAMPLE_RATE}]" \
  --ignore-errors \
  --no-continue \
  --no-overwrites \
  --add-metadata \
  --yes-playlist \
  --extract-audio \
  --audio-format ${AUDIO_EXT} \
  --audio-quality ${BITRATE} \
  --embed-thumbnail \
  --metadata-from-title "(?P<title>.+)" \
  --output "${PLAYLIST_DIR}/%(playlist)s/%(playlist_index)s %(title)s.%(ext)s" \
  --exec 'echo [yata] {} is downloaded.' \
  $1 `# URL` 2>/dev/null
  if [ ${SOX} = true ] ; then
    # lmao, idk, but it's works 

    # files=${PLAYLIST_DIR}/${playlist_title}/*.${AUDIO_EXT}
    echo "[sox]  Starting to merge ${PLAYLIST_TITLE}."
    sox "${PLAYLIST_DIR}/${PLAYLIST_TITLE}/*.${AUDIO_EXT}" "${DEFAULT_DIR}/${AUDIO_EXT}/${PLAYLIST_TITLE}.${AUDIO_EXT}"
    echo "[sox]  ${DEFAULT_DIR}/${AUDIO_EXT}/${PLAYLIST_TITLE}.${AUDIO_EXT} is merged."
  fi
  echo "[yata] All is done."
  exit 0
}

err_msg() { echo -e "${RED}$1${NC}"; }

__main__() {
  while [[ "$#" -gt 0 ]]; do
    argument="$1"
    case $argument in
      -p | --playlist | playlist) PLAYLIST=true ; shift 2 ;;
      -a=* | --audio=* | audio=*) AUDIO_EXT="${argument#*=}" ; shift ;;
      -b=* | --bitrate=* | bitrate=*) BITRATE="${argument#*=}" ; shift ;;
      -q | --quiet | quiet) IS_QUIET='--quiet --console-title' ; shift ;;
      -1 | --sox | sox) SOX=true ; shift ;; 
      -v | --version | version) printf "$__version\n" ; exit 0 ;;
      -h | --help | help) _help ; exit 0 ;;
      -* | --*) err_msg "No such option: $argument.\nType yta [-h|--help|help] to see a list of all options." ; exit 1 ;;
      *) [[ ${PLAYLIST} = false ]] && download $argument || download_playlist $argument ;;
    esac
  done
}

if [[ ${#} -eq 0 ]]; then
  _help ; exit 1
fi
__main__ "$@" ; exit 0