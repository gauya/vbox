.syntax unified
        .cpu    cortex-m4
        .thumb

        .global PendSV_Handler
        .global start_first_task

        .set USE_FPU, 0
        .if __FPU_PRESENT == 1
        .set USE_FPU, 1
        .endif

        .type PendSV_Handler, %function
PendSV_Handler:
        MRS     R0, PSP             
        STMDB   R0!, {R4-R11}       

        .if USE_FPU == 1
        TST     LR, #0x10           
        IT      EQ
        VSTMDBEQ R0!, {S16-S31}     
        .endif

        LDR     R1, =current_task_tcb
        LDR     R1, [R1]
        STR     R0, [R1, #24]       

        LDR     R1, =next_task_tcb
        LDR     R1, [R1]
        LDR     R0, [R1, #24]       

        LDMIA   R0!, {R4-R11}       

        .if USE_FPU == 1
        TST     LR, #0x10
        IT      EQ
        VLDMIAEQ R0!, {S16-S31}     
        .endif

        MSR     PSP, R0             

        BX      LR                  

        .type start_first_task, %function
start_first_task:
        LDR     R0, =current_task_tcb
        LDR     R0, [R0]            

        LDR     R0, [R0, #24]       

        MSR     PSP, R0

        MOV     R3, #0x03           
        .if USE_FPU == 1
        ORR     R3, R3, #0x04       
        .endif
        MSR     CONTROL, R3
        ISB                         

        BX      LR                  
