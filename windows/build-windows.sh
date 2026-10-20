#!/usr/bin/env bash
# Cross-compiles NextToken.scr with MinGW-w64 (Ubuntu: apt install gcc-mingw-w64-x86-64; macOS: brew install mingw-w64).
set -euo pipefail
cd "$(dirname "$0")/src"
x86_64-w64-mingw32-windres nexttoken.rc -O coff -o nexttoken.res
x86_64-w64-mingw32-gcc -O2 -s -municode -mwindows -static -Wall -Wextra \
  nexttoken_scr.c nexttoken.res -o ../NextToken.scr -lshell32 -ladvapi32 -luser32
rm -f nexttoken.res
(cd .. && shasum -a 256 NextToken.scr 2>/dev/null || sha256sum NextToken.scr) > ../NextToken.scr.sha256
echo "Built windows/NextToken.scr"
