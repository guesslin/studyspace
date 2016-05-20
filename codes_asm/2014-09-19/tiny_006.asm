[SECTION .text]
BITS 32
	movsb		; A4
	; moves 1 byte from esi to edi, increments esi and edi
	; modify esi, edi
	rep movsb	; F3 A4
	; moves 1 byte from esi to edi, increments esi and edi, and repeats until ecs is 0
	; modify esi, edi
	; depend on ecx
	lodsb		; AC
	; loads the byte pointed to by esi into eax, and increments esi
	; modify esi
	stosb		; AA
	; save the byte in eax at the address pointed to by edi, and increments edi
	pushad		; 60
	; push all register to the stack
	popad		; 61
	; restores all register from the stack
	cdq		; 99
	; extend eax into a quad-word using edx.
	; Set edx to 0 if eax < 0x80000000
