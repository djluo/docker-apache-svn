#!/bin/bash

find /svnroot/logs/ -type f -name "*gz"       -mtime +30 -exec rm -f {} \;
find /svnroot/logs/ -type f -name "*log*[^z]" -mtime +1  -exec gzip  {} \;
