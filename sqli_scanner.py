import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description="SQLi Scanner")
    parser.add_argument("--urls", required=True, help="File containing URLs to scan")
    parser.add_argument("--output", required=True, help="Output file to save results")
    args = parser.parse_args()

    # Your SQLi scanning logic here
    with open(args.urls, 'r') as f:
        urls = f.readlines()

    # Example: Simulate SQLi scanning
    with open(args.output, 'w') as f:
        for url in urls:
            f.write(f"Vulnerable: {url}")

if __name__ == "__main__":
    main()
