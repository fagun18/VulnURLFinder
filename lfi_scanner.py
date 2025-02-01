import sys
import argparse

def main():
    parser = argparse.ArgumentParser(description="LFI Scanner")
    parser.add_argument("--urls", required=True, help="File containing URLs to scan")
    parser.add_argument("--output", required=True, help="Output file to save results")
    args = parser.parse_args()

    # Your LFI scanning logic here
    with open(args.urls, 'r') as f:
        urls = f.readlines()

    # Example: Simulate LFI scanning
    with open(args.output, 'w') as f:
        for url in urls:
            f.write(f"Vulnerable: {url}")

if __name__ == "__main__":
    main()
