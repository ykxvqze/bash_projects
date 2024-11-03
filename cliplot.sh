#!/usr/bin/env bash
<< 'EOF'
CLI plot of non-negative numeric sequences.

USAGE: ./cliplot.sh  [ -h ]
       ./cliplot.sh  <sequence_of_non-negative_numbers>

OPTIONS:
        [ -h ]    Print usage and exit

OUTPUT:
         Stem plot of a non-negative numerical sequence in the CLI without
         needing an X window system to show the plot. The plot is
         normalized to a default figure height of 10 lines. The y-axis
         values are proportional to the actual values plotted. Negative
         values are clipped to zero.
         Plotting in the CLI can be useful for quick assessment of
         values such as CPU or memory usage over time (see last example).
         The count, minimum, and maximum values of the sequence are also
         displayed.

DESCRIPTION:

cliplot.sh will 'paint' a plot in the CLI, top-level down, line-by-line.
The result is a stem plot showing the sequence to be plotted.

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

        # run `top` in batch mode 8 times and plot CPU usage for the process with PID 807.
        pid=807
        top -b -n 8 | grep -E "^ *$pid" | awk '{print $9}' | ./cliplot.sh

EOF

set -eo pipefail

__plt__print_usage(){
    echo -e "cliplot.sh: plot a function in CLI.
    Usage:
            ./cliplot.sh 1 2 3 4 5        # plot the sequence
            seq 1 5 | ./cliplot.sh        # equivalent\n"
}

# height of plot
export height=10

# list of functions to be overwritten
__plt__get_min         () { :; }
__plt__get_max         () { :; }
__plt__normalize_input () { :; }
__plt__draw_line       () { :; }

__plt__get_min() {
    local input=(${@})
    local min="${input[0]}"
    for i in $(seq 1 "$(($#-1))"); do
        if [ $(echo "$min > ${input[i]}" | bc) -eq 1 ]; then
            min="${input[i]}";
        fi
    done
    echo "$min"
}

__plt__get_max() {
    local input=(${@})
    local max="${input[0]}"
    for i in $(seq 1 "$(($#-1))"); do
        if [ $(echo "$max < ${input[i]}" | bc) -eq 1 ]; then
            max="${input[i]}";
        fi
    done
    echo "$max"
}

__plt__normalize_input() {
    local input=(${@})
    local max=$(__plt__get_max ${input[@]})
    local input_normalized=()
    for i in ${input[@]}; do
        input_normalized+=($(echo "scale=2; $i / $max * $height" | bc -l))
    done
    echo ${input_normalized[@]}
}

__plt__draw_line() {
    if [ "$height" -gt $(tput lines) ]; then
         echo 'Height exceeds screen size. Setting to max height...'
         height=$(tput lines)
    fi

    local input=(${@})
    local count="${#@}"
    local values=$(__plt__normalize_input ${input[@]})
    local y_label=' y  '
    local x_offset='    '

    echo ''

    # paint the plot from top level
    for y in $(seq $((height-1)) -1 0); do
        # y-axis
        [ "$y" -eq $((height/2)) ] \
        && stdout_write="${y_label}|" || stdout_write="${x_offset}|"

        # bars
        for j in ${values}; do
            [ $(echo "$j > $y" | bc) -eq 1 ] \
            && stdout_write+=' |' || stdout_write+='  '
        done
        printf '%s\n' "${stdout_write}"
    done

    local stdout_xaxis="${x_offset} "
    local stdout_xlabel="${x_offset}  1"
    for i in $(seq 1 "$((2 * count))")     ; do stdout_xaxis+="-" ; done
    for i in $(seq 1 "$((2 * count - 3 ))"); do stdout_xlabel+=' '; done
    printf '%s\n' "${stdout_xaxis}"
    printf '%s\n' "${stdout_xlabel}$count"
}

main() {
    while getopts 'h' option; do
        case "$option" in
            h) __plt__print_usage; exit 0  ;;
            *) echo -e 'Incorrect usage!\n';
               __plt__print_usage; exit 1  ;;
        esac
    done

    if [ -z "$@" ]; then
        args="$(</dev/stdin)"
    else
        args="$@"
    fi

    __plt__draw_line $args

    printf '\n'
    printf 'Count   : %s\n' "$(echo "$args" | tr -s ' ' '\n' | wc -l)"
    printf 'Minimum : %s\n' $(__plt__get_min $args)
    printf 'Maximum : %s\n' $(__plt__get_max $args)
    printf '\n'

}

main "$@"
