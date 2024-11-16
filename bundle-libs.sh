#!/bin/sh

# This is intended to generate and copy dependencies
# like msgstream into Sources folder compatible with
# SwiftPM

ROOT="$PWD"
SRC="$ROOT/Sources"

# msgstream
MSGDIR="$SRC/msgstream"

cd msgstream
npm ci
conan install -of conan .
cat > config.json <<EOF
{
	"pkgConfigPaths": ["conan"]
}
EOF

node make.mjs errc.c
node make.mjs include/msgstream/errc.h

rm -rf "$MSGDIR"
mkdir "$MSGDIR"
mkdir "$MSGDIR/include"
cp -R include/ "$MSGDIR/include"
cp -R build/include/ "$MSGDIR/include"
cp src/*.c "$MSGDIR"
cp build/errc.c "$MSGDIR"

cat > "$MSGDIR/include/module.modulemap" <<EOF
// AUTO GENERATED BY bundle-libs.sh
module msgstream {
	umbrella header "msgstream.h"
	header "msgstream/errc.h"
}
EOF

cd ..

# unixsocket
UNIXDIR="$SRC/unixsocket"

rm -rf "$UNIXDIR"
mkdir "$UNIXDIR"
mkdir "$UNIXDIR/include"
cp unixsocket/src/*.c "$UNIXDIR"
cp unixsocket/include/*.h "$UNIXDIR/include"

# catui
CATUIDIR="$SRC/catui"

rm -rf "$CATUIDIR"
mkdir "$CATUIDIR"
mkdir "$CATUIDIR/include"
cp catui/src/catui_server.c "$CATUIDIR"
cp catui/src/catui.c "$CATUIDIR"
cp catui/include/catui.h "$CATUIDIR/include"

cat >> "$CATUIDIR/include/catui.h" <<EOF

// CatuiServer.swift extensions to make swift interop easier
const char * CATUI_API catui_ext_protocol_cstr(const catui_connect_request *req);
EOF

cat > "$CATUIDIR/ext.c" <<EOF
#include "catui.h"

const char *catui_ext_protocol_cstr(const catui_connect_request *req) {
	return req->protocol;
}
EOF

# cjson was manually downloaded/copied.
# Much more stable than the above for now