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


/************ SD card parameters ************/
static FATFS FS_instance;			// File System instance
static FIL fsrc,fdst;					// File instance
FRESULT result;						// FRESULT variable
BYTE in1 [6] ; 					// Line buffer
//char test[] = "hello";
char *remaining;
u32 cache_hit_count,cache_miss_count,mem_addr,trace_input,reset,hit_latency,miss_latency,update_lru;
char header[] = "Memory Address \t Cache Hit Count \t Cache Miss Count \t Hit Latency \t Miss Latency \n";
char data[10];
static const char *Path = "0:/";	//  string pointer to the logical drive number
unsigned int BytesRe;				// Bytes written
/************ SD card parameters ************/

int main()
{
    init_platform();

    result = f_mount(&FS_instance,Path, 1);

    result = f_open(&fsrc, "twolf.txt", FA_READ );

    result = f_open(&fdst,"twolfs1.txt",FA_CREATE_ALWAYS | FA_WRITE);

    printf("\nCache Simulator:\n\r");
    result = f_write(&fdst,"CACHE SIMULATOR\n\n",strlen("CACHE SIMULATOR\n\n"), &BytesRe);
    result = f_write(&fdst,"Block Size: 4 words\n",strlen("Block Size: 4 words\n"), &BytesRe);
    result = f_write(&fdst,"Cache Size: 32 KB\n\n",strlen("Cache Size: 32 KB\n\n"), &BytesRe);
    result = f_write(&fdst,header,strlen(header), &BytesRe);

    while (f_eof(&fsrc)==0) {

    	result = f_read(&fsrc, &in1,6*sizeof(BYTE), &BytesRe); // to read the 1st address of trace file
    	//printf("in1: %s\n",in1);
    	trace_input = strtol(in1, &remaining, 16);
    	result = f_read(&fsrc, &in1,sizeof(BYTE), &BytesRe); // to ignore the new line character

    	Xil_Out32(XPAR_AXI_CACHE_LRU_0_S00_AXI_BASEADDR,trace_input);
    	cache_hit_count = Xil_In32(XPAR_AXI_CACHE_LRU_0_S00_AXI_BASEADDR+4);
    	cache_miss_count = Xil_In32(XPAR_AXI_CACHE_LRU_0_S00_AXI_BASEADDR+8);
    	hit_latency = Xil_In32(XPAR_AXI_CACHE_LRU_0_S00_AXI_BASEADDR+12);
    	miss_latency = Xil_In32(XPAR_AXI_CACHE_LRU_0_S00_AXI_BASEADDR+16);
    	mem_addr = Xil_In32(XPAR_AXI_CACHE_LRU_0_S00_AXI_BASEADDR+20);

    	//xil_printf("\ncache_hit=%d, cache_miss=%d, hit_latency=%d, miss_latency=%d,mem_addr=%x\n\r",cache_hit_count,cache_miss_count,hit_latency,miss_latency,mem_addr);

    	itoa(mem_addr,data,16);
    	result = f_write(&fdst,"\t\t",strlen("\t\t"), &BytesRe);
    	result = f_write(&fdst,data,strlen(data), &BytesRe);
    	result = f_write(&fdst,"\t\t\t\t",strlen("\t\t\t\t"), &BytesRe);

    	itoa(cache_hit_count,data,10);
    	result = f_write(&fdst,data,strlen(data), &BytesRe);
    	result = f_write(&fdst,"\t\t\t\t\t",strlen("\t\t\t\t\t"), &BytesRe);

    	itoa(cache_miss_count,data,10);
    	result = f_write(&fdst,data,strlen(data), &BytesRe);
    	result = f_write(&fdst,"\t\t\t\t",strlen("\t\t\t\t"), &BytesRe);

    	itoa(hit_latency,data,10);
    	result = f_write(&fdst,data,strlen(data), &BytesRe);
    	result = f_write(&fdst,"\t\t\t\t",strlen("\t\t\t\t"), &BytesRe);

    	itoa(miss_latency,data,10);
    	result = f_write(&fdst,data,strlen(data), &BytesRe);
    	result = f_write(&fdst,"\t\t\t\t",strlen("\t\t\t\t"), &BytesRe);

    	result = f_write(&fdst,"\n",strlen("\n"), &BytesRe);
    }

    result = f_close(&fsrc);
    result = f_close(&fdst);
    printf("Cache hit count: %d",cache_hit_count);
    printf("Done!");
 	cleanup_platform();
    return 0;
}
