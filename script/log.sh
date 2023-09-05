RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'

NONE="\033[0m"

function info {
  echo -e "${GREEN}[INFO]${NONE} $1"
}

function warn {
  echo -e "${RED}[WARN]${NONE}  $1"
}

function note {
  echo -e "${BLUE}[NOTE]${NONE}  $1"
}
