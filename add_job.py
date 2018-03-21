#!/usr/bin/env python3

import argparse
import sys

from projectconfig_ruamellib import YAML  # noqa

parser = argparse.ArgumentParser()
parser.add_argument('filename')
args = parser.parse_args()

yaml = YAML()

with open(args.filename, 'r', encoding='utf-8') as f:
    data = yaml.load(f.read())

def add_job(block, queue, job):
    project = block['project']
    queue_data = project.setdefault(queue, {})
    jobs = queue_data.setdefault('jobs', [])
    if job not in jobs:
        jobs.append(job)

for block in data:
    if 'project' in block:
        add_job(block, 'check', 'openstack-tox-lower-constraints')
        add_job(block, 'gate', 'openstack-tox-lower-constraints')

with open(args.filename, 'w', encoding='utf-8') as f:
    yaml.dump(data, f)
