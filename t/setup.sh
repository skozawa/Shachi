#!/bin/sh

set -e
set -v

mysqladmin -uroot -f drop shachi_test || true
mysqladmin -uroot create shachi_test
mysql -uroot shachi_test < db/schema.sql
