(** Interfacing with Flint library. *)

open FfiLib

(* Pointer to a matrix in Flint *)
(* type matrix_ptr *)

(** Pointer to a rational matrix consisting of an integer denominator
    and an integer-valued matrix.
    This is the Ocaml view of [rational_matrix*] in C.
 *)
type rational_matrix_ptr

val set_debug : bool -> unit

(** Create a matrix in Flint *)
val new_matrix : zz list list -> rational_matrix_ptr

(** Dummy value to import symbol when linking; do not use. *)
val dummy : unit -> unit

(** Compute the row Hermite normal form of the input matrix, done in-place.
    The denominator of the rational matrix is ignored and left unchanged.

    A matrix is in row-Hermite normal form if
    (1) its all-zero rows are at the bottom of the matrix,
    (2) for each non-zero row, the leading non-zero entry is positive,
        all entries below it in the column are 0,
        and all entries above it in the column are non-negative and
        strictly smaller.
    (3) for any leading non-zero entry, the leading non-zero entries in rows
        above it must occur strictly to its left, so it is upper-triangular-like.
    Note that columns with no leading non-zero entries or all zeroes are 
    possible, which can happen if the input matrix is not of full column rank.
*)
val hermitize : rational_matrix_ptr -> unit

(** Given an (m x n) matrix A in row Hermite normal form whose non-zero rows
    are the first k rows, return an (n x n) matrix whose first k rows are those
    of A, and the other (n - k) rows are standard basis vectors whose 1's are
    in columns that have no leading entries in A.
*)
val extend_hnf_to_basis : rational_matrix_ptr -> rational_matrix_ptr

(** Given an invertible matrix, construct its inverse. *)
val matrix_inverse :
  rational_matrix_ptr -> rational_matrix_ptr

(** Create the product of two matrices *)
val matrix_multiply : rational_matrix_ptr -> rational_matrix_ptr -> rational_matrix_ptr

(* Get the pointer to the matrix part of a rational matrix.

Possible problem: Ocaml may not see that the returned matrix ptr points to
something that is reached by the structure itself, and the Ocaml values holding
the two pointers are different. When the one corresponding to the pointer to the
structure is garbage-collected, the matrix is also GC'ed, and the matrix
pointer becomes dangling.

val matrix_ptr_of_rational_matrix :
  rational_matrix_ptr -> matrix_ptr
*)

(** Get the contents of a rational matrix *)
val zz_denom_matrix_of_rational_matrix : rational_matrix_ptr -> zz * zz list list

(** Get rank of the matrix *)
val rank : rational_matrix_ptr -> int

(** Transpose a matrix *)
val transpose : rational_matrix_ptr -> rational_matrix_ptr

val solve : rational_matrix_ptr -> rational_matrix_ptr -> rational_matrix_ptr
