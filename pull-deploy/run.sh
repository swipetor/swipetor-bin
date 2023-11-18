#!/bin/bash

BEARER=$(cat ~/.unlockfeed/repos_read_secret)
TMP_DIR="/tmp/unlockfeed-deploy"

rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"

if type "gtar" &>/dev/null; then
    TAR_CMD="gtar"
else
    TAR_CMD="tar"
fi

# Arg 1: Full directory path
function download_release() {
    # Set the GitHub repository (format: user/repo)
    GITHUB_REPO="atas/${1}"
    CODENAME=$2

    GH_TOKEN=$BEARER gh release download -R "$GITHUB_REPO" --pattern="*" --dir="$TMP_DIR"
    filename=$(find "$TMP_DIR" -name "${CODENAME}-*.tar.gz" -print -quit)
    filename=$(basename "$filename")

    echo "$filename" is downloaded and will be extracted

    version=${filename#ufapp-} # Remove prefix up to and including 'ufapp-'
    version=${version%.tar.gz} # Remove '.tar.gz' suffix

    $TAR_CMD -xzf "$TMP_DIR/$filename" -C "$TMP_DIR" --one-top-level="$CODENAME"

    echo "$version" >"$TMP_DIR/$CODENAME/version.txt"
}

download_release "unlockfeed-app" "ufapp"
download_release "unlockfeed-web" "ufweb"

mv $TMP_DIR/ufweb/public/build $TMP_DIR/ufapp/wwwroot/public/
mv $TMP_DIR/ufapp /srv/unlockfeed/app
sudo service supervisor restart
