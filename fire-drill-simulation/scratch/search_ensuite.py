with open("build_level.py", "r") as f:
    for line_num, line in enumerate(f, 1):
        if "ensuite" in line.lower() and "csg_box" in line:
            print(f"Line {line_num}: {line.strip()}")
