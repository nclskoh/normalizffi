#include <iostream>
#include <cassert>
#include <stdio.h>
#include <string.h>

extern "C" {
#include "normaliz_stub.h"
}

void print_two_dim_array(two_dim_array* arr) {
  if(arr == nullptr) {
    std::cout << "two_dim_array: empty\n";
    return;
  }

  for(int i = 0; i < arr->num_rows; i++) {
    for(int j = 0; j < arr->num_cols; j++) {
      std::cout << arr->data[i * arr->num_cols + j] << ", ";
    }
    std::cout << std::endl;
  }
}

bool two_dim_array_eq(two_dim_array* arr1, two_dim_array* arr2) {
  if(arr1->num_rows != arr2->num_rows || arr1->num_cols != arr2->num_cols) {
    printf("arr1 num_rows: %zu, num_cols: %zu; arr2 num_rows: %zu, num_cols: %zu",
	   arr1->num_rows, arr1->num_cols, arr2->num_rows, arr2->num_cols);
    return false;
  }
  for(int i = 0; i < arr1->num_rows; i++) {
    for(int j = 0; j < arr1->num_cols; j++) {
      int idx = i * arr1->num_cols + j;
      if(strcmp(arr1->data[idx], arr2->data[idx]) != 0) {
	printf("two_dim_array not equal: arr1[%d] = %s, arr2[%d] = %s", idx, arr1->data[idx],
	       idx, arr2->data[idx]);
	return false;
      }
    }
  }
  return true;
}

char int_0[] = "0";
char int_1[] = "1", int_minus_1[] = "-1";
char int_2[] = "2", int_minus_2[] = "-2";
char int_3[] = "3", int_minus_3[] = "-3";
char int_4[] = "4", int_minus_4[] = "-4";
char int_5[] = "5", int_minus_5[] = "-5";
char int_6[] = "6", int_minus_6[] = "-6";
char int_7[] = "7", int_minus_7[] = "-7";
char int_8[] = "8", int_minus_8[] = "-8";
char int_9[] = "9", int_minus_9[] = "-9";
char int_10[] = "10", int_minus_10[] = "-10";

int hilbert_basis_test() {
  /*
    Hilbert basis corresponds to the set of integer points in the parallelogram
    with vertices (0, 0), (1, 0), (1, x), (2, x).
    Hence, (1, y) for all 0 <= y <= x.
  */

  char int_big[] = "10";

  // The cone is a "product" of the standard ray in the constant dimension,
  // two rays that form a parallelogram as above, and a subspace.

  char* matrix[7 * 5] = { int_1, int_0, int_0, int_0, int_0,
			  int_0, int_1, int_0, int_0, int_0,
			  int_0, int_1, int_big, int_0, int_0,
			  int_0, int_0, int_0, int_2, int_3,
			  int_0, int_0, int_0, int_minus_2, int_minus_3,
			  int_0, int_0, int_0, int_0, int_2,
			  int_0, int_0, int_0, int_0, int_minus_2
  };

  // Adding lattice generators for the standard basis
  // doesn't change the Hilbert basis of the homogeneous cone.
  char* lattice_gens[5 * 5] = { int_1, int_0, int_0, int_0, int_0,
				int_0, int_1, int_0, int_0, int_0,
				int_0, int_0, int_1, int_0, int_0,
				int_0, int_0, int_0, int_1, int_0,
				int_0, int_0, int_0, int_0, int_1
  };

  NCone* cone = new_cone(matrix, 7,
			 nullptr, 0,
			 nullptr, 0,
			 lattice_gens, 5,
			 nullptr, 0,
			 nullptr, 0,
			 5);

  auto hilbert_basis = get_hilbert_basis(cone);
  print_two_dim_array(hilbert_basis);

  NCone* dehom = dehomogenize(cone);
  auto dehom_hilbert_basis = get_hilbert_basis(dehom);

  std::cout << "Dehomogenized Hilbert Basis" << std::endl;
  print_two_dim_array(dehom_hilbert_basis);

  char* expected_hilbert[] = { int_0, int_1, int_0, int_0, int_0,
			       int_0, int_1, int_1, int_0, int_0,
			       int_0, int_1, int_2, int_0, int_0,
			       int_0, int_1, int_3, int_0, int_0,
			       int_0, int_1, int_4, int_0, int_0,
			       int_0, int_1, int_5, int_0, int_0,
			       int_0, int_1, int_6, int_0, int_0,
			       int_0, int_1, int_7, int_0, int_0,
			       int_0, int_1, int_8, int_0, int_0,
			       int_0, int_1, int_9, int_0, int_0,
			       int_0, int_1, int_10, int_0, int_0,
			       int_1, int_0, int_0, int_0, int_0
  };

  two_dim_array expected;
  expected.data = expected_hilbert;
  expected.num_rows = 12;
  expected.num_cols = 5;

  assert (two_dim_array_eq(hilbert_basis, &expected));
  std::cout << "TEST: hilbert_basis_test(): passed" << std::endl;

  return 0;

}

int max_rank_submatrix_lex_test() {

  // Having 0 in the first dimension is problematic
  // smtlib/non-incremental/QF_NIA/UltimateAutomizer/linear_sea.ch_true-unreach-call.i_162.smt2

  char big_int_1[] = "4294967295";
  char big_minus_int_1[] = "-4294967295";
  char big_int_2[] = "4294967296";
  char big_minus_int_2[] = "-4294967296";

  /*
  char* generators[3 * 5] = { int_0, int_0, big_int_2, int_0, big_minus_int_1,
			      int_0, big_int_2, int_0, big_minus_int_2, big_minus_int_1,
			      int_0, int_0, big_minus_int_2, big_int_2, big_int_1
  };
  */

  char* generators[3 * 5] = { int_0, int_0, int_2, int_0, int_minus_1,
			      int_0, int_2, int_0, int_minus_2, int_minus_1,
			      int_0, int_0, int_minus_2, int_2, int_1
  };

  // char* inequalities[1 * 5] = { int_1, int_0, int_0, int_0, int_0 };

  NCone* cone = new_cone(generators, 3,
			 nullptr, 0,
			 // inequalities, 1,
			 nullptr, 0,
			 nullptr, 0,
			 nullptr, 0,
			 nullptr, 0,
			 5);

  auto hilbert_basis = get_hilbert_basis(cone);
  print_two_dim_array(hilbert_basis);

  return 0;

}

int integer_hull_test() {

  /*
    Triangle whose integer hull is just the vertical segment.

    x >= 0
    x + ky <= k --> k + (-x) + (-ky) >= 0
    x - ky <= 0 --> -x + ky >= 0
   */

  char int_big[] = "10";
  char int_minus_big[] = "-10";

  char* matrix[4 * 3] = { int_1, int_0, int_0,
			  int_0, int_1, int_0,
			  int_big, int_minus_1, int_minus_big,
			  int_0, int_minus_1, int_big
  };

  char* lattice_gens[3 * 3] = { int_1, int_0, int_0,
				int_0, int_1, int_0,
				int_0, int_0, int_1,
  };

  NCone* cone = new_cone(nullptr, 0,
			 nullptr, 0,
			 matrix, 4,
			 // specifying the standard lattice or not doesn't matter
			 lattice_gens, 3,
			 nullptr, 0,
			 nullptr, 0,
			 3);

  NCone* dehom = dehomogenize(cone);
  hull(dehom);

  auto hull_inequalities = get_integer_hull_inequalities(dehom);
  std::cout << "Hull inequaliites:" << std::endl;
  print_two_dim_array(hull_inequalities);
  auto hull_equations = get_integer_hull_equations(dehom);
  std::cout << "Hull equations:" << std::endl;
  print_two_dim_array(hull_equations);

  char* ehull_inequalities[] = { int_0, int_0, int_1,
				 int_1, int_0, int_minus_1
  };

  char* ehull_equations[] = {int_0, int_1, int_0};

  two_dim_array expected_inequalities, expected_equations;
  expected_inequalities.data = ehull_inequalities;
  expected_inequalities.num_rows = 2;
  expected_inequalities.num_cols = 3;
  expected_equations.data = ehull_equations;
  expected_equations.num_rows = 1;
  expected_equations.num_cols = 3;

  assert (two_dim_array_eq(hull_inequalities, &expected_inequalities));
  assert (two_dim_array_eq(hull_equations, &expected_equations));
  std::cout << "TEST: integer_hull_test(): passed" << std::endl;

  return 0;
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

  char int_big[] = "99999";

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

int qflia_cut_lemma_02_010() {
  /*
    This polyhedron has non-integral vertices, but is an integral
    polyhedron according to Normaliz and Gomory-Chvatal.
    Check: Is this because the vertex-ray-line decomposition returned
    by Apron is non-unique?

    [-1 * :-1, 1 * :2, -1 * :3, 1 * :4, -1 * :6, -1 * :9] >= 0
    [-1 * :-1, 1 * :5, 1 * :6] >= 0
    [1 * :-1, -1 * :2, 2 * :6, 1 * :8, -1 * :9] >= 0
    [1 * :-1, 1 * :2, -2 * :3, 1 * :6] >= 0
    [1 * :-1, -1 * :3, 2 * :6, 1 * :7, 1 * :8] >= 0
    [1 * :-1, 1 * :6, 2 * :7, 1 * :8, 1 * :9] >= 0
    [1 * :1, -1 * :4, 1 * :7, 1 * :8, 1 * :9] >= 0
    [-1 * :2, 1 * :5, -1 * :7] >= 0
    [1 * :2, -1 * :3, -1 * :4, -2 * :5] >= 0

    -1, 0, 0,  1, -1,  1,  0, -1,  0, 0, -1,
    -1, 0, 0,  0,  0,  0,  1,  1,  0, 0,  0
     1, 0, 0, -1,  0,  0,  0,  2,  0, 1, -1,
     1, 0, 0,  1, -2,  0,  0,  1,  0, 0,  0,
     1, 0, 0,  0, -1,  0,  0,  2,  1, 1,  0,
     1, 0, 0,  0,  0,  0,  0,  1,  2, 1,  1,
     0, 0, 1,  0,  0, -1,  0,  0,  1, 1,  1,
     0, 0, 0, -1,  0,  0,  1,  0, -1, 0,  0,
     0, 0, 0,  1, -1, -1, -2,  0,  0, 0,  0
  */

  char* matrix[9 * 11] =
    {
     int_minus_1, int_0, int_0, int_1, int_minus_1, int_1,
     int_0, int_minus_1, int_0, int_0, int_minus_1,

     int_minus_1, int_0, int_0, int_0, int_0, int_0,
     int_1, int_1, int_0, int_0, int_0,

     int_1, int_0, int_0, int_minus_1, int_0, int_0,
     int_0, int_2, int_0, int_1, int_minus_1,

     int_1, int_0, int_0, int_1, int_minus_2, int_0, int_0,
     int_1, int_0, int_0, int_0,

     int_1, int_0, int_0, int_0, int_minus_1, int_0, int_0,
     int_2, int_1, int_1, int_0,

     int_1, int_0, int_0, int_0, int_0, int_0, int_0,
     int_1, int_2, int_1, int_1,

     int_0, int_0, int_1, int_0, int_0, int_minus_1, int_0,
     int_0, int_1, int_1, int_1,

     int_0, int_0, int_0, int_minus_1, int_0, int_0, int_1,
     int_0, int_minus_1, int_0, int_0,

     int_0, int_0, int_0, int_1, int_minus_1, int_minus_1, int_minus_2,
     int_0, int_0, int_0, int_0
  };

  NCone* cone = new_cone(nullptr, 0,
			 nullptr, 0,
			 matrix, 9,
			 nullptr, 0,
			 nullptr, 0,
			 nullptr, 0,
			 11);
  NCone* dehom = dehomogenize(cone);
  hull(dehom);

  auto hull_inequalities = get_integer_hull_inequalities(dehom);
  std::cout << "Hull inequaliites:" << std::endl;
  print_two_dim_array(hull_inequalities);
  auto hull_equations = get_integer_hull_equations(dehom);
  std::cout << "Hull equations:" << std::endl;
  print_two_dim_array(hull_equations);

  auto hull_vertices = get_integer_hull_vertices(dehom);
  std::cout << "Hull vertices:" << std::endl;
  print_two_dim_array(hull_vertices);

  return 0;
}

int main(int argc, char** argv) {
  // hilbert_basis_test();
  // integer_hull_test();
  // qflia_cut_lemma_02_010();
  max_rank_submatrix_lex_test();
  return 0;
}
