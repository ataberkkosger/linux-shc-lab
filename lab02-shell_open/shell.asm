global _start

section .text
_start:
	xor eax, eax
	push eax
	push 0x68732f2f;/sh
	push 0x6e69622f;/bin

	mov ebx, esp
	xor ecx, ecx
	xor edx, edx
	mov al, 0x0b
	int 0x80

	;standart sonlandirma
	xor eax, eax
	mov al, 0x01
	xor ebx, ebx
	int 0x80
