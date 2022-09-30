# Normalizffi

This package provides Ocaml bindings to
[Normaliz](https://www.normaliz.uni-osnabrueck.de/) and
[Flint](https://flintlib.org/).

## Installation

1. In the `Normaliz-patch` directory, run `patch-offline.sh` to download
   sources for dependencies and patch the installation directory.

```
cd Normaliz-patch; ./patch-offline.sh
```

2. Install dependencies.

```
opam install ctypes-foreign gmp
```

3. Pin the package and install. In `normalizffi`:

```
opam pin .
```

## Usage

The library is available as `normalizffi`, and exports the modules `Normaliz`
and `Flint`.

