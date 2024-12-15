EOFLine EQU '$'

AStack SEGMENT STACK
DW 1024 DUP(?)
AStack ENDS

DATA SEGMENT
;message DB 'abba', 0dh, 0ah, '$'
header DB 100, 0h ; заголовок для вводимой строки
buffer DB 100 DUP('?'), 0dh, 0ah, '$' ; буфер для входной строки
hello DB 'Введите строку:', 0dh, 0ah, '$' ; приветственная строка
waiting DB 'Ожидание ввода строки', 0dh, 0ah, '$' ; строка ожидания
positive_result DB 'Yes', 0dh, 0ah, '$' ; слово является палиндромом
negative_result DB 'No', 0dh, 0ah, '$' ; слово не является палиндромом
result DB 100 DUP('?'), 0dh, 0ah, '$'

keep_ip dw 0 ; ip исходного прерывания 9h
keep_cs dw 0 ; cs исходного прерывания 9h

input_header db 0ah, 0 ; заголовок входной строки, содержащий предельную и фактическую длины строки
input_buffer db 100 DUP(EOFLine), EOFLine ; буфер для входной строки
ticks     DW 0      	; Счетчик тиков для отсчета времени
n DW 7 					; Количество раз, которое необходимо отработать прерыванию
DATA ENDS 

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:AStack

Print PROC NEAR  
    push ax ; сохранение регистра

    mov ah, 9 ; команда вывода строки на экран
    int 21h ; вызов прерывания 21h распечатает строку,начиная с адреса в dx

    pop ax ; восстановление регистра

    ret ; возврат из процедуры
Print ENDP

ReadString PROC NEAR
    ; сохранение регистров
    push ax
    push bp
    push dx
    push bx

    mov ah, 0ah ; функция ввода строки
    push dx ; смещение заголовка строки
    int 21h ; вызов функции ввода строки
    pop bp ; поместить в bp смещение header
    xor bx, bx ; обнуление bx
    mov bl, ds:[bp+1] ; bl хранит количество введённых символов (размер строки)
    add bx, bp ; bx указывает на конечный введённый символ
    add bx, 2 ; bx указывает на байт, следующий за финальным 0dh
    mov word ptr [bx+1], 240ah ; добавить в конец 0ah и '$'
    mov ds:[bp+1], bl ; записываем длину строки в заголовок

    ; восстановление регистры
    pop bx
    pop dx
    pop bp
    pop ax

    ret ; возврат из процедуры
ReadString ENDP

ProcessString PROC FAR
    ; сохранение регистров
    push ax
    push ds
    push bx
    push cx
    push dx
    push si
    push di
    push es

    mov ax, seg buffer ; ax = адрес сегмента result
    mov ds, ax ; ds = seg result
    mov es, ax ; es = seg result

    mov cl, [header + 1] ; сохранение в cl длины строки
    mov ch, 0

    lea si, buffer ; указатель на входную строку 
    lea di, buffer ; указатель на входную строку

    sub cx, 2 ; обновление cx до нужного размера
    cmp cx, 0 ; сравнение счётчика с нулём
    je EndProc ; переход к концу, если счётчик 0

    inc si  ;двигаем указатель на 1
    add di, cx ; di указывает на конец строки
    dec di  ;двигаем указатель на 1 ближе к концу

Loop1:
    cmp si, di ; проверка, что сравнились все символы
    jge Positive ; переход, если слово - палиндром

    cmpsb ; сравнивает области памяти (байты) по указателям si и di
    jne Negative ; переход, если символы не равны
    sub di, 2 ;двигаем указатель на 2 назад
    

    jmp Loop1 ; переход к началу цикла

Positive:
    mov dx, offset positive_result ; запись в dx смещения до результата
    call Print ; вывод результата
    jmp EndProc

Negative:
    mov dx, offset negative_result ; запись в dx смещения до результата
    call Print ; вывод результата

EndProc:
    ; восстановление регистров
    pop es
    pop di
    pop si
    pop dx
    pop cx
    pop bx
    pop ds
    pop ax

    ret ; возвращение
ProcessString ENDP

New1C PROC FAR
    ; Инкремент счетчика тиков и передача управления старому обработчику
    inc ticks
	push dx
	mov dx, n
    CMP ticks, dx ; Ожидание, пока ticks не достигнет n
	pop dx
    jl  ext
	
	call ProcessString


    push ds
    mov  dx, keep_ip ; dx = ip исходного 1Ch
    mov ax, keep_cs ; ax = cs исходного 1Ch
    mov ds, ax ; ds = ax
    mov ah, 25h ; ah = 25h (номер функции DOS для изменения вектора прерывания)
    mov al, 1ch ; al = 1Ch (номер вектора прерывания)
    int 21h ; запуск восстановления
    pop ds

ext:
    iret
New1C  ENDP

Main PROC
	;инициализация
	push ds         ;Сохраняем в стек адрес начала PSP
	sub ax, ax      ;ax = 0
	push ax         ;Сохраняем с стек 0
	mov ax, DATA    ;Записывает в ax адрес сегмента данных
	mov ds, ax      ;Инициализируем регистр DS адресом сегмента данных
	mov es, ax      ;Инициализируем регистр ES адресом сегмента данных

	;вывод сообщений
	mov dx, offset hello ;dx содержит смещение до строки hello
	call Print      		;Печатаем строку greeting
	mov dx, offset waiting 	;dx содержит смещение до строки waiting
	call Print      		;Печатаем строку waiting

							;ввод пользовательской строки
	mov dx, offset header	;записываем смещение до заголовка считываемой строки в dx
	call ReadString      	;считываем строку	

    mov dx, offset buffer 	;dx содержит смещение до строки waiting
	call Print   

	; Сохранение регистров на стеке перед использованием
	push si					; Сохраняем регистр SI на стеке
	push ax					; Сохраняем регистр AX на стеке
	push bx					; Сохраняем регистр BX на стеке

	; Загрузка адреса начала строки в SI
	lea si, buffer			; Загружаем эффективный адрес переменной origin в SI

	; Загрузка одного байта (символа) из памяти по адресу SI в AL
	lodsb					; Загружаем байт из памяти по адресу SI в AL и увеличиваем SI

	; Проверка, является ли символ цифрой
	cmp al, '0'				; Сравниваем AL с '0'
	jl Skip					; Если AL меньше '0', переходим к метке Skip (не цифра)
	cmp al, '9'				; Сравниваем AL с '9'
	jg Skip					; Если AL больше '9', переходим к метке Skip (не цифра)

	; Преобразование ASCII-символа в число
	mov bl, 10				; Загружаем 10 в BL (множитель для десятичной системы)
	sub al, '0'				; Вычитаем ASCII-код '0' из AL, получаем числовое значение цифры
	mul bl					; Умножаем AL на BL (умножаем число на 10, если нужно обрабатывать многозначные числа, этот шаг нужно будет поместить в цикл)
	mov n, ax				; Сохраняем результат в переменную n

	; Метка Skip: сюда переходим, если символ не является цифрой
Skip:

	; Восстановление регистров из стека
	pop bx					; Восстанавливаем BX из стека
	pop ax					; Восстанавливаем AX из стека
	pop si					; Восстанавливаем SI из стека

	mov ah, 35h
    mov al, 1Ch
    int 21h
    mov keep_cs, ES     ; Сохранение сегмента CS старого обработчика таймера
    mov keep_ip, BX     ; Сохранение адреса IP старого обработчика таймера

	; Установка нового обработчика INT 1C
	PUSH ds
    mov  dx, offset New1C ; Указатель на новый обработчик таймера
    mov  ax, seg New1C    ; Сегмент нового обработчика таймера
    mov  ds, ax
    mov  ah, 25h
    mov  al, 1Ch
    int  21h                              
    pop  ds
	
	mov dx, offset input_header	;записываем смещение до заголовка считываемой строки в dx
	call ReadString      		;считываем строку

	; завершение программы
	mov ah, 4Ch    ;функция для завершения программы
	mov al, 0      ;значение означает успешное завершение программы
	int 21h         ;завершение выполнения программы
Main ENDP

CODE ENDS
END Main