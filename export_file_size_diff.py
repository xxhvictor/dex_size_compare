#!/usr/bin/env python
import sys
import os
import csv

target_file_name = sys.argv[1]
compare_file_name = sys.argv[2]
diff_file_name = sys.argv[3]

target_file = open(target_file_name, 'r')
compare_file = open(compare_file_name, 'r')
target_file_reader = csv.reader(target_file)
compare_file_reader = csv.reader(compare_file)

target_map = {}
for line in target_file_reader:
    target_map[line[0]] = line[1]

compare_map = {}
for line in compare_file_reader:
    compare_map[line[0]] = line[1]

diff_list = {}
add_list =  {}
remove_list =  {}
scale = 1000.0
for key in target_map.keys():
    if compare_map.has_key(key):
        diff_list[key] = round((float(target_map[key]) - float(compare_map[key])) * scale) / scale
    else:
        add_list[key] = round(float(target_map[key]) * scale) / scale

for key in compare_map.keys():
    if not target_map.has_key(key):
        remove_list[key] = - round(float(compare_map[key]) * scale) / scale

f = open(diff_file_name, 'w')
w = csv.writer(f)
w.writerow(["Class Name", "Size Diff in KB(dex1 - dex2)", "Type(Diff, Add, Remove)"])
for key in diff_list.keys():
    w.writerow([key, diff_list[key], "Diff"])

for key in add_list.keys():
    w.writerow([key, add_list[key], "Add"])

for key in remove_list.keys():
    w.writerow([key, remove_list[key], "Remove"])

#print diff_list
#print add_list
#print remove_list
