#!/bin/sh
exec 2>&1

set -e

plenv local 5.20.1
plenv rehash

PLACK_ENV=production carton exec -- start_server --port 5000 --pid-file=${PIDFILE:=./pid} -- plackup -s Starlet -a script/app.psgi
