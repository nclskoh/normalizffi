#include <iostream>
#include <vector>
#include <assert.h>

#include "flint/fmpz_mat.h"

#include "flint_stub.h"

int debug = 0;

// An fmpz is an slong that can encode a pointer to an MPZ.

typedef char* Integer;

typedef struct rational_matrix {
  fmpz_mat_struct* matrix;
  Integer denominator;
} rational_matrix;

void set_debug(int flag) {
  debug = flag;
}

extern "C"
rational_matrix* matrix_from_string_array(Integer* matrix, slong nrows, slong ncols,
					  Integer denom) {
  if(debug) {
    assert(matrix != nullptr && nrows * ncols > 0);
  }

  fmpz_mat_struct* new_matrix = new fmpz_mat_struct;

  fmpz_mat_init(new_matrix, nrows, ncols);

  for(int i = 0; i < nrows; i++) {
    for(int j = 0; j < ncols; j++) {
      auto entry = fmpz_mat_entry(new_matrix, i, j);
      auto str = matrix[i * ncols + j];
      fmpz n;

      if(debug) {
	assert(str != nullptr);
      }

      fmpz_set_str(&n, str, 10);
      *entry = n;
    }
  }

  auto result = new rational_matrix;
  result->matrix = new_matrix;
  // auto one = new std::string("1");
  // result->denominator = &(*one)[0];
  auto d = new std::string(denom);
  result->denominator = &(*d)[0];
  return result;
}

extern "C"
rational_matrix* matrix_from_array(fmpz* matrix, slong nrows, slong ncols,
				   Integer denom) {
  if(debug) {
    assert(matrix != nullptr && nrows * ncols > 0);
  }

  fmpz_mat_struct* new_matrix = new fmpz_mat_struct;

  fmpz_mat_init(new_matrix, nrows, ncols);

  for(int i = 0; i < nrows; i++) {
    for(int j = 0; j < ncols; j++) {
      auto entry = fmpz_mat_entry(new_matrix, i, j);
      *entry = matrix[i * ncols + j];
    }
  }

  auto result = new rational_matrix;
  result->matrix = new_matrix;
  // auto one = new std::string("1");
  // result->denominator = &(*one)[0];
  auto d = new std::string(denom);
  result->denominator = &(*d)[0];
  return result;
}

extern "C"
two_dim_array* matrix_contents(rational_matrix* rmatrix) {

  if(debug) {
    assert(rmatrix != nullptr && rmatrix->matrix != nullptr);
  }

  auto matrix = rmatrix->matrix;

  auto result = new two_dim_array;

  result->num_rows = fmpz_mat_nrows(matrix);
  result->num_cols = fmpz_mat_ncols(matrix);

  size_t size = result->num_rows * result->num_cols;
  result->data = new Integer[size];

  for(int i = 0; i < result->num_rows; i++) {
    for(int j = 0; j < result->num_cols; j++) {
      auto entry = fmpz_mat_entry(matrix, i, j);
      auto str = fmpz_get_str(nullptr, 10, entry);
      result->data[i * result->num_cols + j] = str;
    }
  }

  return result;
}

extern "C"
Integer matrix_denominator(rational_matrix* rmatrix) {
  return rmatrix->denominator;
}

// Set row to e_j (1 in the j-th position, where j starts from 0).
// Assume within bounds.
static
void set_row_as_unit_vector(fmpz_mat_struct* matrix, slong row, slong ej) {

  auto nrows = fmpz_mat_nrows(matrix);
  auto ncols = fmpz_mat_ncols(matrix);

  assert(row < nrows);

  for(int j = 0; j < ncols; j++) {
    auto entry = fmpz_mat_entry(matrix, row, j);
    if(j == ej) {
      *entry = 1;
    } else {
      *entry = 0;
    }
  }
}

static
void copy_row(fmpz_mat_struct* matrix,
	      slong row_dest, const fmpz_mat_struct* matrix_src, slong row_src) {

  auto nrows_dest = fmpz_mat_nrows(matrix);
  auto ncols_dest = fmpz_mat_ncols(matrix);
  auto nrows_src = fmpz_mat_nrows(matrix_src);
  auto ncols_src = fmpz_mat_ncols(matrix_src);

  assert(row_dest < nrows_dest && row_src < nrows_src
	 && ncols_src <= ncols_dest);

  for(int j = 0; j < ncols_src; j++) {
    auto entry_src = fmpz_mat_entry(matrix_src, row_src, j);
    auto entry_dest = fmpz_mat_entry(matrix, row_dest, j);
    *entry_dest = *entry_src;
  }
}

// Given a matrix in row Hermite normal form, return a copy with standard basis
// vectors appended such that the result is of full rank
extern "C"
rational_matrix* extend_hnf_to_basis(rational_matrix* rmatrix) {

  if(debug) {
    assert(rmatrix != nullptr && rmatrix->matrix != nullptr);
  }

  auto matrix = rmatrix->matrix;

  auto nrows = fmpz_mat_nrows(matrix);
  auto ncols = fmpz_mat_ncols(matrix);

  fmpz_mat_struct* new_matrix = new fmpz_mat_struct;
  fmpz_mat_init(new_matrix, ncols, ncols);

  int last_leading = -1;
  int result_row = 0;

  std::vector<slong> v{};

  for(int i = 0; i < nrows; i++) {
    for(int j = last_leading + 1; j < ncols; j++) {
      auto entry = fmpz_mat_entry(matrix, i, j);
      last_leading = j;

      if(*entry != 0) {
	copy_row(new_matrix, result_row, matrix, i);
	result_row = result_row + 1;
	break;
      }
      else {
	v.push_back(j);
	// set_row_as_unit_vector(new_matrix, result_row, j);
	// result_row = result_row + 1;
      }
    }
  }

  for(int j = last_leading + 1; j < ncols; j++) {
    v.push_back(j);
  }

  if(debug) {
    for(int i = 0; i < v.size(); i++) {
      std::cout << v[i];
    }
    std::cout << std::endl;
  }

  for(int i = 0; i < v.size() ; i++) {
    set_row_as_unit_vector(new_matrix, result_row + i, v[i]);
  }

  auto result = new rational_matrix;
  result->matrix = new_matrix;
  auto one = new std::string("1");
  result->denominator = &(*one)[0];
  return result;
}

extern "C"
void make_hnf(rational_matrix* rmatrix) {
  auto matrix = rmatrix->matrix;

  if(debug) {
    std::cout << "make_hnf: input: " << std::endl;
    fmpz_mat_print(matrix);
    std::cout << std::endl;
  }

  fmpz_mat_hnf(matrix, matrix);

  if(debug) {
    std::cout << "make_hnf: output" << std::endl;
    fmpz_mat_print(matrix);
    std::cout << std::endl;
  }
}

extern "C"
rational_matrix* matrix_inverse(rational_matrix* rmatrix) {
  if(debug) {
    assert(rmatrix != nullptr && rmatrix->matrix != nullptr);
  }

  auto matrix = rmatrix->matrix;
  auto nrows = fmpz_mat_nrows(matrix);
  auto ncols = fmpz_mat_ncols(matrix);
  auto inverse = new fmpz_mat_struct;

  fmpz_mat_init(inverse, nrows, ncols);
  fmpz denom;
  fmpz_mat_inv(inverse, &denom, matrix);

  fmpz rmatrix_denom;
  fmpz_set_str(&rmatrix_denom, rmatrix->denominator, 10);

  if(! fmpz_is_one(&rmatrix_denom)) {
    // WARNING: Need to test if in-place is safe.
    fmpz_mat_scalar_mul_fmpz(inverse, inverse, &rmatrix_denom);
  }

  auto str = fmpz_get_str(nullptr, 10, &denom);

  auto result = new rational_matrix;
  result->matrix = inverse;
  result->denominator = str;
  return result;
}

extern "C"
rational_matrix* matrix_multiply(rational_matrix* mat1, rational_matrix* mat2) {
  if(debug) {
    assert(mat1 != nullptr && mat2 != nullptr
	   && mat1->matrix != nullptr && mat2->matrix != nullptr);
  }

  auto product = new fmpz_mat_struct;
  auto nrows = fmpz_mat_nrows(mat1->matrix);
  auto ncols = fmpz_mat_ncols(mat2->matrix);

  fmpz_mat_init(product, nrows, ncols);
  fmpz_mat_mul(product, mat1->matrix, mat2->matrix);

  auto result = new rational_matrix;
  result->matrix = product;
  fmpz new_denom, denom1, denom2;
  fmpz_init(&new_denom);
  fmpz_set_str(&denom1, mat1->denominator, 10);
  fmpz_set_str(&denom2, mat2->denominator, 10);

  fmpz_mul(&new_denom, &denom1, &denom2);
  auto str = fmpz_get_str(nullptr, 10, &new_denom);
  result->denominator = str;
  return result;
}

extern "C"
slong rank(rational_matrix* mat) {
  return fmpz_mat_rank(mat->matrix);
}

extern "C"
rational_matrix* transpose(rational_matrix* mat) {
  auto transposed = new fmpz_mat_struct;
  auto nrows = fmpz_mat_nrows(mat->matrix);
  auto ncols = fmpz_mat_ncols(mat->matrix);

  fmpz_mat_init(transposed, ncols, nrows);
  fmpz_mat_transpose(transposed, mat->matrix);
  auto result = new rational_matrix;
  result->matrix = transposed;

  auto denom = new std::string(mat->denominator);
  result->denominator = &(*denom)[0];
  return result;
}

extern "C"
rational_matrix* solve(rational_matrix* mat_A, rational_matrix* mat_B) {

  auto x = new fmpz_mat_struct;
  auto nrows_A = fmpz_mat_nrows(mat_A->matrix);
  auto ncols_A = fmpz_mat_ncols(mat_A->matrix);
  auto nrows_B = fmpz_mat_nrows(mat_B->matrix);
  auto ncols_B = fmpz_mat_ncols(mat_B->matrix);

  fmpz_mat_init(x, ncols_A, ncols_B);
  fmpz denom, denom_A, denom_B;
  fmpz_init(&denom);
  fmpz_set_str(&denom_A, mat_A->denominator, 10);
  fmpz_set_str(&denom_B, mat_B->denominator, 10);

  int ok = fmpz_mat_solve(x, &denom, mat_A->matrix, mat_B->matrix);

  if(!ok) {
    return NULL;
  }

  // WARNING: Need to test if in-place is safe.
  fmpz_mat_scalar_mul_fmpz(x, x, &denom_A);
  fmpz_mul(&denom, &denom, &denom_B);

  auto str = fmpz_get_str(nullptr, 10, &denom);

  auto result = new rational_matrix;
  result->matrix = x;
  result->denominator = str;

  return result;
}
