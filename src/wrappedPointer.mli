module WrappedArray : sig
  type 'a t

  type pointer

  exception Empty_array
  exception Pointer_already_freed

  val make_string : string -> char t
  val make_array : 'a t list -> pointer t

  val write_ptr : pointer t -> int -> 'a t -> unit
  val write : 'a t -> int -> 'a -> unit
  val read : 'a t -> int -> 'a
  val unwrap : 'a t -> unit Ctypes.ptr

  val free : 'a t -> unit

end
