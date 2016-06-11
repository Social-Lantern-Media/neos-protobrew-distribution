#!/bin/bash
#
# Site build script
#
# This file should contain all necessary steps to build the website. Include here 
# all necessary build steps (e.g. scripts minification, styles compilation etc).
#

CWD=$(pwd)
RUN_BEARD=${RUN_BEARD:=false}

PROJECT_NAME="NEOS-PROTOBREW-DISTRIBUTION"
TYPO3_NEOS_PACKAGE_DIR="${CWD}/Packages/Neos/TYPO3.Neos"
SITE_PACKAGE_DIR="${CWD}/Packages/Sites/Pb.Site"

#
# This will install all development tools needed to run Neos 'grunt build'
#
function installNeosDevTools() {
  echo "Installing Neos dev tools..."
  mkdir -p /data/www && chown www:www /data/www # needed for `npm install for its cache, called from ./install-dev-tools.sh
  cd "${TYPO3_NEOS_PACKAGE_DIR}/Scripts"
  chown -R www:www . # Fix perms for current dir as they are not set to www user yet. Needed for ./install-dev-tools.sh which cannot be run as root (bower error)
  su www -c "./install-dev-tools.sh" # Run as www user: Bower will exit if it's run as root user
  rm -rf /data/www # This function is callled only during docker build. We don't need to embed this dir in the image...
  cd $CWD
}

function buildSitePackage() {
  echo "Building Pb.Site..."
  cd $SITE_PACKAGE_DIR
  bower install --allow-root # this script is called as root in '--preinstall' phase
  npm install
  gulp build
  cd $CWD
}


case $@ in
  #
  # This is called when container is being build (and this script is called with --preinstall param)
  #
  *--preinstall*)
    echo && echo "$PROJECT_NAME BUILD SCRIPT: PREINSTALL"

    set -e # exit with error if any of the following fail
#    installNeosDevTools
    buildSitePackage
    ;;
 
  #
  # This is called when container launches (and script is called without param)
  #
  *)
    echo && echo "$PROJECT_NAME BUILD SCRIPT"
    git config --global user.email "www@build.user" &&  git config --global user.name "WWW User"

#    buildSitePackage

    echo "Done."
esac

echo "$PROJECT_NAME BUILD SCRIPT completed."
