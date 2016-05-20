[SECTION .text]
BITS 32
	; function call usually save return into eax
	; function call often return null into eax
	; after function call can zero out eax
	; save 2 bytes from "xor eax, eax"
