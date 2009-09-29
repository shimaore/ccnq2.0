base_dir=./src
result_file=opensips.cfg

recipe_name=$1
recipe=`egrep -v '^#' ${recipe_name}.recipe`

cat - <<EOH > opensips.cfg
#
# Automatically generated for recipe ${recipe_name}
#
EOH

function nl() { echo >> ${result_file}; }

for building_block in ${recipe}; do
  file="${base_dir}/${building_block}.modules"
  if [ -e $file  ]; then
    nl; echo "## ---  Start ${file}  --- ##" >> ${result_file}; nl;
    cat ${file} >> ${result_file}
    nl; echo "## ---  End ${file}  --- ##" >> ${result_file}; nl;
  fi
done
for building_block in ${recipe}; do
  file="${base_dir}/${building_block}.cfg"
  if [ -e ${base_dir}/${building_block}.cfg ]; then
    nl; echo "## ---  Start ${file}  --- ##" >> ${result_file}; nl;
    cat ${file} >> ${result_file}
    nl; echo "## ---  End ${file}  --- ##" >> ${result_file}; nl;
  fi
done

# Now locate all the route[...] statements
# Then locate all the route(...) statements that do not have a matching route[...] statement and remove them

mv ${result_file} ${result_file}.tmp
perl clean.pl ${result_file}.tmp > ${result_file}
rm ${result_file}.tmp