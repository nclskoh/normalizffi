module WrappedArray : sig
  type 'a t

  type pointer

  val build_string : string -> char t
  val build_array : 'a t list -> pointer t

  val write_ptr : pointer t -> int -> 'a t -> unit
  val write : 'a t -> int -> 'a -> unit
  val read : 'a t -> int -> 'a
  val unwrap : 'a t -> unit Ctypes.ptr

end
