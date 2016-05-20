[SECTION .text]
BITS 32
	mov eax, 0x44	; B8 44 00 00 00
	mov al, 0x44	; B0 44

	inc al		; FE C0
	inc eax		; 40
