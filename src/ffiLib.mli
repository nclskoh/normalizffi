(** Helper functions for converting between Ocaml values and Ocaml
    representations for FFI through Ctypes.
*)

(* TODO: Figure out placement... *)
val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

(* Representation of big integers. TODO: This should come from elsewhere. *)
type zz = Mpzf.t

(* Ocaml representation of a big integer for FFI *)
type integer

(* Ocaml representation of a size_t for FFI *)
type size_t = Unsigned.Size_t.t

(* Ocaml representation of a matrix for FFI *)
type two_dim_array

val integer : integer Ctypes.typ

val integer_of_zz : zz -> integer

val zz_of_integer : integer -> zz

val size_t_of_int : int -> size_t

val int_of_size_t : size_t -> int

val carray_of_zz_list : zz list -> integer Ctypes.CArray.t

val carray_of_zz_matrix : zz list list -> integer Ctypes.CArray.t

val zz_list_of_carray : integer Ctypes.CArray.t -> zz list

val zz_matrix_of_carray : integer Ctypes.CArray.t -> int -> zz list list

val two_dim_array : two_dim_array Ctypes.structure Ctypes.typ

val zz_matrix_of_two_dim_array :
  two_dim_array Ctypes.structure -> zz list list

(* TODO: This should go somewhere, or be superseded if we change representation
   using list list.
 *)
val pp_list_list : Format.formatter -> zz list list -> unit

(* TODO: This should also go somewhere, or be dropped entirely. *)
val zz_matrix_of_int_matrix : int list list -> zz list list
