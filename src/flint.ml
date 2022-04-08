open Foreign
open Ctypes
open FfiLib

let slong = long
let slong_of_int x = Signed.Long.of_int64 (Int64.of_int x)

type rational_matrix_ptr = unit ptr
let rational_matrix_ptr = ptr void

external dummy : unit -> unit = "matrix_from_string_array"

let debug = ref false

let devnull = Format.formatter_of_out_channel (open_out "/dev/null")

let logf fmt fmt_str =
  if !debug then Format.fprintf fmt fmt_str
  else Format.fprintf devnull fmt_str

let log fmt_str = logf Format.std_formatter fmt_str

let set_debug flag =
  debug := flag;
  let f = foreign "debug_flint" (int @-> returning void) in
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

let matrix_from_array =
  foreign "matrix_from_string_array" (ptr integer @-> slong @-> slong
                                      @-> integer
                                      @-> returning rational_matrix_ptr)

let hermitize =
  foreign "make_hnf" (rational_matrix_ptr @-> returning void)

let matrix_to_two_dim_array =
  foreign "matrix_contents"
    (rational_matrix_ptr @-> returning (ptr two_dim_array))

let matrix_denom =
  foreign "matrix_denominator" (rational_matrix_ptr @-> returning integer)

let extend_hnf_to_basis =
  foreign "extend_hnf_to_basis"
    (rational_matrix_ptr @-> returning rational_matrix_ptr)

let matrix_inverse =
  foreign "matrix_inverse" (rational_matrix_ptr @-> returning rational_matrix_ptr)

let matrix_multiply =
  foreign "matrix_multiply" (rational_matrix_ptr @->
                             rational_matrix_ptr @->
                             returning rational_matrix_ptr)

let reshape num_cols l =
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

let zz_matrix_of_matrix (mat_ptr : rational_matrix_ptr) : zz list list =
  let two_dim_arr = !@ (matrix_to_two_dim_array mat_ptr) in
  zz_matrix_of_two_dim_array two_dim_arr

let denom_of_matrix (mat_ptr : rational_matrix_ptr): zz =
  let denom = matrix_denom mat_ptr in
  zz_of_integer denom

let zz_denom_matrix_of_rational_matrix (rm_ptr : rational_matrix_ptr)
    : zz * zz list list =
  if is_null rm_ptr then
    invalid_arg "Flint: rational matrix pointer is null"
  else
    (denom_of_matrix rm_ptr, zz_matrix_of_matrix rm_ptr)

let new_matrix (generators : zz list list): rational_matrix_ptr =
  log "normalizffi: Flint: new_matrix: serializing: @[%a@]@;" pp_list_list generators;
  let arr = carray_of_zz_list (List.concat generators) in
  (* let arr = ffiarray_of_zz_list (List.concat generators) in *)
  let num_rows = List.length generators in
  let num_cols = if num_rows = 0 then 0 else List.length (List.hd generators) in

  if !debug then
    begin
      Gc.compact ();
      log "normalizffi: Flint: new_matrix: deserializing input to test...@;";
      (* let inv_arr = zz_list_of_integer_ffiarray arr |> reshape num_cols in *)
      let inv_arr = zz_list_of_carray arr |> reshape num_cols in
      log "normalizffi: Flint: new_matrix: deserialized input: @[%a@]@;" pp_list_list inv_arr
    end
  else
    ();

  let mat = matrix_from_array
              (CArray.start arr)
              (* (ffiarray_ptr arr) *)
              (slong_of_int num_rows) (slong_of_int num_cols)
              (integer_of_zz (Mpzf.of_int 1)) in

  if !debug then
    let (denom, zzmat) = zz_denom_matrix_of_rational_matrix mat in
    log "normalizffi: Flint: new_matrix: checking allocated matrix: denom = %s@; matrix = @[%a@]"
      (Mpzf.to_string denom)
      pp_list_list zzmat
  else
    ();

  mat

let rank (mat_ptr : rational_matrix_ptr) =
  foreign "rank" (rational_matrix_ptr @-> returning slong) mat_ptr
  |> Signed.Long.to_int64 |> Int64.to_int

let transpose (mat_ptr : rational_matrix_ptr) =
  foreign "transpose" (rational_matrix_ptr @-> returning rational_matrix_ptr) mat_ptr

let solve matA matB =
  let solved = foreign "solve" (rational_matrix_ptr
                                @-> rational_matrix_ptr
                                @-> returning rational_matrix_ptr) matA matB in
  if is_null solved then
    invalid_arg "Flint: Failed to solve matrix equation. Check if the matrix is non-singular."
  else
    solved
