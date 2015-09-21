#!/bin/bash
umask 077
#set -x
export TZ=Asia/Shanghai

usage() {
  echo "Usage: $0 full"
  echo "Usage: $0 incremental"
  echo "Usage: $0 verify"
  echo
  exit 127
}

full_backup() {
  local single="$1"
  local list=$(find . -type f -name uuid)

  [ "x$single" != "x" ] && list=$single

  pushd /svnroot/svnrepos/

  for dir in $list
  do
    echo "---------- full_backup: $dir"

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
      mv ./temp/ restore-$svn_name
      tar cfz $target ./restore-$svn_name/ && \
        echo "$current_rev" > ${revision_file}
      md5sum $target > ${md5sum_file}
      rm -rf ./restore-${svn_name}
      popd
    fi

    [ -d ../backup/temp ] && rm -rf ../backup/temp
  done
  unset dir
  popd
}

incremental() {
  pushd /svnroot/svnrepos/

  for dir in $(find . -type f -name uuid)
  do
    echo "---------- incremental: $dir"

    dir=$(dirname $dir)
    local svn_path=$(dirname $dir)
    local svn_name=$(basename $svn_path)
    mkdir -p ../backup/$svn_path
    local bak_dir=$(readlink -f ../backup/$svn_path)

    local last_rev=0
    local current_rev=-1
    local latest="${bak_dir}/latest-revision"

    [ -f ${latest} ] && last_rev=$(cat ${latest})
    current_rev=$(svnlook youngest $svn_path)

    if [ $last_rev -eq $current_rev ];then
      continue
    elif [ $last_rev -eq 0 ];then
      full_backup "$svn_path/db/uuid"
    else
      local start_rev=$(( $last_rev + 1 ))
      local target="${bak_dir}/r${start_rev}-r${current_rev}"
      /usr/bin/svnadmin dump $svn_path -r ${start_rev}:${current_rev} --incremental \
        > ${target}
      if [ $? -eq 0 ];then
        gzip -f ${target}
        md5sum  ${target}.gz > ${target}.md5
        echo $current_rev > ${latest}
      fi
    fi
  done
  unset dir
  popd
}

# TODO: restore
# tar xf full-rN.tar.gz -C ./temp
# zcat r(N+1)-rY.gz | svnadd load ./temp
#restore() {
#  local repo="$1"
#  pushd /svnroot/backup/
#  [ -d ./temp ] && rm -rf ./temp
#  mkdir ./temp
#
#  local latest_full=$(ls -tr ./$repo/full*gz|tail -1)
#  local latest_rev=$(basename $latest_full)
#  latest_rev=${latest_rev%.tar.gz}
#  latest_rev=${latest_rev#full-r}
#
#  [ "x$latest_full" != "x" ] \
#    && [ -f $latest_full ]   \
#    && tar xf $latest_full -C ./temp/
#}

conf_backup() {
  pushd /svnroot/
  bak_time=$(date +"%Y%m%d-%s")
  local bak_dir="./backup/conf/"
  [ -d $bak_dir ] || mkdir -p $bak_dir
  tar cfz ${bak_dir}/${bak_time}.tar.gz ./conf/
  md5sum  ${bak_dir}/${bak_time}.tar.gz > ${bak_dir}/${bak_time}.md5
  popd
}

verify_all() {
  pushd /svnroot/svnrepos/

  for dir in $(find . -type f -name uuid)
  do
    dir=$(dirname $dir)
    local svn_path=$(dirname  $dir)
    local svn_name=$(basename $svn_path)

    echo "verify: $svn_name ..."
    svnadmin verify -q $svn_path
    [ $? -eq 0 ] && echo "verify: $svn_name OK"
  done
  popd
}

case "$1" in
  full)
    full_backup
    conf_backup
    ;;
  incremental)
    incremental
    conf_backup
    ;;
  verify)
    verify_all
    ;;
  *)
    usage
    ;;
esac
