open Ctypes

module type SimpleWrappedPointer = sig

  type pointer

  type 'a t

  val allocate_chars : int -> char t

  (** Allocate array of pointers *)
  val allocate_ptrs : int -> pointer t

  (** [write_ptr arr i ptr] sets arr[i] to [ptr]. *)
  val write_ptr : pointer t -> int -> 'a t -> unit

  val write : 'a t -> int -> 'a -> unit

  val read : 'a t -> int -> 'a

  val unwrap : 'a t -> unit Ctypes.ptr

  (* TODO: We actually want [pointer] to [char t],
     but how can we be sure that it points to anything valid?
     [pointer] is just [int64].

     val to_string_ptr : pointer t -> char t
   *)

end

module WrappedPointer_BigArray : SimpleWrappedPointer = struct

  type ('a, 'b) array1 = ('a, 'b, Bigarray.c_layout) Bigarray.Array1.t

  type pointer = int64

  type keepalive =
    (* The leaf is the bottom-most array. May improve this to be the layers of non-pointers *)
    | KeepLeaf : { root : ('a, 'b) array1 ; size : int } -> keepalive
    | KeepArray : { root : 'a ; size : int ; children : keepalive option Array.t } -> keepalive

  type 'a t =
    { mutable keepalive : keepalive
    ; pointer : 'a ptr
    }

  let allocate_array kind n =
    let open Bigarray in
    let arr = Array1.create kind c_layout n in
    { keepalive = KeepLeaf { root = arr ; size = n }
    ; pointer = Ctypes.bigarray_start Ctypes.array1 arr
    }

  let allocate_chars n = allocate_array Bigarray.Char n

  let allocate_ptrs n = allocate_array Bigarray.Int64 n

  let raw_address ptr =
    ptr |> to_voidp |> raw_address_of_ptr |> Int64.of_nativeint

  let write_ptr dst index src =
    let { keepalive = dst_keepalive ; pointer = dst_ptr } = dst in
    let { keepalive = src_keepalive ; pointer = src_ptr } = src in
    dst_ptr +@ index <-@ raw_address src_ptr;
    match dst_keepalive with
    | KeepLeaf { root ; size } ->
       let children = Array.make size None in
       Array.set children index (Some src_keepalive);
       dst.keepalive <- KeepArray { root ; size ; children = children }
    | KeepArray { children ; _ } ->
       Array.set children index (Some src_keepalive)

  let write dst index src =
    let { pointer ; _ } = dst in
    pointer +@ index <-@ src

  let read src index =
    let { pointer ; _ } = src in
    !@ (pointer +@ index)

  let unwrap { pointer ; _ } = to_voidp pointer

  (*
  let to_string_ptr { pointer ; keepalive } =
    { keepalive
    ; pointer = from_voidp char (to_voidp pointer)
    }
  *)

end

module WrappedArray : sig
  type 'a t

  type pointer

  val build_string : string -> char t
  val build_array : 'a t list -> pointer t

  val write_ptr : pointer t -> int -> 'a t -> unit
  val write : 'a t -> int -> 'a -> unit
  val read : 'a t -> int -> 'a
  val unwrap : 'a t -> unit Ctypes.ptr

end = struct

  module WrappedPointer = WrappedPointer_BigArray
  type pointer = WrappedPointer.pointer

  type 'a t = 'a WrappedPointer.t

  let write_ptr = WrappedPointer.write_ptr
  let write = WrappedPointer.write
  let read = WrappedPointer.read
  let unwrap = WrappedPointer.unwrap

  let build_string s =
    let ptr = WrappedPointer.allocate_chars (String.length s + 1) in
    String.iteri (fun i c -> WrappedPointer.write ptr i c) s;
    ptr

  let build_array l =
    let parent = WrappedPointer.allocate_ptrs (List.length l) in
    List.iteri
      (fun i wrapped -> WrappedPointer.write_ptr parent i wrapped) l;
    parent

  module Serializable = struct
    (** TODO: Ideally we should export [serialize]. *)
    let serialize_string s =
      (* This is just [build_string] above *)
      let ptr = WrappedPointer.allocate_chars (String.length s + 1) in
      String.iteri (fun i c -> WrappedPointer.write ptr i c) s;
      ptr

    type !_ serializable =
      | SerializeString : string -> char serializable
      | SerializeList : 'a serializable list -> pointer serializable

    let rec serialize : 'a. 'a serializable -> 'a WrappedPointer.t =
      fun (type a) (l : a serializable)
          : a WrappedPointer.t ->
      (match l with
       | SerializeList l ->
          let children = List.map serialize l in
          let parent = WrappedPointer.allocate_ptrs (List.length l) in
          List.iteri
            (fun i wrapped -> WrappedPointer.write_ptr parent i wrapped) children;
          parent
       | SerializeString s -> serialize_string s
      )
  end

  let _ =
    let open Serializable in
    serialize (SerializeList [SerializeString "gobble"])

  (* let allocate t = WrappedPointer.unwrap (serialize t) |> Ctypes.to_voidp *)

end
