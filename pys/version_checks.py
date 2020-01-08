import sys, subprocess

def getver_from_runtime_info(filename):
	keyword = "dkms" if filename.startswith("host") else "libs"
	output = subprocess.Popen(("grep rocm-" + keyword + " " + filename).split(), stdout=subprocess.PIPE)
	c = output.communicate()
	output = c[0].split()
	return output[[output.index(x) for x in output if keyword in x][0] + 1]

def rocm_version_checker(hostfile, dockerfile):

	if hostfile == "" or dockerfile == "":
		sys.exit("Error: did not supply proper arguments to compare ROCm version numbers with")

	hostver = getver_from_runtime_info(hostfile)
	dockver = getver_from_runtime_info(dockerfile)
	host = [int(x) for x in hostver.split('.')]
	docker = [int(x) for x in dockver.split('.')]
	if host[0] > docker[0]:
		print "True " + hostver
	elif host[0] == docker[0] and host[1] > docker[1]:
		print "True " + hostver
	elif host[0] == docker[0] and host[1] == docker[1] and host[2] >= docker[2]:
		print "True " + hostver
	else:
		print hostver + " " + dockver
