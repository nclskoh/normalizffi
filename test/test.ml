open Normalizffi
(* open FfiLib *)
(* open Normaliz *)

let ( let* ) o f =
  match o with
  | Ok x -> f x
  | Error e -> Error e

let test_normaliz () =
  let () = Flint.set_debug true in
  let rational_triangle_gens =
    (* 2D triangle with points (0, 0), (0, 3/2), (3/2, 0) in the x-y plane *)
    (* Homogenize in the first coordinate, lineality in the last coordinate *)
    let tri_gens = [[1; 0; 0; 0]; [2; 0; 3; 0]; [2; 3; 0; 0]] in
    let lineality_gens = [[0; 0; 0; 1]; [0; 0; 0; -1]] in
    List.map (fun l -> List.map Mpzf.of_int l) (List.concat [tri_gens; lineality_gens]) in
  let* c1 = Normaliz.add_rays Normaliz.empty_cone rational_triangle_gens in
  let c1_ptr = Normaliz.new_cone c1 in
  Format.printf "test1: %a\n" Normaliz.pp_hom c1_ptr;
  Result.ok c1_ptr

let test_flint () =
  let zzify = List.map Mpzf.of_int in
  let mat = Flint.new_matrix (List.map zzify [ [ 1 ; 2 ] ; [ 2 ; 1 ] ]) in
  Flint.hermitize mat;
  let rank = Flint.rank mat in
  let rec take n l =
    if n = 0 then [] else
      match l with
      | [] -> []
      | (x :: l) -> x :: take (n-1) l in
  Flint.zz_denom_matrix_of_rational_matrix mat
  |> snd
  |> take rank (* The rows after rank should be all zeros *)

let () =
  Format.printf "Hello world\n";
  ignore (test_normaliz ());
  ignore (test_flint ())
