#!/usr/bin/env bash

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
insert="${src_dir}/../insert"

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
    echo "${1}" >> "${src_dir}"/log_insert.txt
}

echo "$(date +'%F %T')" >> "${src_dir}"/log_insert.txt

#
# test: insert a column
#

f='file_standard.csv'

result="$("${insert}" -c 'col 5',1,2,3,4 "${src_dir}"/"${f}")"

expected="ID,Name,Mark,Grade,col 5
1,Mal,99,10,1
2,Sal,82,9,2
3,Val,78,8,3
4,Kal,29,3,4"

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}:insert a column" || log "[x] failed: ${f}: insert a column"

#
# test: via stdin
#

f='file_standard.csv'

result="$(cat "${src_dir}"/"${f}" | "${insert}" -c 'col 5',1,2,3,4)"

expected="ID,Name,Mark,Grade,col 5
1,Mal,99,10,1
2,Sal,82,9,2
3,Val,78,8,3
4,Kal,29,3,4"

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: via stdin" || log "[x] failed: ${f}: via stdin"

#
# test: insert a row
#

f='file_standard.csv'

result="$("${insert}" -r 5,Wal,34,4 "${src_dir}"/"${f}")"

expected="ID,Name,Mark,Grade
1,Mal,99,10
2,Sal,82,9
3,Val,78,8
4,Kal,29,3
5,Wal,34,4"

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: insert a row" || log "[x] failed: ${f}: insert a row"

#
# test: insert long row
#

f='file_standard.csv'

result="$("${insert}" -r 5,Wal,34,4,5 "${src_dir}"/"${f}")"

expected="Invalid number of elements."

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: insert long row" || log "[x] failed: ${f}: insert long row"

#
# test: insert short row
#

f='file_standard.csv'

result="$("${insert}" -r 5,Wal,34 "${src_dir}"/"${f}")"

expected="Invalid number of elements."

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: insert short row" || log "[x] failed: ${f}: insert short row"


#
# test: insert long column
#

f='file_standard.csv'

result="$("${insert}" -c col,1,2,3,4,5 "${src_dir}"/"${f}")"

expected="Invalid number of elements."

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: insert long column" || log "[x] failed: ${f}: insert long column"

#
# test: insert short column
#

f='file_standard.csv'

result="$("${insert}" -c col,1,2,3 "${src_dir}"/"${f}")"

expected="Invalid number of elements."

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: insert short column" || log "[x] failed: ${f}: insert short column"

#
# test: insert row and column
#

f='file_standard.csv'

result="$("${insert}" -c col,1,2,3,4 -r 5,Wal,34,4 "${src_dir}"/"${f}")"

expected="Provide either row or column data, not both."

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: insert row and column" || log "[x] failed: ${f}: insert row and column"

#
# test: one column
#

f='file_one_column.csv'

result="$("${insert}" -c col,10,20,30,40 "${src_dir}"/file_one_column.csv)"

expected="ID,col
1,10
2,20
3,30
4,40"

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}" || log "[x] failed: ${f}"


#
# test: one element add row
#

f='file_one_element.csv'

result="$("${insert}" -r 99 "${src_dir}"/"${f}")"

expected="ID
99"

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: add row" || log "[x] failed: ${f}: add row"

#
# test: one element add column
#

f='file_one_element.csv'

result="$("${insert}" -c 99 "${src_dir}"/"${f}")"

expected="ID,99"

[ "${result}" == "${expected}" ] && log "[v] passed: ${f}: add column" || log "[x] failed: ${f}: add column"

#
# clean up
#

rm "${src_dir}"/file_*
