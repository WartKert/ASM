
;*******************************************************************************
  EXPORT        Init_Task_Manager
  EXPORT        Mem_Choice_to_Task
  EXPORT        Task_create
  EXPORT        Task_Manager
  EXPORT        del_Data
  EXPORT        wr_data
  EXPORT        SVC_Handler
  EXPORT        TaskDelay_us
  EXPORT        SysTick_Handler
  EXPORT        TIM7_IRQHandler
  EXPORT        TaskDelay_ms
	
  IMPORT        Number_Task		
  IMPORT        Stack_Task
	;IMPORT			  MaxDelData
	get	Config_system.h
;*******************************************************************************
MaxDelData	equ	4  
	;#define sizeStack 10
	;#define odin                    R11
  ;#define null                    R10
;  #define BaseAdrs                R8
 ; #define BaseBitBand             R9
	AREA   	    DATA
;maxTimePausePriorTask							EQU		(0x20000000+(MaxDelData*2))
;mCountTask												EQU		(Number_Task << 1) -1
;pAdrsDelData											EQU		0
pTimePauseAndPrior      					EQU		tes*4
;pAddrAndStack           					EQU		MaxDelData*4+Number_Task*4
;pTimeInTask             					EQU		MaxDelData*4+Number_Task*4+Number_Task*8
;pFlagRunTask            					EQU		MaxDelData*4+Number_Task*4+Number_Task*8+Number_Task*4
;pFlagDelayTask          					EQU		MaxDelData*4+Number_Task*4+Number_Task*8+Number_Task*4+4
;pAdrDDataCurTask        					EQU		pFlagDelayTask+4
;pUSCounttime            					EQU		pAdrDDataCurTask+MaxDelData+1
;pMSCountTime            					EQU		pUSCounttime+2
;pSecCountTime           					EQU		pMSCountTime+2
;pCurrentTask            					EQU		pSecCountTime+4
;pCountTask              					EQU		pCurrentTask+1
;*******************************************************************************
  AREA				OS_stack, NOINIT
start                    					DCD  	sfb
;*******************************************************************************
  AREA   	    CODE
TIM7_ARR                  				EQU   0x4000142C
local_max_mem_RAM         				DCD   0x20004000
NVIC_ICER                 				EQU   0xE000E184
NVIC_ISER                 				EQU   0xE000E104
TIM7_SR                   				EQU   0x40001410
STK_CTRL                  				EQU   0xE000E010
STK_LOAD                  				EQU   0xE000E014;STK_CTRL + 0x04
SCB_SHCSR                 				EQU   0xE000ED24
;*******************************************************************************
  AREA       My_data_OS, ALIGN=4
AdrsDelData               				SPACE	MaxDelData
Time_Pause_and_prior_to_Task   		SPACE	Number_Task*4
Addr_and_stack_tasks           		SPACE	(Number_Task*4)*2
Time_in_task                   		SPACE	Number_Task*4
FlagMask_Run_or_Stop_Task      		SPACE	4
FlagDelayTask                  		SPACE	4
AdrDDataCurTask               		SPACE	MaxDelData
ODD 4
USCounttime                    		DC16    0x2000
MSCountTime                    		DC16    0x4000
SecCountTime                   		DCD		0x80000000
current_task                   		DC8     0
CountTask                      		DC8     0x00
Choice_old_Task                		DC8     0
;high
;*******************************************************************************
  SECTION       My_code : CODE
  THUMB
;*******************************************************************************
;********************** ОПИСАНИЕ МАКРОСОВ **************************************
;***************** Запись числа по адресу (через R0 и R1)***********************
  WR_a_f_lab:       MACRO _adrs,_data
                    ldr   R0,_adrs
                    mov   R1,#_data
                    str   R1,[R0]
                    ENDM
;***************** Запись из регистра по адресу (через R0)**********************
  WR_a_f_reg:       MACRO _adrs,_data
                    ldr   R0,_adrs
                    str   _data,[R0]
                    ENDM
;******************* Чтение из адреса метки в регистр **************************
  R_lab_reg:        MACRO Reg,Label
                    ldr   Reg,Label
                    ldr   Reg,[Reg]
                    ENDM
;************* Чтение из адреса метки в регистр со смещением *******************
  R_lab_reg_sh:     MACRO Reg,Label,Sh
                    ldr   Reg,Label
                    ldr   Reg,[Reg,#Sh]
                    ENDM
;**************** Чтение из адреса метки в разные регистры *********************
  R_lab_r_R:        MACRO Reg1,Reg2,Label
                    ldr   Reg2,Label
                    ldr   Reg1,[Reg2]
                    ENDM
;*********************** ОПИСАНИЕ ФУНКЦИЙ **************************************
  #define SysTick_ON  7
  #define SysTick_Load  16000   ; 1 миллисекунда
  #define SysTick_prior 0x10
Init_Task_Manager   ;str   R1,[R0]
                    mov   R0,#2
                    msr   CONTROL,R0
             WR_a_f_lab   =FlagMask_Run_or_Stop_Task,1
             WR_a_f_lab   =TIM7_ARR,20                                          ; TIM7 -> ARR = 20;
              R_lab_reg   R0,=Addr_and_stack_tasks
                    msr   PSP,R0
                    isb
                    ldr   R0,[R0,#24]
                    ; запуск Systic Timer
                    ldr   R1,=STK_LOAD
                    mov   R2,#SysTick_Load
                    str   R2,[R1]
                    mov   R2,#SysTick_prior
                    str   R2,[R1,#0xD0F]
                    mov   R2,#SysTick_ON
                    str   R2,[R1,#-4]
                    ; старт работы ОС
                    bx    R0
;*******************************************************************************
Mem_Choice_to_Task:
              R_lab_r_R   R1,R12,=start
                    add   R1,R1,#80
                    ldr   R3,local_max_mem_RAM
                    cmp   R1,R3
                    ITT   PL
                    movpl R1,#0
                    bxpl  LR
                    str   R1,[R12]
                    b     continue_Task_create
;*******************************************************************************
;********************* ФУНКЦИЯ СОЗДАНИЯ ЗАДАЧ **********************************
  #define Adrs_func R0
  #define Prior     R1
Task_create         mov   R2,#-1

                    add    R12,BaseAdrs,#pTimePauseAndPrior
  while_prior:      add   R2,R2,#1
                    ldr   R3,[R12,R2,LSL#2]
                    cbz   R3,else_while_pr
                    ubfx  R3,R3,#0,#8
                    cmp   Prior,R3
                    bge   while_prior
                    ldr   R3,[R12,R2,LSL#2]
                    str   R3,[R12,R2,LSL#3]
  else_while_pr:    add   R3,BaseAdrs,#pCountTask
                    ldrb  R3,[R3]
                    orr   R1,Prior,R3,LSL#8
                    str   Prior,[R12,R2,LSL#2]
                    add   R1,BaseAdrs,#pCountTask
                    ldrb  R3,[R1]
  #undef Prior
                    add   R3,R3,#1
                    strb  R3,[R1]
                    b     Mem_Choice_to_Task
  continue_Task_create:
                    add   R12,BaseAdrs,#pAddrAndStack
                    sub   R1,R1,#32
                    add   R12,R12,R2,LSL#3
                    strd  R1,Adrs_func,[R12]
                    mov   R2,#0x1000000
                    strd  Adrs_func,R2,[R1,#24]
  #undef Adrs_func
                    bx    LR
;*******************************************************************************
;********************* ФУНКЦИЯ ДИСПЕТЧЕРА ЗАДАЧ ********************************
Task_Manager        ; проверка улвовия - "Выбор старой задачи по R2"
                   ; mrs   R2,PSP
                   ; stmdb R2!,{R4-R7}
                  ;  mov   R11,#1
  Ch_task:          add   R12,BaseAdrs,#pFlagRunTask
                    ldrd  R1,R2,[R12]
                    orr   R1,R1,R2
                    cmp   R0,#0
                    bne     next_2
  Cont_wh_1:        mov   R0,#-1
  start_wh_1:       add   R0,R0,#1
                    lsrs  R1,R1,#1
                    bcs  start_wh_1
                    push  {R0}
                    ; проверка приоритетов новой задачи и последующей за ней
                    add   R12,BaseAdrs,#(pTimePauseAndPrior)
                    ldrb  R3,[R12,R0,LSL#2]
                    add   R0,R0,#1 ;         ??????????????
  Else_next_prior:  ldrb  R2,[R12,R0,LSL#2]
                    cmp   R3,R2
                    bne   Else_wh_1
                    ; если приоритеты равны, то проверяем статус задачи
                    lsrs  R1,R1,#1
                    add   R0,R0,#1
                    bcs  Else_next_prior
                    ; если задача не блокирована, то идем дальше
                    ; установка флага "STOP" для текущей задачи
                    pop   {R0}
  next_2:           add   R1,BaseBitBand,#(pFlagRunTask)*32
                    str   odin,[R1,R0,LSL#2]
                    b     Exit_wh_1
                    ;если приоритеты разные, то ...
  Else_wh_1:        pop   {R0}
                    add   R12,BaseAdrs,#pFlagRunTask
                    str   R10,[R12]
  Exit_wh_1:        add   R12,BaseAdrs,#pAddrAndStack
                    add   R3,BaseAdrs,#pCurrentTask
                    ldrb  R1,[R3]            ; номер сменяемой задачи
                    mrs   R2,PSP
                    str   R2,[R12,R1,LSL#3]   ; запись стека PSP сменяемой задачи
                    ldr   R2,[R12,R0,LSL#3]   ; значение указателя следующей задачи
                    CPSID i
                 ;   str   R1,[R5]            ; установка метки о переходе на выполнение новой задачи
                    strb  R0,[R3]             ; запоминание номера новой задачи
              ;      ldm   R12!,{R4-R7}
                    msr   PSP,R2              ; установка стека новой задачи
                    isb
                    CPSIE i
                    bx    LR
;*******************************************************************************
;********************* ФУНКЦИЯ ОЖИДАНИЕ ПЕРЕМЕННОЙ *****************************
  #define Adr_Data  R0
  #define Adr_Del_Data  R12
del_Data            mov   R2,#-1
  s_wh_d_Data:      add   R2,R2,#1
                    ldr   R1,[BaseAdrs,R2,LSL#2] ;AdrsDelData
                    cmp   R1,#0
                    bne   s_wh_d_Data
                    ; если есть свободное место
                    str   Adr_Data,[BaseAdrs,R2,LSL#2]
                    add   R12,BaseAdrs,#pCurrentTask
  #undef  Adr_Data
                    ldrb  R0,[R12]
                    add   R12,BaseAdrs,#pAdrDDataCurTask
                    strb  R0,[R12,R2]
                    ; установка флага "СТОП" для текущей задачи
                    add   R12,BaseBitBand,#(pFlagDelayTask)*32
                    str   odin,[R12,R0,LSL#2]
                    str   null,[R12,#-128]
                    svc   0                                                     ;смена задачи
                    bx    LR
;*******************************************************************************
;********************** ФУНКЦИЯ ЗАПИСИ ПЕРЕМЕННОЙ ******************************
  ;#define AdrsDelData R12
  #define adrs_var  R0
  #define data_wr   R1
  #define ch_tasks  R2
wr_data             mov  R12,#-1
  s_while:          add   R12,R12,#1
                    ldr   R3,[BaseAdrs,R12,LSL#2]
                    cmp   adrs_var,R3
                    bne   s_while
                    ; если адреса переменных совпали
                    str   data_wr,[adrs_var]
                    str   null,[BaseAdrs,R12,LSL#2]
  #undef  adrs_var
  #undef  data_wr
                    add   R0,BaseAdrs,#pAdrDDataCurTask
                    ldrb  R0,[R0,R12]
                    ; установка флага "RUN" для текущей задачи
                    add   R1,BaseBitBand,#(pFlagDelayTask)*32
                    str   null,[R1,R0,LSL#2]
                    ; проверка условия вернутся на задачу в которой ожидается переменная
                    ; 0 - иди без перехода,1 - новая задача, 2 - задача где испльзуется переменная
                    cbz   ch_tasks,Exit_wr_data
                    cmp   ch_tasks,odin
                    beq   Go_svc_1
                    b     Go_svc
  Go_svc_1:         mov   R0,#0
  Go_svc:           svc   0
; выход из функции
  Exit_wr_data:     bx    LR
  #undef ch_tasks
;*******************************************************************************
;************************* ФУНКЦИЯ СМЕНЫ ЗАДАЧИ ********************************
SVC_Handler
                    cmp   LR,#0xFFFFFFF1
                    itte  NE
                    mrsne R12,PSP
                    ldrne R12,[R12,#24]
                    ldreq R12,[SP,#24]
                    ldrb  R0,[R12,#-2]
                    cmp   R0,#0

                    beq   Task_Manager

;*******************************************************************************
;********************* ФУНКЦИЯ РАСЧЁТА ВРЕМЕННОЙ ПАУЗЫ *************************
  #define u_Sec R0
TaskDelay_us        ;ldr   R12,NVIC_ICER
                    add   R12,BaseAdrs,#pCurrentTask
                    ldrb  R1,[R12]
                    add   R12,BaseAdrs,#(pTimePauseAndPrior)+2
                    ; считывание текущего состояния счётчика времени и нахождение
                    ; конечной точки времени паузы
                    ; также установка флага в последних 4 битах:13-us;14-ms;15-s
                    ; если записан 0 - неактивное состояние
                    add   R3,BaseAdrs,#pUSCounttime
                    ldrh  R3,[R3]
                    add   u_Sec,u_Sec,R3
                    bic   R3,u_Sec,#0xD000
                    ; сохранение заданной паузы
                    strh   R3,[R12,R1,LSL#2]
                    ; установка флага "СТОП" для текущей задачи
                    add   R2,BaseBitBand,#(pFlagDelayTask)*32
                    str   odin,[R2,R1,LSL#2]
                    str   null,[R2,#-128]
                    ;ldr   R12,=NVIC_ICER
                    ;ldr   R12,[R12]
                    ;mov   R4,#4096
                    ;str   R4,[R12]
                    ;str   R4,[R12,#-128]
                    mov   R0,#0
                    svc   0
                    bx    LR
  #undef u_Sec
;*******************************************************************************
;****** ФУНКЦИЯ ОБРАБОТКИ СИСТЕМНОГО ПРЕРЫВАНИЯ SysTick: СМЕНА ЗАДАЧИ **********
  #define Flag_svc_on   R0
SysTick_Handler     mov   Flag_svc_on,#0
                    ; пересчёт миллисекунд
                    add   R3,BaseAdrs,#pMSCountTime
                    ldrh  R12,[R3]
                    add   R12,R12,#1
                    bic   R12,R12,#0xB000
                    strh  R12,[R3]
  #if SCountTime == 1
                    ; пересчёт секунд
                    ldrh  R1,[R3,#2]
                    add   R3,R3,#1
                    strh  R3,[R12,#2]
                    cmp   R3,#1000
                    ldrh  R4,[R12,#4]
                    bmi   next_1
                    strh  R10,[R12,#2]
                    add   R4,R4,#1
                    bic   R4,R4,#0x7000
                    strh  R4,[R12,#4]
  #endif
                    ; поиск задачи с подходящим временем
  next_1:           add   R3,BaseAdrs,#pTimePauseAndPrior
                    mov   R2,#N_Max_Tasks-1
  go_while:         ldr   R1,[R3,R2,LSL#2]   ;ldr   R1,[R12]
                    cmp   R12,R1,LSR#16
                    bne   ch_next_task
                    ; сброс флага для выбранной задачи
  reset_Flag:       add   R0,R3,R2,LSL#2
                    strh  R10,[R0,#2]
                    ubfx  R1,R1,#8,#8
                    add   R3,BaseBitBand,#(pFlagDelayTask)*32
                    str   null,[R3,R1,LSL#2]
                    mov   Flag_svc_on,#1
                    ; проверка условий цикла
  ch_next_task:     subs  R2,R2,#1
                    bpl   go_while
                    cmp   Flag_svc_on,#1
                    bne   exit
                    mov   Flag_svc_on,#0
                    beq   Task_Manager
  exit:             bx    LR
  #undef  Flag_svc_on
;*******************************************************************************
;****************** ФУНКЦИЯ ПАУЗЫ В ДИАПОЗОНЕ - МИЛЛИСЕКУНДЫ *******************
  #define ms_Sec    R0
TaskDelay_ms         ; определение адреса для текущей задачи
                    add   R12,BaseAdrs,#pCurrentTask
                    ldrb  R1,[R12]
                    add   R12,BaseAdrs,#(pTimePauseAndPrior)+2
                    ; считывание текущего состояния счётчика времени и нахождение
                    ; конечной точки времени паузы
                    ; также установка флага в последних 4 битах:13-us;14-ms;15-s
                    ; если записан 0 - неактивное состояние
                    add   R3,BaseAdrs,#pMSCountTime
                    ldrh  R3,[R3]
                    add   ms_Sec,ms_Sec,R3
                    bic   R3,ms_Sec,#0xB000
                    ; сохранение заданной паузы
                    strh   R3,[R12,R1,LSL#2]
                    ; установка флага "СТОП" для текущей задачи
                    add   R2,BaseBitBand,#(pFlagDelayTask)*32
                    str   odin,[R2,R1,LSL#2]
                    str   null,[R2,#-128]
                    ;ldr   R12,=NVIC_ICER
                    ;ldr   R12,[R12]
                    ;mov   R4,#4096
                    ;str   R4,[R12]
                    ;str   R4,[R12,#-128]
                    mov   R0,#0
                    svc   0
  #undef ms_Sec
                    bx    LR

;*******************************************************************************
;****** ФУНКЦИЯ ОБРАБОТКИ ПРЕРЫВАНИЯ ПО ТАЙМЕРУ №7: ПРОГРАММНАЯ ПАУЗА **********
  #define Flag_svc_on   R0
TIM7_IRQHandler     mov   Flag_svc_on,#0
                    ; сброс статуса прерывания
                    ldr   R12,=TIM7_SR
                    str   R0,[R12]
                    ; пересчёт микросекунд
                    add   R12,BaseAdrs,#pUSCounttime
                    ldrh  R1,[R12]
                    add   R1,R1,#1
                    bic   R1,R1,#0xD000
                    strh  R1,[R12]
                    ; поиск задачи с подходящим временем
                    add   R12,BaseAdrs,#pTimePauseAndPrior
                    mov   R2,#N_Max_Tasks-1
  start_wh_t:       ldr   R3,[R12,R2,LSL#2]
                    cmp   R1,R3,LSR#16
                    bne   else_wh
                    ; тело цикла. Если время совпало
                    ; сброс флага для выбранной задачи
                    add   R0,R12,R2,LSL#2
                    strh  R10,[R0,#2]
                    ubfx  R3,R3,#8,#8
                    add   R0,BaseBitBand,#(pFlagDelayTask)*32
                    str   null,[R0,R3,LSL#2]
                    mov   Flag_svc_on,#1
  else_wh:          subs  R2,R2,#1
                    bpl   start_wh_t
                    cbz   Flag_svc_on,Exit_tim7
                    mov   Flag_svc_on,#0
                    svc   0
  Exit_tim7:        bx    LR
  #undef Flag_svc_on
  END