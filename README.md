# VulnURLFinder

git clone https://github.com/yourusername/VulnURLFinder.git
cd VulnURLFinder
chmod +x vulnurlfinder.sh
./vulnurlfinder.sh --install


./vulnurlfinder.sh --domain example.com --output results --threads 10 --tools gospider,hakrawler,katana --vuln xss,sqli
