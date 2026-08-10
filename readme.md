# Requirements

A D compiler - DMD or LDC (https://dlang.org/)
dub (https://code.dlang.org/)

# How to Run

Standalone (reads a script file, or standard input when no file is given):

    dub build
    ./language scripts/coin_toss.obs

Web, over FastCGI:

    dub build --config=fcgi
    spawn-fcgi -p9001 ./language-fcgi

# Sample programs

The programs under `scripts/` cover arithmetic precedence, loops, strings,
nested arrays, method chaining and the built-in functions.
