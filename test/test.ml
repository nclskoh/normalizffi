open Normalizffi
open OUnit

let () = Normaliz.set_debug true

let ( let* ) o f =
  match o with
  | Ok x -> f x
  | Error e -> Error e

let ( |>* ) x f =
  match x with
  | Ok x -> f x
  | Error e -> Error e

let pp_list_list fmt =
  let pp_comma fmt () = Format.fprintf fmt ", " in
  Format.fprintf fmt "@[<v 0>%a@]"
    (Format.pp_print_list
       (Format.pp_print_list ~pp_sep:pp_comma
          (fun fmt x -> Format.fprintf fmt "%s" (Z.to_string x)))
    )

let is_subset eq l1 l2 =
  let is_in x l = List.fold_left (fun b y -> b || eq x y) false l in
  let all_in = List.fold_left (fun b x -> b && is_in x l2) true l1 in
  all_in

let is_eq eq l1 l2 = is_subset eq l1 l2 && is_subset eq l2 l1

let vector_eq v1 v2 = is_eq (=) v1 v2

let vectors_subseteq l1 l2 = is_subset vector_eq l1 l2
let vectors_eq l1 l2 = is_eq vector_eq l1 l2

let ( === ) l1 l2 = vectors_eq l1 l2

let zzify l = List.map (fun r -> List.map Z.of_int r) l

module HelperTests = struct

  let test_int () =
    let m i = Z.of_int i in
    let l1 = [ m 1; m 2; m 3 ] in
    let l2 = [ m 3; m 2; m 4; m 1] in
    "test_int" @? is_subset (=) l1 l2

  let test1 () =
    "test1" @?
      vectors_subseteq
        (zzify [[1; 2; 3]; [4 ; 5; 6]])
        (zzify ([[1; 3; 2]; [4 ; 6 ; 5]; [7; 8; 9]]))

  let suite = "HelperTests" >::: [
        "test_int" >:: test_int
      ; "test1" >:: test1 ]

end

module NormalizHelper = struct

  open Normaliz

  type standard_cone_data =
    { rays : Z.t list list
    ; lineality : Z.t list list
    ; inequalities : Z.t list list
    ; equations : Z.t list list
    ; embedding_dimension : int
    }

  type inhomogeneous_cone_data =
    { vertices : Z.t list list
    ; dehomogenization : Z.t list list
    }

  type hull_data =
    { hull_inequalities : Z.t list list
    ; hull_equations : Z.t list list
    }

  let get_standard_data ptr =
    { rays = get_extreme_rays ptr
    ; lineality = get_lineality_space ptr
    ; inequalities = get_inequalities ptr
    ; equations = get_equations ptr
    ; embedding_dimension = get_embedding_dimension ptr
    }

  let get_hom_data = get_standard_data

  let get_inhom_data ptr =
    { vertices = get_vertices ptr
    ; dehomogenization = get_dehomogenization ptr
    }

  let get_hull_data ptr =
    {
      hull_inequalities = get_int_hull_inequalities ptr
    ; hull_equations = get_int_hull_equations ptr
    }

  let standard_data_eq d1 d2 =
    d1.rays === d2.rays
    && d1.lineality === d2.lineality
    && d1.inequalities === d2.inequalities
    && d1.equations === d2.equations
    && d1.embedding_dimension = d2.embedding_dimension

  let inhom_data_eq d1 d2 =
    d1.vertices === d2.vertices
    && d1.dehomogenization === d2.dehomogenization

  let hull_data_eq d1 d2 =
    d1.hull_inequalities === d2.hull_inequalities
    && d1.hull_equations === d2.hull_equations

end


module NormalizTests = struct

  open Normaliz
  open NormalizHelper

  let dummy () = ()

  let triangle_vertical_integer_hull k =
    (*
       x >= 0
       x + ky <= k
       x - ky <= 0
     *)
    let constraints = [ [0; 1 ; 0]
                      ; [k; -1 ; -k]
                      ; [0; -1; k] ]
                      |> List.map (fun r -> List.map Z.of_int r) in
    empty_cone |> add_inequalities constraints |> Result.get_ok

  let expected_triangle_vertical_integer_hull k =
    let std_data = { rays = zzify [ [1; 0; 0]
                                  ; [1; 0; 1]
                                  ; [2; k ; 1] ]
                   ; lineality = []
                   ; inequalities = zzify [ [0; 1 ; 0]
                                          ; [k; -1 ; -k]
                                          ; [0; -1; k] ]
                   ; equations = []
                   ; embedding_dimension = 3
                   } in
    let inhom_data = { vertices = zzify [ [1; 0; 0]
                                        ; [1; 0; 1]
                                        ; [2; k; 1] ]
                     ; dehomogenization = zzify [[1 ; 0; 0]]
                     } in
    let hull_data = { hull_inequalities = zzify [ [0 ; 0; 1]
                                                ; [1; 0; -1] ]
                    ; hull_equations = zzify [[0; 1; 0]]
                    } in
    (std_data, inhom_data, hull_data)

  let (===) d1 d2 =
    let (std1, inhom1, hull1) = d1 in
    let (std2, inhom2, hull2) = d2 in
    standard_data_eq std1 std2
    && inhom_data_eq inhom1 inhom2
    && hull_data_eq hull1 hull2

  let test_vertical_integer_hull k () =
    let p = new_cone (triangle_vertical_integer_hull k) in
    let std = get_hom_data p in
    let _hb = hilbert_basis p in
    let dp = dehomogenize p in
    let inhom = get_inhom_data dp in
    hull dp;
    let hull = get_hull_data dp in
    (Format.sprintf "vertical_integer_hull %d" k)
    @? ((std, inhom, hull) === expected_triangle_vertical_integer_hull k)

  let positive_parallelogram_and_lineality =
    (*
      In 2D, (1/2, 1) and (1, 1/2) form the sides of a parallelogram with
      a single non-zero integer point (1, 1).
      Doubled, we have (1, 2), (2, 1), (1, 1) as the Hilbert basis.
      When the span is the entire 2D plane, the Hilbert basis should be
      the standard basis.
     *)
    let rays = zzify [ [2;  0;  0; 0; 0]
                     ; [0;  1;  2; 0; 0]
                     ; [0; -1; -2; 0; 0]
                     ; [0;  2;  1; 0; 0]
                     ; [0; -2; -1; 0; 0]
                     ; [0;  0;  0; 1; 2]
                     ; [0;  0;  0; 2; 1]
                 ] in
    empty_cone |> add_rays rays |> Result.get_ok

  let expected_positive_parallelogram_and_lineality =
    let std_data = { rays = zzify [ [1; 0; 0; 0; 0]
                                  ; [0; 0; 0; 1; 2]
                                  ; [0; 0; 0; 2; 1] ]
                   ; lineality = zzify [ [0; 1; 0; 0; 0 ]
                                       ; [0; 0; 1; 0; 0 ]]
                   ; inequalities = zzify [ [1; 0 ; 0; 0; 0]
                                          ; [0; 0; 0; -1 ; 2]
                                          ; [0; 0; 0; 2; -1] ]
                   ; equations = []
                   ; embedding_dimension = 5
                   } in
    let inhom_data = { vertices = zzify [ [1; 0; 0; 0; 0] ]
                     ; dehomogenization = zzify [[1 ; 0; 0; 0; 0]]
                     } in
    (* Original generators already pass through integer points *)    
    let hull_data = { hull_inequalities = zzify [ [0 ; 0; 0; -1; 2]
                                                ; [0; 0; 0; 2; -1]
                                                ; [1; 0; 0; 0; 0]]
                    ; hull_equations = []
                    } in
    let hilbert_basis = zzify [ [0; 0; 0; 1; 1]
                              ; [0; 0; 0; 1; 2]
                              ; [0; 0; 0; 2; 1]
                              ; [1; 0; 0; 0; 0] ]
    in
    (* The second part of the Hilbert basis, when the cone is not pointed *)
    let maximal_subspace_generators = zzify [ [0; 1; 0; 0; 0]
                                            ; [0; 0; 1; 0; 0] ] in
    (std_data, inhom_data, hull_data, hilbert_basis, maximal_subspace_generators)

  let test_positive_parallelogram_and_lineality () =
    let p = new_cone positive_parallelogram_and_lineality in
    let std = get_hom_data p in
    let hb = hilbert_basis p in
    let maximal = get_lineality_space p in
    let dp = dehomogenize p in
    let inhom = get_inhom_data dp in
    hull dp;
    let hull = get_hull_data dp in
    let (estd, einhom, ehull, ehb, emaximal) =
      expected_positive_parallelogram_and_lineality in
    "positive_parallelogram_and_lineality"
    @? ((std, inhom, hull) === (estd, einhom, ehull)
        && (vectors_eq hb ehb) && (vectors_eq maximal emaximal))

  let print_cone c =
    let p = new_cone c in
    Format.printf "Homogeneous: @[%a@]@." pp_hom p;
    let hb = hilbert_basis p in
    Format.printf "Hilbert basis: @[%a@]@." pp_list_list hb;
    let dp = dehomogenize p in
    Format.printf "Dehomogenized: @[%a@]@." pp_inhom dp;
    hull dp;
    Format.printf "Hull: @[%a@]@." pp_hull dp

  let test_cone () =
    print_cone positive_parallelogram_and_lineality

  let suite = "Normaliz tests" >::: [
        "test_triangle_with_vertical_hull 3" >:: test_vertical_integer_hull 3
      ; "test_positive_parallelogram_and_lineality" >:: test_positive_parallelogram_and_lineality
      ; "new_cone" >:: test_cone
      ]

end

let test_normaliz () =
  let rational_triangle_gens =
    (* 2D triangle with points (0, 0), (0, 3/2), (3/2, 0) in the x-y plane *)
    (* Homogenize in the first coordinate, lineality in the last coordinate *)
    let tri_gens = [[1; 0; 0; 0]; [2; 0; 3; 0]; [2; 3; 0; 0]] in
    let lineality_gens = [[0; 0; 0; 1]; [0; 0; 0; -1]] in
    List.map (fun l -> List.map Z.of_int l) (List.concat [tri_gens; lineality_gens]) in
  let* c1 = Normaliz.empty_cone |> Normaliz.add_rays rational_triangle_gens in
  let c1_ptr = Normaliz.new_cone c1 in
  Format.printf "test1: %a\n" Normaliz.pp_hom c1_ptr;
  Result.ok c1_ptr


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
               ] |> List.map (List.map Z.of_int)
  in
  let cone = Normaliz.empty_cone
             |> Normaliz.add_inequalities matrix
             |> Result.get_ok
             |> Normaliz.new_cone
             |> Normaliz.dehomogenize in
  Normaliz.hull cone;
  let inequalities = Normaliz.get_int_hull_inequalities cone in
  let equations = Normaliz.get_int_hull_equations cone in
  Format.printf "Calypto hull: @[<v 0>inequalities: @[%a@]@; equalities: @[%a@]@]@;"
    pp_list_list inequalities
    pp_list_list equations
