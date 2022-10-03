#ifndef __NORMALIZ_STUB_H
#define __NORMALIZ_STUB_H

#include <stdbool.h>
#include "stub_common.h"

void debug_normaliz(int flag);

void compute_using_big_int(int flag);

struct NCone; // To hide C++

typedef struct NCone NCone;

NCone* new_cone(char** cone_generators, size_t num_cone_gens,
		char** subspace_generators, size_t num_subspace_gens,
		char** inequalities, size_t num_inequalities,
		char** lattice_generators, size_t num_lattice_gens,
		char** lattice_equations, size_t num_lattice_equations,
		char** excluded_face_inequalities, size_t num_excluded_faces,
		size_t dimension);

NCone* intersect_cone(NCone *c1, NCone *c2);

NCone* dehomogenize(NCone* c);

void hull(NCone* c);

two_dim_array* get_extreme_rays(NCone* c);

two_dim_array* get_vertices(NCone* c);

two_dim_array* get_lineality_space(NCone* c);

two_dim_array* get_original_monoid_generators(NCone* c);

two_dim_array* get_inequalities(NCone* c);

two_dim_array* get_equations(NCone* c);

two_dim_array* get_congruences(NCone* c);

two_dim_array* get_dehomogenization(NCone* c);

size_t get_embedding_dimension(NCone* c);

two_dim_array* get_integer_hull_inequalities(NCone* c);

two_dim_array* get_integer_hull_equations(NCone* c);

two_dim_array* get_integer_hull_vertices(NCone* c);

two_dim_array* get_integer_hull_extreme_rays(NCone* c);

two_dim_array* get_integer_hull_lineality_space(NCone* c);

two_dim_array* get_hilbert_basis(NCone* c);

two_dim_array* get_module_generators(NCone* c);

bool is_pointed(NCone* c);

bool is_inhomogeneous(NCone* c);

// For a semiopen polyhedron, determine if it is empty
bool is_empty_semiopen(NCone* c);

bool is_semiopen(NCone* c);

#endif
