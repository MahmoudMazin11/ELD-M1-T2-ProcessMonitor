#!/usr/bin/bash -i

source Process_Monitor.conf


function P_Info () {
    IN_EXIT="IN_PROCESS"
    echo "------------------"
    echo "To QUIT press 'q' "
    echo "------------------"
    read -rp "Enter PROCESS ID (PID) : " pid
    if [ -d "/proc/${pid}" ]; then
        echo "PID:Process ID | PPID:Parent PID | VSZ : Virtual Size (Kib) | RSS : Resident Size (KiB)"
        echo ""
        ps -o pid,ppid,user,vsz,rss,%cpu,%mem,comm -p "${pid}" | column -t
    else
        echo "Process ID : ${pid}' not exists"
        echo "PROCESS '${pid}' doesn't exist to be displayed   $formatted_time" >> ./log.txt
    fi

    stty -echo
    while [[ "${IN_EXIT}" != "q" ]]; do
        read -r -n 1 IN_EXIT
    done
    stty echo

}

function P_Kill () {
    IN_EXIT="IN_PROCESS"
    FLAG=255
    echo "------------------"
    echo "To QUIT press 'q' "
    echo "------------------"
    read -rp "Enter PROCESS ID (PID) To Kill  : " pid
    
    if [[ -d "/proc/${pid}" ]]; then    
            kill -15 "${pid}" &&  FLAG=1  || FLAG=0 
            if [ $FLAG == 1 ]; then
                formatted_time=$(date +%Y-%m-%d_%H:%M:%S)
                echo "Process No. ${pid} terminated successfully."
                echo "Process No. ${pid} terminated successfully .   $formatted_time" >> ./log.txt
            elif [ $FLAG == 0 ]; then
                formatted_time=$(date +%Y-%m-%d_%H:%M:%S)
                echo "Error: Failed to terminate Process No. ${pid}."
                echo "Error: Failed to terminate Process No. ${pid}.   $formatted_time" >> ./log.txt

            fi
            
    else
        formatted_time=$(date +%Y-%m-%d_%H:%M:%S)
        echo "PROCESS '${pid}' doesn't exist "
        echo "PROCESS '${pid}' doesn't exist to be terminated   $formatted_time" >> ./log.txt

    fi

    stty -echo
    while [[ "${IN_EXIT}" != "q" ]]; do
        read -r -n 1 IN_EXIT
    done
    stty echo

}

function P_stats () {
    IN_EXIT="IN_PROCESS"
    echo "------------------"
    echo "To QUIT press 'q' "
    echo "------------------"
    echo "User:$USER displays overall system stats   $formatted_time" >> ./log.txt
    top | awk 'NR >= 2 && NR <= 5'
}

function Set_alert () {
    ps -eo user,pid,%cpu,%mem,comm --sort=-%cpu | head -n 30 | while IFS= read -r line; do
    
        user=$(echo "$line" | awk '{print $1}')
        pid=$(echo "$line" | awk '{print $2}')
        cpu_percent=$(echo "$line" | awk '{print $3}')
        memory_percent=$(echo "$line" | awk '{print $4}')
        command=$(echo "$line" | awk '{print $5}')

        cpu_usage_int=${cpu_percent%.*}
        mem_usage_int=${memory_percent%.*}
        
        if [[ "$cpu_usage_int" =~ ^[-+]?[0-9]+$ ]] &&(( "$cpu_usage_int" >= "$CPU_ALERT_THRESHOLD" )); then
            echo "WARNING: Process $pid ($user - $command) using high CPU ($cpu_percent%)"
            if grep -q "WARNING: Process $pid ($user - $command) using high CPU ($cpu_percent%)" "./log.txt"; then
                :
            else
                formatted_time=:$(date +%Y-%m-%d_%H:%M:%S)
                echo "WARNING: Process $pid ($user - $command) using high CPU ($cpu_percent%)   $formatted_time" >> ./log.txt
            fi
        fi

        if [[ "$mem_usage_int" =~ ^[-+]?[0-9]+$ ]] &&(( "$mem_usage_int" >= "$MEMORY_ALERT_THRESHOLD" )); then
            echo "WARNING: Process $pid ($user - $command) using high MEM ($memory_percent%)"
            if grep -q "WARNING: Process $pid ($user - $command) using high MEM ($memory_percent%)" "./log.txt"; then
                :
            else
                formatted_time=:$(date +%Y-%m-%d_%H:%M:%S)
                echo "WARNING: Process $pid ($user - $command) using high MEM ($memory_percent%)   $formatted_time" >> ./log.txt
            fi
        fi
    done 
}

function P_RMonitoring () {
    IN_EXIT="IN_PROCESS"
    formatted_time=:$(date +%Y-%m-%d_%H:%M:%S)
    echo "User:$USER performs REAL-TIME Monitoring   $formatted_time" >> ./log.txt
    stty -echo
    INTERVAL=$(( UPDATE_INTERVAL / 2 ))
    while [[ "${IN_EXIT}" != "q" ]]; do
        echo "---------------------------------------------------------"
        echo "To QUIT press 'q' , HOLD press 'h' , Continue press 'c' "
        echo "----------------------------------------------------------"
        ps -eo user,pid,ppid,%cpu,%mem,vsz,rss,comm --sort=-%cpu| head -n 20 |column -t 
        echo "--------------------------------------------------"
        Set_alert
        read -t "$INTERVAL" -r -n 1 IN_EXIT || sleep "$INTERVAL" ;  
        if [[ "${IN_EXIT}" == "h" ]];then
            read -r -n 1 IN_EXIT
        fi
        clear
    done
    formatted_time=:$(date +%Y-%m-%d_%H:%M:%S)
    echo "User:$USER exits REAL-TIME Monitoring   $formatted_time" >> ./log.txt
    stty echo
}

function P_Search () {
    IN_EXIT="IN_PROCESS"
    ITEM="no"
    echo "------------------"
    echo "To QUIT press 'q' "
    echo "------------------"
    echo "To Search by USER press 'u  , by Name press 'n' , by CPU% press 'c' , by MEM% press 'm' "
    echo "------------------"
    stty -echo
    read -r -n 1 ITEM
    stty echo

    case "${ITEM}" in
        u)
            read -rp "Enter USER to search : " uSearch
            ps -u "$uSearch" -o user,pid,ppid,%cpu,%mem,comm --sort=pid
        ;;
        n)
            read -rp "Enter Name to search : " name
            echo "USER     PID   PPID  CMD"
            ps -eo user,pid,ppid,comm --sort=pid | grep "$name" | column -t
            
        ;;
        c)
            ps -eo user,pid,ppid,%cpu,%mem,comm --sort=-%cpu| head -n 20 |column -t 
        ;;
        m)
            ps -eo user,pid,ppid,%mem,vsz,rss,%cpu,comm --sort=-%mem| head -n 20 |column -t         
        ;;
        *)
            echo "default (none of above)"
        ;;
    esac
    
    stty -echo
    while [[ "${IN_EXIT}" != "q" ]]; do
        read -r -n 1 IN_EXIT
    done
    stty echo

}

############################################ MAIN PROGRAM ############################################
declare -i EXIT=1
declare -i CHOOSE=255
echo "-----------------------------------------"
echo "--------------WELCOME $USER------------"
echo "-----------------------------------------"

touch log.txt
echo "BEGINNING OF LOG FILE" > ./log.txt
while [[ $EXIT == 1 ]]; do
    echo "CHOOSE 1 To Display PROCESSES INFO"
    echo "CHOOSE 2 To Kill a PROCESS"
    echo "CHOOSE 3 To Display Overall System Statistics"
    echo "CHOOSE 4 To Real-Time Monitoring"
    echo "CHOOSE 5 To Search and Filter  PROCESSES"
    echo "CHOOSE 6 To Terminate"
    read -rp "YOUR CHOICE : " CHOOSE;
    case "${CHOOSE}" in
        1)
            P_Info
        ;;
        2)
            P_Kill
        ;;
        3)
            P_stats
        ;;
        4)
            P_RMonitoring
        ;;
        5)
            P_Search
        ;;
        6)
            echo "PROCESS_MONITOR TERMINATED"
            echo "END OF LOG FILE" >> ./log.txt
            EXIT=0
        ;;
        *)
            echo "WRONG CHOICE!"
        ;;
    esac
    echo "-----------------------------------------"


done

