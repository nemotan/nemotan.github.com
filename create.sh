#!/bin/bash
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
        echo "---\nlayout: post\ntitle: $3\ncategories:\n- $4\ntags:\n- $5\n---" > $file
    fi
}

if [ $# -ne 3 ];
   then
     '参数不对！请输入三个参数【文件名，category，tag'
   else
     today=`date "+%Y-%m-%d"`
     fileName="$today-$1.md"
     dire=`pwd`/_posts/`date "+%Y"`
     createFile $dire $fileName $1 $2 $3
fi

