#!/usr/bin/env sh

######################################################################
#  This file is part of e-antic.
#
#        Copyright (C) 2021 Julian Rüth
#
#  e-antic is free software: you can redistribute it and/or modify
#  it under the terms of the GNU Lesser General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
#
#  e-antic is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with e-antic. If not, see <https://www.gnu.org/licenses/>.
#####################################################################

set -ex

# We cannot run byexample directly since it would be invoked through its shebang
# which makes macOS sanitize some environment variables. Instead, we go thorugh
# our bin/python wrapper to set the necessary environment variables and invoke
# the Python binary to run pytest which keeps our environment intact on macOS.

python -c 'from byexample.byexample import main; exit(main())' -vvv -m /home/jule/proj/eskin/e-antic/libeantic/test/byexample/extensions -l cpp /home/jule/proj/eskin/e-antic/libeantic/test/byexample/../../../doc/manual/libeantic/*.md /home/jule/proj/eskin/e-antic/libeantic/test/byexample/../../e-antic/*.hpp /home/jule/proj/eskin/e-antic/libeantic/test/byexample/../../e-antic/*.h
