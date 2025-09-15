gcc star.c -o star
./star Starcpu32.asm -regcall
nasm -f win32 -o Starcpu32W.o Starcpu32.asm
nasm -f elf32 -o Starcpu32L.o Starcpu32.asm
./star -x64 -win64 Starcpu64W.asm
yasm -f win64 -o Starcpu64W.o Starcpu64W.asm
./star -x64 -amd64 Starcpu64L.asm
yasm -f elf64 -o Starcpu64L.o Starcpu64L.asm
gcc -o cpudebug.o cpudebug.c -c
