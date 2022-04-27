BLUE='\033[0;34m'
GREEN='\033[0;32m'
NONE="\033[0m"

function info {
  echo "${GREEN}[INFO]${NONE}  $1"
}

function note {
  echo "${BLUE}[NOTE]${NONE}  $1"
}
