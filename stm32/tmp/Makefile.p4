# arm-none-eabi-objdump -D -j .text p4.o > p4.ss

arm-none-eabi-gcc -x assembler-with-cpp -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -DSTM32F407xx -D__FPU_PRESENT=1 -DARM_MATH_CM4 -D__VFP_FP__ -g -I. -I./CMSIS/Core/Include -I./CMSIS/Device/ST/stm32f4xx/Include -I./Drivers/STM32STM32F4xx_HAL_Driver/Inc -mcpu=cortex-m4 -mthumb -mfpu=fpv4-sp-d16 -mfloat-abi=hard -T./STM32F407VGTx_FLASH.ld -nostartfiles -Wl,-Map=build/STM32F407xx.map -Wl,--gc-sections -Wl,--print-memory-usage -Wl,--cref -g  -c p4.s
