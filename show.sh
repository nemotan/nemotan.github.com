#/bin/bash
#把文件中所有的字符串替换,前面为啥加“”：http://blog.csdn.net/loveaborn/article/details/41706029
IMG_FILES=`grep {{site.iurl}} -rl ./_posts`
if [ -n "${IMG_FILES}" ];
	then
		sed -i "" "s/{{site.iurl}}/\/Users\/nemo\/07blog\/imgs/g" ${IMG_FILES}
	else
		echo "无文件需要替换图片!"
fi

#显示所有的macdown代码高亮
LANGURAGE_ARR=(java bash js sql)
for LANG in ${LANGURAGE_ARR[@]} 
	do       FILES=`grep -n "{% highlight ${LANG} %}" -rl ./_posts` 
		 if [ -n "$FILES" ];
		 	then
 		 		sed -i "" "s/{% highlight ${LANG} %}/\`\`\`${LANG}/g" ${FILES}
			else
				echo "${LANG}没有需要替换的文件"
		 fi		
	done
#替换结束符
END_FILES=`grep -n "{% endhighlight %}" -rl ./_posts`
if [ -n "${END_FILES}" ];
	then
		sed -i "" "s/{% endhighlight %}/\`\`\`/g" ${END_FILES}
	else
		echo "end结束符没有需要替换的文件"
fi
