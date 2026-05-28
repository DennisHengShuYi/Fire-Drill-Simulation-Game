with open("build_level.py", "r") as f:
    for line_num, line in enumerate(f, 1):
        if "ensuite" in line.lower():
            print(f"Line {line_num}: {line.strip()}")
