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
INTERACTIVE=false

# Function to display help
show_help() {
    echo -e "${GREEN}XSSHunterPro++ - Advanced Vulnerability Scanner${NC}"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --domain DOMAIN       Target domain (e.g., example.com)"
    echo "  --output DIR          Output directory (default: results)"
    echo "  --threads NUM         Number of threads (default: 10)"
    echo "  --tools TOOLS         Comma-separated list of tools to use (default: amass,subfinder,assetfinder,findomain,gospider,waybackurls,gau,paramspider)"
    echo "  --vuln TYPES          Comma-separated list of vulnerabilities to test (default: xss,sqli,lfi,crlf)"
    echo "  --exploit             Automatically exploit vulnerabilities (default: false)"
    echo "  --interactive         Run in interactive mode"
    echo "  --help                Show this help message"
    exit 0
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --domain)
            DOMAIN="$2"
            shift 2
            ;;
        --output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --threads)
            THREADS="$2"
            shift 2
            ;;
        --tools)
            TOOLS="$2"
            shift 2
            ;;
        --vuln)
            VULN_TYPES="$2"
            shift 2
            ;;
        --exploit)
            EXPLOIT=true
            shift
            ;;
        --interactive)
            INTERACTIVE=true
            shift
            ;;
        --help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_help
            ;;
    esac
done

# Check if domain is provided
if [[ -z "$DOMAIN" && "$INTERACTIVE" == false ]]; then
    echo -e "${RED}Error: Domain is required. Use --domain or --interactive.${NC}"
    show_help
fi

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
                mv "$DOMAIN.txt" "$OUTPUT_DIR/findomain.txt"
                ;;
            gospider)
                echo -e "${YELLOW}Running GoSpider...${NC}"
                gospider -s "http://$DOMAIN" -o "$OUTPUT_DIR/gospider.txt" &
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
                paramspider -d "$DOMAIN" -o "$OUTPUT_DIR/paramspider.txt" &
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
                python3 xss_scanner.py --urls "$OUTPUT_DIR/filtered_urls.txt" --output "$OUTPUT_DIR/xss_results.txt"
                ;;
            sqli)
                echo -e "${YELLOW}Testing for SQL Injection...${NC}"
                python3 sqli_scanner.py --urls "$OUTPUT_DIR/filtered_urls.txt" --output "$OUTPUT_DIR/sqli_results.txt"
                ;;
            lfi)
                echo -e "${YELLOW}Testing for LFI...${NC}"
                python3 lfi_scanner.py --urls "$OUTPUT_DIR/filtered_urls.txt" --output "$OUTPUT_DIR/lfi_results.txt"
                ;;
            crlf)
                echo -e "${YELLOW}Testing for CRLF...${NC}"
                python3 crlf_scanner.py --urls "$OUTPUT_DIR/filtered_urls.txt" --output "$OUTPUT_DIR/crlf_results.txt"
                ;;
            *)
                echo -e "${RED}Unknown vulnerability type: $vuln${NC}"
                ;;
        esac
    done
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

# Main function
main() {
    if [[ "$INTERACTIVE" == true ]]; then
        echo -e "${BLUE}Running in interactive mode...${NC}"
        read -p "Enter the target domain: " DOMAIN
        read -p "Enter the output directory (default: results): " OUTPUT_DIR
        OUTPUT_DIR=${OUTPUT_DIR:-"results"}
        read -p "Enter the number of threads (default: 10): " THREADS
        THREADS=${THREADS:-10}
        read -p "Enter the tools to use (comma-separated, default: amass,subfinder,assetfinder,findomain,gospider,waybackurls,gau,paramspider): " TOOLS
        TOOLS=${TOOLS:-"amass,subfinder,assetfinder,findomain,gospider,waybackurls,gau,paramspider"}
        read -p "Enter the vulnerabilities to test (comma-separated, default: xss,sqli,lfi,crlf): " VULN_TYPES
        VULN_TYPES=${VULN_TYPES:-"xss,sqli,lfi,crlf"}
        read -p "Automatically exploit vulnerabilities? (y/n): " EXPLOIT_INPUT
        if [[ "$EXPLOIT_INPUT" =~ ^[Yy]$ ]]; then
            EXPLOIT=true
        fi
    fi

    install_tools
    crawl_urls
    filter_urls
    test_vulnerabilities
    generate_report

    echo -e "${GREEN}Scan completed! Results saved in $OUTPUT_DIR.${NC}"
}

# Run the script
main | lolcat
