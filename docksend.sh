#!/bin/bash

if ! which rsync > /dev/null; then
  echo "cannot use docksend without rsync installed!"
  echo "make sure you have rsync installed and in your path"
  exit 2
fi

# colorful echo only if verbose env var is set
print() {
  if [ "$VERBOSE" ]; then
    tput setaf 3
    echo "$1"
    tput sgr0
  fi
}

printusage() {
  echo "usage: ./docksend.sh [-v docker_volume] [-i ssh_identity_file] [user@]hostname docker_image [command]"
}

# parse arguments
while getopts ":i:v:d:w:" opt; do
  case $opt in
    i)
      IDENTITY_FILE="$OPTARG";;
    d)
      REMOTE_DIR="$OPTARG";;
    w)
      WORKING_DIR="$OPTARG";;
    p)
      PULL_FIRST=true;;
    v)
      # split by colon into array
      IFS=':' read -a DOCKER_VOLUME <<< "$OPTARG";;
    :)
      echo "option -$OPTARG requires an argument." >&2
      exit 1;;
    \?)
      echo "invalid option: -$OPTARG" >&2
      exit 1;;
  esac
done

# remove (shift) option arguments until they are all gone
n=1
while [ $# -gt 0 ]; do
  if [ $n -lt $OPTIND ]; then
    let n=$n+1
    shift
  else
    break
  fi
done

# check non option parameters
if [ "$#" -lt 3 ]; then
    printusage
    exit 1
fi

SSH_HOSTNAME="$1"
DOCKER_IMAGE="$2"
DOCKER_COMMAND="$3"
DOCKER_ARGS="${*:3}"

if [ -z "${DOCKER_VOLUME+x}" ]; then
  LOCAL_DIR="$(pwd)"
  DOCKER_DIR="/root"
else
  LOCAL_DIR="${DOCKER_VOLUME[0]}"
  DOCKER_DIR="${DOCKER_VOLUME[1]}"
fi

if [ -z "${IDENTITY_FILE+x}" ]; then
  SSH_ARGS=""
else
  SSH_ARGS="-i $IDENTITY_FILE"
fi

# more verbose rsync output if user wants it
if [ "$VERBOSE" ]; then
  RSYNC_FLAGS="-avz"
else
  RSYNC_FLAGS="-az"
fi

# create tempdir for remote location if tempdir was not specified
if [ -z "${REMOTE_DIR+x}" ]; then
  USED_TEMPDIR=true
  REMOTE_DIR=$(ssh $SSH_ARGS "$SSH_HOSTNAME" "mktemp -d")
  print "created tempdir $SSH_HOSTNAME:$REMOTE_DIR for syncing"
fi

if [ -z "${WORKING_DIR+x}" ]; then
  WORKING_DIR="$REMOTE_DIR"
fi

# make sure we never have trailing slashes for rsync dirs
# because we append them later
LOCAL_DIR=$(echo "$LOCAL_DIR"|sed 's/\/$//g')
REMOTE_DIR=$(echo "$REMOTE_DIR"|sed 's/\/$//g')

# ensure tempdir gets always deleted
function deltempdir {
  if $USED_TEMPDIR; then
    ssh $SSH_ARGS "$SSH_HOSTNAME" "rm -r $REMOTE_DIR" > /dev/null
    print "deleted tempdir $SSH_HOSTNAME:$REMOTE_DIR"
  fi
}

# sync directory up to server
function syncup {
  print "syncing $LOCAL_DIR up to $SSH_HOSTNAME:$REMOTE_DIR"
  rsync "$RSYNC_FLAGS" --exclude='.git' -e "ssh $SSH_ARGS" "$LOCAL_DIR/" "$SSH_HOSTNAME:$REMOTE_DIR/"
}

function rundocker {
  if [ "$PULL_FIRST" ]; then
    ssh $SSH_ARGS "$SSH_HOSTNAME" "docker pull $DOCKER_IMAGE" > /dev/null
  fi

  ssh $SSH_ARGS "$SSH_HOSTNAME" "docker run --rm -w $WORKING_DIR -v $REMOTE_DIR:$DOCKER_DIR $DOCKER_IMAGE $DOCKER_COMMAND $DOCKER_ARGS"
}

# sync changes down
function syncdown {
  print "syncing $SSH_HOSTNAME:$REMOTE_DIR down to $LOCAL_DIR"
  rsync "$RSYNC_FLAGS" --exclude='.git' -e "ssh $SSH_ARGS" "$SSH_HOSTNAME:$REMOTE_DIR/" "$LOCAL_DIR/"
}

trap deltempdir EXIT
syncup
rundocker
syncdown
