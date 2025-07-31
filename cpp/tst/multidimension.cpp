#include <iostream>

void test() {
  int dim[2,3,2] = { // 2x3x2 배열 초기화
        {{1, 2}, {3, 4}, {5, 6}},
        {{7, 8}, {9, 10}, {11, 12}}
    };

    // 특정 위치 접근
    std::cout << "dim[1,2,1] = " << dim[1,2,1] << "\n"; // 출력: 12

    // 값 수정
    dim[1,2,1] = 99;
    std::cout << "Modified dim[1,2,1] = " << dim[1,2,1] << "\n"; // 출력: 99
}

int main() {
    // 3x4x5 다차원 배열 선언
    int dim[3,4,5];

    // 배열 초기화
    int value = 1;
    for (int i = 0; i < 3; ++i) {
        for (int j = 0; j < 4; ++j) {
            for (int k = 0; k < 5; ++k) {
                dim[i,j,k] = value++; // 각 요소에 1부터 순차적으로 값 할당
            }
        }
    }

    // 배열 출력
    for (int i = 0; i < 3; ++i) {
        std::cout << "Layer " << i << ":\n";
        for (int j = 0; j < 4; ++j) {
            for (int k = 0; k < 5; ++k) {
                std::cout << dim[i,j,k] << " ";
            }
            std::cout << "\n";
        }
        std::cout << "\n";
    }

    test();

    return 0;
}

// g++ -std=c++23 example.cpp -o example 
