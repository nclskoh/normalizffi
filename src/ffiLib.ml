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
      if s = "" then
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
  deserialize_int ptr |> Mpzf.of_string

let allocate_string s =
  log "normalizffi: ffiLib: allocate_string: serializing %s@;" s;
  let len = String.length s in
  let _finalise = (fun (ptr : char ptr) ->
      log "normalizffi: ffiLib: GC: freeing %s@;"
        (string_of integer ptr)
                   (* (string_of nativeint (raw_address_of_ptr (to_voidp ptr))) *)
    )
  in
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

(* A C array is a CArray.t in Ocaml *)

(* Ocaml representation and typ constructors:
  - Ocaml: [CArray.t] (wrapper for [Ctypes_static.carray])
    - [ctypes.mli] holds module signature.
    - [CArray.get], [CArray.set]
    - [CArray.of_list], [CArray.to_list],
    - [CArray.iter], [CArray.fold_left], [CArray.fold_right]
    - [CArray.length]
    - [CArray.from_ptr p n] casts pointer p to a pointer that points to an array
    - [CArray.start] returns a pointer to the first element of the array

  - typ constructor: [array: int -> 'a typ -> 'a CArray.t typ]
 *)

let carray_of_zz_list (l : zz list) : integer CArray.t =
  (* inject into the Ocaml representation of an array of integers *)
  (* CArray.of_list integer (List.map integer_of_zz l) *)
  let integers = List.map integer_of_zz l in
  let result = CArray.of_list (ptr char) integers in
  log "carray_of_zz_list:";
  CArray.iter (fun x -> log "%s, " (Ctypes.string_of integer x)) result;
  log "@\n";
  result

(*
let carray_of_zz_matrix (l : zz list list) : integer CArray.t * integer list =
  let well_formed l =
    if l = [] then invalid_arg "carray_of_zz_matrix: empty matrix"
    else
      let len = List.length (List.hd l) in
      List.for_all (fun r -> List.length r = len) l
  in
  if well_formed l then
    let mat = List.concat l in
    carray_of_zz_list mat
  else
    invalid_arg "carray_of_zz_matrix: malformed matrix"
*)

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

let zz_list_of_carray (arr: integer CArray.t) : zz list =
  (* List.map zz_of_integer (CArray.to_list arr) *)
  let ptr = CArray.start arr in
  let len = CArray.length arr in
  let l = List.hd (gather_as_matrix 1 len ptr) in
  List.map zz_of_integer l

(*
let zz_matrix_of_carray (arr: integer CArray.t) (num_cols : int) : zz list list =
  let ctr = ref num_cols in
  let adjoin x ll =
    if !ctr = 0 then ((ctr := num_cols - 1); [zz_of_integer x] :: ll)
    else
      ((ctr := !ctr - 1);
       if ll = [] then [[zz_of_integer x]]
       else
         (zz_of_integer x :: List.hd ll) :: (List.tl ll)) in
  let l = CArray.fold_right adjoin arr [] in
  (* Format.printf "num_cols: %d, ctr = %d\n" num_cols !ctr;
     assert (!ctr = 0); true only if arr is non-empty *)
  l
 *)

type 't ffiarray =
  {
    arr : 't CArray.t
  ; values : 't list (* Hold values to prevent garbage collection *)
  }

let ffiarray_of_zz_list l =
  let values = List.map integer_of_zz l in
  let arr = CArray.of_list integer values in
  { arr ; values }

let ffiarray_ptr ffiarr =
  CArray.start ffiarr.arr

let zz_list_of_integer_ffiarray ffiarr =
  List.map zz_of_integer ffiarr.values

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
