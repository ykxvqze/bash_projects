#!/usr/bin/env bash
<< 'EOF'
Utility functions for the data toolkit

EOF

#
# strings to numbers, e.g. 4,col1-col5 --> 4,1-5
#

str2num() {
    local input_string="${1}"
    local header="${2}"

    unset arr
    declare -A arr
    OFS="${IFS}"
    IFS=","
    cnt=1
    for i in $header; do
        arr["$i"]=$cnt
        ((cnt++))
    done

    items="${input_string}"
    for i in $(echo "${items}" | tr '-' ','); do
        item=$(grep -oE "${i}" <<< "${header}" | head -1)
        # if non-integer and zero (no hit)
        if [[ ! ("${i}" =~ ^[1-9][0-9]*$) && -z "${item}" ]]; then
            IFS="${OFS}"
            return 1
        fi
        # if non-integer and non-zero
        if [[ ! ("${item}" =~ ^[1-9][0-9]*$) && -n "${item}" ]]; then
            value="$(echo ${arr["$item"]})"
            items="$(sed -E "s/${i}/${value}/" <<< "${items}")"
        fi
    done
    IFS="${OFS}"
    echo "${items}"
}

#
# enumerate input, e.g. 2-5,4,1 --> 2,3,4,5,4,1,...
#

enumerate() {
    local input_string="${1}"
    local n_col="${2}"
    OFS="${IFS}"
    IFS=','
    for i in $input_string; do
        if [ -z $(grep '-' <<< "${i}") ]; then
            echo "${i}"
        else
            # we have a range item (start-end)
            start=$(grep -oE '^[^-]*' <<< "${i}")
            end=$(grep -oE '[^-]*$' <<< "${i}")
            if [ -z "${start}" ]; then
                start=1
            fi
            if [ -z "${end}" ]; then
                end="${n_col}"
            fi
            if [ "${start}" -gt "${end}" ]; then
                seq "${start}" -1 "${end}"
            else
                seq "${start}" "${end}"
            fi
        fi
    done | tr '\n' ',' | rev | cut -c 2- | rev
    IFS="${OFS}"
}
