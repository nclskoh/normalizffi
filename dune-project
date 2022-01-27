(lang dune 2.9.1)
(name normalizffi)
(version 0.1)

(generate_opam_files true)

(source (github nclskoh/normalizffi))
(license MIT)
(authors "Nicolas Koh")
(maintainers "ckoh@princeton.edu")
(package
  (name normalizffi)
  (synopsis "Ocaml bindings for the C++ Normaliz library")
  (description "")
  (depends
  (ocaml (>= 4.09)) (dune (>= 2.9.1))))
