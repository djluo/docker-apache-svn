#!/usr/bin/perl
# vim:set et ts=2 sw=2:

# Author : djluo
# version: 2.0(20150107)
#
# 初衷: 每个容器用不同用户运行程序,已方便在宿主中直观的查看.
# 需求: 1. 动态添加用户,不能将添加用户的动作写死到images中.
#       2. 容器内尽量不留无用进程,保持进程树干净.
# 问题: 如用shell的su命令切换,会遗留一个su本身的进程.
# 最终: 使用perl脚本进行添加和切换操作. 从环境变量User_Id获取用户信息.

use strict;
#use English '-no_match_vars';

my $uid = 1000;
my $gid = 1000;
my $del = 15;

$uid = $gid = $ENV{'User_Id'} if $ENV{'User_Id'} =~ /\d+/;
$del = $ENV{'Del_Day'}        if $ENV{'Del_Day'} =~ /\d+/;

unless (getpwuid("$uid")){
  system("/usr/sbin/useradd", "-U", "-u $uid", "-m", "docker");
}

unlink("/tmp/apache2.pid") if ( -f "/tmp/apache2.pid" );

my @dirs = ("/svnroot/logs", "/svnroot/svnrepos");
foreach my $dir (@dirs) {
  if ( -d $dir && (stat($dir))[4] != $uid ){
    system("chown docker.docker -R " . $dir);
  }
}

my @confd = ("/svnroot/conf/vhost.d", "/svnroot/conf/access.d");
foreach my $dir (@confd){
  mkdir("$dir") unless ( -d "$dir");
  system("chmod","750",    "$dir");
  system("chgrp","docker", "$dir");
}

# init
unless ( -f "/svnroot/conf/.init_complete"){
  system("cp","/svnroot/example/example","/svnroot/conf/access.d/");
  system("cp","/svnroot/example/example.conf","/svnroot/conf/vhost.d/");
  system("touch","/svnroot/conf/.init_complete");
}

my $pw="/svnroot/conf/99-default.passwd";
system("touch", "$pw") unless ( -f "$pw");
system("chmod","640",    "$pw");
system("chgrp","docker", "$pw");

system("rm", "-f", "/run/crond.pid") if ( -f "/run/crond.pid" );
system("/usr/sbin/cron");

my $min  = int(rand(60));
my $hour = int(rand(5));

system("chmod","750", "/svnroot/backup")   if( -d "/svnroot/backup");
system("chmod","750", "/svnroot/svnrepos") if( -d "/svnroot/svnrepos");
open (CRON,"|/usr/bin/crontab") or die "crontab error?";
print CRON ("$min $hour * * * (find /svnroot/backup -type f -mtime +$del -exec rm -f {} \\;)\n");
print CRON ("$min $hour * * * (/svnroot/gzip.sh >/dev/null 2>&1)\n");
print CRON ("$min $hour * * 7 (/svnroot/bak.sh full >/dev/null 2>&1)\n");
print CRON ("$min $hour * * 1,2,3,4,5,6 (/svnroot/bak.sh incremental >/dev/null 2>&1)\n");
if( $ENV{'RSYNC_PASSWORD'} ){
  my $ip=$ENV{'backup_ip'};
  my $dest=$ENV{'backup_dest'}."_".$ENV{'HOSTNAME'};
  my $port="2873";
     $port="$ENV{'RSYNC_PORT'}" if ( $ENV{'RSYNC_PORT'} );

  my $umask = umask;
  umask 0277;
  open (PW,'>', '/rsync.pass') or die "$!";
  print PW $ENV{'RSYNC_PASSWORD'};
  close(PW);
  umask $umask;

  my $rsync_hour = $hour + 1;
  my $rsync_opts = "/usr/bin/rsync --port=$port -al --password-file=/rsync.pass";
  print CRON ("$min $rsync_hour * * * ($rsync_opts /svnroot/backup/ docker@". $ip ."::backup/$dest/)\n");
}
close(CRON);

# 切换当前运行用户,先切GID.
#$GID = $EGID = $gid;
#$UID = $EUID = $uid;
$( = $) = $gid; die "switch gid error\n" if $gid != $( ;
$< = $> = $uid; die "switch uid error\n" if $uid != $< ;

$ENV{'HOME'} = "/home/docker";
exec(@ARGV);
