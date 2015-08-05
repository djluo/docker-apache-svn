#!/bin/bash
# vim:set et ts=2 sw=2:

# Author : djluo
# version: 4.0(20150107)

# chkconfig: 3 90 19
# description:
# processname: redmine container

[ -r "/etc/baoyu/functions"  ] && source "/etc/baoyu/functions" && _current_dir
[ -f "${current_dir}/docker" ] && source "${current_dir}/docker"

# ex: ...../dir1/dir2/run.sh
# container_name is "dir1-dir2"
_container_name ${current_dir}

images="apache-svn"
#images="${registry}/baoyu/apache-svn"
#default_port="172.17.42.1:9292:9292"

action="$1"    # start or stop ...
_get_uid "$2"  # uid=xxxx ,default is "1000"
shift $flag_shift
unset  flag_shift

# 转换需映射的端口号
app_port="$@"  # hostPort
app_port=${app_port:=${default_port}}
_port


_run() {
  local mode="-d" # --restart=always"
  local name="$container_name"
  #local cmd="/usr/sbin/apache2 -DFOREGROUND"
  local cmd=""

  [ "x$1" == "xdebug" ] && _run_debug

  sudo docker run $mode $port \
    -e "TZ=Asia/Shanghai"     \
    -e "User_Id=${User_Id}"   \
    -w "/svnroot/"            \
    --add-host=svn.example.com:127.0.0.1 \
    -v ${current_dir}/logs/:/svnroot/logs/   \
    -v ${current_dir}/conf/:/svnroot/conf/   \
    -v ${current_dir}/backup/:/svnroot/backup/ \
    -v ${current_dir}/svnrepos/:/svnroot/svnrepos/ \
    --name ${name} ${images} \
    $cmd
}
###############
_call_action $action
