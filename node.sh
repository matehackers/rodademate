#!/bin/bash

source utils.sh

VERSION=0.10.13
URL="http://nodejs.org/dist/v$VERSION/node-v$VERSION.tar.gz"

wait_msg "I'll download node $VERSION, compile and install it, is that OK?"


wget $URL
tar -xzf "node-v$VERSION.tar.gz"

cd "node-v$VERSION"

wait_msg "I'll install some dependencies and make node now"

sudo apt-get install -y build-essential

./configure
make -j 4

wait_msg "If you're ready for that I'll install node now"

sudo make install
