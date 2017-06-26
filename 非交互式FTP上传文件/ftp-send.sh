#!/bin/bash

# 客户端非交互式模式将文件发送到ftp server
# 通过返回状态判断传输是否成功,并记录日志

# ftp server 服务器端 IP
ip=192.168.1.1

# ftp server 服务器端 端口
port=3000
user=testluyin
passwd=123456

# 本地文件存放路径
local_dir=/tmp

# 当天日期
time=$(date +%Y%m%d)

# 发送文件函数
# 并回去返回值 226 代表成功
send-ftp(){
a=`bash -c "ftp -n -v $ip $port << EOF
quote USER $user
quote PASS $passwd
passive mode
binary
lcd $local_dir
put $1 
bye
EOF" | grep "^226"`
if [ "$a" = "" ];then
    echo "$time $1 ftp error" >> /var/log/ftp_send.log
else
    echo "$time $1 ftp success" >> /var/log/ftp_send.log
fi
}

# 进入本地需要上传文件的路径
# 目录格式为当天日期
# 将文件按照一定的格式进行打包
# 放到定时计划中,便可以自动执行
cd /home/youlinux/$time
for i in $(ls);do
    name=$(echo $i | awk -F_ '{print $3}')
    tar -czf /tmp/${name}_${time}.tgz ${i}
    send-ftp ${name}_${time}.tgz
done







