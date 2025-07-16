        .syntax unified
        .cpu cortex-m4       ; Cortex-M4 사용
        .thumb

        .global PendSV_Handler      ; PendSV_Handler 함수를 전역으로 선언
        .global start_first_task    ; start_first_task 함수를 전역으로 선언

        ; FPU 지원 여부에 따른 조건부 컴파일
        #if defined(__FPU_PRESENT) && (__FPU_PRESENT == 1)
            #define USE_FPU 1
        #else
            #define USE_FPU 0
        #endif

        .type PendSV_Handler, %function
        PendSV_Handler:
            ; 이 함수는 PendSV 인터럽트가 발생했을 때 호출됩니다.
            ; 여기서 현재 태스크의 컨텍스트를 저장하고, 다음 태스크의 컨텍스트를 복원합니다.

            ; 1. 현재 실행 중인 태스크의 컨텍스트 저장 (R4-R11 저장)
            MRS R0, PSP         ; Process Stack Pointer(PSP)를 R0 레지스터에 로드 (현재 태스크의 스택 포인터)
            STMDB R0!, {R4-R11} ; R4-R11을 R0가 가리키는 주소에 저장하고 R0를 업데이트(감소)합니다 (Full Descending Stack).

            #ifdef USE_FPU
            TST LR, #0x10         ; FPU 사용 여부 확인
            ITTEE EQ
            VSTMDBEQEQ R0!, {S16-S31} ; Save the FPU registers (S16-S31) if FPU was used
            #endif

            ; 2. 현재 태스크의 스택 포인터(SP)를 current_task_tcb->psp 변수에 저장합니다.
            LDR R1, =current_task_tcb ; current_task_tcb 변수의 주소를 R1에 로드
            LDR R1, [R1]              ; current_task_tcb (TCB* 타입) 값을 R1에 로드
            STR R0, [R1, #24]         ; R0 (업데이트된 현재 SP)를 current_task_tcb->psp에 저장

            ; 3. 다음 실행할 태스크의 스택 포인터(SP)를 로드하여 컨텍스트 복원 준비
            LDR R1, =next_task_tcb    ; next_task_tcb 변수의 주소를 R1에 로드
            LDR R1, [R1]              ; next_task_tcb (TCB* 타입) 값을 R1에 로드
            LDR R0, [R1, #24]         ; next_task_tcb->psp 값을 R0에 로드 (이것이 다음 태스크의 새로운 스택 포인터)

            ; 4. 다음 태스크의 컨텍스트 복원
            LDMIA R0!, {R4-R11} ; R4-R11을 스택에서 복원하고 R0를 업데이트(증가)합니다 (Increment After).

            #ifdef USE_FPU
            TST LR, #0x10
            ITTEE EQ
            VLDMIAEQEQ R0!, {S16-S31} ; Restore the FPU registers (S16-S31) if FPU was used
            #endif

            ; 5. R0 (새로운 SP)를 PSP에 저장합니다.
            MSR PSP, R0         ; Process Stack Pointer를 R0 (새로운 SP)로 설정

            ; 6. BX LR을 통해 인터럽트에서 복귀합니다.
            BX LR               ; 인터럽트에서 복귀

        .type start_first_task, %function
        ;__attribute__((naked)) void start_first_task(void) {  // (제거)  C/C++ 코드에서 정의
        start_first_task:
            ; 1. 현재 실행할 첫 태스크의 TCB 포인터를 가져옵니다.
            LDR R0, =current_task_tcb    ; current_task_tcb 변수의 주소를 R0에 로드
            LDR R0, [R0]                  ; current_task_tcb (TCB* 타입) 값을 R0에 로드 (첫 태스크의 TCB 주소)

            ; 2. 첫 태스크의 PSP 값을 TCB에서 로드합니다.
            LDR R0, [R0, #24]             ; R0 = current_task_tcb->psp

            ; 3. PSP 레지스터를 첫 태스크의 스택 포인터로 설정합니다.
            MSR PSP, R0

            ; 4. CONTROL 레지스터를 설정하여 PSP를 사용하고 비특권 모드로 전환합니다.
            MOV R3, #0x03                ; PSP 사용 (bit 1), 비특권 모드 (bit 0) = 0b011
            #ifdef USE_FPU
            ORR R3, R3, #0x04           ; FPCA 비트 (bit 2) 추가 = 0b100. 결과: 0b111 (0x07)
            #endif
            MSR CONTROL, R3               ; CONTROL 레지스터에 설정 값 적용
            ISB                           ; 명령어 동기화 장벽 (레지스터 변경 즉시 반영)

            ; 5. 첫 번째 태스크로 점프 (BX LR)
            BX LR
