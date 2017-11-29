#!/usr/bin/env python
import sys
import os
import csv

dir_name = sys.argv[1]
csv_file_name = sys.argv[2]
file_size_scale = 1
if len(sys.argv) == 4:
    file_size_scale = float(sys.argv[3])

# get file list
file_list = []
for root, dirs , files in os.walk(dir_name, True):
    for file in files:
        file_list.append("%s/%s"%(root,file))

csv_file = open(csv_file_name, 'w')
writer = csv.writer(csv_file)

# get file size
for file in file_list:
    file_size = os.path.getsize(file)
    file_size = file_size / 1024.0
    file_size = file_size * file_size_scale
    file_size = round(file_size * 100) / 100.0
    file = os.path.relpath(file, dir_name)
    file = file.split('.')[0]
    file = file.replace('/', '.')
    writer.writerow([file, file_size])
    #print file, file_size


csv_file.close()

