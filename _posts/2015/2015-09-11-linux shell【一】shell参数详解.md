
---
layout: post
title: linux shell【一】shell参数详解以及常用判断
categories:
- shell
tags:
- linux
---

##参数详解：$#,$@,$*,$?,$0,$1,$2
	
	$0 shell本身文件名
	$1 第一个参数
	$# 参数的个数，不包括命令本身
	$@ 参数列表，也不包括命令本身，是一个参数数组
	$* 参数列表，与$@不同，$*的参数列表是一个字符串
	$? 最后运行的命令的结束码
	$$ shell本身的PID
	
##shell中常用if判断语句参数

	–b 当file存在并且是块文件时返回真
	-c 当file存在并且是字符文件时返回真
	-d 当pathname存在并且是一个目录时返回真
	-e 当pathname指定的文件或目录存在时返回真
	-f 当file存在并且是正规文件时返回真
	-g 当由pathname指定的文件或目录存在并且设置了SGID位时返回为真
	-h 当file存在并且是符号链接文件时返回真，该选项在一些老系统上无效
	-k 当由pathname指定的文件或目录存在并且设置了“粘滞”位时返回真
	-p 当file存在并且是命令管道时返回为真
	-r 当由pathname指定的文件或目录存在并且可读时返回为真
	-s 当file存在文件大小大于0时返回真
	-u 当由pathname指定的文件或目录存在并且设置了SUID位时返回真‘
	-w 当由pathname指定的文件或目录存在并且可执行时返回真。一个目录为了它的内容被访问必然是可执行的。
	-o 当由pathname指定的文件或目录存在并且被子当前进程的有效用户ID所指定的用户拥有时返回真。	
	
##UNIX Shell 里面比较字符写法
	
	-eq   等于
	-ne   不等于
	-gt   大于
	-lt   小于
	-le   小于等于
	-ge   大于等于
	-z    空串
	-n    非空串
	=      两个字符相等
	!=    两个字符不等
	
##实例【一】给出标题直接在目录中创建blog
**说明：**输入文件名，分类，tag三个参数，会在指定目录创建一个文件，并且分类信息和tag信息写入到文件中去。
<br>
shell代码如下：

	!/bin/bash
	function createFile(){
	    dire=$1
	    file=$2
	    file=$dire/$file
	    if [ ! -d $dire ];
	        then mkdir $dire
	        echo "$dire 文件夹创建成功!"
	    fi
	
	    if [ -f $file ];
	        then
	            echo '该文件已经存在!'
	        else
	            `touch $file`
	        echo "$file 创建成功"！
	        echo "---\nlayout: post\ntitle: $2\ncategories:\n- $3\ntags:\n- $4\n---" > $file
	    fi
	}
	
	if [ $# -ne 3 ];
	   then
	     '参数不对！请输入三个参数【文件名，category，tag'
   	else
     	 today=`date "+%Y-%m-%d"`
     	 fileName="$today-$1.md"
     	 dire=`pwd`/_posts/`date "+%Y"`
     	 createFile $dire $fileName $2 $3
	fi
		
	
