#include <stdio.h>
#include <stdlib.h>

int main() {
  long long int n;
  long long int a[100];
  long long int b[100];
  long long int c[100];
  long long int j;
  long long int pomoc;

  n = 9;
  a[0] = 1;
  c[0] = 0;
  for (int i = 1; i <= n; i++) {
    j = i - 1;
    a[i] = i * a[j];
  }
  j = n;
  while (j > 0) {
    b[j] = a[n] - a[j];
    c[j] = b[j] * b[j];
    j--;
  }
  for (int i = n; i >= 0; i--) {
    printf("%d: %lld\n", i, c[i]);
  }
  return 0;
}
