#include <chrono>
#include <iostream>
#include <format>
#include <unistd.h>

int main() {

    auto start = std::chrono::steady_clock::now();

    sleep(1);
    usleep(12345);
    
    auto end = std::chrono::steady_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::milliseconds>(end - start);

    std::cout << std::format("sleep, usleep 시간: {}ms\n", duration.count());

    // 현재 시스템 시간
    auto now = std::chrono::system_clock::now();
    std::cout << std::format("현재 시간(UTC): {:%Y-%m-%d %H:%M:%S}\n", now);
    
    // time_t로 변환
    auto time = std::chrono::system_clock::to_time_t(now);
    
    // 로컬 시간으로 출력
//    std::cout << std::format("현재 시간: {:%Y-%m-%d %H:%M:%S}\n", std::localtime(&time));
    
    std::cout << std::put_time(std::localtime(&time),"현재 시간(KST): %Y-%m-%d %H:%M:%S\n");


    return 0;
}
