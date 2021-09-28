open Foreign
open Ctypes
open FfiLib

let slong = long
let slong_of_int x = Signed.Long.of_int64 (Int64.of_int x)

type rational_matrix_ptr = unit ptr
let rational_matrix_ptr = ptr void

let matrix_from_array =
  foreign "matrix_from_string_array" (ptr integer @-> slong @-> slong
                                      @-> integer
                                      @-> returning rational_matrix_ptr)

let hermitize =
  foreign "make_hnf" (rational_matrix_ptr @-> returning void)

let matrix_to_two_dim_array =
  foreign "matrix_contents"
    (rational_matrix_ptr @-> returning (ptr two_dim_array))

let matrix_denom =
  foreign "matrix_denominator" (rational_matrix_ptr @-> returning integer)

let extend_hnf_to_basis =
  foreign "extend_hnf_to_basis"
    (rational_matrix_ptr @-> returning rational_matrix_ptr)

let matrix_inverse =
  foreign "matrix_inverse" (rational_matrix_ptr @-> returning rational_matrix_ptr)

let matrix_multiply =
  foreign "matrix_multiply" (rational_matrix_ptr @->
                             rational_matrix_ptr @->
                             returning rational_matrix_ptr)


let new_matrix (generators : zz list list): rational_matrix_ptr =
  let arr = carray_of_zz_matrix generators in
  let num_rows = List.length generators in
  let num_cols = if num_rows = 0 then 0 else List.length (List.hd generators) in
  matrix_from_array (CArray.start arr)
    (slong_of_int num_rows) (slong_of_int num_cols)
    (integer_of_zz (Mpzf.of_int 1))

let zz_matrix_of_matrix (mat_ptr : rational_matrix_ptr) : zz list list =
  let two_dim_arr = !@ (matrix_to_two_dim_array mat_ptr) in
  zz_matrix_of_two_dim_array two_dim_arr

let denom_of_matrix (mat_ptr : rational_matrix_ptr): zz =
  let denom = matrix_denom mat_ptr in
  zz_of_integer denom

let zz_denom_matrix_of_rational_matrix (rm_ptr : rational_matrix_ptr)
  : zz * zz list list =
  (denom_of_matrix rm_ptr, zz_matrix_of_matrix rm_ptr)
