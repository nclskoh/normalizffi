extern "C" {
#include "normaliz_stub.h"
}

int hola08() {

  /* Crashes due to OOM even at Normaliz level. */

  /*
  [99999 * x_{-1}, -1 * x_{1}] >= 0
  [99999 * x_{-1}, -1 * x_{2}] >= 0
  [99999 * x_{-1}, 1 * x_{2}] >= 0
  [1 * x_{1}] >= 0
  [1 * x_{2}] >= 0

  i.e.,
  x1 <= 99999
  -99999 <= x2 <= 99999
  x1 >= 0
  x2 >= 0

  Thus: 0 <= x1, x2 <= 99999, just a square, and this is ALREADY integral.
  */

  char* int_0 = (char*)"0";
  char* int_1 = (char*)"1";
  char* int_minus_1 = (char*)"-1";
  char* int_big = (char*)"99999";

  char* matrix[18] = { int_big, int_minus_1, int_0,
                       int_big, int_0, int_minus_1,
                       int_big, int_0, int_1,
                       int_0, int_1, int_0,
                       int_0, int_0, int_1,
                       int_1, int_0, int_0  // to keep cone pointed
  };

  NCone* cone = new_cone(nullptr, 0,
			 nullptr, 0,
			 matrix, 6,
			 nullptr, 0,
			 nullptr, 0,
			 nullptr, 0,
			 3);
  NCone* dehom = dehomogenize(cone);
  // hull(dehom); This causes Normaliz to crash.
  return 0;
}

int main(int argc, char** argv) {
  hola08();
  return 0;
}

