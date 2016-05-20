[SECTION .text]
BITS 32
			; eax
			; 0x01020304
	rol eax, 8	; 0x02030401
	ror eax, 16	; 0x04010203
	ror ax, 8	; 0x04010302
	shl eax, 8	; 0x01030200
	shr ax, 8	; 0x01030002
	shr eax, 1	; 0x00818001
