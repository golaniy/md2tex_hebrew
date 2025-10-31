import sys

def process_markdown():
    for line in sys.stdin:
        line = line.rstrip()
        if line.startswith("#"):
            print()  # Add a newline before
            print(line)
            print()  # Add a newline after
        elif line.startswith("> [!"):
            print(line)
            print("> ")
        else:
            print(line)

if __name__ == "__main__":
    process_markdown()