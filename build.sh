#!/bin/sh

echo "Compiling naws..."
nasm -f elf64 -o http.o -O3 http.asm
nasm -f elf64 -o naws.o -O3 naws.asm

echo "Linking naws..."
mold -o naws http.o naws.o

echo "Ensuring it is executable..."
chmod +x naws

echo "Final binary size: `stat -c %s naws` bytes."

