open Normalizffi
(* open FfiLib *)
(* open Normaliz *)

let ( let* ) o f =
  match o with
  | Ok x -> f x
  | Error e -> Error e

let pp_list_list fmt l =
  let p = List.iter (fun x -> Format.fprintf fmt "%s, " (Mpzf.to_string x)) in
  List.iter (fun x -> p  x; Format.fprintf fmt "\n") l

let test_normaliz () =
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
  let () = Flint.set_debug true in
  let zzify = List.map Mpzf.of_int in
  let rec e n i =
    if n = 0 then [] else if i = 0 then (1 :: e (n-1) (i-1)) else (0 :: e (n-1) (i-1))
  in
  let rec diagonal m n i =
    if m = 0 then [] else (e n i) :: diagonal (m-1) n (i + 1) in
  let rec go n =
    if n = 0 then ()
    else
      let mat = List.map zzify (diagonal n n 0) in
      let () = Format.printf "matrix: @[<v 0>%a@]@;" pp_list_list mat in
      let mat = Flint.new_matrix mat in
      Flint.hermitize mat;
      let rank = Flint.rank mat in
      let rec take n l =
        if n = 0 then [] else
          match l with
          | [] -> []
          | (x :: l) -> x :: take (n-1) l in
      let _result =
        Flint.denom_matrix_of_rational_matrix mat
        |> snd
        |> take rank (* The rows after rank should be all zeros *)
      in
      go (n-1)
  in
  go 15

let test_qfnia_calypto_000797 () =
  (*
    0 0 0 0 0 1
    0 0 0 0 1 0
    0 0 0 1 0 0
    0 0 1 0 0 0
    0 1 0 0 0 0
    127 0 0 -1 0 0
    127 0 0 0 -1 0
    255 0 -1 0 0 0
    255 0 0 0 0 -1
    134217728 -1 0 0 0 0
   *)
  Normaliz.set_debug true;
  let matrix = [ [0; 0; 0; 0; 0; 1]
               ; [0; 0; 0; 0; 1; 0]
               ; [0; 0; 0; 1; 0; 0]
               ; [0; 0; 1; 0; 0; 0]
               ; [0; 1; 0; 0; 0; 0]
               ; [127; 0; 0; -1; 0; 0]
               ; [127; 0; 0; 0; -1; 0]
               ; [255; 0; -1; 0; 0; 0]
               ; [255; 0; 0; 0; 0; -1]
               ; [134217728; -1; 0; 0; 0; 0]
               ] |> List.map (List.map Mpzf.of_int)
  in
  let cone = Result.get_ok (Normaliz.add_inequalities Normaliz.empty_cone matrix)
             |> Normaliz.new_cone
             |> Normaliz.dehomogenize in
  Normaliz.hull cone;
  let inequalities = Normaliz.get_int_hull_inequalities cone in
  let equations = Normaliz.get_int_hull_equations cone in
  Format.printf "Calypto hull: @[<v 0>inequalities: @[%a@]@; equalities: @[%a@]@]@;"
    pp_list_list inequalities
    pp_list_list equations

let test_gc () =
  Flint.set_debug true;
  let matrix = [ [0; 0; 0; 0; 0; 1]
               ; [0; 0; 0; 0; 1; 0]
               ; [0; 0; 0; 1; 0; 0]
               ; [0; 0; 1; 0; 0; 0]
               ; [0; 1; 0; 0; 0; 0]
               ; [127; 0; 0; -1; 0; 0]
               ; [127; 0; 0; 0; -1; 0]
               ; [255; 0; -1; 0; 0; 0]
               ; [255; 0; 0; 0; 0; -1]
               ; [134217728; -1; 0; 0; 0; 0]
               ] |> List.map (List.map Mpzf.of_int)
  in
  Flint.new_matrix matrix

let () =
  Format.printf "Hello world\n";
  (* ignore (test_normaliz ()); *)
  (* ignore (test_flint ()) *)
  (* ignore (test_qfnia_calypto_000797 ()) *)
  ignore (test_gc ())
