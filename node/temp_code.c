#include <stdio.h>

int main() {
    int age;
    
    printf("Enter your age: ");
    scanf("%d", &age);
    
    if (age >= 18) {
        printf("You are allowed to drink alcohol.\n");
    } else {
        printf("You are not allowed to drink alcohol.\n");
    }
    
    return 0;
}
