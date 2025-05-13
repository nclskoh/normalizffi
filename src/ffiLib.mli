(** Helper functions for converting between Ocaml values and Ocaml
    representations for FFI through Ctypes.
*)

(* TODO: Figure out placement... *)
val ( let* ) : ('a, 'b) result -> ('a -> ('c, 'b) result) -> ('c, 'b) result

(** Debug memory management *)
val set_debug : bool -> unit

(** Integers as seen by client *)
type zz = Mpzf.t

(** An integer allocated in C memory can be wrapped or unwrapped.
    A wrapped integer is one that is protected against garbage collection
    and is what you want when preparing pointers to pass to C.
    An unwrapped integer is just a C.Types.integer,
    and is one that is returned from C.
    In other words: use [wrapped_integer] when sending pointers to C,
    use [C.Types.integer] when receiving pointers from C.

    Wrapped values have to be manually freed when no longer needed.
 *)
type wrapped_integer

val wrapped_integer_of_zz : zz -> wrapped_integer

val wrapped_integer_start : wrapped_integer -> unit Ctypes.ptr

val free_wrapped_integer : wrapped_integer -> unit

val zz_of_integer : C.Types.integer -> zz

val size_t_of_int : int -> C.Types.size_t

val int_of_size_t : C.Types.size_t -> int

(** A wrapped array of wrapped integers to be sent to C *)
type integer_array

val integer_array_of_zz_list : zz list -> integer_array

(* TODO: Have to recover the wrapped pointers inside, not just
   the addresses.
val zz_list_of_integer_array : integer_array -> zz list
 *)

val integer_array_start: integer_array -> unit Ctypes.ptr

val free_integer_array : integer_array -> unit

val zz_matrix_of_two_dim_array :
  C.Types.two_dim_array Ctypes.structure -> zz list list

(* TODO: This should go somewhere, or be superseded if we change representation
   using list list.
 *)
val pp_list_list : Format.formatter -> zz list list -> unit

(* TODO: This should also go somewhere, or be dropped entirely. *)
val zz_matrix_of_int_matrix : int list list -> zz list list
