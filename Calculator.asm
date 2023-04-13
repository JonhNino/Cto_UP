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
        number1 DB  0,0,0,0    ;Thousands,Hundreds,Tens,Units   Numero 1 de 4 digitos
        number2 DB  0,0,0,0    ;Thousands,Hundreds,Tens,Units   Numero 1 de 4 digitos
        result  DB  0,0,0,0    ;Thousands,Hundreds,Tens,Units   Numero 1 de 4 digitos
        n1_bin  DW  ?          ;Convertir numero 1 a binario
        n2_bin  DW  ?          ;Convertir numero 2 a binario
        show    DB  3FH,3FH,3FH,3FH;Mostrar 0 al inicio del programa 
        ;           0   1   2   3   4   5   6   7   8   9   0
        cod7seg DB  3FH,06h,5BH,4FH,66H,6DH,7DH,07H,7FH,67H,00H   ;0 ->,OFF  datos de conversion
        get_key DB  ?          ;Obtener una tecla 
        key     DB  ?          ; saber que tecla es
        old_key DB  ?          ; saber cual fue la tecla anterior 
      ; Scand DCBA RETURN 1234
      ;teclacaptur   0   1    2      3   4   5     6     7   8   9    ON/C                  
        codkeyb DB  7Dh,0BEh,0BDh,0BBh,0DEh,0DDh,0DBh,0EEh,0EDh,0EBh,0E7h,0D7h,0B7h,77h,7Bh,7Eh  ;Keyboard codes (0->9,/,x,-,+,=,ON/C) Diferentes combianaciones

;               3210 3210 
;                                0111 1101
        ;  BCD     7-Seg  
        ; Digit     Code
        ;        0                3FH
        ;         1                06H
        ;         2                5BH
        ;         3                4FH
        ;         4                66H
        ;         5                6DH
        ;         6                7DH
        ;         7                07H
        ;         8                7FH
        ;         9                67H
         
        ;Para el teclado 4*4
        ;       DIGITO        SCAND DCBA  RETURN 4321  Hexa    
        ;       ON/C            0111= 7H     1110= EH     07EH
        ;         0             0111= 7H     1101= DH     07DH          
        ;         =             0111= 7H     1011= BH     07BH
        ;         +             0111= 7H     0111= 7H     077H          A=1010
        ;         1             1011= BH     1110= EH     0BEH          B=1011
        ;         2             1011= BH     1101= DH     0BDH          C=1100
        ;         3             1011= BH     1011= BH     0BBH          D=1101
        ;         -             1011= BH     0111= 7H     0B7H          E=1110
        ;         4             1101= DH     1110= EH     0DEH          F=1111
        ;         5             1101= DH     1101= DH     0DDH          
        ;         6             1101= DH     1011= BH     0DBH
        ;         *             1101= DH     0111= 7H     0D7H
        ;         7             1110= EH     1110= EH     0EEH
        ;         8             1110= EH     1101= DH     0EDH
        ;         9             1110= EH     1011= BH     0EBH
        ;         /             1110= EH     1110= 7H     0E7H
;------------------------------------------------------------------------------------------------------------------------------
; SEGMENTO DE variables de apoyo
;------------------------------------------------------------------------------------------------------------------------------

   res          dw  0
   
   unidades     db 0
   decenas      db 0
   centenas     db 0
   mil          db 0 
   
   
   
   CantUnoR     dw 0
   CantDosR     dw 0
   Resulta      dw 0,"$"
   ResultaR     dw 11 DUP(?),"$"
   Cantidad     dw 0
   Potencia     dw 0



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
             
;Iniciar proc near
;Iniciar endp               


CNV7SEG PROC NEAR             ;Para convertir a 7 segmentos
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
        ;cmp  al,14          
        ;je   equal          ;Equal
        cmp  al,15          
        call on_clr         ;Call to ON/Clear process
        ret
        
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
       
      
       call Division
       call equal
       ret
        
multi:  
       
       
        
       call Multiplica
       call equal
       ret
        
subtrac:
       
        
       call Resta
       call equal
       ret              
           
sum:
       call NumberDos
       mov ax,n1_bin
       mov bx,n2_bin
       mov CantUnoR,ax
       mov CantDosR,bx
       
       call Suma 
       
       call equal
        ;resultado, conversion bin a bcd  (Dividir/1000-100/10)
        ; Resusltado se almacena en variable show en bcd se envio a la funcion printd impreime en lcd
       ret
        
         
        
EVAL    ENDP
          
Opera proc near

Opera ENDP          


ON_CLR  PROC NEAR

    mov number1[0],0
    mov number1[1],0
    mov number1[2],0
    mov number1[3],0 
    mov number2[0],0
    mov number2[1],0
    mov number2[2],0
    mov number2[3],0
    mov result[0],0
    mov result[1],0
    mov result[2],0
    mov result[3],0
    
    ret
            
ON_CLR  ENDP

equal proc near
     
        call deco
        call CNV7SEG2 
        call PRINTDR        
        ret
                
equal endp 

PRINTDR  PROC NEAR
        ;Process to print on the 7-Seg display
                mov  bl,0FEh         ;Strobe init value   1111_1110
                mov  si,0    
cycle_prR:  
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
                jne  cycle_prR
                ret
PRINTDR  ENDP
          
                    
              
DELAY   PROC NEAR
        ;Delay process
        mov cx,3000
        loop $
        ret     
DELAY   ENDP        



Numberdos proc near   
        mov dx,0206h        ;PPI Initialization
        mov al,89h
        out dx,al
                
cycle2:                      ;Main cycle  
        call CNV7SEG2
        call PRINTD2
        jmp  cycle2
       
        ret 
Numberdos endp 

CNV7SEG2 PROC NEAR             ;Para convertir a 7 segmentos
        mov  si,0
        lea  bx,cod7seg     ;Start address of 7-Seg code table
cycle_cv2:
        mov  al,number2[si] ;Reading the number to be translated
        xlat                ;BCD to 7-Seg translation
        mov  show[si],al    ;Writing the translated number
        inc  si
        cmp  si,4
        jne  cycle_cv2
        ret
CNV7SEG2 ENDP            
        
        
PRINTD2  PROC NEAR
        ;Process to print on the 7-Seg display
                mov  bl,0FEh         ;Strobe init value   1111_1110
                mov  si,0    
cycle_pr2:  
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
                call KEYDEC2          
                                  
                ;LIGHTS OFF 
                mov  dx,0200h
                mov  al,0FFh
                out  dx,al
                
                ;PREPARE THE NEXT DATA PRINTING
                rol  bl,1
                inc  si        
                cmp  si,4
                jne  cycle_pr2
                ret
PRINTD2  ENDP




KEYDEC2  PROC NEAR
        push bx
        mov  al,get_key
        cmp  al,old_key
        jne  key_pressed2
        jmp  go_back22       ;Return. The same key is still pressed               
key_pressed2:        
        and  al,0Fh         ;Mask 0Fh
        cmp  al,0Fh
        jne  decode_key2     
        jmp  go_back22       ;Return. No key was pressed
decode_key2:                 ;Keyboard decoding routine    
        mov  ah,0           ;Counter to zero
        lea  bx,codkeyb     ;Keyboard code table
cycle_kbd2:  
        mov  al,ah          ;Load counter to AX(L)
        xlat 
        cmp  al,get_key
        je   key_decoded2
        inc  ah
        cmp  ah,16
        jl   cycle_kbd2
        jmp  go_back22       ;Return. It is not a valid key                     
key_decoded2:
        mov  old_key,al     ;Pressed Key Code
        mov  key,ah         ;Key (0->15 Hex)
        call EVAL2  
                            ;Return. Key successfully decoded
go_back22:
        pop  bx
        ret
KEYDEC2  ENDP 


EVAL2    PROC NEAR  
        
        mov  al,key
        cmp  al,10
        jb Number2bin
        cmp  al,14          
        call   equal          ;Equal
        cmp  al,15          
        call on_clr         ;Call to ON/Clear process
        ret
                  
Number2bin:                 
        
        mov ah,number2[1]    ;Rotate Units->Tens, Tens->Hundreds, Hundreds->Thousands
        mov number2[0],ah
        mov ah,number2[2]
        mov number2[1],ah
        mov ah,number2[3]    
        mov number2[2],ah
        
        mov al,key
        mov number2[3],al    ;Save key in Units
        
        ;Conversion to binary routine
        mov ah,0
        mov al,number2[0]
        mov cx,1000
        mul cx
        mov n2_bin,ax
        mov ah,0
        mov al,number2[1]
        mov cx,100
        mul cx
        add n2_bin,ax
        mov ah,0
        mov al,number2[2]
        mov cx,10
        mul cx
        add n2_bin,ax
        mov ah,0
        mov al,number2[3]
        add n2_bin,ax      
        
        
        ret
EVAL2    ENDP

deco proc near 
    
    mov ax,res      ; 2345/10  
    mov bx,10
    div bl
    
    mov show[3],ah
    mov ah,0
    div bl
    mov show[2],ah
    mov ah,0
    div bl
    mov show[1],ah
    mov ah,0
    div bl
    mov show[0],ah   
    
 
ret
    
 deco endp

;**************************
;                   R U T I N A S    D E    S O P O R T E
;**************************
; las siguientes rutinas fueron tomadas del ing. Wilson Javier Peres H
;------------------------------------------------------------------------------
; Rutina      : Multiplica
; Prop¢sito   : Multiplica dos n£meros enteros sin signo
; Par metros  : En el registro AX el multiplicando y en BX el multiplicador
; Regresa     : El resultado en el registro par DX:AX, que es desplegado en
;               la pantalla.
;------------------------------------------------------------------------------

Multiplica Proc Near
 ; Xor  Dx, Dx               ; Dx = 0 por si acaso
 ; Mov  Ax, CantUnoR         ; Primera cantidad (multiplicando)
 ; Mov  Bx, CantDosR         ; Segunda cantidad (multiplicador)
 ; Mul  Bx                   ; Multiplica
 ; Call ConvASCII            ; Convierte en ASCII
 ; Mov  Dx, Offset Resulta   ; Prepara para desplegar la cadena del
 ; Call Imprime              ; resultado
 ; Mov  Dx, Offset ResultaR  ; Despliega el resultado.
 ; Call Imprime
 ; Ret
Multiplica Endp

;------------------------------------------------------------------------------
; Rutina      : Divide
; Prop¢sito   : Divide dos n£meros enteros sin signo
; Par metros  : En el registro AX el dividendo y en BX el divisor
; Regresa     : El resultado en el registro par DX:AX, que es desplegado en
;               la pantalla.
;------------------------------------------------------------------------------

Divide Proc Near

  ;Mov  Ax, CantUnoR        ; Carga la cantidad 1 (dividendo)
  ;Mov  Bx, CantDosR        ; Carga la cantidad 2 (divisor)
  ;Cmp  Bx, 0               ; Revisa si el divisor es 0 para evitar un
  			   ; error de divisi¢n por cero.
  ;Jnz  DIVIDE01
  ;Mov  Cantidad, 3         ; Hubo error, as¡ que despliega el mensaje y
 			   ; salta
  ;Call HuboERROR
  ;Ret
DIVIDE01:
  ;Div  Bx                  ; Divide
  ;Xor  Dx, Dx              ; Dx = 0. No se usa el residuo para simplificar
                           ; las operaciones
  ;mov res,ah
  ;Call ConvASCII           ; Convierte en ASCII
  ;Mov  Dx, Offset Resulta  ; Despliega la cadena del resultado
  ;Call Imprime
  ;Mov  Dx, Offset ResultaR ; Despliega el resultado
  ;Call Imprime
  ;Ret
Divide Endp

;------------------------------------------------------------------------------
; Rutina      : Suma
; Prop¢sito   : Suma dos n£meros enteros sin signo
; Par metros  : En el registro AX el primer n£mero y en BX el segundo
; Regresa     : El resultado en el registro par DX:AX, que es desplegado en
;               la pantalla.
;------------------------------------------------------------------------------

Suma Proc Near
  Mov  Ax, CantUnoR         ; Primera cantidad
  Mov  Bx, CantDosR         ; Segunda cantidad
  Add  Ax, Bx               ; suma
  Mov  Res, Ax              ; Guardoresultadosuma
  Ret
Suma Endp

;------------------------------------------------------------------------------
; Rutina      : Resta
; Prop¢sito   : Resta dos n£meros enteros sin signo
; Par metros  : En el registro AX el primer n£mero y en BX el segundo
; Regresa     : El resultado en el registro par DX:AX, que es desplegado en
;               la pantalla.
;------------------------------------------------------------------------------

Resta Proc Near
  ;Xor  Dx, Dx              ; Dx = 0 por si acaso existe acarreo
  
  ;push cx
  ;mov cx ,CantDosR
  ;cmp  CantUnoR,cx
  ;jg  directa              ; CantDosR >  CantUnoR
  ;jmp inversa
inversa:
  ;Mov  Bx, CantUnoR        ; Primera cantidad
  ;Mov  Ax, CantDosR        ; Segunda cantidad
  ;jmp operacion_resta
directa:  
  ;Mov  Ax, CantUnoR        ; Primera cantidad
  ;Mov  Bx, CantDosR        ; Segunda cantidad
operacion_resta:
  ;pop  cx
  ;Sub  Ax, Bx              ; Resta cantidades
  ;Jnc  RESTACONV           ; ¨Hubo acarreo?
  ;Sbb  Dx, 0               ; S¡.
RESTACONV:
  ;Call ConvASCII           ; Convierte en ASCII
  ;Mov  Dx, Offset Resulta  ; Despliega cadena del resultado
  ;Call Imprime
  ;Mov  Dx, Offset ResultaR ; Despliega el resultado
  ;Call Imprime
  ;Ret
Resta Endp

;------------------------------------------------------------------------------
; Rutina      : Imprime
; Prop¢sito   : Despliega una cadena
; Par metros  : El registro DX contiene el desplazamiento de la cadena
; Regresa     : Nada
;------------------------------------------------------------------------------

Imprime Proc Near
  Mov  Ah, 9               ; Prepara para desplegar la cadena a trav‚s de la
  Int  21h                 ;  INT 21h.
  Ret
Imprime Endp

;------------------------------------------------------------------------------
; Rutina      : Obt‚nTecla
; Prop¢sito   : Espera a que el usuario digite una tecla
; Par metros  : Ninguno
; Regresa     : En el registro AL el c¢digo ASCII de la tecla
;------------------------------------------------------------------------------

ObtenTecla Proc Near
  Mov  Ah, 0               ; Lee una tecla del teclado a trav‚s de la INT 16h
  Int  16h
  Ret
ObtenTecla Endp

;------------------------------------------------------------------------------
; Rutina      : ConvNUM
; Prop¢sito   : Convertir una cadena a un entero largo
; Par metros  : La longitud de la cadena y la direcci¢n de la misma, y se
;               pasan a la pila.
; Regresa     : En el registro BX la cadena convertida en un entero
;------------------------------------------------------------------------------

ConvNUM Proc Near
  Mov  Dx, 0Ah                   ; Multiplicador es 10
  Cmp  Cantidad, 0               ; ¨Es la cantidad 1?
  Jnz  CONVNUM01                 ; NO, as¡ que es la cantidad 2
  Mov  Di, Offset CantUnoN + 1   ; Bytes le¡dos de la cantidad 1
  Mov  Cx, [Di]
  Mov  Si, Offset CantUnoN + 2   ; La cantidad 1
  Jmp  CONVNUM02

CONVNUM01:
  Mov  Di, Offset CantDosN + 1   ; Bytes le¡dos de la cantidad 2
  Mov  Cx, [Di]
  Mov  Si, Offset CantDosN + 2   ; La cantidad 2

CONVNUM02:
  Xor  Ch, Ch                    ; CH = 0
  Mov  Di, Offset Potencia       ; Direcci¢n de la tabla de potencias
  Dec  Si                        ; Posiciona Si en el primer byte de la
  Add  Si, Cx                    ; cadena capturada y le suma el
  Xor  Bx, Bx                    ; desplazamiento de bytes le¡dos
  Std                            ; para que podamos posicionarnos en el
                                 ; final de la misma (apunta al £ltimo
                                 ; d¡gito capturado). BX = 0 y lee la 
                                 ; cadena en forma inversa; es decir, de
                                 ; atr s hacia adelante.

CONVNUM03:
  Lodsb                 ; Levanta un byte del n£mero (esta instrucci¢n indica
                        ; que el registro AL ser  cargado con el contenido
                        ; de la direcci¢n apuntada por DS:SI.
  Cmp  AL,"0"           ; ¨Es menor a 0? (entonces NO es un d¡gito v lido)
  Jb   CONVNUM04        ; S¡, despliega el mensaje de error y termina
  Cmp  AL,"9"           ; ¨Es mayor a 9? (entonces NO es un d¡gito v lido)
  Ja   CONVNUM04        ; S¡, despliega el error y salta
  Sub  Al, 30h          ; Convierte el d¡gito de ASCII a binario
  Cbw                   ; Convierte a palabra
  Mov  Dx, [Di]         ; Obtiene la potencia de 10 que ser  usada para
  Mul  Dx               ; multiplicar, multiplica n£mero y lo suma
  Jc   CONVNUM05        ; a BX. Revisa si hubo acarreo, y si lo hubo, ‚sto
  Add  Bx, Ax           ; significa que la cantidad es > 65535.
  Jc   CONVNUM05        ; Si hay acarreo la cantidad es > 65535
  Add  Di, 2            ; Va a la siguiente potencia de 10
  Loop CONVNUM03        ; Itera hasta que CX sea = 0
  Jmp  CONVNUM06

CONVNUM04:
 ; Call HuboERROR        ; Algo ocurri¢, despliega mensaje y salta
  Jmp  CONVNUM06

CONVNUM05:
  Mov  Cantidad, 2      ; Hubo acarreo en la conversi¢n, por lo tanto la
  ;Call HuboERROR        ; cantidad capturada es mayor a 65535.

CONVNUM06:
  Cld                   ; Regresa la bandera de direcci¢n a su estado normal
  Ret                   ; y REGRESA.

ConvNum Endp

;------------------------------------------------------------------------------
; Rutina      : ConvASCII
; Prop¢sito   : Convertir un valor binario en ASCII
; Par metros  : El registro par DX:AX
; Regresa     : Nada, pero almacena el resultado en el buffer ResultaR
;------------------------------------------------------------------------------

ConvASCII Proc Near

;------------------------------------------------------------------------------
; Lo primero que se hace es inicializar la variable que contendr  el
; resultado de la conversi¢n.
;------------------------------------------------------------------------------

  Push Dx
  Push Ax                  ; Guarda el resultado
  Mov  Si, Offset ResultaR ; Inicializa la variable ResultaR llen ndola
  Mov  Cx, 10              ; con asteriscos
  Mov  Al, '*'

ConvASCII01:
  Mov  [Si], Al
  Inc  Si
  Loop ConvASCII01
  Pop  Ax
  Pop  Dx
  Mov  Bx, Ax                  ; Palabra baja de la cantidad
  Mov  Ax, Dx                  ; Palabra alta de la cantidad
  Mov  Si,Offset ResultaR      ; Cadena donde se guardar  el resultado
  Add  Si, 11
  Mov  CX, 10                  ; Divisor = 10

OBTENDIGITO:
  Dec  Si
  Xor  Dx, Dx                  ; DX contendr  el residuo
  Div  Cx                      ; Divide la palabra alta (AX)
  Mov  Di, Ax                  ; Guarda cociente (AX)
  Mov  Ax, Bx                  ; AX = palabra baja (BX)
  Div  Cx                      ; DX ten¡a un residuo de la divisi¢n anterior
  Mov  Bx, Ax                  ; Guarda el cociente
  Mov  Ax, Di                  ; Regresa la palabra alta
  Add  Dl,30h                  ; Convierte residuo en ASCII
  Mov  [Si], Dl                ; Lo almacena
  Or   Ax, Ax                  ; ¨Palabra alta es 0?
  Jnz  OBTENDIGITO             ; No, sigue procesando
  Or   Bx, Bx                  ; ¨Palabra baja es 0?
  Jnz  OBTENDIGITO             ; No, sigue procesando
  Ret

ConvASCII Endp

;------------------------------------------------------------------------------
; Rutina      : HuboERROR
; Prop¢sito   : Desplegar el mensaje de error adecuado.
; Par metros  : Nada
; Regresa     : Nada
;------------------------------------------------------------------------------




              
              
CODE    ENDS 


        END START  ; set entry point and stop the assembler.