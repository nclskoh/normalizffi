#ifndef __STUB_COMMON_H
#define __STUB_COMMON_H

#define DEBUG

extern "C" {

  typedef struct two_dim_array {
    char** data;
    size_t num_rows;
    size_t num_cols;
  } two_dim_array;

}

#endif
