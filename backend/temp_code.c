#include <stdio.h>

int main() {
    char meno[50];

    printf("Zadajte svoje meno: ");
    scanf("%s", meno);

    printf("Ahoj, %s!\n", meno);

    return 0;
}
