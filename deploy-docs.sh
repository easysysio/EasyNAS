#!/bin/sh
# Build the EasyNAS website and documentation and publish it to easynas.org.
#
# Mirrors EasyDC/deploy-docs.sh and EasySYS-web/deploy.sh: pull, build with
# mkdocs, replace what is served. Run it on the host that serves the site; the
# web server's easynas.org vhost should point at the target directory.
#
# Usage: ./deploy-docs.sh [TARGET]    (default /var/www/easynas)
set -e

TARGET=${1:-/var/www/easynas}

# The target is removed wholesale below, so refuse anything that isn't a
# dedicated directory.
case "$TARGET" in
  /|/var|/var/www|/var/www/) echo "Refusing to deploy over $TARGET" >&2; exit 1 ;;
esac

cd "$(dirname "$0")"

echo "Building the EasyNAS website"
git pull
# Built before the old site is touched: a failed build leaves the live site up.
mkdocs build --strict

rm -rf "$TARGET"
cp -r site "$TARGET"
echo "Deployed to $TARGET"
