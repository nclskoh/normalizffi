#ifndef __NORMALIZ_STUB_H
#define __NORMALIZ_STUB_H

#include "libnormaliz/libnormaliz.h"
#include "stub_common.h"

using namespace libnormaliz;

extern "C" {

  typedef mpz_class Integer;

  Cone<Integer>* new_cone(char** cone_generators,
			  size_t num_cone_gens,
			  char** subspace_generators,
			  size_t num_subspace_gens,
			  char** inequalities,
			  size_t num_inequalities,
			  char** lattice_equations,
			  size_t num_lattice_equations,
			  char** excluded_face_inequalities,
			  size_t num_excluded_faces,
			  size_t dimension);

  Cone<Integer>* intersect_cone(Cone<Integer> *c1, Cone<Integer> *c2);

  Cone<Integer>* dehomogenize(Cone<Integer>* c);

  void hull(Cone<Integer>* c);

  two_dim_array* get_extreme_rays(Cone<Integer>* c);

  two_dim_array* get_vertices(Cone<Integer>* c);

  two_dim_array* get_lineality_space(Cone<Integer>* c);

  two_dim_array* get_original_monoid_generators(Cone<Integer>* c);

  two_dim_array* get_inequalities(Cone<Integer>* c);

  two_dim_array* get_equations(Cone<Integer>* c);

  two_dim_array* get_congruences(Cone<Integer>* c);

  two_dim_array* get_dehomogenization(Cone<Integer>* c);

  size_t get_embedding_dimension(Cone<Integer>* c);

  two_dim_array* get_integer_hull_inequalities(Cone<Integer>* c);

  two_dim_array* get_integer_hull_equations(Cone<Integer>* c);

  bool is_pointed(Cone<Integer>* c);

  bool is_inhomogeneous(Cone<Integer>* c);

  // For a semiopen polyhedron, determine if it is empty
  bool is_empty_semiopen(Cone<Integer>* c);

  bool is_semiopen(Cone<Integer>* c);

}

#endif
