import sys
import json

modules_grps = (sys.argv)[1:]
print(modules_grps)
modules = []
num_jobs = 5


# Allocate modules to jobs with lowest load
def split_modules(modules, num_jobs):
    modules.sort(key=lambda x: x[1], reverse=True)
    jobs = [[] for _ in range(num_jobs)]
    for module, count in modules:
        min_sum_job_idx = min(
            range(num_jobs), key=lambda i: sum(subset[1] for subset in jobs[i])
        )
        jobs[min_sum_job_idx].append([module, count])
    return jobs


# Produce matrix in format expected by 'make hdl_test' job step
def generate_matrix(jobs):
    matrix = {"modules": []}
    for job in jobs:
        job_include = " ".join(module[0] for module in job)
        matrix["modules"].append(job_include)
    return matrix


# Convert bash array to sensible py array
for i in range(0, len(modules_grps) - 1, 2):
    # If duplicate module names are found, add their counts
    if modules and modules_grps[i] == modules_grps[i - 2]:
        modules[-1][1] += int(modules_grps[i + 1])
    # If no duplicate present, append new element
    else:
        modules.append([modules_grps[i], int(modules_grps[i + 1])])
print(modules)

# Produce JSON file to pass to GH job
with open("github_tests.json", "w") as matrix_file:
    json.dump(generate_matrix(split_modules(modules, num_jobs)), matrix_file)
