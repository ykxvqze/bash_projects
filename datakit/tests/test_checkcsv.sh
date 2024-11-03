#!/usr/bin/env bash

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
checkcsv="${src_dir}/../checkcsv"

cat << EOF > "${src_dir}"/file_standard.csv
ID,Name,Mark,Grade
1,Mal,99,10
2,Sal,82,9
3,Val,78,8
4,Kal,29,3
EOF

cat << EOF > "${src_dir}"/file_space_in_element.csv
ID,Name,Final Mark,Grade
1,Mal,99,10
2,Sal,82,9
3,Val,78,8
4,Kal,29,3
EOF

cat << EOF > "${src_dir}"/file_long_row.csv
ID,Name,Mark,Grade
1,Mal,99,10
2,Sal,82,9
3,Val,78,8
4,Kal,29,3,5
EOF

cat << EOF > "${src_dir}"/file_short_row.csv
ID,Name,Mark,Grade
1,Mal,99,10
2,Sal,82,9
3,Val,8
4,Kal,29,3
EOF

cat << EOF > "${src_dir}"/file_empty_value.csv
ID,Name,Mark,Grade
1,Mal,99,10
2,Sal,82,9
3,Val,,8
4,Kal,29,3
EOF

cat << EOF > "${src_dir}"/file_one_row.csv
ID,Name,Mark,Grade
EOF

cat << EOF > "${src_dir}"/file_one_column.csv
ID
1
2
3
4
EOF

cat << EOF > "${src_dir}"/file_one_element.csv
ID
EOF

log() {
    echo "${1}" >> "${src_dir}"/log_checkcsv.txt
}

echo "$(date +'%F %T')" >> "${src_dir}"/log_checkcsv.txt

#
# test: standard
#

f='file_standard.csv'

result="$("${checkcsv}" "${src_dir}"/"${f}")"

expected=""

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"

#
# test: standard via stdin
#

f='file_standard.csv'

result="$(cat "${src_dir}"/"${f}" | "${checkcsv}")"

expected=""

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"

#
# test: space in element
#

f='file_space_in_element.csv'

result="$("${checkcsv}" "${src_dir}"/"${f}")"

expected=""

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"

#
# test: long row
#

f='file_long_row.csv'

result="$("${checkcsv}" "${src_dir}"/"${f}")"

expected="Invalid CSV data."

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"

#
# test: short row
#

f='file_short_row.csv'

result="$("${checkcsv}" "${src_dir}"/"${f}")"

expected="Invalid CSV data."

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"

#
# test: empty value
#

f='file_empty_value.csv'

result="$("${checkcsv}" "${src_dir}"/"${f}")"

expected=""

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"

#
# test: one row
#

f='file_one_row.csv'

result="$("${checkcsv}" "${src_dir}"/"${f}")"

expected=""

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"


#
# test: one column
#

f='file_one_column.csv'

result="$("${checkcsv}" "${src_dir}"/"${f}")"

expected=""

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"


#
# test: one element
#

f='file_one_element.csv'

result="$("${checkcsv}" "${src_dir}"/"${f}")"

expected=""

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"


#
# clean up
#

rm "${src_dir}"/file_*
