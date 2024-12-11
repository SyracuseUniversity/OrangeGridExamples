#!/usr/bin/env python

import json
import sys

data = json.load(sys.stdin)

freeCounts = [0 for _ in range(256)]

clusterCPUs = 0 
clusterGPUs = 0
clusterFreeCPUs = 0
clusterFreeGPUs = 0

clusterMaxFreeCPUs = 0
clusterMaxFreeGPUs = 0

print("Name\ttotalCPUs\tfreeCPUs\ttotalGPUs\tfreeGPUs")

for node in data:
    if 'ChildCpus' not in node:
        continue

    addr = node['AddressV1']
    idx1 = addr.find('alias')
    idx2 = addr.find('"',idx1+7)
    name = addr[idx1+7:idx2]

    totalCPUs = int(node['TotalCpus'])
    totalGPUs = 'TotalGPUs' in node and node['TotalGPUs'] or 0

    usedCPUs  = 'ChildCpus' in node and int(sum(node['ChildCpus'])) or 0
    usedGPUs  = 'ChildGPUs' in node and sum(node['ChildGPUs']) or 0

    freeCPUs = totalCPUs - usedCPUs
    freeGPUs = totalGPUs - usedGPUs

    if totalGPUs == 0:
        clusterCPUs += totalCPUs
        clusterFreeCPUs += freeCPUs
        clusterMaxFreeCPUs = max(clusterMaxFreeCPUs,freeCPUs)
        freeCounts[freeCPUs] += 1

    clusterGPUs += totalGPUs
    clusterFreeGPUs += freeGPUs
    clusterMaxFreeGPUs = max(clusterMaxFreeGPUs,freeGPUs)

    print(name, totalCPUs, freeCPUs, totalGPUs, freeGPUs)


print("Total CPUs", clusterCPUs)
print("Free CPUs", clusterFreeCPUs)
print("Largest free CPUs on a single node", clusterMaxFreeCPUs)
print()

print("Total GPUs", clusterGPUs)
print("Free GPUs", clusterFreeGPUs)
print("Largest free GPUs on a single node", clusterMaxFreeGPUs)


print()
print("free CPUs\t# nodes")

for c,v in enumerate(freeCounts):
    if v != 0 and c != 0:
        print(c, "\t", v)


