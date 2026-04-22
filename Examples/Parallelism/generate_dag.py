#!/usr/bin/env python3

import sys

class Job(object):
    id = None

    def __init__(self,id):
        self.id = id


class MapJob(Job):
    value = None

    def __init__(self, id, value):
        super().__init__(f"MAP{id:03d}")
        
        self.value = value

    def __str__(self):
        return f'JOB {self.id} square.sub\nVARS {self.id} id="{self.id}" value="{self.value}"\n'

class ReduceJob(Job):
    parents = None

    def __init__(self, id, parents):
        super().__init__(f"REDUCE{id:03d}")
        
        self.parents = parents

    def __str__(self):
        parent_ids = ",".join([job.id for job in self.parents])

        return f"JOB {self.id} add.sub\nVARS {self.id} id=\"{self.id}\" value=\"{parent_ids}\"\nPARENT {parent_ids.replace(',',' ')} CHILD {self.id}\n"

arguments = sys.argv[1:]
map_jobs  = [MapJob(idx, v) for idx,v in enumerate(arguments)]
jobs      = map_jobs
reduce_id = 0
all_jobs  = [] + jobs

while len(jobs) > 1:
    job_chunks = [jobs[n:n+5] for n in range(0,len(jobs),5)]
    jobs       = [ReduceJob(reduce_id+id,chunk) for id,chunk in enumerate(job_chunks)]
    reduce_id += len(jobs)
    all_jobs  += jobs

# Give the last reduce job a special name
all_jobs[-1].id = 'FINAL'

repr = "\n".join([job.__str__() for job in all_jobs])

print(repr)

print("DOT mapreduce.dot")

