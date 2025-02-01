#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m' # No Color

# Variables
DOMAIN=""
OUTPUT_DIR="results"
THREADS=5
TOOLS="gospider,hakrawler,katana"
VULN_TYPES="xss"
INTERACTIVE=false

# Function to display help
show_help() {
    echo -e "${GREEN}VulnURLFinder - Advanced URL Vulnerability Scanner${NC}"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --domain DOMAIN       Target domain (e.g., example.com)"
    echo "  --output DIR          Output directory (default: results)"
    echo "  --threads NUM         Number of threads (default: 5)"
    echo "  --tools TOOLS         Comma-separated list of tools to use (default: gospider,hakrawler,katana)"
    echo "  --vuln TYPES          Comma-separated list of vulnerabilities to test (default: xss)"
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
    sudo apt install -y git python3 python3-pip golang
    pip3 install --upgrade pip
    pip3 install uro arjun

    # Install Go tools
    go install github.com/jaeles-project/gospider@latest
    go install github.com/hakluke/hakrawler@latest
    go install github.com/projectdiscovery/katana/cmd/katana@latest

    echo -e "${GREEN}Tools installed successfully!${NC}"
}

# Function to crawl URLs
crawl_urls() {
    echo -e "${BLUE}Crawling URLs for $DOMAIN...${NC}"
    mkdir -p "$OUTPUT_DIR"
    TOOL_LIST=($(echo "$TOOLS" | tr ',' ' '))

    for tool in "${TOOL_LIST[@]}"; do
        case "$tool" in
            gospider)
                echo -e "${YELLOW}Running GoSpider...${NC}"
                gospider -s "http://$DOMAIN" -o "$OUTPUT_DIR/gospider.txt" &
                ;;
            hakrawler)
                echo -e "${YELLOW}Running Hakrawler...${NC}"
                echo "http://$DOMAIN" | hakrawler -depth 3 -plain > "$OUTPUT_DIR/hakrawler.txt" &
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
    grep -E "^(http|https)://" "$OUTPUT_DIR/all_urls.txt" > "$OUTPUT_DIR/filtered_urls.txt"
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
                cat "$OUTPUT_DIR/filtered_urls.txt" | dalfox pipe --silence --skip-bav -o "$OUTPUT_DIR/xss_results.txt"
                ;;
            sqli)
                echo -e "${YELLOW}Testing for SQL Injection...${NC}"
                sqlmap -m "$OUTPUT_DIR/filtered_urls.txt" --batch -o "$OUTPUT_DIR/sqli_results.txt"
                ;;
            *)
                echo -e "${RED}Unknown vulnerability type: $vuln${NC}"
                ;;
        esac
    done
    echo -e "${GREEN}Vulnerability testing completed!${NC}"
}

# Main function
main() {
    if [[ "$INTERACTIVE" == true ]]; then
        echo -e "${BLUE}Running in interactive mode...${NC}"
        read -p "Enter the target domain: " DOMAIN
        read -p "Enter the output directory (default: results): " OUTPUT_DIR
        OUTPUT_DIR=${OUTPUT_DIR:-"results"}
        read -p "Enter the number of threads (default: 5): " THREADS
        THREADS=${THREADS:-5}
        read -p "Enter the tools to use (comma-separated, default: gospider,hakrawler,katana): " TOOLS
        TOOLS=${TOOLS:-"gospider,hakrawler,katana"}
        read -p "Enter the vulnerabilities to test (comma-separated, default: xss): " VULN_TYPES
        VULN_TYPES=${VULN_TYPES:-"xss"}
    fi

    install_tools
    crawl_urls
    filter_urls
    test_vulnerabilities

    echo -e "${GREEN}Scan completed! Results saved in $OUTPUT_DIR.${NC}"
}

# Run the script
main
