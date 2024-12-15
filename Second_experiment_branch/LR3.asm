ASSUME CS:CODE, SS:AStack, DS:DATA

AStack    SEGMENT  STACK
          DW 32 DUP(0)
AStack    ENDS

DATA      SEGMENT
a 	DW 	5
b	DW	2
i	DW	2
k	DW	0
i1	DW	0		;f3
i2	DW	0		;f7
res	DW	0		;f5
DATA      ENDS
 
CODE SEGMENT
	;f3 = 7-4i, a>b
	;	  8-6i, a<=b
	;f7 = -(4i-5), a>b
	;	  10-3i, a<=b
	;f5 = min(|i1|,6), k=0
	;	  |i1|+|i2|, k/=0

Main      PROC  FAR
          push  DS          
          sub   AX,AX
          push  AX          
          mov   AX,DATA
          mov   DS,AX
	
;Вычисление f3 и f7
	mov ax,a	;заносим значение а в ах
	mov cx,i	;заносим i в cx
	shl cx,1    ;умножаем cx на 2
	cmp ax,b	;сравнение значений a и b	
	ja  PART1	;если a>b, то на PART1

				;если a<=b
	add cx,i	;cx = 3i
	neg cx      ;cx = -3i
	add cx,10   ;cx = -3i + 10
	mov i2,cx	;сохраняем результат в i2

	sub cx,6    ;cx = -3i + 4
	shl cx,1       ;cx = -6i + 8
	mov i1,cx	;сохранение результата в i1
	jmp PART2	;пропускаем следующие шаги
	
PART1:			;если a>b	
	shl cx,1	;cx = 4i
	neg cx      ;cx = -4i
	add cx,7	;cx = 7 - 4i
	mov i1,cx	;сохраняем результат в i1
	sub cx, 2   ;cx= 5 - 4i
	mov i2,cx	;сохраняем результат в i2
	
;Вычисление f5
PART2:
	mov ax,i1	;ax = i1
ABS0:
	neg ax 		; ax = -ax
	JL ABS0 	; ax < 0
	mov bx,k 	; bx = k
	cmp bx,0	;сравниваем k и 0
	JE PART4	;если k равно 0 то перйти на PART4
	
PART3:			;решение при к /= 0
    mov dx,i2   ;dx = i2
ABS1:	
	neg dx      ;i2 = -i2
    JL ABS1     ;i2 < 0

    add ax,dx   ;i1 + i2
	mov res,ax	;res = ax
	jmp ENDPART
	
PART4:
	cmp ax,6    ;сравнить i1 и 6
	JGE PART5 	;если i1 >= 6 то перейти на PART5
	
	mov res,ax  ;сохраняем 
	jmp ENDPART
	
PART5:
	mov res,6	;если i1 >= 6
	
ENDPART:
	int 20h
		  
Main      ENDP
CODE      ENDS
          END Main