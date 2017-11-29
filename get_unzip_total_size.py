#!/usr/bin/env python
import sys
import os
import csv

dir_name = sys.argv[1]

# get file list
file_list = []
for root, dirs , files in os.walk(dir_name, True):
    for file in files:
        file_list.append("%s/%s"%(root,file))

total_file_size = 0
# get total file size
for file in file_list:
    file_size = os.path.getsize(file)
    total_file_size += file_size

print total_file_size
