#!/bin/sh
# build.sh -- generates configuration files from fragments
# Copyright (C) 2009  Stephane Alnet
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


base_dir=./src
output_dir=./output

recipe_name=$1
recipe=`egrep -v '^#' ${recipe_name}.recipe`

## ---  Generate opensips.cfg  --- ##

result_file=${output_dir}/opensips.cfg

cat - <<EOH > ${result_file}
#
# Automatically generated for recipe ${recipe_name}
#
EOH

function nl() { echo >> ${result_file}; }

for extension in variables modules cfg; do
  for building_block in ${recipe}; do
    file="${base_dir}/${building_block}.${extension}"
    if [ -e $file  ]; then
      nl; echo "## ---  Start ${file}  --- ##" >> ${result_file}; nl;
      cat ${file} >> ${result_file}
      nl; echo "## ---  End ${file}  --- ##" >> ${result_file}; nl;
    fi
  done
done

mv -f ${result_file} ${result_file}.tmp
perl clean.pl ${result_file}.tmp > ${result_file}
rm ${result_file}.tmp


## ---  Generate opensips.sql  --- ##

extension=sql
result_file=${output_dir}/opensips.${extension}

rm -f ${result_file}
for building_block in ${recipe}; do
  file="${base_dir}/${building_block}.${extension}"
  if [ -e $file  ]; then
    cat ${file} >> ${result_file}
  fi
done
