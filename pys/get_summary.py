#!/usr/bin/env python2

import csv
import re
import os
import glob
import sys


def get_mydict (number, my_lines):
  my_dict = {}
  num_gpu = 0
  my_dict["No:"] = number                       
  for i in range (len(lines)):
    if(lines[i].find('GPUs')) != -1:
      temp = lines[i].split()
      my_dict["# of GPUs:"] = temp[2]
      num_gpu = int(temp[2])
    elif (lines[i].find('Fetching GPU info ...')) != -1:
      x=i+4
      for j in range (num_gpu):
        j +=1
        temp = lines[x].split()
        #print temp
        label = 'gpu ' + str(j)
        my_dict[label+" ASIC-Type"] = temp[1]
        my_dict[label+" Board-ID"] = temp[2]
        my_dict[label+" BIOS-Part-Number"] = temp[3]
        #print label
        x+=1
        #my_dict["# of GPUs:"] = temp[2]
    elif(lines[i].find('Tensorflow Version:')) != -1:
      temp = lines[i].split()
      my_dict["Tensorflow Version:"] = temp[2]
    elif(lines[i].find('Model:')) != -1:
      temp = lines[i].split()
      my_dict["Model:"] = temp[1]
    elif(lines[i].find('Mode:')) != -1:
      temp = lines[i].split()
      my_dict["Mode:"] = temp[1]
    elif(lines[i].find('my_dictSet:')) != -1:
      temp = lines[i].split()
      my_dict["my_dictSet:"] = temp[1]  
    elif(lines[i].find('Batch Size:')) != -1:
      temp = lines[i].split()
      my_dict["Batch Size:"] = temp[2]
    elif(lines[i].find('Batches:')) != -1:
      temp = lines[i].split()
      my_dict["Batches:"] = temp[1]
    elif(lines[i].find('Test Loops:')) != -1:
      temp = lines[i].split()
      my_dict["Test Loops:"] = temp[2]
    elif(lines[i].find('Tensor Command:')) != -1:
      temp = lines[i].split()
      command = ''
      for j in range(2, (len(temp)-1)):
        command += temp[j]
      my_dict["Tensor Command:"] = command 
    elif(lines[i].find('total images/sec:')) != -1:
      temp = lines[i].split()
      my_dict["total images/sec:"] = temp[2]
    elif(lines[i].find('duration')) != -1:
      temp = lines[i].split()
      my_dict["duration"] = temp[1]
      break
  return my_dict;


#print (sys.argv[1])

path = sys.argv[1] # '/root/SnakeBytes/lib/docker/results/docker_tf_03022019-213732/'
i=1
full_list = []
for filename in glob.glob(os.path.join(path, '*.log')):
  #print filename
  lines = []
  with open (filename,"r") as in_file:
    for line in in_file:
      lines.append(line)
  final_dict = get_mydict ( i, lines)
  full_list.append(dict(final_dict))
  i+=1
  



#print(full_list)
#keylist = full_list[0].keys()
#print sorted(keylist)
csv_columns = sorted(full_list[0].keys()) #['No:','Tensorflow Version:','Model:','Mode:','Batch Size:','Batches:','Test Loops:','Tensor Command:','total images/sec:','duration','# of GPUs:']


csvpath = path + '/summary.csv'  #'/root/SnakeBytes/lib/docker/results/docker_tf_05022019-153534/summary.csv'
#print (csvpath)
try:    
  with open(csvpath, 'w') as csvfile:
    writer = csv.DictWriter(csvfile,fieldnames=csv_columns)
    writer.writeheader()
    for data in full_list:
            writer.writerow(data)
  
except IOError as (errno, strerror):
            print("I/O error({0}): {1}".format(errno, strerror))    

csvfile.close


 #filewriter = csv.writer(csvfile, delimiter=',',quotechar='|', quoting=csv.QUOTE_MINIMAL)
    #fieldnames = ['Tensorflow Version:','Model:','Mode:','my_dictSet:','Batch Size:','Batches:','Test Loops:','Tensor Command:','total images/sec:','duration']





