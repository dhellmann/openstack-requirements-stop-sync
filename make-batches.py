#!/usr/bin/env python3

with open('../requirements/projects.txt', 'r', encoding='utf-8') as f:
    projects = [l.partition('/')[-1] for l in f.readlines()]

b = 1
c = 0

while projects:
    filename = 'todo/{:-02d}'.format(b)
    with open(filename, 'w', encoding='utf-8') as f:
        f.writelines(projects[:10])
    b += 1
    projects = projects[10:]
