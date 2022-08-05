#!/usr/bin/env bash
<< 'EOF'
CLI plot of positive functions (no X11 windows system required).

USAGE: ./cliplot.sh [ -h ] | <sequence_of_numerical_values>

OPTIONS:
        [ -h ]    Print usage and exit

OUTPUT:
         A plot of a numerical float sequence (time series) is the CLI
         without need for a GUI or X11 windows system to show the plot.
         The plot is normalized to a default figure height of 10 lines,
         thus the y-axis values are proportional to the actual values
         plotted. Plotting in CLI can be useful for quick assessment of
         values such as CPU or memory usage over time (see last example).
         The count, minimum, and maximum values of the time series are
         also displayed.

DESCRIPTION:

cliplot will 'paint' a plot top-level down in the CLI, line-by-line. The
result is a stem plot delineating the function to be plotted.

EXAMPLES:
         ./cliplot.sh 1 4 9 16 25 36 49 64 81 100
         echo '1 30 0 4 8 10' | xargs ./cliplot.sh

        # run `top` in batch mode 8 times and plot CPU usage for a given PID.
        pid=807
        top -b -n 8 | grep -E "^ *$pid" | awk '{print $9}' | xargs ./cliplot.sh
EOF

set -eo pipefail

__plt__print_usage(){
    echo -e "cliplot.sh: plot a function in CLI.
    Usage:

    ./cliplot.sh 1 2 3 4 5     # plot the sequence
    seq 1 5 | xargs ./cliplot  # equivalent\n"
}

# height of plot
export height=10

# default list of functions to be overwritten
__plt__get_min         () { :; }
__plt__get_max         () { :; }
__plt__normalize_input () { :; }
__plt__draw_line       () { :; }

__plt__get_min() {
    local input=(${@})
    local min="${input[0]}"
    for i in `seq 1 "$(($#-1))"`; do
        if [ `echo "$min > ${input[i]}" | bc` -eq 1 ]; then
            min="${input[i]}";
        fi
    done
    echo "$min"
}

__plt__get_max() {
    local input=(${@})
    local max="${input[0]}"
    for i in `seq 1 "$(($#-1))"`; do
        if [ `echo "$max < ${input[i]}" | bc` -eq 1 ]; then
            max="${input[i]}";
        fi
    done
    echo "$max"
}

__plt__normalize_input() {
    local input=(${@})
    local max=`__plt__get_max ${input[@]}`
    local input_normalized=()
    for i in ${input[@]}; do
        input_normalized+=(`echo "scale=2; $i / $max * $height" | bc -l`)
    done
    echo ${input_normalized[@]}
}

__plt__draw_line() {
    if [ "$height" -gt `tput lines` ]; then
         echo 'Height exceeds screen size. Setting to max height...'
         height=`tput lines`
    fi

    local    input=(${@})
    local    count="${#@}"
    local   values=`__plt__normalize_input ${input[@]}`
    local  y_label=' y  '
    local x_offset='    '

    echo ''

    # paint the plot from top level
    for y in `seq $((height-1)) -1 0`; do
        # y-axis
        [ "$y" -eq $((height/2)) ] \
        && stdout_write="${y_label}|" || stdout_write="${x_offset}|"

        # bars
        for j in ${values}; do
            [ `echo "$j > $y" | bc` -eq 1 ] \
            && stdout_write+=' |' || stdout_write+='  '
        done
        printf '%s\n' "${stdout_write}"
    done

    local stdout_xaxis="${x_offset} "
    local stdout_xlabel="${x_offset}  1"
    for i in `seq 1 "$((2 * count))"`     ; do stdout_xaxis+="-" ; done
    for i in `seq 1 "$((2 * count - 3 ))"`; do stdout_xlabel+=' '; done
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

    __plt__draw_line "$@"
    printf '\n'
    printf 'Count   : %s\n' "${#@}"
    printf 'Minimum : %s\n' `__plt__get_min "$@"`
    printf 'Maximum : %s\n' `__plt__get_max "$@"`
    printf '\n'

}

main "$@"

