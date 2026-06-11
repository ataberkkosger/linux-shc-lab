global _start

section .text
_start:
	xor eax, eax
	mov al, 0x03
	xor ebx, ebx
	mov ecx, esp
	xor edx, edx
	mov dl, 64
	int 0x80

	mov edx, eax

	xor eax, eax
	mov al, 0x04
	mov bl, 1
	mov ecx, esp
	int 0x80

	xor eax, eax
	mov al, 0x01
	xor ebx, ebx
	int 0x80


