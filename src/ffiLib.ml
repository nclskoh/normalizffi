open Ctypes

let ( let* ) o f =
  match o with
  | Ok x -> f x
  | Error e -> Error e

type zz = Mpzf.t
type integer = string
let integer = string

let integer_of_zz = Mpzf.to_string
let zz_of_integer = Mpzf.of_string

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
  CArray.of_list integer (List.map integer_of_zz l)

let carray_of_zz_matrix (l : zz list list) : integer CArray.t =
  let mat = List.concat l in
  carray_of_zz_list mat

let zz_list_of_carray (arr: integer CArray.t): zz list =
  List.map zz_of_integer (CArray.to_list arr)

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
  let data = CArray.from_ptr (getf arr two_dim_array_data) (m * n) in
  zz_matrix_of_carray data n

let pp_list_list fmt l =
  let p = List.iter (fun x -> Format.fprintf fmt "%s, " (Mpzf.to_string x)) in
  List.iter (fun x -> p  x; Format.fprintf fmt "\n") l

let zz_matrix_of_int_matrix m : zz list list =
  List.map (List.map Mpzf.of_int) m
