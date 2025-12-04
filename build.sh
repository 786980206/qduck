#!/bin/bash
wget https://install.duckdb.org/v1.4.2/libduckdb-linux-amd64.zip
unzip libduckdb-linux-amd64.zip -d libduckdb
gcc -shared -fPIC -o qduck/qduck.l64.so src/c/qduck.c -I./libduckdb -L./libduckdb -lduckdb -mavx2 -O2 -Wl,-rpath,'$ORIGIN'
cp libduckdb/libduckdb.so qduck/