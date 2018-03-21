#!/bin/env python3

import fileinput
import sys

state = None

import pdb; pdb.set_trace()

for line in fileinput.input(sys.argv[1:], inplace=False):
    line = line.rstrip()

    if state is None:
        # Looking for '- project:' line
        if line.strip() == '- project:':
            state = 'project'
        print(line)
        continue

    if state == 'project':
        # Looking for 'check:' line
        if line.strip() == 'check:':
            state = 'check'
        print(line)
        continue

    if state == 'check':
        # Looking for 'jobs:' line
        if line.strip() == 'jobs:':
            state = 'check-jobs'
        print(line)
        continue

    if state in ('check-jobs', 'gate-jobs'):
        # Looking for something that is not a list item
        if line.strip() == 'gate:':
            # We hit the end of the check jobs, so add
            # our job.
            indent = len(line) - len(line.lstrip())
            print('{}- openstack-tox-lower-constraints'.format(' ' * indent))
            state = 'post-' + state
        else:
            print(line)
            continue

    if state == 'post-check-jobs':
        # We've done the check jobs so we're looking for the
        # gate jobs.
        if line.strip() == 'gate:':
            state = 'gate'
        print(line)
        continue

    if state == 'gate':
        # Looking for 'jobs:' line
        if line.strip() == 'jobs:':
            state = 'gate-jobs'
        print(line)
        continue

    if state == 'post-gate-jobs':
        # Print everything that comes after
        print(line)

    raise ValueError('unexpected state {}'.format(state))
