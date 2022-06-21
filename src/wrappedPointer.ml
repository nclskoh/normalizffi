open Ctypes

let global_root = ref ([] : Obj.t list)

module type SimpleWrappedPointer = sig

  type pointer

  type 'a t

  (** Cannot allocate an empty array *)
  exception Empty_array

  (** Cannot free something that is already freed *)
  exception Pointer_already_freed

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

  val free : 'a t -> unit

end

module WrappedPointer_BigArray_Keepalive : SimpleWrappedPointer = struct

  type ('a, 'b) array1 = ('a, 'b, Bigarray.c_layout) Bigarray.Array1.t

  type pointer = nativeint

  exception Empty_array

  exception Pointer_already_freed

  type keepalive =
    | KeepCharPtr of (char, Bigarray.int8_unsigned_elt) array1
    | KeepArrayPtr of { root : (nativeint, Bigarray.nativeint_elt) array1
                      ; mutable descendents : keepalive list
                      }

  type 'a t =
    | CharPtr : keepalive -> char t
    | ArrayPtr : keepalive -> pointer t

  let get_keepalive : type a. a t -> keepalive =
    function
    | CharPtr k -> k
    | ArrayPtr k -> k

  let allocate_chars n =
    if n < 0 then raise Empty_array
    else
      let open Bigarray in
      let arr = Array1.create Char c_layout n in
      CharPtr (KeepCharPtr arr)

  let allocate_ptrs n =
    if n < 0 then raise Empty_array
    else
      let open Bigarray in
      let arr = Array1.create Nativeint c_layout n in
      ArrayPtr (KeepArrayPtr { root = arr ; descendents = []})

  let unwrap : type a. a t -> unit ptr =
    function
    | CharPtr alive ->
       begin match alive with
       | KeepCharPtr arr -> to_voidp (bigarray_start Ctypes.array1 arr)
       | _ -> failwith "WrappedPointer: Shouldn't happen"
       end
    | ArrayPtr alive ->
       begin match alive with
       | KeepArrayPtr arr -> to_voidp (bigarray_start Ctypes.array1 arr.root)
       | _ -> failwith "WrappedPointer: Shouldn't happen"
       end

  let write_ptr dst index src =
    match dst with
    | ArrayPtr (KeepArrayPtr arr) ->
       (from_voidp (ptr void) (unwrap dst)) +@ index <-@ (unwrap src);
       arr.descendents <- (get_keepalive src) :: arr.descendents
    | _ -> invalid_arg "WrappedPointer: mistyped"

  let write : type a. a t -> int -> a -> unit =
    fun dst index src ->
    match dst with
    | CharPtr (KeepCharPtr arr) -> Bigarray.Array1.set arr index src
    | ArrayPtr (KeepArrayPtr { root ; _ }) -> Bigarray.Array1.set root index src
    | _ -> failwith "WrappedPointer: Shouldn't happen"

  let read : type a. a t -> int -> a =
    fun p index ->
    match p with
    | CharPtr (KeepCharPtr arr) -> Bigarray.Array1.get arr index
    | ArrayPtr (KeepArrayPtr { root ; _ }) -> Bigarray.Array1.get root index
    | _ -> failwith "WrappedPointer: Shouldn't happen"

  (** [free] is just an illusion to force the client to hold onto the Ocaml
      value. *)
  let free t = ()

end

module WrappedPointer_BigArray_Roots : SimpleWrappedPointer = struct

  type pointer = nativeint

  exception Empty_array
  exception Pointer_already_freed

  type 'a t =
    { pointer : 'a ptr
    (* all registered roots of Ocaml values that are logically reachable from this pointer *)
    ; mutable roots : unit ptr list
    }

  let allocate_array kind n =
    if n < 0 then raise Empty_array
    else
      let open Bigarray in
      let arr = Array1.create kind c_layout n in
      let root = Ctypes.Root.create arr in
      (*
         let addr = Ctypes.raw_address_of_ptr root in
         Gc.finalise (fun a -> Format.printf "GC: Finalizing %x\n"
           (Nativeint.to_int addr)) root; *)
      let obj_repr = Obj.repr arr in
      let dummy_tag = Obj.repr "Hello" in
      global_root := dummy_tag :: obj_repr :: !global_root;
      (*
    Format.printf "tags: lazy: %d, closure: %d, object: %d, infix: %d, forward: %d,
                   no_scan: %d, abstract: %d, string: %d, double: %d, double_array: %d,
                   custom: %d, int: %d, out_of_heap: %d"
      Obj.lazy_tag Obj.closure_tag Obj.object_tag Obj.infix_tag Obj.forward_tag
      Obj.no_scan_tag Obj.abstract_tag Obj.string_tag Obj.double_tag Obj.double_array_tag
      Obj.custom_tag Obj.int_tag Obj.out_of_heap_tag;
       *)

      (*Format.printf "registered root with address %x, (object, dummy) representation = (%d, %d)\n"
        (Nativeint.to_int addr) (Obj.tag obj_repr) (Obj.tag dummy_tag); *)
      { roots = [root]
      ; pointer = Ctypes.bigarray_start Ctypes.array1 arr
      }

  let allocate_chars n =
    allocate_array Bigarray.Char n

  let allocate_ptrs n = allocate_array Bigarray.Nativeint n

  let raw_address ptr =
    ptr |> to_voidp |> raw_address_of_ptr

  let write_ptr dst index src =
    dst.roots <- List.append dst.roots src.roots;
    dst.pointer +@ index <-@ raw_address src.pointer

  let write dst index src =
    let { pointer ; _ } = dst in
    pointer +@ index <-@ src

  let read src index =
    let { pointer ; _ } = src in
    !@ (pointer +@ index)

  let unwrap { pointer ; _ } = to_voidp pointer

  let free { roots ; _ } =
    List.iter (fun uptr -> Ctypes.Root.release uptr) roots

end

module type WrappedArray = sig

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

module WrappedArrayFromPointer (Wp : SimpleWrappedPointer) : WrappedArray =
  struct

    type pointer = Wp.pointer
    exception Empty_array = Wp.Empty_array
    exception Pointer_already_freed = Wp.Pointer_already_freed

    type 'a t = 'a Wp.t

    let write_ptr = Wp.write_ptr
    let write = Wp.write
    let read = Wp.read
    let unwrap = Wp.unwrap
    let free = Wp.free

    let make_string s =
      let ptr = Wp.allocate_chars (String.length s + 1) in
      String.iteri (fun i c -> Wp.write ptr i c) s;
      ptr

    let make_array l =
      if l = [] then raise Wp.Empty_array
      else
        let parent = Wp.allocate_ptrs (List.length l) in
        List.iteri
          (fun i wrapped -> Wp.write_ptr parent i wrapped) l;
        parent

    module Serializable = struct
      (** TODO: Redundant now... *)
      let serialize_string s =
        let ptr = Wp.allocate_chars (String.length s + 1) in
        String.iteri (fun i c -> Wp.write ptr i c) s;
        ptr

      type !_ serializable =
        | SerializeString : string -> char serializable
        | SerializeList : 'a serializable list -> pointer serializable

      let rec serialize : 'a. 'a serializable -> 'a Wp.t =
        fun (type a) (l : a serializable)
            : a Wp.t ->
              (match l with
               | SerializeList l ->
                  let children = List.map serialize l in
                  let parent = Wp.allocate_ptrs (List.length l) in
                  List.iteri
                    (fun i wrapped -> Wp.write_ptr parent i wrapped) children;
                  parent
               | SerializeString s -> serialize_string s
              )

      (* let allocate t = WrappedPointer.unwrap (serialize t) |> Ctypes.to_voidp *)
    end

    let _ =
      let open Serializable in
      serialize (SerializeList [SerializeString "gobble"])

  end

module WrappedArray_BigArray_Keepalive : WrappedArray =
  WrappedArrayFromPointer (WrappedPointer_BigArray_Keepalive)

module WrappedArray_BigArray_Roots : WrappedArray =
  WrappedArrayFromPointer (WrappedPointer_BigArray_Roots)

module WrappedArray_NormalizAlloc : WrappedArray = struct
  (** TODO:
      - Double free isn't protected against yet.
      - Only a list of strings is supported for now; arbitrary nesting
        raises an exception.
   *)

  type _ t =
    | CString : char Ctypes.ptr -> char t
    | CArray : char ptr Ctypes.ptr * int -> char ptr t

  type pointer = char ptr

  exception Empty_array
  exception Pointer_already_freed

  let make_string s =
    let n = String.length s in
    let cast p = Ctypes.from_voidp char p in
    let p = C.Functions.Memory.alloc (n + 1) (sizeof char)
            |> cast in
    String.iteri (fun i c -> (p +@ i) <-@ c) s;
    p +@ n <-@ Char.chr 0;
    CString p

  let ptr_of (type a) (t : a t) : a Ctypes.ptr =
    match t with
    | CString p -> p
    | CArray (p, _) -> p

  let _ptr_of_string (type a) (t : a t) : a Ctypes.ptr =
    match t with
    | CString p -> p
    | CArray (p, _) ->
       invalid_arg "Normalizffi: WrappedPointer: ptr_of_string: not a string"

  let ptr_of_array (type a) (t : a t) : a Ctypes.ptr =
    match t with
    | CString _ ->
       invalid_arg "Normalizffi: WrappedPointer: ptr_of_array: not an array"
    | CArray (p, _) -> p

  type level =
    | JustString | JustArray

  let get_level (type a) (t : a t) =
    match t with
    | CString _ -> JustString
    | CArray _ -> JustArray

  let join_level x y =
    match x, y with
    | JustString, JustString -> JustString
    | JustArray, _
      | _, JustArray -> JustArray

  let make_array (type a) (l : a t list) : char ptr t =
    if l = [] then raise Empty_array
    else
      let arr = C.Functions.Memory.alloc (List.length l) (sizeof (ptr char))
                |> Ctypes.from_voidp (ptr char) in
      (* Downcast and upcast to bypass type unification *)
      let upcast p = Ctypes.from_voidp char p in
      let lev = List.fold_left (fun lev t -> join_level lev (get_level t))
                  JustString l in
      match lev with
      | JustString ->
         List.iteri (fun i p -> (arr +@ i) <-@ (upcast p))
           (List.map (fun t -> to_voidp (ptr_of t)) l);
         CArray (arr, List.length l)
      | JustArray ->
         invalid_arg "Normalizffi: WrappedPointer: make_array:
                      nested arrays not supported yet"

  let free_strings (arr, n) =
    let cast p = Ctypes.to_voidp p in
    for i = 0 to n -1 do
      let p = !@ (arr +@ i) in
      C.Functions.Memory.free (cast p)
    done;
    C.Functions.Memory.free (cast arr)

  let write_ptr dst index src =
    let dst_ptr = ptr_of_array dst in
    (dst_ptr +@ index) <-@ from_voidp char (to_voidp (ptr_of src))

  let write t index value = (ptr_of t) +@ index <-@ value

  let read t index = !@ ((ptr_of t) +@ index)

  let unwrap t = ptr_of t |> to_voidp

  let free (type a) (t : a t) : unit =
    match t with
    | CString p ->
       let cast p = Ctypes.to_voidp p in
       C.Functions.Memory.free (cast p)
    | CArray (arr, n) -> free_strings (arr, n)

end

(* module WrappedArray = WrappedArray_BigArray_Keepalive *)
module WrappedArray = WrappedArray_NormalizAlloc
