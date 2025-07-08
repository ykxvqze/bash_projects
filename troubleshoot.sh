#!/usr/bin/env bash

<< 'EOF'
Script to help troubleshoot CPU, Memory, and I/O usage issues.
EOF

<< 'EOF'
The script was tested using the following packages:

Package  : procps
Version  : 2:3.3.15-2
Includes : free, uptime, top, vmstat

Package  : sysstat
Version  : 12.0.3-2
Includes : mpstat, iostat, pidstat, sar
EOF

#
# functions
#

__load_color    () { :; }
__check_sysinfo () { :; }
__check_free    () { :; }
__check_uptime  () { :; }
__check_top     () { :; }
__check_vmstat  () { :; }
__check_mpstat  () { :; }
__check_iostat  () { :; }
__check_sar     () { :; }
__check_pidstat () { :; }

#
# colors
#

__load_color() {
    export RED="$(tput setaf 1)"
    export GREEN="$(tput setaf 2)"
    export DEFAULT="$(tput sgr0)"
}

#
# system info
#

__check_sysinfo() {
    superuser=$(grep ':x:0:' /etc/passwd | cut -d ':' -f 1)

    ip_public=$(wget -q -O - 'ipinfo.io/ip')

    ip_private=$(ip -o -4 address    |
                 tr -s ' '           |
                 grep -v '127.0.0.1' |
                 cut -d ' ' -f 4     |
                 sed 's/\/.*//'      |
                 head -n 1)

    ip_gateway=$(ip route            |
                 grep '^default via' |
                 head -1             |
                 cut -d ' ' -f 3)

    ports_open=$(netstat -atn              |
                 grep '^tcp'               |
                 tr -s ' '                 |
                 cut -d ' ' -f 4           |
                 grep -oE '[^:][0-9]{1,}$' |
                 sort -un                  |
                 xargs)

    echo "
    Username       : $(whoami)
    Superuser      : ${superuser}
    Hostname       : $(hostname)
    OS             : $(uname -mrs)
    Kernel         : $(uname -r)
    Architecture   : $(uname -m)
    Logical cores  : $(cat /proc/cpuinfo | grep -c 'processor')
    Physical cores : $(grep "core id" /proc/cpuinfo | sort -u | wc -l)
    IP (Public)    : ${ip_public}
    IP (Private)   : ${ip_private}
    IP (Gateway)   : ${ip_gateway}
    Ports open     : ${ports_open}"
}

#
# free -m
#

__check_free() {
    echo
    echo "[*] Checking free -m..."

    if [ -z "$(which free)" ]; then
        echo "Command 'free' is not installed."
        echo "Use: sudo apt-get install procps"
        echo "Then rerun the script. Exiting..."
        return 1
    fi

    # thresholds
    local memory_threshold=70                # 70%
    local available_memory_threshold=2048    # 2 GB
    local swap_threshold=10                  # 10%

    # metrics
    memory_info=$(free -m)
    used_memory=$(echo "${memory_info}"      | awk '/Mem:/ {print $3}')
    total_memory=$(echo "${memory_info}"     | awk '/Mem:/ {print $2}')
    available_memory=$(echo "${memory_info}" | awk '/Mem:/ {print $7}')
    used_swap=$(echo "${memory_info}"        | awk '/Swap:/ {print $3}')
    total_swap=$(echo "${memory_info}"       | awk '/Swap:/ {print $2}')

    memory_usage_percent=$(( 100 * used_memory / total_memory ))
    swap_usage_percent=$(( 100 * used_swap / total_swap ))

    # flag
    issues=0

    # check memory usage
    if [ "${memory_usage_percent}" -ge "${memory_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] Memory usage is high: ${memory_usage_percent}% used."
        issues=1
    fi

    # check available memory
    if [ "${available_memory}" -le "${available_memory_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] Available memory is low: ${available_memory} MB."
        issues=1
    fi

    # check swap usage
    if [ "${total_swap}" -gt 0 ]; then
        if [ "${swap_usage_percent}" -ge "${swap_threshold}" ]; then
            echo "[ ${RED}Warning${DEFAULT} ] Swap usage is high: ${swap_usage_percent}% used."
            issues=1
        fi
    else
        echo "No swap space configured."
    fi

    if [ "$issues" -eq 0 ]; then
        echo "${GREEN}No issues found.${DEFAULT}"
    fi
}

#
# uptime (load average)
#

__check_uptime() {
    echo
    echo "[*] Checking load average (uptime)..."

    if [ -z "$(which uptime)" ]; then
        echo "Command 'uptime' is not installed."
        echo "Use: sudo apt-get install procps"
        echo "Then rerun the script. Exiting..."
        return 1
    fi

    # number of physical cores
    num_cores=$(grep "core id" /proc/cpuinfo | sort -u | wc -l)

    # 1-minute load average
    load_average=$(uptime | tr ',' ' ' | awk '{print $((NF-2))}')

    # flag
    issues=0

    if (( $(echo "${load_average} >= ${num_cores}" | bc -l) )); then
        echo "[ ${RED}Warning${DEFAULT} ] Load average (${load_average}) is greater than or equal to the number of physical CPUs (${num_cores})."
        issues=1
    fi

    if [ "$issues" -eq 0 ]; then
        echo "${GREEN}No issues found.${DEFAULT}"
    fi
}

#
# top
#

__check_top() {
    echo
    echo "[*] Checking top..."

    if [ -z "$(which top)" ]; then
        echo "Command 'top' is not installed."
        echo "Use: sudo apt-get install procps"
        echo "Then rerun the script. Exiting..."
        return 1
    fi

    # number of physical cores
    num_cores=$(grep "core id" /proc/cpuinfo | sort -u | wc -l)

    # threshold values
    local cpu_user_threshold=$((70 * num_cores))     # user CPU usage threshold (%)
    local cpu_system_threshold=$((30 * num_cores))   # system CPU usage threshold (%)
    local cpu_idle_threshold=20                      # idle CPU threshold (%)
    local cpu_iowait_threshold=10                    # I/O wait threshold (%)
    local cpu_process_threshold=$((70 * num_cores))  # CPU usage for specific processes (%)
    local memory_process_threshold=70                # memory usage for specific processes (%)

    # cpu metrics from `top`
    top_output="$(top -b -n 1)"
    cpu_metrics="$(echo "${top_output}" | grep "Cpu(s)" | tr ',' ' ')"
    cpu_user="$(echo "${cpu_metrics}"   | awk '{print $2}')"
    cpu_system="$(echo "${cpu_metrics}" | awk '{print $4}')"
    cpu_idle="$(echo "${cpu_metrics}"   | awk '{print $8}')"
    cpu_iowait="$(echo "${cpu_metrics}" | awk '{print $10}')"

    # flag
    issues=0

    # check CPU usage thresholds
    if (( $(echo "${cpu_user} >= ${cpu_user_threshold}" | bc -l) )); then
        echo "[ ${RED}Warning${DEFAULT} ] User CPU usage is high: ${cpu_user}%."
        issues=1
    fi

    if (( $(echo "${cpu_system} >= ${cpu_system_threshold}" | bc -l) )); then
        echo "[ ${RED}Warning${DEFAULT} ] System CPU usage is high: ${cpu_system}%."
        issues=1
    fi

    if (( $(echo "${cpu_idle} <= ${cpu_idle_threshold}" | bc -l) )); then
        echo "[ ${RED}Warning${DEFAULT} ] Idle CPU usage is low: ${cpu_idle}%."
        issues=1
    fi

    if (( $(echo "${cpu_iowait} >= ${cpu_iowait_threshold}" | bc -l) )); then
        echo "[ ${RED}Warning${DEFAULT} ] I/O wait is high: ${cpu_iowait}%."
        issues=1
    fi

    # check specific processes for high CPU and memory usage 
    while read -r line; do
        process="$(echo "$line" | awk '{print $12}')"
        cpu="$(echo "$line" | awk '{print $9}')"
        memory="$(echo "$line" | awk '{print $10}')"
        
        if (( $(echo "${cpu} >= ${cpu_process_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Process $process is using high CPU: $cpu%"
            issues=1
        fi
        
        if (( $(echo "${memory} >= ${memory_process_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Process $process is using high memory: $memory%"
            issues=1
        fi

    done <<< $(echo "${top_output}" | awk 'NR >7')

    if [ "$issues" -eq 0 ]; then
        echo "${GREEN}No issues found.${DEFAULT}"
    fi
}

#
# vmstat
#

__check_vmstat() {
    echo
    echo "[*] Checking vmstat..."

    if [ -z "$(which vmstat)" ]; then
        echo "Command 'vmstat' is not installed."
        echo "Use: sudo apt-get install procps"
        echo "Then rerun the script. Exiting..."
        return 1
    fi

    # number of physical cores
    local num_cores=$(grep "core id" /proc/cpuinfo | sort -u | wc -l)

    # threshold values
    local free_memory_threshold=2048                 # 2 GB in MB
    local swap_in_threshold=0                        # swap in threshold
    local swap_out_threshold=0                       # swap out threshold
    local io_threshold=100                           # I/O threshold in blocks per second (for bi, bo)
    local cpu_user_threshold=$((70 * num_cores))     # user CPU usage threshold (%)
    local cpu_system_threshold=$((30 * num_cores))   # system CPU usage threshold (%)
    local cpu_idle_threshold=20                      # idle CPU threshold (%)
    local cpu_iowait_threshold=10                    # I/O wait threshold (%)

    # vmstat output (1 second interval, 2 iterations) - ignore first row (i.e., stats since boot time)
    vmstat_output="$(vmstat 1 2 | tail -n 1)"

    # extract values
    r=$(echo "${vmstat_output}" | awk '{print $1}')            # run queue
    free_memory=$(echo "${vmstat_output}" | awk '{print $4}')  # free memory
    si=$(echo "${vmstat_output}" | awk '{print $7}')           # swap in
    so=$(echo "${vmstat_output}" | awk '{print $8}')           # swap out
    bi=$(echo "${vmstat_output}" | awk '{print $9}')           # blocks in
    bo=$(echo "${vmstat_output}" | awk '{print $10}')          # blocks out
    us=$(echo "${vmstat_output}" | awk '{print $13}')          # user CPU time
    sy=$(echo "${vmstat_output}" | awk '{print $14}')          # system CPU time
    id=$(echo "${vmstat_output}" | awk '{print $15}')          # idle CPU time
    wa=$(echo "${vmstat_output}" | awk '{print $16}')          # I/O wait

    # flag
    issues=0

    # check thresholds
    if [ "${r}" -ge "${num_cores}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] Run queue is high: ${r} processes waiting for CPU."
        issues=1
    fi

    if [ "${free_memory}" -lt "${free_memory_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] Free memory is low: ${free_memory} MB."
        issues=1
    fi

    if [ "${si}" -gt "${swap_in_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] Swap in is occurring: ${si} MB."
        issues=1
    fi

    if [ "${so}" -gt "${swap_out_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] Swap out is occurring: ${so} MB."
        issues=1
    fi

    if [ "${bi}" -gt "${io_threshold}" ] || [ "${bo}" -gt "${io_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] High I/O activity: ${bi} blocks in, ${bo} blocks out."
        issues=1
    fi

    if [ "${us}" -ge "${cpu_user_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] User CPU usage is high: ${us}%."
        issues=1
    fi

    if [ "${sy}" -ge "${cpu_system_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] System CPU usage is high: ${sy}%."
        issues=1
    fi

    if [ "${id}" -lt "${cpu_idle_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] Idle CPU time is low: ${id}%. The system may be overloaded."
        issues=1
    fi

    if [ "${wa}" -gt "${cpu_iowait_threshold}" ]; then
        echo "[ ${RED}Warning${DEFAULT} ] I/O wait is high: ${wa}%. Processes are waiting on I/O."
        issues=1
    fi

    if [ "$issues" -eq 0 ]; then
        echo "${GREEN}No issues found.${DEFAULT}"
    fi
}

#
# mpstat -P ALL
#

__check_mpstat() {
    echo
    echo "[*] Checking mpstat..."

    if [ -z "$(which mpstat)" ]; then
        echo "Command 'mpstat' is not installed."
        echo "Use: sudo apt-get install sysstat"
        echo "Then rerun the script. Exiting..."
        return 1
    fi

    # threshold values
    local cpu_user_threshold=70      # user CPU usage threshold (%)
    local cpu_system_threshold=30    # system CPU usage threshold (%)
    local cpu_idle_threshold=20      # idle CPU usage threshold (%)
    local cpu_iowait_threshold=10    # I/O wait threshold (%)
    local cpu_irq_threshold=10       # irq time threshold - hardware interrupts (%)
    local cpu_softirq_threshold=10   # softirq time threshold - software interrupts (%)

    # mpstat output for all CPUs
    mpstat_output="$(mpstat -P ALL 1 1 | grep 'Average' | sed -n '3,$ p')"

    # flag
    issues=0

    # parse and check each line for CPU usage
    while read -r line; do
        cpu_id=$(echo "${line}"  | awk '{print $2}')
        usr=$(echo "${line}"     | awk '{print $3}')
        sys=$(echo "${line}"     | awk '{print $5}')
        iowait=$(echo "${line}"  | awk '{print $6}')
        irq=$(echo "${line}"     | awk '{print $7}')
        softirq=$(echo "${line}" | awk '{print $8}')
        idle=$(echo "${line}"    | awk '{print $12}')

        # check thresholds
        if (( $(echo "${usr} >= ${cpu_user_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] CPU ${cpu_id} - User CPU usage is high: ${usr}%."
            issues=1
        fi

        if (( $(echo "${sys} >= ${cpu_system_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] CPU ${cpu_id} - System CPU usage is high: ${sys}%."
            issues=1
        fi

        if (( $(echo "${idle} <= ${cpu_idle_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] CPU ${cpu_id} - Idle CPU time is low: ${idle}%. The system may be overloaded."
            issues=1
        fi

        if (( $(echo "${iowait} >= ${cpu_iowait_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] CPU ${cpu_id} - I/O wait is high: ${iowait}%. Processes are waiting on I/O."
            issues=1
        fi

        if (( $(echo "${irq} >= ${cpu_irq_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] CPU ${cpu_id} - IRQ time is high: ${irq}%. This may indicate hardware issues."
            issues=1
        fi

        if (( $(echo "${softirq} >= ${cpu_softirq_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] CPU ${cpu_id} - SoftIRQ time is high: ${softirq}%. This may indicate network or software delays."
            issues=1
        fi

    done <<< "${mpstat_output}"

    if [ "$issues" -eq 0 ]; then
        echo "${GREEN}No issues found.${DEFAULT}"
    fi
}

#
# iostat -x 1
#

__check_iostat() {
    echo
    echo "[*] Checking iostat..."

    if [ -z "$(which iostat)" ]; then
        echo "Command 'iostat' is not installed."
        echo "Use: sudo apt-get install sysstat"
        echo "Then rerun the script. Exiting..."
        return 1
    fi

    # threshold values
    local utilization_threshold=70      # utilization threshold (%)
    local read_wait_threshold=10        # average read wait time threshold (ms)
    local write_wait_threshold=10       # average write wait time threshold (ms)
    local queue_size_threshold=1        # average queue size threshold
    local service_time_threshold=10     # service time threshold (ms)

    # iostat output - ignore the first result (i.e., stats since boot time) 
    n_lines_iostat="$(iostat -x 1 1 | wc -l)"
    iostat_output="$(iostat -x 1 2 | sed -n "$((n_lines_iostat +1)),$ p" | sed -n '/Device/,$ p' | tail -n +2)"

    # flag
    issues=0

    # parse and check each line for disk I/O performance
    while read -r line; do
        device=$(echo "${line}" | awk '{print $1}')
        read_await=$(echo "${line}" | awk '{print $10}')
        write_await=$(echo "${line}" | awk '{print $11}')
        queue_size=$(echo "${line}" | awk '{print $12}')
        service_time=$(echo "${line}" | awk '{print $15}')
        utilization=$(echo "${line}" | awk '{print $16}')

        # check thresholds
        if (( $(echo "${utilization} >= ${utilization_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Utilization is high: ${utilization}%."
            issues=1
        fi

        if (( $(echo "${read_await} >= ${read_wait_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Average read wait time is high: ${read_await} ms."
            issues=1
        fi

        if (( $(echo "${write_await} >= ${write_wait_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Average write wait time is high: ${write_await} ms."
            issues=1
        fi

        if (( $(echo "${queue_size} >= ${queue_size_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Average queue size is high: ${queue_size}."
            issues=1
        fi

        if (( $(echo "${service_time} >= ${service_time_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Service time is high: ${service_time} ms."
            issues=1
        fi

    done <<< "${iostat_output}"

    if [ "$issues" -eq 0 ]; then
        echo "${GREEN}No issues found.${DEFAULT}"
    fi
}

#
# sar -n DEV 1
#

__check_sar() {
    echo
    echo "[*] Checking sar..."

    if [ -z "$(which sar)" ]; then
        echo "Command 'sar' is not installed."
        echo "Use: sudo apt-get install sysstat"
        echo "Then rerun the script. Exiting..."
        return 1
    fi

    # threshold values
    # local rx_packets_threshold=1000  # receive packets per second
    # local tx_packets_threshold=1000  # transmit packets per second
    # local rx_kb_threshold=100        # receive kilobytes per second
    # local tx_kb_threshold=100        # transmit kilobytes per second
    local ifutil_threshold=70          # interface utilization threshold (%)

    # sar output for network devices
    sar_output="$(sar -n DEV 1 1 | grep 'Average' | sed -n '2,$ p')"

    # flag
    issues=0

    # parse and check each line for network performance
    while read -r line; do
        device=$(echo "${line}" | awk '{print $2}')
        # rxpck=$(echo "${line}"  | awk '{print $3}')
        # txpck=$(echo "${line}"  | awk '{print $4}')
        # rxkb=$(echo "${line}"   | awk '{print $5}')
        # txkb=$(echo "${line}"   | awk '{print $6}')
        ifutil=$(echo "${line}" | awk '{print $10}')

        # check thresholds
<< 'EOF'
        if (( $(echo "${rxpck} >= ${rx_packets_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Receive packets per second is high: ${rxpck}."
        fi

        if (( $(echo "${txpck} >= ${tx_packets_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Transmit packets per second is high: ${txpck}."
        fi

        if (( $(echo "${rxkb} >= ${rx_kb_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Receive kilobytes per second is high: ${rxkb} KB."
        fi

        if (( $(echo "${txkb} >= ${tx_kb_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Transmit kilobytes per second is high: ${txkb} KB."
        fi
EOF
        if (( $(echo "${ifutil} >= ${ifutil_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] Device ${device} - Interface utilization is high: ${ifutil}%."
            issues=1
        fi

    done <<< "${sar_output}"

    if [ "$issues" -eq 0 ]; then
        echo "${GREEN}No issues found.${DEFAULT}"
    fi
}

#
# pidstat 1
#

__check_pidstat() {
    echo
    echo "[*] Checking pidstat..."

    if [ -z "$(which pidstat)" ]; then
        echo "Command 'pidstat' is not installed."
        echo "Use: sudo apt-get install sysstat"
        echo "Then rerun the script. Exiting..."
        return 1
    fi

    # number of physical cores
    local num_cores=$(grep "core id" /proc/cpuinfo | sort -u | wc -l)

    # threshold values
    local cpu_user_threshold=$((70 * num_cores))    # user CPU time threshold (%)
    local cpu_system_threshold=$((30 * num_cores))  # system CPU time threshold (%)
    local cpu_iowait_threshold=10                   # I/O wait threshold (%)
    local cpu_usage_threshold=$((70 * num_cores))   # %CPU threshold (%)

    # pidstat output
    pidstat_output="$(pidstat | sed -n '4,$ p')"

    # flag
    issues=0

    # parse and check each line for process performance
    while read -r line; do
        pid=$(echo "${line}"        | awk '{print $4}')
        user_cpu=$(echo "${line}"   | awk '{print $5}')
        system_cpu=$(echo "${line}" | awk '{print $6}')
        iowait=$(echo "${line}"     | awk '{print $8}')
        cpu_usage=$(echo "${line}"  | awk '{print $9}')

        # check thresholds
        if (( $(echo "${user_cpu} >= ${cpu_user_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] PID ${pid} - User CPU time is high: ${user_cpu}%."
            issues=1
        fi

        if (( $(echo "${system_cpu} >= ${cpu_system_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] PID ${pid} - System CPU time is high: ${system_cpu}%."
            issues=1
        fi

        if (( $(echo "${iowait} >= ${cpu_iowait_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] PID ${pid} - I/O wait is high: ${iowait}%. This may indicate slow I/O operations."
            issues=1
        fi

        if (( $(echo "${cpu_usage} > ${cpu_usage_threshold}" | bc -l) )); then
            echo "[ ${RED}Warning${DEFAULT} ] PID ${pid} - %CPU usage is high: ${cpu_usage}."
            issues=1
        fi

    done <<< "${pidstat_output}"

    if [ "$issues" -eq 0 ]; then
        echo "${GREEN}No issues found.${DEFAULT}"
    fi
}

__main() {
    __load_color
    __check_sysinfo
    __check_free
    __check_uptime
    __check_top
    __check_vmstat
    __check_mpstat
    __check_iostat
    __check_sar
    __check_pidstat
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    __main
fi
