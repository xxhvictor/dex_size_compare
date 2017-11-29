#!/usr/bin/env python
import sys
import os
import re
import shutil

dir_name = sys.argv[1]
mapping_file = sys.argv[2]
new_dir_name = sys.argv[3]

# get file list
file_list = []
for root, dirs , files in os.walk(dir_name, True):
    for file in files:
        file_list.append("%s/%s"%(root,file))

# convert to package name list
pkg_name_list= []
pkg_name_list_str = ""
for file in file_list:
    if not file.endswith('.class'):
        continue
    file = os.path.relpath(file, dir_name)
    file = file.split('.')[0]
    file = file.replace('/', '.')
    pkg_name_list.append(file)
    pkg_name_list_str += file + '\n'

# construct map: proguard package -> unproguard package
pkg_name_map = {}
mapping_lines = open(mapping_file, 'r').readlines()
current_process_line_num = 0
processed_line_num_delta = 0
total_mapping_line_num = len(mapping_lines)
print "will construct file name mapping, this process may be very slow ..."
for line in mapping_lines:
    # show progress
    current_process_line_num += 1
    processed_line_num_delta += 1
    if processed_line_num_delta > total_mapping_line_num/20.0:
        processed_line_num_delta = 0
        progress = round(current_process_line_num * 100.0 / total_mapping_line_num)
        #print "current progress is: " + str(progress) + "%"
    
    # execlude unused lines
    if line.startswith(' '):
        continue
    # line's format
    #com.uc.external.barcode.oned.Code39Reader -> com.uc.external.barcode.b.c:
    simple_name = line.split()[-1][:-1]
    if pkg_name_list_str.find(simple_name) == -1:
        continue

    for n in pkg_name_list:
        if line.find("-> " + n + ":") != -1:
            v = line.split()[0]
            pkg_name_map[n] = v
            break
print "construct file name mapping complete!"

def get_recovered_name(package_name, mapping_str):
   # for regex special char
   package_name = package_name.replace('$', '\$')
   pattern_str = "(?P<origin>[\w.\$0-9]+)\ ->\ %s"%package_name
   r = re.search(pattern_str, mapping_str)
   # if failed, fallback to origin proguarded package name
   if r == None:
       return package_name
   return r.group("origin")

# rename according to mapping file
current_process_file_num = 0
processed_file_num_delta = 0
print "will rename class file using mapping file, this process may be very slow ..."
for file in file_list:
    # show progress every 10% add
    current_process_file_num += 1
    processed_file_num_delta += 1
    if processed_file_num_delta >= len(file_list)/10.0:
        processed_file_num_delta = 0
        progress = round(current_process_file_num * 100.0 / len(file_list))
        #print "current progress is: " + str(progress) + "%"

    
    old_file = file
    if not file.endswith('.class'):
        continue
    file = os.path.relpath(file, dir_name)
    file = file.split('.')[0]
    file = file.replace('/', '.')
    new_file = ""
    if pkg_name_map.has_key(file):
        new_file = pkg_name_map[file]
        new_file = new_file.replace('.', '/')
        new_file = new_file + ".class"
        new_file = os.path.join(new_dir_name, new_file)
    else:
        #print "cannot file mapping file: " + old_file
        new_file = os.path.relpath(old_file, dir_name)
        new_file = os.path.join(new_dir_name, new_file)

    #recovered_package_name = get_recovered_name(file, mapping_str)
    #new_file = recovered_package_name.replace('.', '/')
    #new_file = new_file + ".class"
    #new_file = os.path.join(new_dir_name, new_file)

    new_file_dir_name = os.path.dirname(new_file)
    if not os.path.exists(new_file_dir_name):
        os.makedirs(new_file_dir_name)
    #print "will copy:", old_file, new_file
    shutil.copy(old_file, new_file)
print "rename class file name complete!"

