#!/bin/bash
umask 077
#set -x
export TZ=Asia/Shanghai

usage() {
  echo "Usage: $0 full"
  echo "Usage: $0 incremental"
  echo
  exit 127
}

full_backup() {
  pushd /svnroot/svnrepos/

  for dir in $(find . -type f -name uuid)
  do
    dir=$(dirname $dir)
    local svn_path=$(dirname  $dir)
    local svn_name=$(basename $svn_path)
    mkdir -p ../backup/$svn_path
    local bak_dir=$(readlink -f ../backup/$svn_path)

    [ -d ../backup/temp ] && rm -rf ../backup/temp
    mkdir -p ../backup/temp

    /usr/bin/svnadmin hotcopy $svn_path ../backup/temp

    local current_rev=$(svnlook youngest ../backup/temp/)

    local md5sum_file="${bak_dir}/full-r${current_rev}.md5"
    local revision_file="${bak_dir}/latest-revision"
    local target="${bak_dir}/full-r${current_rev}.tar.gz"

    if [ -f $target ] && md5sum --quiet -c ${md5sum_file} ;then
        rm -rf ../backup/temp
        continue
    else
      [ -f $target ] && rm -fv $target
      pushd /svnroot/backup
      tar cfz $target ./temp/ && \
        echo "$current_rev" > ${revision_file}
      md5sum $target > ${md5sum_file}
      popd
    fi

    rm -rf ../backup/temp
  done
  unset dir
  popd
}

incremental() {
  pushd /svnroot/svnrepos/

  for dir in $(find . -type f -name uuid)
  do
    dir=$(dirname $dir)
    local svn_path=$(dirname $dir)
    local svn_name=$(basename $svn_path)
    mkdir -p ../backup/$svn_path
    local bak_dir=$(readlink -f ../backup/$svn_path)

    local last_rev=0
    local current_rev=0
    local latest="${bak_dir}/latest-revision"

    [ -f ${latest} ] && last_rev=$(cat ${latest})
    current_rev=$(svnlook youngest $svn_path)

    if [ $last_rev -eq 0 ];then
      full_backup
    elif [ $last_rev -eq $current_rev ];then
      continue
    else
      /usr/bin/svnadmin dump $svn_path -r ${last_rev}:${current_rev} --incremental \
        > ${bak_dir}/r${last_rev}-r${current_rev}
      if [ $? -eq 0 ];then
        gzip -f ${bak_dir}/r${last_rev}-r${current_rev}
        echo $current_rev > ${latest}
      fi
    fi
  done
  unset dir
  popd
}

case "$1" in
  full)
    full_backup
    ;;
  incremental)
    incremental
    ;;
  *)
    usage
    ;;
esac
