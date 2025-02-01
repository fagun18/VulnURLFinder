#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 -d <domain>"
    exit 1
}

# Parse command-line arguments
while getopts ":d:" opt; do
    case $opt in
        d) domain_name="$OPTARG" ;;
        *) usage ;;
    esac
done

# Check if domain name is provided
if [ -z "$domain_name" ]; then
    usage
fi

# Step 1: Domain Enumeration
echo "Starting domain enumeration for $domain_name..."
dnsbruter -d "$domain_name" -w subs-dnsbruter-small.txt -c 150 -wt 80 -rt 500 -wd -ws wild.txt -o output-dnsbruter.txt
subdominator -d "$domain_name" -o output-subdominator.txt
cat output-dnsbruter.txt output-subdominator.txt > "${domain_name}-domains.txt"
rm output-dnsbruter.txt output-subdominator.txt

# Step 2: URL Crawling
echo "Starting URL crawling for $domain_name..."
gospider -S "${domain_name}-domains.txt" -c 10 -d 5 | tee -a "${domain_name}-gospider.txt"
cat "${domain_name}-domains.txt" | hakrawler -d 3 | tee -a "${domain_name}-hakrawler.txt"
cat "${domain_name}-domains.txt" | katana -jc | tee -a "${domain_name}-katana.txt"
cat "${domain_name}-domains.txt" | waybackurls | tee -a "${domain_name}-waybackurls.txt"
cat "${domain_name}-domains.txt" | gau | tee -a "${domain_name}-gau.txt"

# Step 3: URL Filtering
echo "Filtering URLs..."
grep -oP 'http[^\s]*' "${domain_name}-gospider.txt" > "${domain_name}-gospider1.txt"
grep -oP 'http[^\s]*' "${domain_name}-hakrawler.txt" > "${domain_name}-hakrawler1.txt"
uro -i "${domain_name}-gospider1.txt" -o urogospider.txt
uro -i "${domain_name}-hakrawler1.txt" -o urohakrawler.txt
uro -i "${domain_name}-katana.txt" -o urokatana.txt
uro -i "${domain_name}-waybackurls.txt" -o urowaybackurls.txt
uro -i "${domain_name}-gau.txt" -o urogau.txt
cat urogospider.txt urohakrawler.txt urokatana.txt urowaybackurls.txt urogau.txt > "${domain_name}-links-final.txt"
rm urogospider.txt urohakrawler.txt urokatana.txt urowaybackurls.txt urogau.txt

# Step 4: XSS Testing
echo "Starting XSS testing..."
./xss0r --get --urls "${domain_name}-links-final.txt" --payloads payloads.txt --shuffle --threads 10 --path

echo "XSS testing completed. Check the output files for results."
