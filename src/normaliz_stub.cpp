#include <iostream>
#include <vector>
#include <string>

#include "libnormaliz/libnormaliz.h"
using namespace libnormaliz;

#include "stub_common.h"

typedef mpz_class Integer;

static int debug = 0;

typedef struct NCone {
  Cone<Integer>* v;
} NCone;

void debug_normaliz(int flag) {
  debug = flag;
}

typedef mpz_class Integer;
// typedef long long Integer;

/*
typedef struct two_dim_array {
  ocaml_integer* data;
  size_t num_rows;
  size_t num_cols;
} two_dim_array;
*/

static
vector<vector<Integer> >* vector_of(char** arr, size_t num_rows, size_t num_cols) {
  if(num_rows * num_cols == 0) {
    return nullptr;
  }

  auto result = new vector<vector<Integer> >;

  for(int i = 0; i < num_rows; i++) {
    vector<Integer> v;
    int j = 0;
    for(; j < num_cols; j++) {
      auto n_str = arr[i * num_cols + j];
      try {
	Integer n(n_str, 10);
	v.push_back(n);
      } catch (std::invalid_argument& e) {
	std::cerr << "vector_of: Invalid argument: " << e.what() << ", input: " << n_str << std::endl;
      }
    }
    result->push_back(v);
  }

  return result;
}

static
two_dim_array* two_dim_array_of(const vector<vector<Integer> >& matrix) {
  auto num_rows = matrix.size();
  if(num_rows == 0) {
    return nullptr;
  }

  // WARNING: assume that matrix is well-formed
  auto num_cols = matrix.front().size();
  if(num_cols == 0) {
    return nullptr;
  }

  auto arr = new two_dim_array;
  arr->num_rows = num_rows;
  arr->num_cols = num_cols;
  auto data = new char*[num_rows * num_cols];
  arr->data = data;

  for(int i = 0; i < num_rows; i++) {
    for(int j = 0; j < num_cols; j++) {
      auto str = matrix[i][j].get_str();
      data[i * num_cols + j] = new char[str.length() + 1];
      std::strcpy(data[i * num_cols + j], str.c_str());
    }
  }

  return arr;
}


static
void print_matrix(const vector<vector<Integer> > &matrix) {
  std::cout << "Matrix:" << std::endl;
  for(auto row : matrix) {
    for(auto entry : row) {
      std::cout << entry << " ";
    }
    std::cout << std::endl;
  }
  std::cout << "end matrix" << std::endl;
}

/*
static
vector<Integer>* negate_vector(const vector<Integer> &v) {
  auto result = new vector<Integer>(v.size());
  Integer minus_one{"-1"};

  for(int i = 0; i < v.size(); i++) {
    Integer value{v[i]};
    value *= minus_one;
    result[i] = value;
  }
  return result;
}
*/

extern "C"
Integer* new_integer(const char* s, int base) {
  auto n = new Integer(s, base);
  return n;
}

extern "C"
void print_cone(Cone<Integer>* c0) {
  /* In Normaliz, constraints come from 3 sources: inequalities, equations,
     and congruences.

     - Inequalities (supporting hyperplanes) and equations are the constraints
       for the (homogenizing) cone over the polyhedron P, i.e.,
       when intersected with z = 1 for homogenizing variable z (adjoining the
       constraint), we get the constraints for the polyhedron.

       Note that the dehomogenizing equation z = 1 is not among the
       equations even when the cone has a dehomogenization (when constructed
       with it).

     - Inequalities and congruences are the constraints for the "efficient"
       lattice (c.f., Section 2.1 in Normaliz manual) that reside within the
       cone over P.

     The equations correspond to linear subspaces and hence the lineality
     space of the polyhedron.

     Thus, neither supporting hyperplanes nor equations by themselves are
     sufficient constraints.

     How do you tell that a polyhedron is empty, given the homogenization?
     - When the intersection with the homogenizing constraint z = 1 leads
       to a contradiction. For example, if z = 0 is an equation.
     - Is there an easier form, e.g., 0x + 0y = 1?
  */

  auto num_hyperplanes = c0->getNrSupportHyperplanes();
  auto hyperplanes = c0->getSupportHyperplanes();
  auto num_equations = c0->getNrEquations();
  auto equations = c0->getEquations();
  auto num_cong = c0->getNrCongruences();
  auto congruences = c0->getCongruences();

  std::cout << "Printing cone:" << std::endl;
  std::cout << "There are " << num_hyperplanes
	    << " support hyperplanes:" << std::endl;
  print_matrix(hyperplanes);
  std::cout << "There are " << num_equations
	    << " equations:" << std::endl;
  print_matrix(equations);
  std::cout << "There are " << num_cong
	    << " congruences:" << std::endl;
  print_matrix(congruences);

  auto num_rays = c0->getNrExtremeRays();
  auto rays = c0->getExtremeRays();

  std::cout << "There are " << num_rays
	    << " extreme rays:" << std::endl;
  print_matrix(rays);
}


// See Sections 3.2 and 3.3 in Normaliz manual.
extern "C"
NCone* new_cone(char** cone_generators, size_t num_cone_gens,
		char** subspace_generators, size_t num_subspace_gens,
		char** inequalities, size_t num_inequalities,
		char** lattice_equations, size_t num_lattice_equations,
		char** excluded_face_inequalities, size_t num_excluded_faces,
		size_t dimension)
{
  std::map<InputType, vector<vector< Integer>>> input;

  if(debug) {
    std::cout << "Creating new cone of dimension " << dimension << std::endl;
  }

  auto cone_gens = vector_of(cone_generators, num_cone_gens, dimension);
  auto subspace_gens = vector_of(subspace_generators, num_subspace_gens, dimension);
  auto ineqs = vector_of(inequalities, num_inequalities, dimension);
  auto lattice_eqns = vector_of(lattice_equations, num_lattice_equations, dimension);
  auto excluded_faces = vector_of(excluded_face_inequalities, num_excluded_faces, dimension);
  // auto dehom = vector_of(dehomogenization, dim_dehomogenization);

  if(cone_gens != nullptr) {
    if(debug) {
      std::cout << "Cone generators: " << std::endl << *cone_gens << std::endl;
    }
    input.insert({InputType::cone, *cone_gens});
  }

  if(subspace_gens != nullptr) {
    if(debug) {
      std::cout << "Subspace generators: " << std::endl << *subspace_gens << std::endl;
    }
    input.insert({InputType::subspace, *subspace_gens});
  }

  if(ineqs != nullptr) {
    if(debug) {
      std::cout << "Inequalities: " << std::endl << *ineqs << std::endl;
    }
    input.insert({InputType::inequalities, *ineqs});
  }

  if(lattice_eqns != nullptr) {
    if(debug) {
      std::cout << "Lattice equations: " << std::endl << *lattice_eqns << std::endl;
    }
    input.insert({InputType::equations, *lattice_eqns});
  }

  if(excluded_faces != nullptr) {
      if(debug) {
      std::cout << "Excluded faces: " << std::endl << *excluded_faces << std::endl;
    }
    input.insert({InputType::excluded_faces, *excluded_faces});
  }

  /*
  if(dehom != nullptr) {
    if(debug) {
      std::cout << "Dehomogenization: " << *equations << std::endl;
    }
    input.insert({InputType::dehomogenization, *dehom});
  }
  */

  Cone<Integer>* c = new Cone<Integer>(input);

  if(debug) {
    assert(c != nullptr);
    std::cout << "New cone created.\n" << std::endl;
  }

  NCone* ncone = new NCone;
  ncone->v = c;

  return ncone;
}

extern "C"
NCone* intersect_cone(NCone *nc1, NCone *nc2) {

  Cone<Integer>* c1 = nc1->v;
  Cone<Integer>* c2 = nc2->v;

  if(debug) {
    std::cout << "intersecting..." << std::endl;
  }

  auto hyperplanes1 = c1->getSupportHyperplanes();
  auto equations1 = c1->getEquations();
  auto hyperplanes2 = c2->getSupportHyperplanes();
  auto equations2 = c2->getEquations();

  if(debug) {
    auto num_hyperplanes1 = c1->getNrSupportHyperplanes();
    auto num_hyperplanes2 = c2->getNrSupportHyperplanes();
    auto num_equations1 = c1->getNrEquations();
    auto num_equations2 = c2->getNrEquations();
    std::cout << "Number of equations: ("
	      << num_equations1
	      << ", "
	      << num_equations2
	      << "):"
	      << std::endl;

    std::cout << "Number of supporting hyperplanes: ("
	      << num_hyperplanes1
	      << ", "
	      << num_hyperplanes2
	      << "):"
	      << std::endl;
  }

  /* Equations when given as input are for the lattice and are thus wrong. */
  // vector<vector<Integer> > equations;
  // equations.insert(equations.begin(), equations1.begin(), equations1.end());
  // equations.insert(equations.end(), equations2.begin(), equations2.end());

  // print_matrix(equations);

  vector<vector<Integer> > hyperplanes;
  hyperplanes.insert(hyperplanes.begin(), hyperplanes1.begin(), hyperplanes1.end());
  hyperplanes.insert(hyperplanes.end(), hyperplanes2.begin(), hyperplanes2.end());
  hyperplanes.insert(hyperplanes.end(), equations1.begin(), equations1.end());
  hyperplanes.insert(hyperplanes.end(), equations2.begin(), equations2.end());

  vector<vector<Integer> > negated_equations;
  negated_equations.insert(negated_equations.begin(), equations1.begin(), equations1.end());
  negated_equations.insert(negated_equations.end(), equations2.begin(), equations2.end());

  for(int i = 0; i < negated_equations.size(); i++) {
    Integer minus_one{-1};
    v_scalar_multiplication(negated_equations[i], minus_one);
    hyperplanes.push_back(negated_equations[i]);
  }

  // print_matrix(hyperplanes);

  // vector<vector<Integer> > dehom1{c1->getDehomogenization()};

  Cone<Integer>* c0 = new Cone<Integer>(InputType::inequalities, hyperplanes);
  // Bad: InputType::equations, equations;

  // InputType::dehomogenization, dehom1);

  if(debug) {
    assert(c0 != nullptr);
  }

  if(debug) {
    std::cout << "Intersection computed!" << std::endl;
    c0->compute(ConeProperty::ExtremeRays, ConeProperty::MaximalSubspace);
    auto rays = c0->getExtremeRays();
    std::cout << "Generators of intersected cone: " << rays << std::endl;
  }

  NCone* result = new NCone;
  result->v = c0;

  return result;
}

// Return dehomogenized cone
extern "C"
NCone* dehomogenize(NCone* nc) {

  Cone<Integer>* c = nc->v;

  // Dehomogenize to get polyhedron, and then compute the integral hull

  if(debug) {
    assert(c != nullptr);
  }

  auto hyperplanes = c->getSupportHyperplanes();
  auto equations = c->getEquations();
  auto congruences = c->getCongruences();
  auto dim = c->getEmbeddingDim();

  map<InputType, vector<vector<Integer> > > coneInputs;
  coneInputs.insert({InputType::inequalities, hyperplanes});
  coneInputs.insert({InputType::equations, equations});
  coneInputs.insert({InputType::congruences, congruences});

  // add dehomogenization
  vector<Integer> unit_vec(dim);
  unit_vec[0] = 1; // first coordinate, by convention
  // std::cout << "Dehomogenization is " << unit_vec << std::endl;
  coneInputs.insert({InputType::dehomogenization, {unit_vec}});

  Cone<Integer>* c0 = new Cone<Integer>(coneInputs);
  // std::cout << "Homogenized cone: " << std::endl;
  // print_cone(c0);

  if(debug) {
    assert(c0 != nullptr);
  }

  NCone* result = new NCone;
  result->v = c0;
  return result;
}

extern "C" void hull(NCone* nc) {
  Cone<Integer>* c = nc->v;

  if(debug) {
    assert(c != nullptr);
    std::cout << "Computing integer hull of:" << std::endl;
    print_cone(c);
  }

  c->compute(ConeProperty::IntegerHull, ConeProperty::LatticePoints);

  if(debug) {
    auto c0_hull = c->getIntegerHullCone();

    if(&c0_hull == nullptr) {
      std::cout << "Computed null integer hull!" << std::endl;
    }

    std::cout << "Integer hull constraints:" << std::endl;
    print_cone(&c0_hull);
  }
}

extern "C"
two_dim_array* get_extreme_rays(NCone* nc) {
  Cone<Integer>* c = nc->v;

  if(debug) {
    assert(c != nullptr);
  }

  if(! c->isComputed(ConeProperty::ExtremeRays) && debug) {
    std::cout << "Extreme rays not computed!" << std::endl;
  }

  auto rays = c->getExtremeRays();
  auto arr = two_dim_array_of(rays);
  return arr;
}

extern "C"
two_dim_array* get_vertices(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }
  auto rays = c->getVerticesOfPolyhedron();
  auto arr = two_dim_array_of(rays);
  return arr;
}

extern "C"
two_dim_array* get_lineality_space(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }

  if(! c->isComputed(ConeProperty::MaximalSubspace) && debug) {
    std::cout << "Maximal subspace not computed!" << std::endl;
  }

  auto rays = c->getMaximalSubspace();
  auto arr = two_dim_array_of(rays);
  return arr;
}

extern "C"
two_dim_array* get_original_monoid_generators(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }
  auto rays = c->getOriginalMonoidGenerators();
  auto arr = two_dim_array_of(rays);
  return arr;
}

extern "C"
two_dim_array* get_inequalities(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }
  auto hyperplanes = c->getSupportHyperplanes();
  auto arr = two_dim_array_of(hyperplanes);
  return arr;
}

extern "C"
two_dim_array* get_equations(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }
  auto equations = c->getEquations();
  auto arr = two_dim_array_of(equations);
  return arr;
}

extern "C"
two_dim_array* get_congruences(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }
  auto congruences = c->getCongruences();
  auto arr = two_dim_array_of(congruences);
  return arr;
}

extern "C"
two_dim_array* get_dehomogenization(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }
  auto dehom = c->getDehomogenization();
  vector<vector<Integer> > v{{dehom}};
  auto arr = two_dim_array_of(v);
  return arr;
}

extern "C"
size_t get_embedding_dimension(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }
  auto dim = c->getEmbeddingDim();
  return dim;
}

extern "C"
two_dim_array* get_integer_hull_inequalities(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }

  auto c0_hull = c->getIntegerHullCone();
  auto dehom = c->getDehomogenization();

  // std::cout << "Integer hull constraints:" << std::endl;
  // print_cone(&c0_hull);

  vector<vector<Integer> > v{{dehom}};
  // print_matrix(v);

  NCone hull;
  hull.v = &c0_hull;

  return get_inequalities(&hull);
}

extern "C"
two_dim_array* get_integer_hull_equations(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }

  auto c0_hull = c->getIntegerHullCone();
  auto dehom = c->getDehomogenization();

  // std::cout << "Integer hull constraints:" << std::endl;
  // print_cone(&c0_hull);

  vector<vector<Integer> > v{{dehom}};
  // print_matrix(v);

  NCone hull;
  hull.v = &c0_hull;

  return get_equations(&hull);
}

extern "C"
two_dim_array* get_hilbert_basis(NCone* nc) {
  Cone<Integer>* c = nc->v;
  auto basis = c->getHilbertBasis();
  return two_dim_array_of(basis);
}

extern "C"
two_dim_array* get_module_generators(NCone* nc) {
  Cone<Integer>* c = nc->v;
  auto generators = c->getModuleGenerators();
  return two_dim_array_of(generators);
}

extern "C"
bool is_pointed(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }

  return c->isPointed();
}

extern "C"
bool is_inhomogeneous(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }

  return c->isInhomogeneous();
}

extern "C"
bool is_empty_semiopen(NCone* nc) {
  Cone<Integer>* c = nc->v;
  if(debug) {
    assert(c != nullptr);
  }

  return c->isEmptySemiOpen();
}

extern "C"
bool is_semiopen(NCone* nc) {
  Cone<Integer>* c = nc->v;
  auto num_excluded_faces = c->getNrExcludedFaces();
  return (num_excluded_faces > 0);
}
