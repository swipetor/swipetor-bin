#!/bin/bash

BEARER=$(cat ~/.swipetor/repos_read_secret)
FIREBASE_ADMIN=$(cat ~/.swipetor/firebase-admin.json)
TMP_DIR="/tmp/swipetor-deploy"

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

    version=${filename#swpapp-} # Remove prefix up to and including 'swpapp-'
    version=${version%.tar.gz}  # Remove '.tar.gz' suffix

    $TAR_CMD -xzf "$TMP_DIR/$filename" -C "$TMP_DIR" --one-top-level="$CODENAME"

    echo "$version" >"$TMP_DIR/$CODENAME/version.txt"
}

download_release "swpapp" "swpapp"
download_release "swpweb" "swpweb"

echo "$FIREBASE_ADMIN" >"$TMP_DIR/swpapp/App_Data/firebase-admin.json"
mv $TMP_DIR/swpweb/public/build $TMP_DIR/swpapp/wwwroot/public/
cp $TMP_DIR/swpapp/version.txt $TMP_DIR/swpapp/App_Data/app-version.txt
cp $TMP_DIR/swpweb/version.txt $TMP_DIR/swpapp/App_Data/ui-version.txt
sudo rsync -r --delete --filter='P /wwwroot/public/sitemaps/' --no-perms $TMP_DIR/swpapp/ /srv/swipetor/app/
sudo rm -rf $TMP_DIR/swpapp
sudo service supervisor restart
