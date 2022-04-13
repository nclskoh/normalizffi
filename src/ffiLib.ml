open Ctypes

let ( let* ) o f =
  match o with
  | Ok x -> f x
  | Error e -> Error e

type zz = Mpzf.t
type integer = char ptr
let integer = ptr char (* string *)

let debug = ref false

let set_debug flag =
  debug := flag

let logf fmt fmt_str =
  if !debug then Format.fprintf fmt fmt_str
  else Format.ifprintf fmt fmt_str

let log fmt_str = logf Format.std_formatter fmt_str

let deserialize_int (x : integer) : string =
  let rec go i s =
    let c = !@ (x +@ i) in
    if Char.equal c (Char.chr 0) then
      if String.equal s "" then
        invalid_arg "normalizffi: ffiLib: deserialize_int: empty string!"
      else
        s
    else
      begin
        let s = String.concat "" [s ; String.make 1 c] in
        go (i + 1) s
      end
  in
  go 0 ""

let pp_list_list fmt l =
  let p = List.iter (fun x -> Format.fprintf fmt "%s, " (Mpzf.to_string x)) in
  List.iter (fun x -> p x; Format.fprintf fmt "@;") l

let zz_of_integer ptr =
  (* deserialize_int ptr |> Mpzf.of_string *)
  let s = deserialize_int ptr in
  (* Format.printf "%s\n" s; *)
  Mpzf.of_string s

let allocate_string s =
  log "normalizffi: ffiLib: allocate_string: serializing %s@;" s;
  let len = String.length s in
  let _finalise =
    (* TODO: This finalise is somehow the reason for the string not being garbage-collected
       prematurely; once taken away, [new_matrix] in Flint would give garbage if GC runs.
     *)
    (fun (ptr : char ptr) ->
      log "normalizffi: ffiLib: GC: freeing %s@;"
        (string_of integer ptr)
                   (* (string_of nativeint (raw_address_of_ptr (to_voidp ptr))) *)
    )
  in
  Gc.compact ();
  let ptr = allocate_n
              (* ~finalise *)
              char
              ~count:(len + 1) in
  let rec copy i =
    if i = len then
      begin
        (ptr +@ i) <-@ (Char.chr 0)
      end
    else
      begin
        (ptr +@ i) <-@ (String.get s i);
        (* log "allocate_string: serializing %c, getting %c back@;"
          (String.get s i) (!@ (ptr +@ i)); *)
        copy (i + 1)
      end
  in
  copy 0;
  ptr

let integer_of_zz x =
  Mpzf.to_string x |> allocate_string

type size_t = Unsigned.Size_t.t
let size_t_of_int = Unsigned.Size_t.of_int
let int_of_size_t x = Int64.to_int (Unsigned.Size_t.to_int64 x)

(* Suppose we allocate a value in C memory via Ctypes' [allocate] or [allocate_n].
   This returns an Ocaml value [v] representing the C pointer, and as long as
   this Ocaml value is live, what it points to in C memory is live.

   If we have something like a CArray, say [arr] and set say [arr[i]] to
   [v]'s C pointer, if [v] goes out of scope, what [v] points to gets garbage-collected
   and [arr[i]] points to garbage, even if [arr] itself is live in Ocaml.
   Possible reason: The GC doesn't seem to follow pointers from Ocaml memory into C
   memory.

   An [('a ptr) ffiarray] remedies this by holding both views:
   the CArray and the list of Ocaml ['a ptr]'s, so that the values in C memory
   remain live.

   An [('a, 'b) dual_array] remedies this by holding both views:
   an ['a CArray] pointing to a C array of values in C memory, and a ['b list] that
   holds the Ocaml values necessary to keep these C values live.
   In the simplest case, ['b] is just ['a] itself, where ['a] is say ['t ptr] for some ['t].
   If the array is nested, ['b] can be a [dual_array] itself.
*)
type ('a, 'b) dual_array =
  {
    arr : 'a CArray.t
  ; contents : 'b list (* Hold values in Ocaml to prevent garbage collection *)
  }

type integer_array = (integer, integer) dual_array

let carray_of_integer_array arr = arr.arr

let integer_array_of_zz_list (l : zz list) : integer_array =
  let contents = List.map integer_of_zz l in
  (* let arr = CArray.make integer (List.length l) in *)
  let arr = CArray.of_list integer contents in
  {
    arr
  ; contents
  }

let gather_as_matrix
      (num_rows : int) (num_cols : int) (ptr : 'a ptr) : 'a list list =
  let get_row i =
    let idx = i * num_cols in
    let rec go_col j l =
      if j = num_cols then List.rev l
      else
        let value = !@ (ptr +@ (idx + j)) in
        go_col (j + 1) (value :: l)
    in
    go_col 0 []
  in
  let rec go_row i l =
    if i = num_rows then List.rev l
    else go_row (i + 1) ((get_row i) :: l)
  in
  go_row 0 []

let zz_list_of_integer_array (arr : integer_array) =
  let ptr = CArray.start arr.arr in
  let len = CArray.length arr.arr in
  let l = List.hd (gather_as_matrix 1 len ptr) in
  List.map zz_of_integer l

type two_dim_array =
  { data : integer ptr; (* To cast to an array of integers *)
    num_rows : size_t ;
    num_cols: size_t }

let two_dim_array : two_dim_array structure typ = structure "two_dim_array"
let two_dim_array_data = field two_dim_array "data" (ptr integer)
let two_dim_array_nrows = field two_dim_array "num_rows" size_t
let two_dim_array_ncols = field two_dim_array "num_cols" size_t
let () = seal two_dim_array

let zz_matrix_of_two_dim_array (arr : two_dim_array structure) : zz list list =
  let m = int_of_size_t (getf arr two_dim_array_nrows) in
  let n = int_of_size_t (getf arr two_dim_array_ncols) in
  let data = getf arr two_dim_array_data in
  let mat = gather_as_matrix m n data in
  List.map (fun r -> List.map zz_of_integer r) mat

let zz_matrix_of_int_matrix m : zz list list =
  List.map (List.map Mpzf.of_int) m
