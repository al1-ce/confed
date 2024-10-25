#!/usr/bin/env -S just --justfile
# just reference  : https://just.systems/man/en/

@default:
    just --list

build:
    dub build

release:
    dub build -b release
