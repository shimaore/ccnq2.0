base_dir=.
result_file=opensips.cfg

recipe_name=$1
recipe=`egrep -v '^#' ${recipe_name}.recipe`

cat - <<EOH > opensips.cfg
#
# Automatically generated for recipe ${recipe_name}
#
EOH

for building_block in ${recipe}; do
  echo >> ${result_file}; echo "# Start ${building_block}.modules" >> ${result_file}
  cat ${base_dir}/${building_block}.modules >> ${result_file}
  echo >> ${result_file}; echo "# End ${building_block}.modules" >> ${result_file}
done
for building_block in ${recipe}; do
  echo >> ${result_file}; echo "# Start ${building_block}.cfg" >> ${result_file}
  cat ${base_dir}/${building_block}.cfg >> ${result_file}
  echo >> ${result_file}; echo "# End ${building_block}.cfg" >> ${result_file}
done

# Now locate all the route[...] statements
# Then locate all the route(...) statements that do not have a matching route[...] statement and remove them

mv ${result_file} ${result_file}.tmp
perl clean.pl ${result_file}.tmp > ${result_file}
rm ${result_file}.tmp