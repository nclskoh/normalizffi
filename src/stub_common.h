#ifndef __STUB_COMMON_H
#define __STUB_COMMON_H

#include <stddef.h>

#define DEBUG

typedef struct two_dim_array {
  char** data;
  size_t num_rows;
  size_t num_cols;
} two_dim_array;

#endif
