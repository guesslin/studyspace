[SECTION .text]
BITS 32
	mov edi, eax	; 89 F8
	mov ecx, eax	; 89 C1
	mov edi, ecx	; 89 CF

	push eax	; 50
	push ecx	; 51
	pop eax		; 58
	pop ecx		; 59

	xchg eax, ecx	; 91
