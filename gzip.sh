#!/bin/bash

find /svnroot/logs/ -type f -name "*_log*gz"   -mtime +30 -exec rm -f {} \;
find /svnroot/logs/ -type f -name "*_log*[^z]" -mtime +1  -exec gzip  {} \;
