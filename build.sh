#!/bin/sh

echo "Compiling naws..."
nasm -f elf64 -o naws.o -O3 naws.asm

echo "Linking naws..."
ld -o naws naws.o

echo "Ensuring it is executable..."
chmod +x naws

echo "Final binary size: `stat -c %s naws` bytes."

