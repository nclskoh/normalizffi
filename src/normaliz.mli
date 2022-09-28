(** Interfacing with Normaliz library. *)

open FfiLib

(** Ocaml representation of a cone;
    'a is the type of the entries of generators and constraints of the cone.
 *)
type 'a cone

(** Pointer to a Normaliz cone in C++ *)

(** A pointer to a cone.

    A homogeneous cone is just a cone; it is {x: Ax >= 0} for some A.

    An inhomogeneous cone is a homogeneous cone intersected with the constraint
    x0 = 1, so an inhomogeneous cone defines a polyhedron.
    Constraints of the inhomogeneous cone such as inequalities and equalities
    are the constraints of this polyhedron, by reading the x0 component as 1.
    Generators of the inhomogeneous cone such as extreme rays, lineality space
    generators, and vertices are the generators of this polyhedron by firstly,
    normalizing each vector to get 1 in the x0 component (possibly getting
    fractional entries as a result), and secondly, by dropping the x0 component.

    Note that the constraint x0 = 1 cannot be explicitly expressed because a
    homogeneous cone only allows linear forms and not affine forms,
    and hence does not show up among the equations of an inhomogeneous cone.
    (This is also why we cannot define a polyhedron ourselves by just adding
    this constraint to a cone.)

    A cone_ptr points to either a homogeneous cone or an inhomogeneous one.
 *)
type homogeneous
type inhomogeneous

(** Phantom type with 'a being homogeneous or inhomogeneous *)
type 'a cone_ptr

val set_debug : bool -> unit

(** Create an empty cone *)
val empty_cone : Mpzf.t cone

(** Add conic generators of a cone, to the cone, provided that dimensions match. *)
val add_rays : Mpzf.t list list -> Mpzf.t cone -> (Mpzf.t cone, string) result

(** Add generators of a subspace to the cone, provided that dimensions match.
    This is the same as [add_generators] applied to a list of vectors and their
    negation. *)
val add_subspace_generators : Mpzf.t list list -> Mpzf.t cone ->
                              (Mpzf.t cone, string) result

(** Add inequalities each of the form [a0; a1; a2; ...; an] representing
    a0 x0 + a1 x1 + ... + an xn >= 0, to the cone, provided that dimensions match. *)
val add_inequalities : Mpzf.t list list -> Mpzf.t cone -> (Mpzf.t cone, string) result

(** Add equalities each of the form [a0; a1; a2; ...; an] representing
    a0 x0 + a1 x1 + ... + an xn = 0, to the cone, provided that dimensions match. *)
val add_equalities : Mpzf.t list list -> Mpzf.t cone  -> (Mpzf.t cone, string) result

(** Add lattice equations, each of the form [a0; a1; a2; ...; an] representing
    a0 x0 + a1 x1 + ... + an xn = 0, provided that dimensions match.
    Mathematically, the output cone is the input cone intersected
    with these equations. However, Normaliz can be sneaky and add a positive
    orthant constraint if the cone only has these equations, and this is one
    of other behaviors yet to be figured out. Hence, it is best to avoid these;
    add equations as two inequalities using [add_inequalities] instead.
*)
val add_lattice_equations : Mpzf.t list list -> Mpzf.t cone ->
                            (Mpzf.t cone, string) result

(** Add inequalities each of the form [a0; a1; a2; ...; an] representing
    a0 + a1 x1 + ... + an xn > 0, to the cone, provided that dimensions match. *)
val add_excluded_face_inequalities : Mpzf.t list list -> Mpzf.t cone -> 
                                     (Mpzf.t cone, string) result

(** Construct a cone in Normaliz. *)
val new_cone : zz cone -> homogeneous cone_ptr

(** For ctypes to link properly. *)
val dummy_new_cone : unit -> unit

(** Intersect two cones *)
val intersect_cone : homogeneous cone_ptr -> homogeneous cone_ptr ->
                     (homogeneous cone_ptr, string) result

(** Construct a new cone whose constraints (inequalities and equalities)
    are the generators of the input cone. *)
val generators_to_constraints : homogeneous cone_ptr -> homogeneous cone_ptr

(** Dehomogenize the cone by adding an implicit constraint x0 = 1, where x0
    is the first coordinate. The result points to a polyhedron that is
    obtained by intersecting the homogeneous cone with x0 = 1.
*)
val dehomogenize : homogeneous cone_ptr -> inhomogeneous cone_ptr

(** Given an inhomogeneous cone obtained through [dehomogenize],
    hence representing a polyhedron, compute the integer hull of the polyhedron.
*)
val hull : inhomogeneous cone_ptr -> unit


(** Get the unique Hilbert Basis of the salient cone obtained by quotienting
    out the lineality space (but still residing in the same ambient space).
    The Hilbert basis for the cone is this result together with the lineality
    space generators obtained through [get_lineality_space].
*)
val hilbert_basis : homogeneous cone_ptr -> zz list list

(** Get the conic generators of a homogeneous cone or a polyhedron
    (inhomogeneous cone). Note that these extreme rays do not
    include generators of the lineality space, which have to be obtained
    separately via [get_lineality_space].
*)
val get_extreme_rays : 'a cone_ptr -> zz list list

(** Get the lineality generators of a homogeneous cone or a polyhedron
    (inhomogeneous cone). The linear combination of these generators is a
    (maximal) subspace within the object. Note that purely conic generators are
    not among these; they have to be separately obtained via [get_extreme_rays].
*)
val get_lineality_space : 'a cone_ptr -> zz list list

(** Get the inequalities that define the homogeneous cone or polyhedron.
    Note that these do not include equations, i.e., two-sided inequalities,
    which have to be obtained separately using [get_equations]. *)
val get_inequalities : 'a cone_ptr -> zz list list

(** Get the equations (two-sided inequalities) defining the cone. *)
val get_equations : 'a cone_ptr -> zz list list

(** Get the vertices of the polyhedron defined by the homogeneous cone
    intersected with the dehomogenizing constraint x0 = 1. *)
val get_vertices : inhomogeneous cone_ptr -> zz list list

val get_dehomogenization : inhomogeneous cone_ptr -> zz list list

(** The integer hull MUST first be computed using [hull].
    Get the inequalities defining the integer hull of the polyhedron defined
    by the homogeneous cone intersected with the dehomogenizing constraint
    x0 = 1.  Note that these do not include equations, i.e., two-sided
    inequalities, that define the hull. They have to be obtained via
    [get_int_hull_equations] separately. *)
val get_int_hull_inequalities : inhomogeneous cone_ptr -> zz list list

(** The integer hull MUST first be computed using [hull].
    Get the equations (two-sided inequalities) defining the integer hull of the
    polyhedron defined by the homogeneous cone intersected with the dehomogenizing
    constraint x0 = 1. Note that these do not include one-sided inequalities,
    which have to be obtained separately via [get_int_hull_inequalities].
  *)
val get_int_hull_equations : inhomogeneous cone_ptr -> zz list list

val get_embedding_dimension : 'a cone_ptr -> int

val is_empty : inhomogeneous cone_ptr -> bool

(** This is exported for testing purposes only. *)
val is_empty_semiopen : homogeneous cone_ptr -> bool

(* val is_semiopen: homogeneous_cone_ptr -> bool *)

(** Determine if a vector is contained in a cone or not.
    Fails if the dimension of the vector doesn't match the dimension of the
    cone. *)
val contains : homogeneous cone_ptr -> zz list -> (bool, string) result

val pp_hom : Format.formatter -> homogeneous cone_ptr -> unit
val pp_inhom : Format.formatter -> inhomogeneous cone_ptr -> unit
val pp_hull : Format.formatter -> inhomogeneous cone_ptr -> unit

val pp_cone : Format.formatter -> zz cone -> unit

val print_hull_constraints :
  string -> zz list list * zz list list -> unit
