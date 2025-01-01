#!/bin/bash

# Default values for arguments
interval=10
format="text"

# Function to display usage
usage() {
    echo "Usage: $0 [--interval seconds] [--format text|JSON|CSV]"
    exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --interval) interval="$2"; shift ;;
        --format) format="$2"; shift ;;
        *) usage ;;
    esac
    shift
done

# Validate inputs
if ! [[ "$interval" =~ ^[0-9]+$ ]]; then
    echo "Error: Interval must be a positive integer."
    exit 1
fi

if ! [[ "$format" =~ ^(text|JSON|CSV)$ ]]; then
    echo "Error: Format must be one of text, JSON, or CSV."
    exit 1
fi

# Function to collect system information
collect_system_info() {
    # Get CPU usage (percentage)
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

    # Get Memory usage
    mem_info=$(free -m)
    total_mem=$(echo "$mem_info" | awk '/^Mem:/ {print $2}')
    used_mem=$(echo "$mem_info" | awk '/^Mem:/ {print $3}')
    mem_usage=$(echo "scale=2; ($used_mem/$total_mem)*100" | bc)

    # Get Disk usage (mounted filesystems)
    disk_info=$(df -h --output=source,size,used,avail,pcent | tail -n +2)

    # Get Top 5 CPU-consuming processes
    top_processes=$(ps -eo pid,comm,%cpu --sort=-%cpu | head -n 6 | tail -n +2)
}

# Function to generate the report in text format
generate_text_report() {
    echo "CPU Usage: $cpu_usage%"
    echo "Memory Usage: $mem_usage%"
    echo -e "\nDisk Usage:"
    echo "$disk_info" | awk '{printf "%-20s %-10s %-10s %-10s %-10s\n", $1, $2, $3, $4, $5}'
    echo -e "\nTop 5 CPU-Consuming Processes:"
    echo "PID    Command            CPU Usage"
    echo "$top_processes" | awk '{printf "%-6s %-20s %-10s\n", $1, $2, $3}'
}

# Function to generate the report in JSON format
generate_json_report() {
    echo "{"
    echo "  \"CPU_Usage\": \"$cpu_usage\","
    echo "  \"Memory_Usage\": \"$mem_usage\","
    echo "  \"Disk_Usage\": ["
    echo "$disk_info" | awk '{print "    {\"Filesystem\": \"" $1 "\", \"Total\": \"" $2 "\", \"Used\": \"" $3 "\", \"Available\": \"" $4 "\", \"Usage\": \"" $5 "\"},"}'
    echo "  ],"
    echo "  \"Top_Processes\": ["
    echo "$top_processes" | awk '{print "    {\"PID\": \"" $1 "\", \"Command\": \"" $2 "\", \"CPU_Usage\": \"" $3 "\"},"}'
    echo "  ]"
    echo "}"
}

# Function to generate the report in CSV format
generate_csv_report() {
    # CPU and Memory Usage
    echo "CPU Usage, Memory Usage"
    echo "$cpu_usage%, $mem_usage%"

    # Disk Usage
    echo -e "\nDisk Usage"
    echo "Filesystem, Total, Used, Available, Usage"
    echo "$disk_info" | awk '{printf "%s, %s, %s, %s, %s\n", $1, $2, $3, $4, $5}'

    # Top Processes
    echo -e "\nTop 5 CPU-Consuming Processes"
    echo "PID, Command, CPU Usage"
    echo "$top_processes" | awk '{printf "%s, %s, %s\n", $1, $2, $3}'
}

# Main loop for monitoring
while true; do
    collect_system_info

    # Generate report based on format
    case $format in
        text) generate_text_report ;;
        JSON) generate_json_report ;;
        CSV) generate_csv_report ;;
        *) echo "Error: Unsupported format"; exit 1 ;;
    esac
    sleep "$interval"
done
