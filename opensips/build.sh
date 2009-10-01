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
