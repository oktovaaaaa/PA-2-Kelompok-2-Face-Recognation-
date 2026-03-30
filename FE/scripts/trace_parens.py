import os

file_path = r"c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognation-\FE\lib\features\employee\presentation\screens\tabs\employee_attendance_tab.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines):
    for char in line:
        if char == '(':
            print(f"L{i+1}: (")
        if char == ')':
            print(f"L{i+1}: )")
