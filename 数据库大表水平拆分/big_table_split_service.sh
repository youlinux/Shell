#!/bin/bash

# 2017-05-23
wjm=`date "+%Y-%m-%d"`

# 1495468800
wjm_l=`date "+%Y%m%d"`

# 三个月之前的时间
# 2017-02-23 00:00:00
wjm_ago_3month=`date "+%Y-%m-%d 00:00:00" -d "-3 month"`

# 1487779200 三个月之前的时间戳
time1=`date -d "$wjm_ago_3month"  +%s`

# 服务器IP
ES_IP=$1

# 数据库密码
mysql_pw=$2

mysql_conn1(){
        mysql -uroot -p${mysql_pw} talk -N -e "$1"
}
mysql_conn2(){
        mysql -uroot -p${mysql_pw}
}
mysql_conn3(){
        mysql -N -uroot -p${mysql_pw}
}

# 首先我来进行备份操作
mkdir /home/tongji/big_table_split/backup_sql -p
current_time1=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`

# 记录日志
echo "###${wjm}拆分${ES_IP}服务器original_table表${wjm_ago_3month}以前数据，脚本开始执行${current_time1}" >/home/tongji/big_table_split/big_table_split.log

#######第一步#######
if [ $# -nq 2 ] ; then	
	echo "useage `basename` server_ip mysql_pw"
	exit 66
fi

# 备份original_table表(原来的一张大表)
# rm -rf /home/tongji/big_table_split/backup_sql/original_table${ES_IP}.sql
mysqldump -t -uroot -p${mysql_pw} --add-drop-database --databases talk --tables original_table > /home/tongji/big_table_split/backup_sql/original_table${ES_IP}.sql
if [  $? -eq 0  ]; then
	echo "备份original_table表成功!!!" >>/home/tongji/big_table_split/big_table_split.log
else
	echo "备份original_table表失败，脚本执行结束!!!" >>/home/tongji/big_table_split/big_table_split.log
	exit 1
fi

#######第二步#######
# 2.1创建保存original_table三月前数据的备份表
echo "use talk;create table if not exists original_table${wjm_l} (like original_table);" | mysql_conn2
# 2.2判断original_table${wjm_l}表存储引擎
engine_type=`mysql_conn1 "select engine from information_schema.tables where table_name='original_table${wjm_l}'"`
if [ "$engine_type" == "MyISAM" ];then
	# 2.3修改original_table${wjm_l}表存储引擎
	echo "修改original_table${wjm_l}表存储引擎,原存储引擎:${engine_type},修改为:InnoDB" >>/home/tongji/big_table_split/big_table_split.log
	echo "use talk;alter table original_table${wjm_l} engine=innodb;" | mysql_conn2
fi
# 2.4插入original_table三月前数据
current_time2=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
echo "开始向original_table${wjm_l}插入original_table三月前数据${current_time2}" >>/home/tongji/big_table_split/big_table_split.log
echo "use talk;insert into original_table${wjm_l} (eid,call_type,dialing,dialing_member,incoming,incoming_member,start_time,end_time,duration_time,duration_minute,call_state,pub_number,outnumber,provinc_city,line_type,outside_type,cc_number,event_str,event_name,res_token,record_status,record_filename) select eid,call_type,dialing,dialing_member,incoming,incoming_member,start_time,end_time,duration_time,duration_minute,call_state,pub_number,outnumber,provinc_city,line_type,outside_type,cc_number,event_str,event_name,res_token,record_status,record_filename from original_table where start_time < ${time1};" | mysql_conn2
if [  $? -eq 0  ]; then
	current_time3=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
	echo "向original_table${wjm_l}插入original_table三月前数据成功${current_time3}!!!" >>/home/tongji/big_table_split/big_table_split.log
else
	current_time4=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
	echo "向original_table${wjm_l}插入original_table三月前数据失败${current_time4}，脚本执行结束!!!" >>/home/tongji/big_table_split/big_table_split.log
	exit 1
fi

#######第三步#######
# 3.1创建临时表original_table_wftmp，用于临时存储三个月内的数据
echo "use talk;create table if not exists original_table_wftmp (like original_table);" | mysql_conn2
# 3.2判断original_table_wftmp表存储引擎
wftmp_engine_type=`mysql_conn1 "select engine from information_schema.tables where table_name='original_table_wftmp'"`
if [ "$wftmp_engine_type" == "MyISAM" ];then
	#3.3修改original_table_wftmp表存储引擎
	echo "修改original_table_wftmp表存储引擎,原存储引擎:${wftmp_engine_type},修改为:InnoDB" >>/home/tongji/big_table_split/big_table_split.log
	echo "use talk;alter table original_table_wftmp engine=innodb;" | mysql_conn2
fi
# 3.4插入original_table三月内数据
current_time5=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
echo "开始向original_table_wftmp插入original_table三月内数据${current_time5}" >>/home/tongji/big_table_split/big_table_split.log
echo "use talk;insert into original_table_wftmp (eid,call_type,dialing,dialing_member,incoming,incoming_member,start_time,end_time,duration_time,duration_minute,call_state,pub_number,outnumber,provinc_city,line_type,outside_type,cc_number,event_str,event_name,res_token,record_status,record_filename) select eid,call_type,dialing,dialing_member,incoming,incoming_member,start_time,end_time,duration_time,duration_minute,call_state,pub_number,outnumber,provinc_city,line_type,outside_type,cc_number,event_str,event_name,res_token,record_status,record_filename from original_table where start_time >= ${time1};" | mysql_conn2
if [  $? -eq 0  ]; then
        current_time6=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
        echo "向original_table_wftmp插入original_table三月内数据成功${current_time6}!!!" >>/home/tongji/big_table_split/big_table_split.log
else
        current_time7=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
        echo "向original_table_wftmp插入original_table三月内数据失败${current_time7}，脚本执行结束!!!" >>/home/tongji/big_table_split/big_table_split.log
        exit 1
fi
# 3.5备份original_table_wftmp表数据
# rm -rf /home/tongji/big_table_split/backup_sql/original_table_wftmp${ES_IP}.sql
mysqldump -t -uroot -p${mysql_pw} --add-drop-database --databases talk --tables original_table_wftmp > /home/tongji/big_table_split/backup_sql/original_table_wftmp${ES_IP}.sql
if [  $? -eq 0  ]; then
        echo "备份original_table_wftmp表成功!!!" >>/home/tongji/big_table_split/big_table_split.log
else
        echo "备份original_table_wftmp表失败，脚本执行结束!!!" >>/home/tongji/big_table_split/big_table_split.log
        exit 1
fi

#######第四步#######
# 4.1截断原表original_table，使id自增从1开始
current_time8=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
echo "truncate table original_table开始${current_time8}" >>/home/tongji/big_table_split/big_table_split.log
echo "use talk;truncate table original_table;" | mysql_conn2
if [  $? -eq 0  ]; then
	current_time9=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
        echo "truncate table original_table成功${current_time9}!!!" >>/home/tongji/big_table_split/big_table_split.log
else
	current_time10=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
        echo "truncate table original_table失败${current_time10}，脚本执行结束!!!" >>/home/tongji/big_table_split/big_table_split.log
        exit 1
fi
# 4.2判断original_table表存储引擎
original_engine_type=`mysql_conn1 "select engine from information_schema.tables where table_name='original_table'"`
if [ "$original_engine_type" == "MyISAM" ];then
	#4.3修改original_table_表存储引擎
	echo "修改original_table表存储引擎,原存储引擎:${original_engine_type},修改为:InnoDB" >>/home/tongji/big_table_split/big_table_split.log
	echo "use talk;alter table original_table engine=innodb;" | mysql_conn2
fi
# 4.4重新导入original_table_wftmp表三月内数据
current_time11=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
echo "重新导入original_table_wftmp表三月内数据${current_time11}" >>/home/tongji/big_table_split/big_table_split.log
echo "use talk;insert into original_table select * from original_table_wftmp;" | mysql_conn2
if [  $? -eq 0  ]; then
        current_time12=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
        echo "重新导入original_table_wftmp表三月内数据成功${current_time12}!!!" >>/home/tongji/big_table_split/big_table_split.log
else
        current_time13=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
        echo "重新导入original_table_wftmp表三月内数据失败${current_time13}，脚本执行结束!!!" >>/home/tongji/big_table_split/big_table_split.log
        exit 1
fi

#######第五步#######
# 删除临时表original_table_wftmp
echo "use talk;drop table if exists original_table_wftmp;" | mysql_conn2
current_time14=`date +%Y"-"%m"-"%d" "%H":"%M":"%S`
echo "###${wjm}拆分${ES_IP}服务器original_table表${wjm_ago_3month}以前数据，脚本执行结束${current_time14}" >>/home/tongji/big_table_split/big_table_split.log

