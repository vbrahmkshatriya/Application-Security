#!/bin/bash

# Function to display help
function show_help() {
    echo "Usage: $0 -d <domain> | -f <file> | -h"
    echo
    echo "Options:"
    echo "  -d <domain>  Enumerate subdomains using Sublist3r and Amass, and combine results."
    echo "  -f <file>    Verify subdomains from the given file to check if they are live using httprobe."
    echo "  -h           Show this help message."
}

# Check if no arguments were provided
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# Parse command line arguments
while getopts "d:f:h" opt; do
    case ${opt} in
        d)
            DOMAIN=$OPTARG
            MODE="enumerate"
            ;;
        f)
            FILE=$OPTARG
            MODE="verify"
            ;;
        h)
            show_help
            exit 0
            ;;
        *)
            show_help
            exit 1
            ;;
    esac
done

# Function to enumerate subdomains
function enumerate_subdomains() {
    local domain=$1
    local sublist3r_output="sublist3r_$domain.txt"
    local amass_output="amass_$domain.txt"
    local combined_output="combined_subdomains_$domain.txt"
    local ip_output="amass_ips_$domain.txt"

    # Run Sublist3r
    echo "[*] Running Sublist3r for domain: $domain"
    sublist3r -d $domain -o $sublist3r_output

    # Check if Sublist3r succeeded
    if [ $? -ne 0 ]; then
        echo "[!] Sublist3r failed to run"
        echo "install sublist3r by executing following command: "
        echo "sudo apt-get install sublist3r"
        exit 1
    fi

    # Run Amass
    echo "[*] Running Amass for domain: $domain"
    amass enum -d $domain -o $amass_output

    # Check if Amass succeeded
    if [ $? -ne 0 ]; then
        echo "[!] Amass failed to run"
        echo "install amass by executing following command: "
        echo "sudo apt-get install amass"
        exit 1
    fi

    # Combine subdomain results
    echo "[*] Combining results from Sublist3r and Amass"
    cat $sublist3r_output $amass_output | sort -u > $combined_output

    # Extract IP addresses from Amass output
    echo "[*] Extracting IP addresses from Amass output"
    grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' $amass_output | sort -u > $ip_output

    # Print the combined subdomains and IP addresses
    echo "[*] Combined subdomains saved in $combined_output"
    cat $combined_output
    echo "[*] IP addresses saved in $ip_output"
    cat $ip_output
}

# Function to verify live subdomains
function verify_subdomains() {
    local file=$1
    local live_output="live_subdomains_$domain.txt"

    # Verify live subdomains using httprobe
    echo "[*] Verifying live subdomains from file: $file"
    cat $file | httprobe > $live_output

    # Print live subdomains
    echo "[*] Live subdomains saved in $live_output"
    cat $live_output
}

# Execute the appropriate function based on the mode
if [ "$MODE" == "enumerate" ]; then
    enumerate_subdomains $DOMAIN
elif [ "$MODE" == "verify" ]; then
    verify_subdomains $FILE
else
    show_help
    exit 1
fi

exit 0
