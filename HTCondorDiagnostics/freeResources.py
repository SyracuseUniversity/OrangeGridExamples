#!/usr/bin/env python

import json

from functools import reduce

def maybeAddValues(dict, node, key, value1, value2):
    if value1 in node and value2 in node:
        dict.setdefault(key, []).append( (node[value1], node[value2]) )
        
    return dict

def addFromNode(acc, node):
    maybeAddValues(acc, node, 'CPUs', 'TotalCpus', 'ChildCpus')
    if 'CUDADeviceName' in node:
        maybeAddValues(acc, node, node['CUDADeviceName'], 'TotalGPUs', 'ChildGPUs')

    return acc

if __name__ == '__main__':
    results = reduce(addFromNode, json.load(open(0)), {})

    print("Resource\t\tTotal\tAvailable")
    for k in results.keys():
        total = int(reduce(lambda a,v: a+v[0], results[k], 0))
        used  = int(reduce(lambda a,v: a+sum(v[1]), results[k], 0))

        print(f"{k:{' '}<24}{total}\t{total-used}")

    largest = sorted(map(lambda x: (int(x[0]),int(x[0])-sum(x[1])), results['CPUs']))

    print(f"\nLargest free block of CPUs: {largest[-1][1]}, on a node with {largest[-1][0]} CPUs")
