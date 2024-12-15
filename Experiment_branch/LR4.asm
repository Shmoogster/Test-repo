EOFLine EQU '$'

AStack SEGMENT STACK
DW 1024 DUP(?)
AStack ENDS

DATA SEGMENT
;message DB 'abba', 0dh, 0ah, '$'
header DB 100, 0h ; ��������� ��� �������� ��ப�
buffer DB 100 DUP('?'), 0dh, 0ah, '$' ; ���� ��� �室��� ��ப�
hello DB '������ ��ப�:', 0dh, 0ah, '$' ; �ਢ���⢥���� ��ப�
waiting DB '�������� ����� ��ப�', 0dh, 0ah, '$' ; ��ப� ��������
positive_result DB 'Yes', 0dh, 0ah, '$' ; ᫮�� ���� ������஬��
negative_result DB 'No', 0dh, 0ah, '$' ; ᫮�� �� ���� ������஬��
result DB 100 DUP('?'), 0dh, 0ah, '$'

keep_ip dw 0 ; ip ��室���� ���뢠��� 9h
keep_cs dw 0 ; cs ��室���� ���뢠��� 9h

input_header db 0ah, 0 ; ��������� �室��� ��ப�, ᮤ�ঠ騩 �।����� � 䠪����� ����� ��ப�
input_buffer db 100 DUP(EOFLine), EOFLine ; ���� ��� �室��� ��ப�
ticks     DW 0      	; ���稪 ⨪�� ��� ����� �६���
n DW 7 					; ������⢮ ࠧ, ���஥ ����室��� ��ࠡ���� ���뢠���
DATA ENDS 

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack

Print PROC NEAR  
    push ax ; ��࠭���� ॣ����

    mov ah, 9 ; ������� �뢮�� ��ப� �� �࠭
    int 21h ; �맮� ���뢠��� 21h �ᯥ�⠥� ��ப�,��稭�� � ���� � dx

    pop ax ; ����⠭������� ॣ����

    ret ; ������ �� ��楤���
Print ENDP

ReadString PROC NEAR
    ; ��࠭���� ॣ���஢
    push ax
    push bp
    push dx
    push bx

    mov ah, 0ah ; �㭪�� ����� ��ப�
    push dx ; ᬥ饭�� ��������� ��ப�
    int 21h ; �맮� �㭪樨 ����� ��ப�
    pop bp ; �������� � bp ᬥ饭�� header
    xor bx, bx ; ���㫥��� bx
    mov bl, ds:[bp+1] ; bl �࠭�� ������⢮ ������� ᨬ����� (ࠧ��� ��ப�)
    add bx, bp ; bx 㪠�뢠�� �� ������ ������ ᨬ���
    add bx, 2 ; bx 㪠�뢠�� �� ����, ᫥���騩 �� 䨭���� 0dh
    mov word ptr [bx+1], 240ah ; �������� � ����� 0ah � '$'
    mov ds:[bp+1], bl ; �����뢠�� ����� ��ப� � ���������

    ; ����⠭������� ॣ�����
    pop bx
    pop dx
    pop bp
    pop ax

    ret ; ������ �� ��楤���
ReadString ENDP

ProcessString PROC FAR
    ; ��࠭���� ॣ���஢
    push ax
    push ds
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, seg buffer ; ax = ���� ᥣ���� result
    mov ds, ax ; ds = seg result
    mov es, ax ; es = seg result

    mov cl, [header + 1] ; ��࠭���� � cl ����� ��ப�
    mov ch, 0

    lea si, buffer ; 㪠��⥫� �� �室��� ��ப� 
    lea di, buffer ; 㪠��⥫� �� �室��� ��ப�

    sub cx, 2 ; ���������� cx �� �㦭��� ࠧ���
    cmp cx, 0 ; �ࠢ����� ����稪� � ���
    je EndProc ; ���室 � �����, �᫨ ����稪 0

    inc si  ;������� 㪠��⥫� �� 1
    add di, cx ; di 㪠�뢠�� �� ����� ��ப�
    dec di  ;������� 㪠��⥫� �� 1 ����� � �����

Loop1:
    cmp si, di ; �஢�ઠ, �� �ࠢ������ �� ᨬ����
    jge Positive ; ���室, �᫨ ᫮�� - ������஬

    cmpsb ; �ࠢ������ ������ ����� (�����) �� 㪠��⥫� si � di
    jne Negative ; ���室, �᫨ ᨬ���� �� ࠢ��
    sub di, 2 ;������� 㪠��⥫� �� 2 �����
    

    jmp Loop1 ; ���室 � ��砫� 横��

Positive:
    mov dx, offset positive_result ; ������ � dx ᬥ饭�� �� १����
    call Print ; �뢮� १����
    jmp EndProc

Negative:
    mov dx, offset negative_result ; ������ � dx ᬥ饭�� �� १����
    call Print ; �뢮� १����

EndProc:
    ; ����⠭������� ॣ���஢
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ds
    pop ax

    ret ; �����饭��
ProcessString ENDP

New1C PROC FAR
    ; ���६��� ���稪� ⨪�� � ��।�� �ࠢ����� ��஬� ��ࠡ��稪�
    inc ticks
	push dx
	mov dx, n
    CMP ticks, dx ; ��������, ���� ticks �� ���⨣��� n
	pop dx
    jl  ext
	
	call ProcessString


    push ds
    mov  dx, keep_ip ; dx = ip ��室���� 1Ch
    mov ax, keep_cs ; ax = cs ��室���� 1Ch
    mov ds, ax ; ds = ax
    mov ah, 25h ; ah = 25h (����� �㭪樨 DOS ��� ��������� ����� ���뢠���)
    mov al, 1ch ; al = 1Ch (����� ����� ���뢠���)
    int 21h ; ����� ����⠭�������
    pop ds

ext:
    iret
New1C  ENDP

Main PROC
	;���樠������
	push ds         ;���࠭塞 � �⥪ ���� ��砫� PSP
	sub ax, ax      ;ax = 0
	push ax         ;���࠭塞 � �⥪ 0
	mov ax, DATA    ;�����뢠�� � ax ���� ᥣ���� ������
	mov ds, ax      ;���樠�����㥬 ॣ���� DS ���ᮬ ᥣ���� ������
	mov es, ax      ;���樠�����㥬 ॣ���� ES ���ᮬ ᥣ���� ������

	;�뢮� ᮮ�饭��
	mov dx, offset hello ;dx ᮤ�ন� ᬥ饭�� �� ��ப� hello
	call Print      		;���⠥� ��ப� greeting
	mov dx, offset waiting 	;dx ᮤ�ন� ᬥ饭�� �� ��ப� waiting
	call Print      		;���⠥� ��ப� waiting

							;���� ���짮��⥫�᪮� ��ப�
	mov dx, offset header	;�����뢠�� ᬥ饭�� �� ��������� ���뢠���� ��ப� � dx
	call ReadString      	;���뢠�� ��ப�	

    mov dx, offset buffer 	;dx ᮤ�ন� ᬥ饭�� �� ��ப� waiting
	call Print   

	; ���࠭���� ॣ���஢ �� �⥪� ��। �ᯮ�짮������
	push si					; ���࠭塞 ॣ���� SI �� �⥪�
	push ax					; ���࠭塞 ॣ���� AX �� �⥪�
	push bx					; ���࠭塞 ॣ���� BX �� �⥪�

	; ����㧪� ���� ��砫� ��ப� � SI
	lea si, buffer			; ����㦠�� ��䥪⨢�� ���� ��६����� origin � SI

	; ����㧪� ������ ���� (ᨬ����) �� ����� �� ����� SI � AL
	lodsb					; ����㦠�� ���� �� ����� �� ����� SI � AL � 㢥��稢��� SI

	; �஢�ઠ, ���� �� ᨬ��� ��ன
	cmp al, '0'				; �ࠢ������ AL � '0'
	jl Skip					; �᫨ AL ����� '0', ���室�� � ��⪥ Skip (�� ���)
	cmp al, '9'				; �ࠢ������ AL � '9'
	jg Skip					; �᫨ AL ����� '9', ���室�� � ��⪥ Skip (�� ���)

	; �८�ࠧ������ ASCII-ᨬ���� � �᫮
	mov bl, 10				; ����㦠�� 10 � BL (�����⥫� ��� �����筮� ��⥬�)
	sub al, '0'				; ���⠥� ASCII-��� '0' �� AL, ����砥� �᫮��� ���祭�� ����
	mul bl					; �������� AL �� BL (㬭����� �᫮ �� 10, �᫨ �㦭� ��ࠡ��뢠�� ���������� �᫠, ��� 蠣 �㦭� �㤥� �������� � 横�)
	mov n, ax				; ���࠭塞 १���� � ��६����� n

	; ��⪠ Skip: � ���室��, �᫨ ᨬ��� �� ���� ��ன
Skip:

	; ����⠭������� ॣ���஢ �� �⥪�
	pop bx					; ����⠭�������� BX �� �⥪�
	pop ax					; ����⠭�������� AX �� �⥪�
	pop si					; ����⠭�������� SI �� �⥪�

	mov ah, 35h
    mov al, 1Ch
    int 21h
    mov keep_cs, ES     ; ���࠭���� ᥣ���� CS ��ண� ��ࠡ��稪� ⠩���
    mov keep_ip, BX     ; ���࠭���� ���� IP ��ண� ��ࠡ��稪� ⠩���

	; ��⠭���� ������ ��ࠡ��稪� INT 1C
	PUSH ds
    mov  dx, offset New1C ; �����⥫� �� ���� ��ࠡ��稪 ⠩���
    mov  ax, seg New1C    ; ������� ������ ��ࠡ��稪� ⠩���
    mov  ds, ax
    mov  ah, 25h
    mov  al, 1Ch
    int  21h                              
    pop  ds
	
	mov dx, offset input_header	;�����뢠�� ᬥ饭�� �� ��������� ���뢠���� ��ப� � dx
	call ReadString      		;���뢠�� ��ப�

	; �����襭�� �ணࠬ��
	mov ah, 4Ch    ;�㭪�� ��� �����襭�� �ணࠬ��
	mov al, 0      ;���祭�� ����砥� �ᯥ譮� �����襭�� �ணࠬ��
	int 21h         ;�����襭�� �믮������ �ணࠬ��
Main ENDP

CODE ENDS
END Main