#/bin/bash
#把文件中所有的字符串替换,前面为啥加“”：http://blog.csdn.net/loveaborn/article/details/41706029
FILES_IMG=`grep /Users/nemo/07blog/imgs -rl ./_posts/`
echo ${FILES_IMG}
if [ -n "${FILES_IMG}" ];
    then 
	sed -i "" "s/\/Users\/nemo\/07blog\/imgs/{{site.iurl}}/g" ${FILES_IMG}
    else 
    	echo "没有需要替换的文件！"
fi

LANGURAGE_ARR=(java bash js sql)
for LANG in ${LANGURAGE_ARR[@]}
do
     PA="\`\`\`";
     FILES=`grep -n "${PA}${LANG}" -rl ./_posts/`
     if [ -n "${FILES}" ];
     	then 
	    sed -i "" "s/\`\`\`${LANG}/{% highlight ${LANG} %}/g" ${FILES}
        else
	    echo "${LANG}无匹配的文件"
     fi
done

FILES_END=`grep -n '\`\`\`' -rl ./_posts/`
if [ -n "${FILES_END}" ];
	then 
 		sed -i "" "s/\`\`\`/{% endhighlight %}/g" ${FILES_END}
	else
		echo "结束符无匹配的文件"
fi	
