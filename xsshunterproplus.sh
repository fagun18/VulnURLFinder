#!/bin/bash

# Banner
echo -e "${BLUE}"
echo "  __  __  ____  ____  _   _ _   _ _____ ____ ____  ____  "
echo " |  \/  |/ ___||  _ \| | | | \ | | ____|  _ \___ \|  _ \ "
echo " | |\/| |\___ \| |_) | | | |  \| |  _| | |_) |__) | |_) |"
echo " | |  | | ___) |  __/| |_| | |\  | |___|  _ </ __/|  __/ "
echo " |_|  |_|____/|_|    \___/|_| \_|_____|_| \_\____|_|    "
echo -e "${NC}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Variables
DOMAIN=""
OUTPUT_DIR="results"
THREADS=10
TOOLS="amass,subfinder,assetfinder,findomain,gospider,waybackurls,gau,paramspider"
VULN_TYPES="xss,sqli,lfi,crlf"
EXPLOIT=false

# Function to display menu
show_menu() {
    clear
    echo -e "${BLUE}"
    echo "┌──────────────────────────────────────────────┐"
    echo "│               XSSHunterPro++                │"
    echo "├──────────────────────────────────────────────┤"
    echo "│ 1. Subdomain Enumeration                     │"
    echo "│ 2. URL Discovery                             │"
    echo "│ 3. Vulnerability Scanning                    │"
    echo "│ 4. Full Scan (Subdomain + URL + Vuln Scan)   │"
    echo "│ 5. Update Tool                               │"
    echo "│ 6. Install all tools                         │"
    echo "│ 7. Help                                      │"
    echo "│ 8. Exit                                      │"
    echo "└──────────────────────────────────────────────┘"
    echo -e "${NC}"
}

# Function to install tools
install_tools() {
    echo -e "${BLUE}Installing required tools...${NC}"
    sudo apt update
    sudo apt install -y git python3 python3-pip golang lolcat parallel
    pip3 install --upgrade pip
    pip3 install uro arjun qsreplace

    # Install Go tools
    go install github.com/OWASP/Amass/v3/...@latest
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install github.com/tomnomnom/assetfinder@latest
    go install github.com/Findomain/Findomain@latest
    go install github.com/jaeles-project/gospider@latest
    go install github.com/tomnomnom/waybackurls@latest
    go install github.com/lc/gau/v2/cmd/gau@latest
    go install github.com/devanshbatham/paramspider@latest
    go install github.com/hakluke/hakrawler@latest
    go install github.com/projectdiscovery/katana/cmd/katana@latest
    go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
    go install github.com/hahwul/dalfox/v2@latest

    echo -e "${GREEN}Tools installed successfully!${NC}"
}

# Function to crawl URLs
crawl_urls() {
    echo -e "${BLUE}Crawling URLs for $DOMAIN...${NC}"
    mkdir -p "$OUTPUT_DIR"
    TOOL_LIST=($(echo "$TOOLS" | tr ',' ' '))

    for tool in "${TOOL_LIST[@]}"; do
        case "$tool" in
            amass)
                echo -e "${YELLOW}Running Amass...${NC}"
                amass enum -d "$DOMAIN" -o "$OUTPUT_DIR/amass.txt" &
                ;;
            subfinder)
                echo -e "${YELLOW}Running Subfinder...${NC}"
                subfinder -d "$DOMAIN" -o "$OUTPUT_DIR/subfinder.txt" &
                ;;
            assetfinder)
                echo -e "${YELLOW}Running Assetfinder...${NC}"
                assetfinder "$DOMAIN" > "$OUTPUT_DIR/assetfinder.txt" &
                ;;
            findomain)
                echo -e "${YELLOW}Running Findomain...${NC}"
                findomain -t "$DOMAIN" -o &
                mv "$DOMAIN.txt" "$OUTPUT_DIR/findomain.txt" 2>/dev/null || echo -e "${RED}Findomain output file not found!${NC}"
                ;;
            gospider)
                echo -e "${YELLOW}Running GoSpider...${NC}"
                gospider -s "http://$DOMAIN" -o "$OUTPUT_DIR/gospider" &
                ;;
            waybackurls)
                echo -e "${YELLOW}Running Waybackurls...${NC}"
                waybackurls "$DOMAIN" > "$OUTPUT_DIR/waybackurls.txt" &
                ;;
            gau)
                echo -e "${YELLOW}Running Gau...${NC}"
                gau "$DOMAIN" > "$OUTPUT_DIR/gau.txt" &
                ;;
            paramspider)
                echo -e "${YELLOW}Running ParamSpider...${NC}"
                paramspider -d "$DOMAIN" -o "$OUTPUT_DIR/paramspider" &
                ;;
            hakrawler)
                echo -e "${YELLOW}Running Hakrawler...${NC}"
                hakrawler -url "http://$DOMAIN" -depth 3 -scope subs -plain > "$OUTPUT_DIR/hakrawler.txt" &
                ;;
            katana)
                echo -e "${YELLOW}Running Katana...${NC}"
                katana -u "http://$DOMAIN" -o "$OUTPUT_DIR/katana.txt" &
                ;;
            *)
                echo -e "${RED}Unknown tool: $tool${NC}"
                ;;
        esac
    done
    wait
    echo -e "${GREEN}Crawling completed!${NC}"
}

# Function to filter URLs
filter_urls() {
    echo -e "${BLUE}Filtering URLs...${NC}"
    cat "$OUTPUT_DIR"/*.txt | sort -u > "$OUTPUT_DIR/all_urls.txt"
    grep -E "^(http|https)://" "$OUTPUT_DIR/all_urls.txt" | uro > "$OUTPUT_DIR/filtered_urls.txt"
    echo -e "${GREEN}Filtering completed!${NC}"
}

# Function to test vulnerabilities
test_vulnerabilities() {
    echo -e "${BLUE}Testing vulnerabilities...${NC}"
    VULN_LIST=($(echo "$VULN_TYPES" | tr ',' ' '))

    for vuln in "${VULN_LIST[@]}"; do
        case "$vuln" in
            xss)
                echo -e "${YELLOW}Testing for XSS...${NC}"
                dalfox file "$OUTPUT_DIR/filtered_urls.txt" -o "$OUTPUT_DIR/xss_results.txt" &
                ;;
            sqli)
                echo -e "${YELLOW}Testing for SQL Injection...${NC}"
                sqlmap -m "$OUTPUT_DIR/filtered_urls.txt" --batch -o "$OUTPUT_DIR/sqli_results.txt" &
                ;;
            lfi)
                echo -e "${YELLOW}Testing for LFI...${NC}"
                nuclei -t ~/nuclei-templates/lfi.yaml -l "$OUTPUT_DIR/filtered_urls.txt" -o "$OUTPUT_DIR/lfi_results.txt" &
                ;;
            crlf)
                echo -e "${YELLOW}Testing for CRLF...${NC}"
                nuclei -t ~/nuclei-templates/crlf.yaml -l "$OUTPUT_DIR/filtered_urls.txt" -o "$OUTPUT_DIR/crlf_results.txt" &
                ;;
            *)
                echo -e "${RED}Unknown vulnerability type: $vuln${NC}"
                ;;
        esac
    done
    wait
    echo -e "${GREEN}Vulnerability testing completed!${NC}"
}

# Function to update the tool
update_tool() {
    echo -e "${BLUE}Updating the tool...${NC}"
    git clone https://github.com/fagun18/VulnURLFinder.git /tmp/VulnURLFinder
    cp -r /tmp/VulnURLFinder/* .
    rm -rf /tmp/VulnURLFinder
    echo -e "${GREEN}Tool updated successfully!${NC}"
}

# Function to display help
show_help() {
    echo -e "${BLUE}"
    echo "┌──────────────────────────────────────────────┐"
    echo "│               XSSHunterPro++ Help            │"
    echo "├──────────────────────────────────────────────┤"
    echo "│ 1. Subdomain Enumeration                     │"
    echo "│    - Enumerate subdomains using Amass, Subfinder, etc."
    echo "│ 2. URL Discovery                             │"
    echo "│    - Discover URLs using GoSpider, Waybackurls, etc."
    echo "│ 3. Vulnerability Scanning                    │"
    echo "│    - Scan for vulnerabilities like XSS, SQLi, LFI, etc."
    echo "│ 4. Full Scan (Subdomain + URL + Vuln Scan)   │"
    echo "│    - Perform a full scan including all steps."
    echo "│ 5. Update Tool                               │"
    echo "│    - Update the tool to the latest version."
    echo "│ 6. Install all tools                         │"
    echo "│    - Install all required tools."
    echo "│ 7. Help                                      │"
    echo "│    - Show this help menu."
    echo "│ 8. Exit                                      │"
    echo "│    - Exit the script."
    echo "└──────────────────────────────────────────────┘"
    echo -e "${NC}"
}

# Function to perform full scan
full_scan() {
    echo -e "${BLUE}Starting Full Scan...${NC}"
    read -p "Enter the target domain: " DOMAIN
    read -p "Enter the output directory (default: results): " OUTPUT_DIR
    OUTPUT_DIR=${OUTPUT_DIR:-"results"}
    read -p "Enter the number of threads (default: 10): " THREADS
    THREADS=${THREADS:-10}

    install_tools
    crawl_urls
    filter_urls
    test_vulnerabilities

    echo -e "${GREEN}Full Scan completed! Results saved in $OUTPUT_DIR.${NC}"
}

# Main function
main() {
    while true; do
        show_menu
        read -p "Select an option (1-8): " choice

        case "$choice" in
            1)
                read -p "Enter the target domain: " DOMAIN
                read -p "Enter the output directory (default: results): " OUTPUT_DIR
                OUTPUT_DIR=${OUTPUT_DIR:-"results"}
                install_tools
                crawl_urls
                ;;
            2)
                read -p "Enter the target domain: " DOMAIN
                read -p "Enter the output directory (default: results): " OUTPUT_DIR
                OUTPUT_DIR=${OUTPUT_DIR:-"results"}
                install_tools
                crawl_urls
                filter_urls
                ;;
            3)
                read -p "Enter the target domain: " DOMAIN
                read -p "Enter the output directory (default: results): " OUTPUT_DIR
                OUTPUT_DIR=${OUTPUT_DIR:-"results"}
                install_tools
                crawl_urls
                filter_urls
                test_vulnerabilities
                ;;
            4)
                full_scan
                ;;
            5)
                update_tool
                ;;
            6)
                install_tools
                ;;
            7)
                show_help
                ;;
            8)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option! Please select a valid option.${NC}"
                ;;
        esac

        read -p "Press Enter to continue..."
    done
}

# Run the script
main | lolcat
