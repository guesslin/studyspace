[SECTION .text]
BITS 32
	; 組合多個較小的指令來達到目的
	mov DWORD [esp], 0xFF	; C7 04 E4 FF 00 00 00

	xor eax, eax		; 31 C0	
	dec al			; FE C8	
	push eax		; 50
