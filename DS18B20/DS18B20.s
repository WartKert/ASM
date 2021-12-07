  #include      "Config_system.h"
;*******************************************************************************

  ;PUBLIC  DS18B20_ON                      ; ФУНКЦИЯ ВКЛЮЧЕНИЯ DS18B20
  EXPORT  DS1820_init                     ; ФУНКЦИЯ ИНИЦИАЛИЗАЦИИ DS18B20
  EXPORT  READ_BIT_DS1820                 ; ФУНКЦИЯ ПРОЧТЕНИЯ БИТА С УСТРОЙСТВА DS18B20
  EXPORT  WRITE_BIT_DS1820                ; ФУНКЦИЯ ПЕРЕДАЧИ БИТА НА УСТРОУСТВО DS18B20
  EXPORT  SEARCH_ROM_DS1820               ; ФУНКЦИЯ ПОИСКА ROM DS18B20
  EXPORT  Send_com_DS1820                 ; ФУНКЦИЯ ПОСЫЛКИ КОММАНДЫ НА УСТРОЙСТВО DS18B20
  EXPORT  Con_TEMP_all_DS1820             ; ФУНКЦИЯ ПОСЫЛКИ КОММАНДЫ ПРЕОБРАЗОВАНИЯ ТЕМПЕРАТУРЫ НА УСТРОЙСТВО DS18B20
  ;PUBLIC  Send_address_DS18B20            ; ФУНКЦИЯ ПОСЫЛКИ АДРЕСА УСТРОЙСТВА DS18B20
  EXPORT  Read_TEMP_DS1820                ; ФУНКЦИЯ СЧИТЫВАНИЯ ТЕМПЕРАТУРЫ С ОДНОГО УСТРОЙСТВА DS18B20
  ;PUBLIC  READ_bits_DS18B20               ; ФУНКЦИЯ ПРОЧТЕНИЯ 8 БАЙТ ДАННЫХ С УСТРОЙСТВА DS18B20
  EXPORT  CRC_DS1820                      ; ФУНКЦИЯ РАСЧЁТА КОНТРОЛЬНОЙ СУММЫ CRC
  EXPORT  CRC_DS1820_Tab                  ; ФУНКЦИЯ РАСЧЁТА КОНТРОЛЬНОЙ СУММЫ CRC по таблице
  EXPORT  Con_Val_Temp_DS1820             ; ФУНКЦИЯ КОНВЕРТИРОВАНИЯ ДАННЫХ ТЕМПЕРАТУРЫ DS1820
  IMPORT  TaskDelay_us
  IMPORT  _16bit_to_ACSII
  IMPORT  Adrs_DS1820
  IMPORT  Data_memory_DS1820
  IMPORT  Temp_DS1820
;*******************************************************************************
  #define BitBandPerif            R7
  #define T_us(set_us)            (set_us*(SYS_CLK / 1000000))/3
  #define odin                    R11
  #define null                    R10
  #define BaseAdrs                R8
  #define BaseBitBand             R9
;*******************************************************************************
;  AREA       DS1820,DATA 
;	ALIGN 4
;Adrs_DS1820                    DCD  Sum_enable_device*2
;Data_memory_DS1820             DCD  Sum_enable_device*2;
;Temp_DS1820                    DCD  Sum_enable_device

;*******************************************************************************
  AREA       My_code,CODE
  THUMB
;*******************************************************************************
;*********************** ФУНКЦИЯ ИНИЦИАЛИЗАЦИИ 1-WIRE **************************
pBitBandBSRR        EQU   GPIO_BSRR_offset_DS18B20

DS1820_init         PROC
                    ldr   R1,=pBitBandBSRR
                    ; Установка линии 1-WIRE в лог. "0"
                    str   R10,[R1]
                    ; установка паузы в 480 мкс
                    mov   R0,#25
                    push  {R1,LR}
                    FRAME PUSH {R1,LR}
                    bl     TaskDelay_us
                    ; Установка линии 1-WIRE в лог. "1"
                    pop   {R1}
                    FRAME POP {R1}
                    str   R11,[R1]
                    push  {R1}
                    FRAME PUSH {R1}
                    ; установка паузы в 100 мкс
                    mov   R0,#5
                    bl    TaskDelay_us
                    pop   {R1,LR}
                    FRAME POP {R1,LR}
                    ; проверка ответа устройства 1-WIRE 0 - готов; 1 - ошибка
                    ldr   R0,[R1,#-128]
                    ands  R0,R0,#1
                    ; установка паузы в 300 мкс
                    mov   R1,#T_us(300)
DS18B20initpause 		subs  R1,R1,#1
                    bne   DS18B20initpause

                    bx    LR
                    ENDP
;*******************************************************************************
;************* ФУНКЦИЯ ПРОЧТЕНИЯ БИТА С УСТРОЙСТВА DS18B20 *********************
READ_BIT_DS1820     PROC
                    ldr   R0,=pBitBandBSRR
                    ; Установка линии 1-WIRE в лог. "0"
                    str   R10,[R0]
                    ; установка паузы в 4 мкс
                    mov   R1,#T_us(4)
READ_BITpause_0  		subs  R1,R1,#1
                    bne   READ_BITpause_0
                    ; Установка линии 1-WIRE в лог. "1"
                    str   R11,[R0]
                    ; установка паузы в 9 мкс
                    mov   R1,#T_us(9)
READ_BITpause_1  		subs  R1,R1,#1
                    bne   READ_BITpause_1
                    ; считывание бита от устройства
                    ldr   R0,[R0,#-128]
                    ; установка паузы в 3 мкс
                    mov   R1,#T_us(48)
READ_BITpause_2 		subs  R1,R1,#1
                    bne   READ_BITpause_2
                    bx    LR
                    ENDP
;*******************************************************************************
;************* ФУНКЦИЯ ПЕРЕДАЧИ БИТА НА УСТРОЙСТВО DS18B20 *********************
WRITE_BIT_DS1820    PROC
                    ldr   R12,=pBitBandBSRR
                    ; Установка линии 1-WIRE в лог. "0"
                    str   R10,[R12]
                    ; установка паузы в 3 мкс
                    mov   R2,#T_us(5)
WR_BITpause_0    		subs  R2,R2,#1
                    bne   WR_BITpause_0
                    ; Установка линии 1-WIRE в лог. "1" или "0"
                    str   R0,[R12]
                    ; установка паузы в 65 мкс
                    mov   R2,#T_us(50)
WR_BITpause_1    		subs  R2,R2,#1
                    bne   WR_BITpause_1
                    str   R11,[R12]
                    ; установка паузы в 2 мкс
                    mov   R2,#T_us(12)
WR_BITpause_2    		subs  R2,R2,#1
                    bne   WR_BITpause_2
                    bx    LR
                    ENDP
;*******************************************************************************
;************* ФУНКЦИЯ ПОСЫЛКИ КОММАНДЫ НА УСТРОЙСТВО DS18B20 ******************
Send_com_DS1820     PROC
                    push  {LR}
                    mov   R1,#8
S_com_while      		;and   R1,R0,#1
                    bl    WRITE_BIT_DS1820
                    lsr   R0,R0,#1
                    subs  R1,R1,#1
                    bne   S_com_while
                    pop   {LR}
                    bx    LR
                    ENDP
;*******************************************************************************
;** ФУНКЦИЯ ПОСЫЛКИ КОММАНДЫ ПРЕОБРАЗОВАНИЯ ТЕМПЕРАТУРЫ НА УСТРОЙСТВО DS18B20 **
  #define SKIP_ROM      0xCC				  ; значение команды пропуска
  #define CONVERT_TEMP	0x44					; значение команды конвертирований температуры
Con_TEMP_all_DS1820 PROC
                    push  {LR}
                    bl    DS1820_init
                    tst   R0,#1
                    bne   ex_Con_TEMP_all
                    ; если инициализация пройдена, то идём дальше
                    mov   R0,#SKIP_ROM
                    bl    Send_com_DS1820
                    mov   R0,#CONVERT_TEMP
                    bl    Send_com_DS1820
                    mov   R0,#10
                    bl    TaskDelay_us
                    pop   {LR}
ex_Con_TEMP_all  		bx    LR
                    ENDP
  #undef SKIP_ROM
  #undef CONVERT_TEMP
;*******************************************************************************
;*********************** ФУНКЦИЯ ПОИСКА ROM DS18B20 ****************************
SEARCH_ROM_DS1820   PROC
                    push  {R4,R5,R6,LR}
  #define index         R3
  #define AdrsDev1Wire  R6
  #define Temp_Coll     R12
  #define CountDS1820   R4
  #define last_coll     R5
                    mov   last_coll,#-1
                    ldr   AdrsDev1Wire,=Adrs_DS1820
                    orr   AdrsDev1Wire,BaseBitBand,AdrsDev1Wire,LSL#5
                    mov   CountDS1820,#Sum_enable_device
                    ; инициализация устройства
next_device      		;push  {R1,R12}
                    bl    DS1820_init
                    ; проверка готовности устройства
                    tst   R0,#1
                    bne   exit_ROM_while
                    ; посылка команды "SEARCH_ROM"
                    mov   R0,#0xF0
                    bl    Send_com_DS1820

                    mov   index,#64
                    ; считывание бита А и бита Б
SEARCH_ROM_while 		; считавание одного бита (2 раза)
                    bl    READ_BIT_DS1820
                    mov   R2,R0
                    bl    READ_BIT_DS1820
                    ; проверка считанных битов
                    cmp   R2,R0
                    bne   and_1_or_0
                    cbnz  R2,exit_ROM_while
                    ; если нули в обоих случаях, то идём дальше на
                    ; проверку коллизии
                    ; если биты равны "0"
                    cmp   last_coll,index
                    itt   LT
                    ; если меньше, то выполняем условие
                    movlt R0,#0
                    blt   equ_last_coll
                    ; если больше, то переход на метку
                    bgt   more_last_coll
                    ; если равны, то выполняем условие
                    mov   R0,#1
                    b     equ_last_coll
more_last_coll   		;cmp   CountDS1820,#Sum_enable_device
                    ldr   R0,[R12,#-255]
                    tst   R0,odin
                    ite   NE
                    movne R0,#1
                    moveq R0,#0
                    ; сохранение места коллизии
equ_last_coll    		mov   Temp_Coll,index
                    b     exit_while
and_1_or_0       		tst   R2,#1
                    ite   EQ
                    moveq R0,#0
                    movne R0,#1
                    ; проверка нахождения всего кода 1 устройства
exit_while       		str   R0,[AdrsDev1Wire],#4 ; замопинание бита
                    push  {R12,LR}
                    bl    WRITE_BIT_DS1820
                    pop   {R12,LR}
                    subs  index,#1
                    bne   SEARCH_ROM_while
                    ; если найден весь код 1 устройства, тогда
                    ; проверяем нужно ли находить ещё устройства
                    subs  CountDS1820,#1
                    mov   last_coll,Temp_Coll
                    bne   next_device

                    ldr   AdrsDev1Wire,=Adrs_DS1820
                    ldrd  R0,R1,[AdrsDev1Wire]
                    mov   R3,#7
                    bl    CRC_DS1820_Tab

exit_ROM_while   		pop   {R4,R5,R6,LR}
                    bx    LR
                    ENDP
  #undef index
;*******************************************************************************
;************ ФУНКЦИЯ РАСЧЁТА КОНТРОЛЬНОЙ СУММЫ CRC ****************************
  #define L_RegVal    R0
  #define H_RegVal    R1
  #define index       R2
  #define con_crc     R3
CRC_DS1820          PROC
                    mov   index,#56
                    uxtb  con_crc,H_RegVal,ROR#24
                    ubfx  H_RegVal,H_RegVal,#0,#24
wh_CRC_DS1820    		lsrs  L_RegVal,L_RegVal,#1
                    bfi   L_RegVal,H_RegVal,#31,#1
                    lsr   H_RegVal,H_RegVal,#1
                    it    CS
                    eorcs L_RegVal,L_RegVal,#0x8C
                    subs  index,#1
                    bne   wh_CRC_DS1820
                    eor   R0,con_crc,L_RegVal
                    ; если в "R0" получился "0", значит полученное число - верно
                    bx    LR
                    ENDP
  #undef L_RegVal
  #undef H_RegVal
  #undef index
  #undef con_crc
;*******************************************************************************
;********** ФУНКЦИЯ РАСЧЁТА КОНТРОЛЬНОЙ СУММЫ CRC ПО ТАБЛИЦЕ *******************
  #define con_crc     R3
  #define L_RegVal    R0
  #define H_RegVal    R1

CRC_DS1820_Tab      PROC
                    push  {R4}
                    mov   R4,R3
                    mov   con_crc,#0
                    adr   R12,CRC8_TAB
wh_CRC8_Tab      		ubfx  R2,L_RegVal,#0,#8
                    eor   con_crc,con_crc,R2
                    ldrb  con_crc,[R12,con_crc]
                    lsr   L_RegVal,L_RegVal,#8
                    bfi   L_RegVal,H_RegVal,#24,#8
                    lsr   H_RegVal,H_RegVal,#8
                    subs  R4,#1
                    bne   wh_CRC8_Tab
                    eor   R0,L_RegVal,con_crc
                    pop   {R4}
                    bx    LR
                    ENDP
  #undef con_crc
  #undef L_RegVal
  #undef H_RegVal
DATA
CRC8_TAB                DCB  0x00,0x5E,0xBC,0xE2,0x61,0x3F,0xDD,0x83,0xC2,0x9C,\
                             0x7E,0x20,0xA3,0xFD,0x1F,0x41,0x9D,0xC3,0x21,0x7F,\
                             0xFC,0xA2,0x40,0x1E,0x5F,0x01,0xE3,0xBD,0x3E,0x60,\
                             0x82,0xDC,0x23,0x7D,0x9F,0xC1,0x42,0x1C,0xFE,0xA0,\
                             0xE1,0xBF,0x5D,0x03,0x80,0xDE,0x3C,0x62,0xBE,0xE0,\
                             0x02,0x5C,0xDF,0x81,0x63,0x3D,0x7C,0x22,0xC0,0x9E,\
                             0x1D,0x43,0xA1,0xFF,0x46,0x18,0xFA,0xA4,0x27,0x79,\
                             0x9B,0xC5,0x84,0xDA,0x38,0x66,0xE5,0xBB,0x59,0x07,\
                             0xDB,0x85,0x67,0x39,0xBA,0xE4,0x06,0x58,0x19,0x47,\
                             0xA5,0xFB,0x78,0x26,0xC4,0x9A,0x65,0x3B,0xD9,0x87,\
                             0x04,0x5A,0xB8,0xE6,0xA7,0xF9,0x1B,0x45,0xC6,0x98,\
                             0x7A,0x24,0xF8,0xA6,0x44,0x1A,0x99,0xC7,0x25,0x7B,\
                             0x3A,0x64,0x86,0xD8,0x5B,0x05,0xE7,0xB9,0x8C,0xD2,\
                             0x30,0x6E,0xED,0xB3,0x51,0x0F,0x4E,0x10,0xF2,0xAC,\
                             0x2F,0x71,0x93,0xCD,0x11,0x4F,0xAD,0xF3,0x70,0x2E,\
                             0xCC,0x92,0xD3,0x8D,0x6F,0x31,0xB2,0xEC,0x0E,0x50,\
                             0xAF,0xF1,0x13,0x4D,0xCE,0x90,0x72,0x2C,0x6D,0x33,\
                             0xD1,0x8F,0x0C,0x52,0xB0,0xEE,0x32,0x6C,0x8E,0xD0,\
                             0x53,0x0D,0xEF,0xB1,0xF0,0xAE,0x4C,0x12,0x91,0xCF,\
                             0x2D,0x73,0xCA,0x94,0x76,0x28,0xAB,0xF5,0x17,0x49,\
                             0x08,0x56,0xB4,0xEA,0x69,0x37,0xD5,0x8B,0x57,0x09,\
                             0xEB,0xB5,0x36,0x68,0x8A,0xD4,0x95,0xCB,0x29,0x77,\
                             0xF4,0xAA,0x48,0x16,0xE9,0xB7,0x55,0x0B,0x88,0xD6,\
                             0x34,0x6A,0x2B,0x75,0x97,0xC9,0x4A,0x14,0xF6,0xA8,\
                             0x74,0x2A,0xC8,0x96,0x15,0x4B,0xA9,0xF7,0xB6,0xE8,\
                             0x0A,0x54,0xD7,0x89,0x6B,0x35
CODE
;*******************************************************************************
;****** ФУНКЦИЯ СЧИТЫВАНИЯ ТЕМПЕРАТУРЫ С ОДНОГО УСТРОЙСТВА DS1820 **************
  #define MATCH_ROM					0x55					; значение команды соответствия
  #define READ_FROM_MEM			0xBE					; значение команды чтение из памяти
Read_TEMP_DS1820    PROC
                    push  {R0,LR}
                    bl    DS1820_init
                    tst   R0,#1
                    bne   ex_Read_TEMP
                    ; если инициализация пройдена, то идём дальше
                    ; посылаем комманду - выбор устройства
                    mov   R0,#MATCH_ROM
                    bl    Send_com_DS1820
                    ; посылаем адрес выбранного устройства
                    pop   {R0}
                    sub   SP,SP,#4
                    bl    Send_adrs_DS1820
                    ; посылаем комманду - чтения из памяти
                    mov   R0,#READ_FROM_MEM
                    bl    Send_com_DS1820
                    ; считываем 8 байт из устройства
                    pop   {R0}
                    bl    READ_bits_DS1820
                    ; проверяем правильность принятого значения
                    cmp   R0,R2,LSR#24
                    beq   ex_Read_TEMP
                    ldr   R12,=Data_memory_DS1820
                    strd  R10,R10,[R12]

ex_Read_TEMP     		pop   {LR}
                    bx    LR
                    ENDP
;*******************************************************************************
;****************** ФУНКЦИЯ ПОСЫЛКИ АДРЕСА УСТРОЙСТВА DS1820 *******************
  #define index         R3
  #define AdrsDev       R1
Send_adrs_DS1820    PROC
                    mov   index,#64
                    ; находим адресс выбранного устройства
                    ldr   AdrsDev,=Adrs_DS1820
                    add   AdrsDev,AdrsDev,R0,LSL#3
                    orr   AdrsDev,BaseBitBand,AdrsDev,LSL#5
                    push  {LR}
                    ; пишем в устройство по биту
wh_Send_adrs     		ldr   R0,[AdrsDev],#4
                    bl    WRITE_BIT_DS1820
                    subs  index,#1
                    bne   wh_Send_adrs
                    pop   {LR}
                    bx    LR
                    ENDP
  #undef index
  #undef AdrsDev
;*******************************************************************************
;************* ФУНКЦИЯ ПРОЧТЕНИЯ 8 БАЙТ ДАННЫХ С УСТРОЙСТВА DS1820 *************
  #define index           R3
  #define DataMemDS1820   R2
READ_bits_DS1820    PROC
                    mov   index,#64
                    ; находим адресс выбранного устройства
                    ldr   R12,=Data_memory_DS1820
                    add   R12,R12,R0,LSL#3
                    orr   DataMemDS1820,BaseBitBand,R12,LSL#5
                    push  {LR}
                    ; считываем 8 байт с устройства
wh_R_bits_DS1820 		bl    READ_BIT_DS1820
                    str   R0,[DataMemDS1820],#4
                    subs  index,#1
                    bne   wh_R_bits_DS1820
  #undef DataMemDS1820
                    ; считываем 9 байт - CRC
  #define crc_DS1820   R2
                    mov   crc_DS1820,#0
                    mov   index,#8
wh_R_crc_DS      		bl    READ_BIT_DS1820
                    orr   crc_DS1820,R0,crc_DS1820,LSL#1
                    subs  index,#1
                    bne   wh_R_crc_DS
                    rbit  crc_DS1820,crc_DS1820
                    push  {crc_DS1820}
                    ; проверяем CRC8
                    ldrd  R0,R1,[R12]
                    mov   R3,#8
                    bl    CRC_DS1820_Tab
                    pop   {crc_DS1820,LR}
                    bx    LR
                    ENDP
  #undef crc_DS1820
  #undef index
;*******************************************************************************
;************** ФУНКЦИЯ КОНВЕРТИРОВАНИЯ ДАННЫХ ТЕМПЕРАТУРЫ DS1820 **************
  #define DataMemDS1820   R2
  #define _MINUS_         0x2D
Con_Val_Temp_DS1820 PROC
                    ; находим адресс выбранного устройства
                    ldr   R12,=Data_memory_DS1820
                    ldrh  DataMemDS1820,[R12,R0,LSL#3]
                    ldr   R12,=Temp_DS1820
                    add   R12,R12,R0,LSL#2
                    push  {LR}
                    tst   DataMemDS1820,#0xFF00
                    beq   t4
                    mov   R1,#_MINUS_
t4               		mov   R1,#5
                    mul   R0,R2,R1
                    bl    _16bit_to_ACSII

                    str   R1,[R12]
                    pop   {LR}
                    bx    LR
                    ENDP





  END







