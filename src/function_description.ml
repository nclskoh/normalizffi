module Types = Types_generated

module Functions (F : Ctypes.FOREIGN) = struct

  open Ctypes
  open F

  open Types

  module Memory = struct

    let alloc = foreign "normalizffi_alloc" (int @-> int @-> returning (ptr void))

    let free = foreign "normalizffi_free" (ptr void @-> returning void)

  end

  module Flint = struct

    let debug_flint = foreign "debug_flint" (int @-> returning void)

    let matrix_from_string_array =
      foreign "matrix_from_string_array" (ptr void @-> slong @-> slong
                                          @-> ptr void
                                          @-> returning rational_matrix_ptr)

    let hermitize =
      foreign "make_hnf" (rational_matrix_ptr @-> returning void)

    let matrix_to_two_dim_array =
      foreign "matrix_contents"
        (rational_matrix_ptr @-> returning (ptr Types.two_dim_array))

    let matrix_denom =
      foreign "matrix_denominator" (rational_matrix_ptr @-> returning integer)

    let extend_hnf_to_basis =
      foreign "extend_hnf_to_basis"
        (rational_matrix_ptr @-> returning rational_matrix_ptr)

    let matrix_inverse =
      foreign "matrix_inverse"
        (rational_matrix_ptr @-> returning rational_matrix_ptr)

    let matrix_multiply =
      foreign "matrix_multiply" (rational_matrix_ptr @->
                                   rational_matrix_ptr @->
                                     returning rational_matrix_ptr)

    let rank = foreign "rank" (rational_matrix_ptr @-> returning slong)

    let transpose = foreign "transpose"
                      (rational_matrix_ptr @-> returning rational_matrix_ptr)

    let solve = foreign "solve" (rational_matrix_ptr
                                 @-> rational_matrix_ptr
                                 @-> returning rational_matrix_ptr)

  end

  module Normaliz = struct

    let debug_normaliz = foreign "debug_normaliz" (int @-> returning void)

    let new_cone = foreign "new_cone"
                     (ptr integer @-> size_t (* cone generators *)
                      @-> ptr integer @-> size_t (* subspace generators *)
                      @-> ptr integer @-> size_t (* inequalities *)
                      @-> ptr integer @-> size_t (* lattice generators *)
                      @-> ptr integer @-> size_t (* lattice equations *)
                      @-> ptr integer @-> size_t (* excluded faces *)
                      @-> size_t (* dimension *)
                      @-> returning cptr)

    let get_embedding_dimension =
      foreign "get_embedding_dimension" (cptr @-> returning size_t)

    let intersect_cone =
      foreign "intersect_cone" (cptr @-> cptr @-> returning cptr)

    let dehomogenize =
      foreign "dehomogenize" (cptr @-> returning cptr)

    let hull = foreign "hull" (cptr @-> returning void)

    let get_property name =
      foreign name (cptr @-> returning (ptr Types.two_dim_array))

    let get_extreme_rays = get_property "get_extreme_rays"

    let get_lineality_space = get_property "get_lineality_space"

    let get_inequalities = get_property "get_inequalities"

    let get_equations = get_property "get_equations"

    let get_congruences = get_property "get_congruences"

    let get_vertices = get_property "get_vertices"

    let get_integer_hull_inequalities = get_property "get_integer_hull_inequalities"
    let get_integer_hull_equations = get_property "get_integer_hull_equations"
    let get_integer_hull_vertices = get_property "get_integer_hull_vertices"
    let get_integer_hull_extreme_rays = get_property "get_integer_hull_extreme_rays"
    let get_integer_hull_lineality_space = get_property "get_integer_hull_lineality_space"

    let get_dehomogenization = get_property "get_dehomogenization"
    let get_hilbert_basis = get_property "get_hilbert_basis"

    let is_empty_semiopen = foreign "is_empty_semiopen" (cptr @-> returning bool)

  end


end
