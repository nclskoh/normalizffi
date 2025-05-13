module Types (F : Ctypes.TYPE) = struct

  open Ctypes
  open F

  (** Ocaml representation of a C (big) Integer *)
  type integer = char ptr

  (** Ocaml representation of a C size_t *)
  type size_t = Unsigned.Size_t.t

  (** Ocaml representation of a C two_dim_array *)
  type two_dim_array =
  { data : unit ptr; (* To cast to an array of integers *)
    num_rows : size_t ;
    num_cols: size_t }

  (** typ for integers *)
  let integer = ptr char (* string *)

  let two_dim_array : two_dim_array structure typ = structure "two_dim_array"
  let two_dim_array_data = field two_dim_array "data" (ptr void)
  let two_dim_array_nrows = field two_dim_array "num_rows" size_t
  let two_dim_array_ncols = field two_dim_array "num_cols" size_t
  let () = seal two_dim_array

  let slong = long

  (** Pointer to a rational matrix consisting of an integer denominator
      and an integer-valued matrix.
      This is the Ocaml view of [rational_matrix*] in C.
   *)
  type rational_matrix_ptr = unit ptr

  (** typ for rational matrices *)
  let rational_matrix_ptr = ptr void

  (** Ocaml type for cone pointers *)
  type cptr = unit ptr

  (** typ for cone pointers *)
  let cptr = ptr void

end
