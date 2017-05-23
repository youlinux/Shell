
## ssh批量修改密码小脚本

为了保证服务器的安全，大家肯定需要定期的去修改服务器的root密码
但是在服务器从多的情况下，手动修改肯定是非常麻烦的
因此我们可以采用脚本来进行批量的密码修改，


```shell
#!/bin/bash
port=22

# 在ip_list.txt文件中，可以将我们所有服务器的IP地址写出来 
for IP in `cat ip_list.txt`;do

# 使用命令生成一个随机密码并赋值给TMP_PWD
TMP_PWD=`mkpasswd -l 18 -C 8`

# R_PWD.txt 文件的格式 : 用户名:密码
echo "root:${TMP_PWD}" > R_PWD.txt

	if [ $? = 0 ]; then
		# 前提是执行此脚本的服务器要和其他所有的服务器互信并且可以免密码登陆
		# 使用ssh密码在每台需要修改密码的服务器上执行一个命令
		# chpasswd命令 读入 R_PWD.txt 文件(格式为用户名:密码)
		ssh -p${port} ${IP} chpasswd < R_PWD.txt
		
		# 将修改密码的时间,服务器IP,及新的密码记录到R_Server.log 文件中
		echo -e "$(date "+%Y-%m-%d %H:%M:%S")\t${IP}\t${TMP_PWD}\t" >> R_Server.log
		
	else
	
		echo -e "$(date "+%Y-%m-%d %H:%M:%S")\t${IP} R_PWD.txt is create fail\tplease check!\t" >> M_pass.log
	
	fi

	if [ $? = 0 ]; then	
		# 查看密码修改成功的服务器
		echo -e "$(date "+%Y-%m-%d %H:%M:%S")\tThe ${IP} passwd is modify OK\t" >> M_pass.log
	else
		# 查看密码修改失败的服务器
		echo -e "$(date "+%Y-%m-%d %H:%M:%S")\tThe ${IP} passwd is modify fail\tplease check!\t" >> M_pass.log
	fi 

done
```