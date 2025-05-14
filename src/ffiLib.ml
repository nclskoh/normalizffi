open Ctypes
open WrappedPointer

include C.Types

let ( let* ) o f =
  match o with
  | Ok x -> f x
  | Error e -> Error e

let debug = ref false

let set_debug flag =
  debug := flag

(*
let logf fmt fmt_str =
  if !debug then Format.fprintf fmt fmt_str
  else Format.ifprintf fmt fmt_str

let log fmt_str = logf Format.std_formatter fmt_str
 *)

(* type zz = Mpzf.t *)

type zz = Z.t

(** An integer is wrapped with the Ocaml value keeping its string contents
    alive. *)
type wrapped_integer = char WrappedArray.t

type integer_array =
  { wrapped_ptr : WrappedArray.pointer WrappedArray.t
  ; arr_len : int
  }

let wrapped_integer_start p = WrappedArray.unwrap p

let free_wrapped_integer p = WrappedArray.free p

let wrapped_integer_of_zz x = Z.to_string x |> WrappedArray.make_string

let deserialize_int (x : char ptr) : string =
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

let zz_of_integer ptr =
  let s = deserialize_int ptr in
  Z.of_string s

let size_t_of_int = Unsigned.Size_t.of_int
let int_of_size_t x = Int64.to_int (Unsigned.Size_t.to_int64 x)

let integer_array_of_zz_list (l : zz list) : integer_array =
  let wrapped_ptr =
    WrappedArray.make_array
      (List.map (fun x -> WrappedArray.make_string (Z.to_string x)) l) in
  { wrapped_ptr ; arr_len = List.length l }

let integer_array_start { wrapped_ptr ; _ } =
  WrappedArray.unwrap wrapped_ptr

let free_integer_array { wrapped_ptr ; _ } =
  WrappedArray.free wrapped_ptr

(*
let gather_as_matrix
      (num_rows : int) (num_cols : int) (ptr : 'a WrappedArray.t) : 'a list list =
  let get_row i =
    let idx = i * num_cols in
    let rec go_col j l =
      if j = num_cols then List.rev l
      else
        let value = WrappedArray.read ptr (idx + j) in
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
  let l = List.hd (gather_as_matrix 1 arr.arr_len arr.wrapped_ptr) in
  List.map zz_of_integer l
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

let zz_matrix_of_two_dim_array (arr : two_dim_array structure) : zz list list =
  let m = int_of_size_t (getf arr two_dim_array_nrows) in
  let n = int_of_size_t (getf arr two_dim_array_ncols) in
  let data = getf arr two_dim_array_data in
  let cast p = Ctypes.from_voidp (ptr char) p in
  let mat = gather_as_matrix m n (cast data) in
  List.map (fun r -> List.map (fun x -> Z.of_string (deserialize_int x)) r) mat

let zz_matrix_of_int_matrix m : zz list list =
  List.map (List.map Z.of_int) m

let pp_list_list fmt =
  let pp_comma fmt () = Format.fprintf fmt ", " in
  Format.fprintf fmt "@[<v 0>%a@]"
    (Format.pp_print_list
       (Format.pp_print_list ~pp_sep:pp_comma
          (fun fmt x -> Format.fprintf fmt "%s" (Z.to_string x)))
    )
