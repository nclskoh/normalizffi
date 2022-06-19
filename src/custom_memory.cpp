#include <cstdlib>

extern "C"
void* normalizffi_alloc(int n, int size) {
  void* result = calloc(n, size);
  return result;
}

extern "C"
void normalizffi_free(void* ptr) {
  free(ptr);
}
