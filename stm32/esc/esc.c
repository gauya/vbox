//chatgpt
// foc_stm32.c - Sensorless FOC Algorithm Overview (simplified)
// Assumes: STM32F4 MCU, 3-shunt current sensing, 3-phase BLDC motor

#include "stm32f4xx.h"
#include <math.h>

#define PI 3.14159265f
#define SQRT3 1.7320508f
#define PWM_MAX 4095
#define PWM_HALF 2048

// Motor parameters (simplified)
float motor_flux = 0.01f; // Flux linkage
float pole_pairs = 7;
float Ts = 0.0001f; // Sampling time (10kHz)

// Motor state
float theta_e = 0.0f; // Electrical angle
float omega = 0.0f;   // Electrical speed

// Current feedback (measured by ADC)
float ia, ib, ic;
float id, iq;

// Control references
float id_ref = 0.0f;
float iq_ref = 1.5f;

// PI control gains
float kp = 5.0f, ki = 100.0f;
float id_err_int = 0.0f, iq_err_int = 0.0f;

// Output voltages
float vd, vq;
float va, vb, vc;

// Clarke transform (abc -> alpha-beta)
void clarke(float ia, float ib, float ic, float *ialpha, float *ibeta) {
    *ialpha = ia;
    *ibeta = (ia + 2 * ib) / SQRT3;
}

// Park transform (alpha-beta -> dq)
void park(float ialpha, float ibeta, float theta, float *id, float *iq) {
    float cos_t = cosf(theta);
    float sin_t = sinf(theta);
    *id =  ialpha * cos_t + ibeta * sin_t;
    *iq = -ialpha * sin_t + ibeta * cos_t;
}

// Inverse Park (dq -> alpha-beta)
void inv_park(float vd, float vq, float theta, float *valpha, float *vbeta) {
    float cos_t = cosf(theta);
    float sin_t = sinf(theta);
    *valpha = vd * cos_t - vq * sin_t;
    *vbeta  = vd * sin_t + vq * cos_t;
}

// SVPWM output (alpha-beta -> duty cycle)
void svpwm(float valpha, float vbeta) {
    float v1 = valpha;
    float v2 = -0.5f * valpha + 0.866f * vbeta;
    float v3 = -0.5f * valpha - 0.866f * vbeta;

    float vmin = fminf(fminf(v1, v2), v3);
    float vmax = fmaxf(fmaxf(v1, v2), v3);

    float offset = (vmax + vmin) / 2.0f;
    
    va = (v1 - offset);
    vb = (v2 - offset);
    vc = (v3 - offset);

    TIM1->CCR1 = (uint32_t)(PWM_HALF + va * PWM_HALF);
    TIM1->CCR2 = (uint32_t)(PWM_HALF + vb * PWM_HALF);
    TIM1->CCR3 = (uint32_t)(PWM_HALF + vc * PWM_HALF);
}

// PI controller for d, q
void pi_control() {
    float id_err = id_ref - id;
    float iq_err = iq_ref - iq;

    id_err_int += id_err * Ts;
    iq_err_int += iq_err * Ts;

    vd = kp * id_err + ki * id_err_int;
    vq = kp * iq_err + ki * iq_err_int;
}

// Main FOC loop (called from timer interrupt at 10kHz)
void foc_loop() {
    float ialpha, ibeta, valpha, vbeta;

    // Step 1: Clarke
    clarke(ia, ib, ic, &ialpha, &ibeta);

    // Step 2: Park
    park(ialpha, ibeta, theta_e, &id, &iq);

    // Step 3: Control
    pi_control();

    // Step 4: Inverse Park
    inv_park(vd, vq, theta_e, &valpha, &vbeta);

    // Step 5: SVPWM
    svpwm(valpha, vbeta);

    // Step 6: Update electrical angle (sensorless: observer or estimator)
    theta_e += omega * Ts;
    if (theta_e > 2 * PI) theta_e -= 2 * PI;
}

// ISR (e.g., TIM1_UP_TIM10_IRQHandler)
void TIM1_UP_TIM10_IRQHandler(void) {
    TIM1->SR &= ~TIM_SR_UIF;
    foc_loop();
}

