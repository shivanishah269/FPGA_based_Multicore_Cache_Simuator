/******************************************************************************
*
* Copyright (C) 2009 - 2014 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/

/*
 * helloworld.c: simple test application
 *
 * This application configures UART 16550 to baud rate 9600.
 * PS7 UART (Zynq) is not initialized by this application, since
 * bootrom/bsp configures it to baud rate 115200
 *
 * ------------------------------------------------
 * | UART TYPE   BAUD RATE                        |
 * ------------------------------------------------
 *   uartns550   9600
 *   uartlite    Configurable only in HW design
 *   ps7_uart    115200 (configured by bootrom/bsp)
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "platform.h"
#include "xil_printf.h"
#include "xil_io.h"
#include "xbasic_types.h"
#include "xparameters.h"
#include "xsdps.h"
#include "ff.h"
#include "xtime_l.h"

/************ SD card parameters ************/
static FATFS FS_instance;			// File System instance
static FIL fsrc,fdst;					// File instance
FRESULT result;						// FRESULT variable
BYTE newline ; 					// Line buffer
static const char *Path = "0:/";	//  string pointer to the logical drive number
unsigned int BytesRe;                // bytes written
/************ SD card parameters ************/

/************ parameters ************/
char mem_addr[1000005][11];			// local buffer to store mem_addr
char ins_type[1000005][2];				// local buffer to store ins_type
char core_id[1000005][2];				// local buffer to store core_id
char *remaining;
u32 trace_input,L1_hit_count_core0,L1_hit_count_core1,L1_hit_count_core2,L1_hit_count_core3,L2_hit_count4,L2_hit_count8,L2_hit_count16,L2_ss1_count4,L2_ss1_count8,L2_ss1_count16,L2_ss2_count4,L2_ss2_count8,L2_ss2_count16;
u32 ss1_hit_way,ss1_index;
char data[20];
unsigned int count,final_count;
float read_delay,processing_delay;
XTime read_delay_Start,read_delay_End,processing_delay_Start,processing_delay_End;

/************ parameters ************/

int main()
{
    init_platform();

    result = f_mount(&FS_instance,Path, 1);

    result = f_open(&fsrc, "657.txt", FA_READ );     // file reading

    result = f_open(&fdst,"657n.txt",FA_CREATE_ALWAYS | FA_WRITE);    // file writing

    //printf("\nCache-accel Simulator:\n");
    result = f_write(&fdst,"/***************Cache-accel Simulator*****************/\n\n",strlen("/***************Cache-accel Simulator*****************/\n\n"), &BytesRe);
    result = f_write(&fdst,"Block Size: 4 words\n",strlen("Block Size: 4 words\n"), &BytesRe);

    count = 0;

    // read delay start - reading from SD card and storing it locally to this code in 2d array named mem_addr
    XTime_GetTime(&read_delay_Start);
    while (f_eof(&fsrc)==0){
    	result = f_read(&fsrc, &mem_addr[count],10*sizeof(char), &BytesRe); // to read the 1st address of trace file
    	mem_addr[count][11] = '\0';
    	result = f_read(&fsrc, &ins_type[count],1*sizeof(char), &BytesRe); // to read the ins type of address
    	ins_type[count][2] = '\0';
    	result = f_read(&fsrc, &core_id[count],1*sizeof(char), &BytesRe); // to read the core id of address
    	core_id[count][2] = '\0';
    	result = f_read(&fsrc, &newline,sizeof(char), &BytesRe); // to ignore the new line character
    	count++;
    }
    XTime_GetTime(&read_delay_End);
    // read delay end


    // processing delay start
    XTime_GetTime(&processing_delay_Start);
    final_count = count;

    Xil_Out32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR,0x0);
	for (count = 0; count<final_count; count++){

		trace_input = strtoul(mem_addr[count], &remaining, 16);// string to unsigned long int
    	Xil_Out32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+4,trace_input);
    	trace_input = strtoul(core_id[count], &remaining, 16);// string to unsigned long int
    	Xil_Out32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+8,trace_input);
    	trace_input = strtoul(ins_type[count], &remaining, 16);// string to unsigned long int
    	Xil_Out32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+12,trace_input);

    	L1_hit_count_core0 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+16);
    	L1_hit_count_core1 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+20);
    	L1_hit_count_core2 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+24);
    	L1_hit_count_core3 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+28);
    	L2_hit_count4 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+32);
    	L2_hit_count8 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+36);
    	L2_hit_count16 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+40);
    	L2_ss1_count4 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+44);
       	L2_ss1_count8 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+48);
    	L2_ss1_count16 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+52);
    	L2_ss2_count4 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+56);
    	L2_ss2_count8 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+60);
    	L2_ss2_count16 = Xil_In32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR+64);

	}

    XTime_GetTime(&processing_delay_End);


    // processing delay end

    // 1st configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 16",strlen("L2 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 4\n",strlen("L2 Number of Ways: 4\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_ss2_count4,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    // 2nd configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 16",strlen("L2 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 8\n",strlen("L2 Number of Ways: 8\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_ss2_count8,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    // 3rd configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 16",strlen("L2 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 16\n",strlen("L2 Number of Ways: 16\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_ss2_count16,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    // 4th configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 32",strlen("L2 Number of Sets: 32"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 4\n",strlen("L2 Number of Ways: 4\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_ss1_count4,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    // 5th configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 32",strlen("L2 Number of Sets: 32"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 8\n",strlen("L2 Number of Ways: 8\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_ss1_count8,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    // 6th configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 32",strlen("L2 Number of Sets: 32"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 16\n",strlen("L2 Number of Ways: 16\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_ss1_count16,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    // 7th configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 64",strlen("L2 Number of Sets: 64"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 4\n",strlen("L2 Number of Ways: 4\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_hit_count4,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    // 8th configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 64",strlen("L2 Number of Sets: 64"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 8\n",strlen("L2 Number of Ways: 8\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_hit_count8,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    // 9th configuration
    result = f_write(&fdst,"L1 Number of Sets: 16",strlen("L1 Number of Sets: 16"), &BytesRe);
    result = f_write(&fdst,"L1 Number of Ways: 4\n",strlen("L1 Number of Ways: 4\n"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Sets: 64",strlen("L2 Number of Sets: 64"), &BytesRe);
    result = f_write(&fdst,"L2 Number of Ways: 16\n",strlen("L2 Number of Ways: 16\n"), &BytesRe);

   	result = f_write(&fdst,"L1 core0 hit count: ",strlen("L1 core0 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core0,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core1 hit count: ",strlen("L1 core1 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core1,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core2 hit count: ",strlen("L1 core2 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core2,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
   	result = f_write(&fdst,"L1 core3 hit count: ",strlen("L1 core3 hit count: "), &BytesRe);
   	itoa(L1_hit_count_core3,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

    result = f_write(&fdst,"L2 hit count: ",strlen("L2 hit count: "), &BytesRe);
   	itoa(L2_hit_count16,data,10);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	read_delay = 1.0 * (read_delay_End - read_delay_Start) / COUNTS_PER_SECOND;
   	processing_delay = 1.0 * (processing_delay_End - processing_delay_Start) / COUNTS_PER_SECOND;

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"Read Delay: ",strlen("Read Delay: "), &BytesRe);
   	gcvt(read_delay, 4, data);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst," sec ",strlen(" sec"), &BytesRe);

   	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);

   	result = f_write(&fdst,"Processing Delay: ",strlen("Processing Delay: "), &BytesRe);
   	gcvt(processing_delay, 4, data);
   	result = f_write(&fdst,data,strlen(data), &BytesRe);
   	result = f_write(&fdst," sec ",strlen(" sec"), &BytesRe);

   	Xil_Out32(XPAR_QUADCORE_CACHE_0_S00_AXI_BASEADDR,0x1);

    result = f_close(&fsrc);
    result = f_close(&fdst);

 	cleanup_platform();
    return 0;

}
