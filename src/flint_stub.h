#ifndef __FLINT_STUB_H
#define __FLINT_STUB_H

#include "flint/fmpz.h"
#include "flint/fmpz_mat.h"

#include "stub_common.h"

typedef char* Integer;

typedef struct rational_matrix rational_matrix;

void debug_flint(int flag);

rational_matrix* matrix_from_string_array(Integer* matrix, slong nrows, slong ncols,
					  Integer denom);

rational_matrix* matrix_from_fpmz_array(fmpz* matrix, slong nrows, slong ncols,
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
   Make the matrix into row-Hermite normal form, in-place.
   The denominator is ignored and left unchanged.

   A matrix is in row-Hermite normal form if
   (1) its all-zero rows are at the bottom of the matrix,
   (2) for each non-zero row, the leading non-zero entry is positive,
   all entries below it in the column are 0,
   and all entries above it in the column are non-negative and
   strictly smaller, and
   (3) for any leading non-zero entry, the leading non-zero entries in rows
   above it must occur strictly to its left, so it is upper-triangular-like.
   Note that columns with no leading non-zero entries or all zeroes are
   possible, which can happen if the input matrix is not of full column rank.
*/
void make_hnf(rational_matrix* matrix);

rational_matrix* matrix_inverse(rational_matrix* matrix);

rational_matrix* matrix_multiply(rational_matrix* mat1, rational_matrix* mat2);

slong rank(rational_matrix* matrix);

rational_matrix* transpose(rational_matrix* mat);

/**
   Solve the matrix equation AX = B.
   A MUST be invertible, otherwise NULL is returned.
*/
rational_matrix* solve(rational_matrix* mat_A, rational_matrix* mat_B);

#endif
