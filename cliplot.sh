#!/usr/bin/env bash

<< 'EOF'
CLI plot of non-negative numeric sequences.

USAGE:
       ./cliplot.sh  [ -h ]
       ./cliplot.sh  <sequence_of_non-negative_numbers>

OPTIONS:
        [ -h ]    Print usage and exit

OUTPUT:
         Stem plot of a numeric sequence in the CLI (no X window system).
         The plot is normalized to a default height of 10 lines.
         The y-axis values are proportional to the numeric values plotted.
         The count, minimum, and maximum values of the sequence are also
         displayed. The plot can be useful for quick assessment of values,
         such as CPU or memory usage over time (see last example).

DESCRIPTION:

cliplot.sh will 'paint' a stem plot in the CLI, top-level down, line-by-line.

EXAMPLES:
         ./cliplot.sh 1 4 9 16 25 36 49 64 81 100

            |                   |
            |                 | |
            |               | | |
         y  |               | | |
            |             | | | |
            |           | | | | |
            |       | | | | | | |
            | | | | | | | | | | |
             --------------------
              1                 10

        Count   : 10
        Minimum : 1
        Maximum : 100

        echo '1 30 0 4 8 10' | ./cliplot.sh
        seq 1 5 | ./cliplot.sh

        # run top in batch mode 8 times, and plot CPU usage for the process with PID 807.
        PID=807
        top -b -n 8 | grep -E "^ *$PID" | awk '{print $9}' | ./cliplot.sh
EOF

set -eo pipefail

# height of plot
export height=10

__print_usage     () { :; }
__get_min         () { :; }
__get_max         () { :; }
__normalize       () { :; }
__draw_plot       () { :; }
__parse_options   () { :; }
__parse_arguments () { :; }
__validate_args   () { :; }
__print_stats     () { :; }
__main            () { :; }

__print_usage(){
    echo -e "Plot a numeric sequence in CLI.

    Usage:

            ./cliplot.sh 1 2 3 4 5        # plot the sequence
            seq 1 5 | ./cliplot.sh        # equivalent\n"
}

__get_min() {
    local array=("$@")
    local min="${array[0]}"
    for i in $(seq 1 "$(($# - 1))"); do
        if [ $(echo "$min > ${array[i]}" | bc) -eq 1 ]; then
            min="${array[i]}";
        fi
    done
    echo "$min"
}

__get_max() {
    local array=("$@")
    local max="${array[0]}"
    for i in $(seq 1 "$(($# - 1))"); do
        if [ $(echo "$max < ${array[i]}" | bc) -eq 1 ]; then
            max="${array[i]}";
        fi
    done
    echo "$max"
}

__normalize() {
    local array=("$@")
    local max=$(__get_max ${array[@]})
    local array_normalized=()
    for i in ${array[@]}; do
        array_normalized+=("$(echo "scale=2; $i / $max * $height" | bc -l)")
    done
    echo "${array_normalized[@]}"
}

__draw_plot() {
    if [[ "$height" -gt "$(tput lines)" ]]; then
         echo 'Height exceeds screen size. Setting to max height...'
         height="$(tput lines)"
    fi

    local array=($args)
    local count="${#array[@]}"
    local values=$(__normalize ${array[@]})
    local y_label=' y  '
    local x_offset='    '

    echo ''

    # paint the plot from top level
    for y in $(seq $((height - 1)) -1 0); do
        # y-axis
        if [[ "$y" -eq $((height/2)) ]]; then
            stdout_write="${y_label}|"
        else
            stdout_write="${x_offset}|"
        fi

        # bars
        for j in ${values}; do
            if [[ $(echo "$j > $y" | bc) -eq 1 ]]; then
                stdout_write+=' |'
            else
                stdout_write+='  '
            fi
        done

        printf '%s\n' "${stdout_write}"
    done

    local stdout_xaxis="${x_offset} "
    local stdout_xlabel="${x_offset}  1"
    
    for i in $(seq 1 "$((2 * count))"); do
        stdout_xaxis+="-"
    done

    for i in $(seq 1 "$((2 * count - 3 ))"); do
        stdout_xlabel+=' '
    done

    printf '%s\n' "${stdout_xaxis}"
    printf '%s\n' "${stdout_xlabel}$count"
}

__parse_options() {
    while getopts 'h' option; do
        case "$option" in
            h) __print_usage; exit 0;;
            *) echo -e "Incorrect usage!\n";
               __print_usage; exit 1;;
        esac
    done
}

__parse_arguments() {
    if [[ -z "$@" ]]; then
        args="$(</dev/stdin)"
    else
        args="$@"
    fi
}

__validate_args() {
    local array=($args)
    for i in ${array[@]}; do
        if ! [[ "$i" =~ ^[0-9]*\.?[0-9]*$ ]]; then
            echo "Numeric value $i must be non-negative. Exiting..."
            exit 1
        fi
    done
}

__print_stats() {
    printf '\n'
    printf 'Count   : %s\n' "$(echo "$args" | tr -s ' ' '\n' | wc -l)"
    printf 'Minimum : %s\n' "$(__get_min $args)"
    printf 'Maximum : %s\n' "$(__get_max $args)"
    printf '\n'
}

__main() {
    __parse_options "$@"
    __parse_arguments "$@"
    __validate_args
    __draw_plot
    __print_stats
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    __main "$@"
fi
