#!/bin/bash

# Define colors
BOLD_WHITE='\033[1;97m'
BOLD_BLUE='\033[1;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

# Banner
display_banner() {
    echo -e "${BOLD_BLUE}"
    echo "               ___         ____                              ____  "
    echo "__  _____ ___ / _ \ _ __  |  _ \ ___  ___ ___  _ __   __   _|___ \ V2"
    echo "\ \/ / __/ __| | | | '__| | |_) / _ \/ __/ _ \| '_ \  \ \ / / __) |"
    echo " >  <\__ \__ \ |_| | |    |  _ <  __/ (_| (_) | | | |  \ V / / __/ "
    echo "/_/\_\___/___/\___/|_|    |_| \_\___|\___\___/|_| |_|   \_/ |_____|"
    echo -e "${NC}"
    echo -e "${BOLD_BLUE}                      Website: store.xss0r.com${NC}"
    echo -e "${BOLD_BLUE}                      Free BlindXSS Testing: xss0r.com${NC}"
    echo -e "${BOLD_BLUE}                      X: x.com/xss0r${NC}"
    echo -e "\n"
}

# Menu
display_menu() {
    echo -e "${BOLD_BLUE}Please select an option:${NC}"
    echo -e "${RED}1: Start Scan${NC}"
    echo -e "${RED}2: Install All Tools${NC}"
    echo -e "${RED}3: Exit${NC}"
}

# Install all tools
install_tools() {
    echo -e "${BOLD_WHITE}Installing all required tools...${NC}"
    sudo apt update
    sudo apt install -y python3 python3-pip python3-venv git wget curl tmux golang-go unzip
    sudo pip3 install --upgrade pip

    # Install Python tools
    pip3 install uro arjun requests bs4 lxml colorama

    # Install Go tools
    go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go install github.com/tomnomnom/assetfinder@latest
    go install github.com/tomnomnom/waybackurls@latest
    go install github.com/lc/gau/v2/cmd/gau@latest
    go install github.com/hakluke/hakrawler@latest
    go install github.com/jaeles-project/gospider@latest
    go install github.com/projectdiscovery/katana/cmd/katana@latest
    go install github.com/projectdiscovery/httpx/cmd/httpx@latest
    go install github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest

    # Add Go binaries to PATH
    export PATH=$PATH:$(go env GOPATH)/bin
    echo 'export PATH=$PATH:$(go env GOPATH)/bin' >> ~/.bashrc
    source ~/.bashrc

    echo -e "${BOLD_BLUE}All tools have been installed successfully.${NC}"
}

# Start Scan
start_scan() {
    read -p "Enter the target domain (e.g., example.com): " domain_name
    if [ -z "$domain_name" ]; then
        echo -e "${RED}Domain name cannot be empty.${NC}"
        return
    fi

    echo -e "${BOLD_WHITE}Starting scan for domain: ${domain_name}${NC}"

    # Step 1: Subdomain Enumeration
    echo -e "${BOLD_BLUE}Enumerating subdomains...${NC}"
    subfinder -d "$domain_name" -o subfinder.txt
    assetfinder --subs-only "$domain_name" > assetfinder.txt
    cat subfinder.txt assetfinder.txt | sort -u > "${domain_name}-subdomains.txt"
    rm subfinder.txt assetfinder.txt

    # Step 2: URL Discovery
    echo -e "${BOLD_BLUE}Discovering URLs...${NC}"
    cat "${domain_name}-subdomains.txt" | waybackurls > waybackurls.txt
    cat "${domain_name}-subdomains.txt" | gau > gau.txt
    cat "${domain_name}-subdomains.txt" | hakrawler > hakrawler.txt
    gospider -S "${domain_name}-subdomains.txt" -c 10 -d 5 | tee -a gospider.txt
    katana -list "${domain_name}-subdomains.txt" -jc -o katana.txt

    # Step 3: Merge and Filter URLs
    echo -e "${BOLD_BLUE}Merging and filtering URLs...${NC}"
    cat waybackurls.txt gau.txt hakrawler.txt gospider.txt katana.txt | sort -u > "${domain_name}-raw-urls.txt"
    rm waybackurls.txt gau.txt hakrawler.txt gospider.txt katana.txt

    # Step 4: Remove Duplicates and Invalid URLs
    echo -e "${BOLD_BLUE}Removing duplicates and invalid URLs...${NC}"
    uro -i "${domain_name}-raw-urls.txt" -o "${domain_name}-unique-urls.txt"
    grep -E '^https?://' "${domain_name}-unique-urls.txt" > "${domain_name}-valid-urls.txt"
    rm "${domain_name}-raw-urls.txt" "${domain_name}-unique-urls.txt"

    # Step 5: Filter Out Unwanted Extensions
    echo -e "${BOLD_BLUE}Filtering out unwanted extensions...${NC}"
    grep -Ev '\.(css|js|jpg|jpeg|png|gif|svg|ico|woff|woff2|ttf|eot|pdf|doc|docx|xls|xlsx|ppt|pptx|zip|tar|gz|rar|exe|dll|bin|swf|flv|mp3|mp4|avi|mov|mpeg|webm|ogg|ogv|wav|wmv|webp|json|xml|txt|log|sql|db|bak|old|backup|tmp|temp|php|asp|aspx|jsp|cfm|pl|py|sh|bat|cmd|bin|deb|rpm|apk|iso|img|vmdk|ova|ovf|vhd|vhdx)' "${domain_name}-valid-urls.txt" > "${domain_name}-filtered-urls.txt"
    rm "${domain_name}-valid-urls.txt"

    # Step 6: Final Cleanup and Output
    echo -e "${BOLD_BLUE}Finalizing output...${NC}"
    awk '!seen[$0]++' "${domain_name}-filtered-urls.txt" > "${domain_name}-links-final.txt"
    rm "${domain_name}-filtered-urls.txt"

    echo -e "${BOLD_GREEN}Scan completed! Final URLs saved to ${domain_name}-links-final.txt${NC}"
}

# Main loop
while true; do
    display_banner
    display_menu
    read -p "Enter your choice [1-3]: " choice

    case $choice in
        1)
            start_scan
            ;;
        2)
            install_tools
            ;;
        3)
            echo -e "${BOLD_WHITE}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please select 1, 2, or 3.${NC}"
            ;;
    esac

    read -p "Press Enter to continue..."
done
