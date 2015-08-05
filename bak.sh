#!/bin/bash
umask 077

export TZ=Asia/Shanghai
bak_dir=$(date +"%Y")
bak_day=$(date +"%Y%m%d-%H%M%S")

pushd /svnroot/
[ -d ./backup/${bak_dir} ] || mkdir -p ./backup/${bak_dir}

for dir in $(find /svnroot/svnrepos/ -type f -name uuid)
do
  dir=$(dirname $dir)
  svn=$(dirname $dir)
  repo=$(basename $svn)

  [ -d /svnroot/backup/temp ] && rm -rf /svnroot/backup/temp
  mkdir -p /svnroot/backup/temp

  /usr/bin/svnadmin hotcopy $svn /svnroot/backup/temp/
  pushd /svnroot/backup/
  tar cfz ./${bak_dir}/${repo}-${bak_day}.tar.gz  ./temp/
  popd

  rm -rf /svnroot/backup/temp
done
popd
