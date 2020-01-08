import torch
import torchvision
import random
import time
import argparse
import os
import sys
from fp16util import network_to_half, get_param_copy

def get_network(net):
    if (net == "resnet50"):
        return torchvision.models.resnet50().to(device="cuda")
    elif (net == "resnet101"):
        return torchvision.models.resnet101().to(device="cuda")
    elif (net == "vgg16"):
        return torchvision.models.vgg16().to(device="cuda")
    elif (net == "alexnet"):
        return torchvision.models.alexnet().to(device="cuda")
    elif (net == "vgg19"):
        return torchvision.models.vgg19().to(device="cuda")
    elif (net == "resnet152"):
        return torchvision.models.resnet152().to(device="cuda")
    elif (net == "densenet121"):
        return torchvision.models.densenet121().to(device="cuda")
    elif (net == "inception_v3"):
        return torchvision.models.inception_v3(aux_logits=False).to(device="cuda")
    elif (net == "SqueezeNet"):
        return torchvision.models.squeezenet1_0().to(device="cuda")
    else:
        print ("ERROR: not a supported model.")
        sys.exit(1)

def forwardbackward(inp, optimizer, network, target):
    optimizer.zero_grad()
    out = network(inp)
    loss = torch.nn.functional.cross_entropy(out, target)
    loss.backward()
    optimizer.step()

def run_benchmarking(net, batch_size, iterations, run_fp16):
    network = get_network(net)
    if (run_fp16):
        network = network_to_half(network)
    if (net == "inception_v3"):
        inp = torch.randn(batch_size, 3, 299, 299, device="cuda")
    else:
        inp = torch.randn(batch_size, 3, 224, 224, device="cuda")
    if (run_fp16):
        inp = inp.half()
    target = torch.arange(batch_size, device="cuda")
    param_copy = network.parameters()
    if (run_fp16):
        param_copy = get_param_copy(network)
    optimizer = torch.optim.SGD(param_copy, lr = 0.01, momentum = 0.9)

    ## warmup.
    print ("INFO: running forward and backward for warmup.")
    forwardbackward(inp, optimizer, network, target)
    forwardbackward(inp, optimizer, network, target)

    time.sleep(10)

    ## benchmark.
    print ("INFO: running the benchmark..")
    torch.cuda.synchronize()
    tm = time.time()
    for i in range(iterations):
        forwardbackward(inp, optimizer, network, target)
    torch.cuda.synchronize()
    
    tm2 = time.time()
    time_per_batch = (tm2 - tm) / iterations

    print ("OK: finished running benchmark..")
    print ("--------------------SUMMARY--------------------------")
    print ("Microbenchmark for network : {}".format(net))
    print ("Mini batch size [img] : {}".format(batch_size))
    print ("Time per mini-batch : {}".format(time_per_batch))
    print ("Throughput [img/sec] : {}".format(batch_size/time_per_batch))

def main():
    net = args.network
    batch_size = args.batch_size
    iterations = args.iterations
    run_fp16 = args.fp16

    run_benchmarking(net, batch_size, iterations, run_fp16)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument("--network", type=str, 
        choices=['resnet50', 'vgg16', 'vgg19', 'resnet152', 'alexnet', 'resnet101', 'densenet121', 'inception_v3', 'SqueezeNet'], 
        required=True, help="Network to run.")
    parser.add_argument("--batch-size" , type=int, required=False, default=64, help="Batch size")
    parser.add_argument("--iterations", type=int, required=False, default=20, help="Iterations")
    parser.add_argument("--fp16", type=int, required=False, default=0,help="FP16 mixed precision benchmarking")

    args = parser.parse_args()

    main()
