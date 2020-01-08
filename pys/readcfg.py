#!/usr/bin/env python2
import sys

#function that reads all the test cases from a csv
class caffe2:
    @staticmethod
    def read_test_case(filename, column):
            dict = {}
            dict['model'] = 0
            dict['batchsize'] = 1
            dict['iterations'] = 2
            dict['loops'] = 3

            out = []
            with open(filename, 'r') as configfile:
                    for line in configfile:
                            if not line.startswith('#'):
                                    info = line.strip().split(",")
                                    if(len(info) > 3):
                                            out.append(info[dict[column]])
            configfile.close()
            print ','.join(out)

class miopen:
    @staticmethod
    def read_test_case(filename, column):
            dict = {}
            dict['model'] = 0
            dict['dataset'] = 1
            dict['batchsize'] = 2
            dict['batches'] = 3
            dict['loops'] = 4

            out = []
            with open(filename, 'r') as configfile:
                    for line in configfile:
                            if not line.startswith('#'):
                                    info = line.strip().split(",")
                                    if(len(info) > 3):
                                            out.append(info[dict[column]])
            configfile.close()
            print ','.join(out)

class tensorflow:
    @staticmethod
    def read_test_case(filename, column):
            dict = {}
            dict['model'] = 0
            dict['dataset'] = 1
            dict['batchsize'] = 2
            dict['batches'] = 3
            dict['loops'] = 4

            out = []
            with open(filename, 'r') as configfile:
                    for line in configfile:
                            if not line.startswith('#'):
                                    info = line.strip().split(",")
                                    if(len(info) > 3):
                                            out.append(info[dict[column]])
            configfile.close()
            print ','.join(out)
			
class pytorch:
    @staticmethod
    def read_test_case(filename, column):
            dict = {}
            dict['network'] = 0
            dict['batchsize'] = 1
            dict['iterations'] = 2
            dict['fp16'] = 3
            dict['loops'] = 4
            out = []
            with open(filename, 'r') as configfile:
                    for line in configfile:
                             if not line.startswith('#'):
                                    info = line.strip().split(",")
                                    if(len(info) > 3):
                                            out.append(info[dict[column]])
            configfile.close()
            print ','.join(out)
            

#function that reads all other lines
def read_line(filename, word):
	with open(filename, 'r') as configfile:
		for line in configfile:
			if line.startswith(word):
				print line.split(',')[-1]
	configfile.close()

# start reading config file from here
config = sys.argv[1]
col = sys.argv[2]
runmode = ''
if len(sys.argv) > 3:
    runmode = sys.argv[3]

if runmode == 'tf' and (col == 'model' or col == 'dataset' or col == 'batchsize' or col == 'batches' or col == 'loops'):
	tensorflow.read_test_case(config, col)
elif runmode == 'c2' and (col == 'model' or col == 'dataset' or col == 'batchsize' or col == 'epochsize' or col == 'numepochs' or col == 'iterations' or col == 'loops'):
	caffe2.read_test_case(config, col)
elif runmode == 'py' and (col == 'network' or col == 'batchsize' or col == 'iterations' or col == 'fp16' or col == 'loops'):
	pytorch.read_test_case(config, col)	
elif runmode == 'mi' and (col == 'model' or col == 'batchsize' or col == 'epochsize' or col == 'numepochs' or col == 'loops'):
	miopen.read_test_case(config, col)
else:
	if col == 'python' or col == 'repo' or col == 'imagenet' or col == 'cifar' or col == 'loopall' or col == 'atirez':
		read_line(config, col)
	else:
		print "Could not understand request"
