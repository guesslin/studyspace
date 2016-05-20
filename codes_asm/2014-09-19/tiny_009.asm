[SECTION .text]
BITS 64
	mov rax, 0x0200000065	; B8 65 00 00 02

	mov ax, 0x6502		; 66 B8 02 65
	ror eax, 8		; C1 C8 08
	; null-free code
