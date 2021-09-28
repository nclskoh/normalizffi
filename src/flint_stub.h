#ifndef __FLINT_STUB_H
#define __FLINT_STUB_H

#include "flint/fmpz_mat.h"

#include "stub_common.h"

extern "C" {

  typedef char* Integer;

  typedef struct rational_matrix rational_matrix;

  rational_matrix* matrix_from_string_array(Integer* matrix, slong nrows, slong ncols,
					    Integer denom);

  rational_matrix* matrix_from_array(fmpz* matrix, slong nrows, slong ncols,
				     Integer denom);

  two_dim_array* matrix_contents(rational_matrix* matrix);

  Integer matrix_denominator(rational_matrix* matrix);

  /**
     Given an (m x n) matrix A in row Hermite normal form whose non-zero rows
     are the first k rows, return an (n x n) matrix whose first k rows are those
     of A, and the other (n - k) rows are standard basis vectors whose 1's are
     in columns that have no leading entries in A.
  */
  rational_matrix* extend_hnf_to_basis(rational_matrix* matrix);

  /**
     Make the matrix into Hermite normal form, in-place.
   */
  void make_hnf(rational_matrix* matrix);

  rational_matrix* matrix_inverse(rational_matrix* matrix);

  rational_matrix* matrix_multiply(rational_matrix* mat1, rational_matrix* mat2);

}

#endif
