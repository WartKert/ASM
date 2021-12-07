/*************************************************************************************************************************
"Delay.h" - �������� �������� ������ ������� �����. ��� ������ ���������� ��������� ������� �7 � "system_stm32l1xx.h".
������ �������:  Pause(time); - ��� "time" �������� ���������� �������� ����� ����� � ���.

���� �����������: 11.04.12
�����: RUS_SERV
***************************************************************************************************************************/
#ifndef Delay_H
//#include "Graf_LCD.h"
//	 #include "system_stm32l1xx.h"
//#include "stm32l1xx.h"


//#include "system_stm32l1xx.h"



	#define TIM7_SYS_CLK						(10000/ ( ((SYS_CLK / 2) / (DIV_TIM7+1)) / 100000 ) )
/***************************************************************************************************************************/
/*    ���������� ����������     */
//	int goto_First_cycle = 1;									// ���������� �� ������� ������������ ������ ���������� ������� Pause
//	register  int CountPC __asm("pc");							// ���������� �������� R15 - Count program
//extern void (*return_to_first_cycle)(void);
/*extern struct OptionsTasks *StrTasks;
extern char CurrentTask;
extern short FlagDelayTask;
extern short FlagMask_Run_or_Stop_Task;
extern unsigned long NextPointerStackTASK;
extern char high;
extern char CountPause;
extern char current_task;
extern unsigned long **Low_Time;
extern unsigned short count_us_TIME;
extern unsigned long *AdrsdelData[2][3];
extern unsigned short Choice_old_Task;*/





extern unsigned long begin;

/***************************************************************************************************************************/
/*    ������� ��������� ���������� �� ������� �7     */
extern void TIM7_IRQHandler (void);

 /******************************************************************************/
//      ������� ��������� ���������� �� ������� �6: ����� ������������
//                                      �����
extern void TIM6_IRQHandler (void);

/***************************************************************************************************************************/
/*    ������� ���ר�� ��������� �����     */
extern void TaskDelay_us (unsigned short  u_secunda);
/***************************************************************************************************************************/
/*    ������� ���ר�� ��������� ����� �������������     */
extern void TaskDelay_ms (unsigned short  m_secunda);
/***************************************************************************************************************************/
/*    ������� �������� �� �������� ����     */
//      ������� �������� �����
extern void Task_create (void (*tsk)(), char prior);
/******************************************************************************/
//      ������� ���������� �����
extern void Task_Manager (unsigned long *p);
/******************************************************************************/
//      ������� ������������� ���������� �����
extern void Init_Task_Manager();
/******************************************************************************/
//      ������� ������ ������ ���������� �����
extern void Start_Task_Manager();
/******************************************************************************/
extern unsigned long Mem_Choice_to_Task(char number);
/******************************************************************************/
/*    ������� �������� ����������     */
extern void del_Data (void *data);
/******************************************************************************/
/*    ������� ������ ����������     */
extern void wr_data(void *adrs_var, unsigned long data_write, char ch_task);
/******************************************************************************/
//      ������� �������� ������
//extern void Task_Delete(unsigned long delStructTask);



#endif
