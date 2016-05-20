[SECTION .text]
BITS 32
; Use register values early in the code to set parameters later in the code
	xor eax, eax	; 31 C0
	inc eax		; 40
	push eax	; 50
	call lable	; E8 01 00 00 00
	pop eax		; 58
lable:

