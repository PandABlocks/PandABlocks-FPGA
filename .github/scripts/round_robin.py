import sys
import json

modules_grps=(sys.argv)[1:]
print(modules_grps)
modules=[]
num_jobs=5

def split_modules(modules,num_jobs):
    modules.sort(key=lambda x: x[1], reverse=True)
    jobs = [[] for _ in range(num_jobs)]
    for module, count in modules:
        min_sum_job_idx = min(range(num_jobs), key=lambda i: sum(subset[1] for subset in jobs[i]))
        jobs[min_sum_job_idx].append([module,count])
    return jobs

def generate_matrix(jobs):
    matrix = {'modules':[]}
    for job in jobs:
        job_include = ' '.join(module[0] for module in job)
        matrix['modules'].append(job_include)
    return matrix

for i in range(0,len(modules_grps)-1,2):
    modules.append([modules_grps[i],int(modules_grps[i+1])])
print(modules)
with open("github_tests.json", "w") as matrix_file:
    json.dump(generate_matrix(split_modules(modules,num_jobs)), matrix_file)
