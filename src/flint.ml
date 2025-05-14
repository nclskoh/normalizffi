open Ctypes
open FfiLib

let slong_of_int x = Signed.Long.of_int64 (Int64.of_int x)

(* Just to load in Flint *)
external dummy : unit -> unit = "matrix_from_string_array"

let debug = ref false

let logf fmt fmt_str =
  if !debug then Format.fprintf fmt fmt_str
  else Format.ifprintf fmt fmt_str

let log fmt_str = logf Format.std_formatter fmt_str

let set_debug flag =
  debug := flag;
  let f = C.Functions.Flint.debug_flint in
  if flag then
    begin
      f 1;
      FfiLib.set_debug true;
    end
  else
    begin
      f 0;
      FfiLib.set_debug false
    end

let hermitize = C.Functions.Flint.hermitize

let extend_hnf_to_basis = C.Functions.Flint.extend_hnf_to_basis

let matrix_inverse = C.Functions.Flint.matrix_inverse

let matrix_multiply = C.Functions.Flint.matrix_multiply

let _reshape num_cols l =
  if num_cols <= 0 then
    invalid_arg "Flint: reshape: number of columns in a matrix must be positive"
  else
    let d = List.length l in
    let rec go l matrix idx =
      match l with
      | [] ->
         if idx <> 0 then
           begin
             Format.fprintf
               Format.str_formatter
               "Flint: list of length %d cannot be reshaped into a matrix with %d columns"
               d num_cols;
             let s = Format.flush_str_formatter () in
             invalid_arg s
           end
         else
           matrix
      | (x :: xs) ->
         if idx = 0 then
           go xs ([x] :: matrix) (if num_cols = 1 then 0 else 1)
         else if idx = num_cols - 1 then
           let row = List.rev (x :: List.hd matrix) in
           go xs (row :: List.tl matrix) 0
         else
           go xs ((x :: List.hd matrix) :: List.tl matrix) (idx + 1)
    in
    List.rev (go l [] 0)

let zz_matrix_of_matrix (mat_ptr : C.Types.rational_matrix_ptr) : zz list list =
  let two_dim_arr = !@ (C.Functions.Flint.matrix_to_two_dim_array mat_ptr) in
  zz_matrix_of_two_dim_array two_dim_arr

let denom_of_matrix (mat_ptr : C.Types.rational_matrix_ptr): zz =
  let denom = C.Functions.Flint.matrix_denom mat_ptr in
  zz_of_integer denom

let denom_matrix_of_rational_matrix (rm_ptr : C.Types.rational_matrix_ptr)
    : zz * zz list list =
  if is_null rm_ptr then
    invalid_arg "Flint: rational matrix pointer is null"
  else
    (denom_of_matrix rm_ptr, zz_matrix_of_matrix rm_ptr)
  
let new_matrix (generators : zz list list): C.Types.rational_matrix_ptr =
  log "normalizffi: Flint: new_matrix: serializing: @[%a@]@;" pp_list_list generators;
  let arr = integer_array_of_zz_list (List.concat generators) in
  (* let denom = wrapped_integer_of_zz (Mpzf.of_int 1) in *)
  let denom = wrapped_integer_of_zz (Z.of_int 1) in
  let num_rows = List.length generators in
  let num_cols = if num_rows = 0 then 0 else List.length (List.hd generators) in
  let mat = C.Functions.Flint.matrix_from_string_array
              (integer_array_start arr)
              (slong_of_int num_rows) (slong_of_int num_cols)
              (wrapped_integer_start denom) in
  FfiLib.free_integer_array arr;
  FfiLib.free_wrapped_integer denom;
  mat

let rank (mat_ptr : C.Types.rational_matrix_ptr) =
  C.Functions.Flint.rank mat_ptr |> Signed.Long.to_int64 |> Int64.to_int

let transpose (mat_ptr : C.Types.rational_matrix_ptr) =
   C.Functions.Flint.transpose mat_ptr

let solve matA matB =
  let solved = C.Functions.Flint.solve matA matB in
  if is_null solved then
    invalid_arg "Flint: Failed to solve matrix equation. 
                 Check if the matrix is non-singular."
  else
    solved
