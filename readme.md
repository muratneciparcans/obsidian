# Obsidian

The Obsidian programming language: a compact, dynamically typed language and
execution environment written in D. Source text is turned into tokens by a
hand-written lexer, a parser applies operator precedence and emits a
project-specific intermediate language, and a stack-based virtual machine
executes the resulting instruction stream.

This repository is the implementation accompanying the bachelor thesis
*Design and Implementation of the Obsidian Programming Language*
(University of Information Science and Technology "St. Paul the Apostle",
Ohrid, Faculty of Computer Science and Engineering).

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

# Repository map

| File | Role | Thesis section |
| --- | --- | --- |
| `source/lexer.d` | Token types and scanner | 4.2 |
| `source/parser.d` | Statements, precedence table, code generation | 4.3 |
| `source/interlang.d` | Intermediate language and opcode encoding | 4.4, Appendix B |
| `source/vm.d` | Stack virtual machine, instruction dispatch | 4.5 |
| `source/obsobject.d` | Runtime object model and method tables | 4.6, 4.7 |
| `source/builtin.d` | Native built-ins: print, uniform, dice | 4.6 |
| `source/app.d` | Standalone and FastCGI entry points | 4.10 |
| `source/fcgi/` | Vendored FastCGI library for the D language | 3.6 |

# Sample programs

The programs under `scripts/` cover arithmetic precedence, loops, strings,
nested arrays, method chaining and the built-in functions. The regression
cases printed in Appendix C of the thesis are reproduced by:

    ./language scripts/complex_math.obs
    ./language scripts/arrays.obs
    ./language scripts/strings.obs
