import os

file_path = r"c:\Users\Oktovaaaaa\Documents\GitHub\PA-2-Kelompok-2-Face-Recognation-\FE\lib\features\employee\presentation\screens\tabs\employee_attendance_tab.dart"

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

build_lines = lines[70:364] # build method is around here
content = "".join(build_lines)

parens = 0
brackets = 0
braces = 0

for char in content:
    if char == '(': parens += 1
    if char == ')': parens -= 1
    if char == '[': brackets += 1
    if char == ']': brackets -= 1
    if char == '{': braces += 1
    if char == '}': braces -= 1

print(f"Final Count - Parens: {parens}, Brackets: {brackets}, Braces: {braces}")
