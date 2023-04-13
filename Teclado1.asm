
;--------------------------------------------------------
;Universidad Pedagogica y Tecnologica de Colombia UPTC
;Facultad Seccional Sogamoso
;Escuela de Ingenieria Electronica
;--------------------------------------------------------
;Microprocessors Course
;Description: Calculator. Example of keyboard decoding
;             and operations implementation 
;Author:      Wilson Javier Perez Holguin
;Date:        30-07-2020
;--------------------------------------------------------

DATA   SEGMENT PARA PUBLIC 'DATA'
	number1	DB  0,0,0,0    ;Thousands,Hundreds,Tens,Units
	number2	DB  0,0,0,0    ;Thousands,Hundreds,Tens,Units
	n1_bin  DW  ?
	n2_bin  DW  ?
	show    DB  3FH,3FH,3FH,3FH
	cod7seg DB  3FH,06h,5BH,4FH,66H,6DH,7DH,07H,7FH,67H,00H   ;0 ->,OFF
	get_key DB  ?
	key     DB  ?
	old_key DB  ?
	codkeyb DB  7Dh,0BEh,0BDh,0BBh,0DEh,0DDh,0DBh,0EEh,0EDh,0EBh,0E7h,0D7h,0B7h,77h,7Bh,7Eh  ;Keyboard codes (0->9,/,x,-,+,=,ON/C)
;               3210 3210 
;				0111 1101
	;  BCD     7-Seg  
	; Digit     Code
	;	0		3FH
	; 	1		06H
	; 	2		5BH
	; 	3		4FH
	; 	4		66H
	; 	5		6DH
	; 	6		7DH
	; 	7		07H
	; 	8		7FH
	; 	9		67H
DATA    ENDS  


STACK   SEGMENT PARA STACK 'STACK'
        DB      64 DUP ?
STACK   ENDS
   
   
CODE    SEGMENT PUBLIC 'CODE'
        ASSUME CS:CODE, DS:DATA, SS:STACK, ES:DATA
		
MAIN    PROC NEAR
START:
		mov ax,@DATA
		mov ds,ax
		                    
		mov dx,0206h        ;PPI Initialization
		mov al,89h
		out dx,al
		
cycle:                      ;Main cycle  
        call CNV7SEG
        call PRINTD
        jmp  cycle
       
        ret                 ;Return to another subroutine or to OS
MAIN    ENDP 
             
               

CNV7SEG PROC NEAR      
        mov  si,0
        lea  bx,cod7seg     ;Start address of 7-Seg code table
cycle_cv:
        mov  al,number1[si] ;Reading the number to be translated
        xlat                ;BCD to 7-Seg translation
        mov  show[si],al    ;Writing the translated number
        inc  si
        cmp  si,4
        jne  cycle_cv
        ret
CNV7SEG ENDP            
        
        
PRINTD  PROC NEAR
        ;Process to print on the 7-Seg display
        mov  bl,0FEh         ;Strobe init value   1111_1110
		mov  si,0    
cycle_pr:  
		;LIGHTS ON
		mov  dx,0202h
		mov  al,show[si]     ;Reading the number to show
		out  dx,al
		
		mov  dx,0200h
		mov  al,bl           ;Strobe
		out  dx,al
		                  
		;GETTING THE KEYBOARD CODE
		shl  al,4            ;Scan_0000
		mov  get_key,al
		mov  dx,0204h        ;get_key <= PTOC(L)
		in   al,dx                        
		and  al,0Fh
		or   get_key,al      ;Scan_PTOC(L)
		call KEYDEC          
		                  
		;LIGHTS OFF 
		mov  dx,0200h
		mov  al,0FFh
		out  dx,al
		
		;PREPARE THE NEXT DATA PRINTING
		rol  bl,1
	    inc  si        
		cmp  si,4
		jne  cycle_pr
		ret
PRINTD  ENDP


KEYDEC  PROC NEAR
        push bx
        mov  al,get_key
        cmp  al,old_key
        jne  key_pressed
        jmp  go_back2       ;Return. The same key is still pressed               
key_pressed:        
        and  al,0Fh         ;Mask 0Fh
        cmp  al,0Fh
        jne  decode_key     
        jmp  go_back2       ;Return. No key was pressed
decode_key:                 ;Keyboard decoding routine    
        mov  ah,0           ;Counter to zero
        lea  bx,codkeyb     ;Keyboard code table
cycle_kbd:  
        mov  al,ah          ;Load counter to AX(L)
        xlat 
        cmp  al,get_key
        je   key_decoded
        inc  ah
        cmp  ah,16
        jl   cycle_kbd
        jmp  go_back2       ;Return. It is not a valid key                     
key_decoded:
        mov  old_key,al     ;Pressed Key Code
        mov  key,ah         ;Key (0->15 Hex)
        call EVAL  
                            ;Return. Key successfully decoded
go_back2:
        pop  bx
        ret
KEYDEC  ENDP


EVAL    PROC NEAR
        mov  al,key
        cmp  al,10          
        jb   rot_save_cbin  ;Number 0->9. Rotate, save and conversion to binary
        je   division       ;Division 
        cmp  al,11          
        je   multi          ;Multiplication
        cmp  al,12          
        je   subtrac        ;Subtraction
        cmp  al,13          
        je   sum            ;Sum
        cmp  al,14          
        je   equal          ;Equal
        cmp  al,15          
        call on_clr         ;Call to ON/Clear process
        
rot_save_cbin:
        mov ah,number1[1]    ;Rotate Units->Tens, Tens->Hundreds, Hundreds->Thousands
        mov number1[0],ah
        mov ah,number1[2]
        mov number1[1],ah
        mov ah,number1[3]    
        mov number1[2],ah
        
        mov al,key
        mov number1[3],al    ;Save key in Units
        
        ;Conversion to binary routine
        mov ah,0
        mov al,number1[0]
        mov cx,1000
        mul cx
        mov n1_bin,ax
        mov ah,0
        mov al,number1[1]
        mov cx,100
        mul cx
        add n1_bin,ax
        mov ah,0
        mov al,number1[2]
        mov cx,10
        mul cx
        add n1_bin,ax
        mov ah,0
        mov al,number1[3]
        add n1_bin,ax        
        
        ret  

division:
		; Capture the second number
        ; Wait for the equal key
		ret
        
multi:
		; Capture the second number
		; Wait for the equal key
        ret
        
subtrac:
		; Capture the second number
		; Wait for the equal key
        ret              
           
sum:
		; Capture the second number
		; Wait for the equal key
        ret
        
equal:
		; Capture the second number
		; Wait for the equal key
        ret
                     
        
EVAL    ENDP
          
          

ON_CLR  PROC NEAR
        ; Zeroing variables number1 and number2    
            
ON_CLR  ENDP            
          
                    
              
DELAY   PROC NEAR
        ;Delay process
        mov cx,3000
        loop $
        ret     
DELAY   ENDP        

              
              
CODE    ENDS 

        END START