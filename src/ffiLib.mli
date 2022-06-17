(** Helper functions for converting between Ocaml values and Ocaml
    representations for FFI through Ctypes.
*)

(* TODO: Figure out placement... *)
val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

(* Representation of big integers. TODO: This should come from elsewhere. *)
type zz = Mpzf.t

(* Ocaml representation of a C array of C (big) Integers *)
type integer_array

(* Debug memory management *)
val set_debug : bool -> unit

val integer_to_ptr : C.Types.integer -> unit Ctypes.ptr

val integer_of_zz : zz -> C.Types.integer

val zz_of_integer : C.Types.integer -> zz

val size_t_of_int : int -> C.Types.size_t

val int_of_size_t : C.Types.size_t -> int

val integer_array_of_zz_list : zz list -> integer_array

val zz_list_of_integer_array : integer_array -> zz list

(* TODO: This carries the risk that when [integer_array] goes out of scope,
   GC kicks in and the pointers (integers) in the array become garbage.
*)
val carray_of_integer_array : integer_array -> C.Types.integer Ctypes.CArray.t

val two_dim_array : C.Types.two_dim_array Ctypes.structure Ctypes.typ

val zz_matrix_of_two_dim_array :
  C.Types.two_dim_array Ctypes.structure -> zz list list

(* TODO: This should go somewhere, or be superseded if we change representation
   using list list.
 *)
val pp_list_list : Format.formatter -> zz list list -> unit

(* TODO: This should also go somewhere, or be dropped entirely. *)
val zz_matrix_of_int_matrix : int list list -> zz list list
