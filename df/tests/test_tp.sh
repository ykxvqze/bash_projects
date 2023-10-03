#!/usr/bin/env bash

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tp="${src_dir}/../tp"

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

log() {
    echo "${1}" >> "${src_dir}"/log_tp.txt
}

echo "$(date +'%F %T')" >> "${src_dir}"/log_tp.txt

#
# test: standard
#

result="$(tp "${src_dir}"/file_standard.csv)"

expected="ID,1,2,3,4
Name,Mal,Sal,Val,Kal
Mark,99,82,78,29
Grade,10,9,8,3"

[ "${result}" == "${expected}" ] && log '[v] passed: file_standard via file' || log '[x] failed: file_standard via file'

#
# test: standard via stdin
#

result="$(cat "${src_dir}"/file_standard.csv | tp)"

expected="ID,1,2,3,4
Name,Mal,Sal,Val,Kal
Mark,99,82,78,29
Grade,10,9,8,3"

[ "${result}" == "${expected}" ] && log '[v] passed: file_standard via stdin' || log '[x] failed: file_standard via stdin'

#
# test: space in element
#

result="$(tp "${src_dir}"/file_space_in_element.csv)"

expected="ID,1,2,3,4
Name,Mal,Sal,Val,Kal
Final Mark,99,82,78,29
Grade,10,9,8,3"

[ "${result}" == "${expected}" ] && log '[v] passed: file_space_in_element' || log '[x] failed: file_space_in_element'

#
# test: long row
#

result="$(tp "${src_dir}"/file_long_row.csv)"

expected="Invalid csv data."

[ "${result}" == "${expected}" ] && log '[v] passed: file_space_long_row' || log '[x] failed: file_space_long_row'

#
# test: short row
#

result="$(tp "${src_dir}"/file_short_row.csv)"

expected="Invalid csv data."

[ "${result}" == "${expected}" ] && log '[v] passed: file_space_short_row' || log '[x] failed: file_space_short_row'

#
# test: empty value
#

result="$(tp "${src_dir}"/file_empty_value.csv)"

expected="ID,1,2,3,4
Name,Mal,Sal,Val,Kal
Mark,99,82,,29
Grade,10,9,8,3"

[ "${result}" == "${expected}" ] && log '[v] passed: file_empty_value' || log '[x] failed: file_empty_value'

#
# cleanup
#

rm "${src_dir}"/file_*
