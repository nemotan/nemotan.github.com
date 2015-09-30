#/bin/bash
#把文件中所有的字符串替换,前面为啥加“”：http://blog.csdn.net/loveaborn/article/details/41706029
sed -i "" "s/{{site.iurl}}/\/Users\/nemo\/07blog\/imgs/g" `grep {{site.iurl}} -rl ./_posts/`
#显示所有的macdown代码高亮
LANGURAGE_ARR=(java bash js sql)
for LANG in ${LANGURAGE[@]} 
do       
  echo ${LANG}
  sed -i "" "s/{% highlight ${LANG} %}/\`\`\`${LANG}/g" `grep -n "{% highlight ${LANG} %}" -rl ./_posts`
done
#替换结束符
sed -i "" "s/{% endhighlight %}/\`\`\`/g" `grep -n "{% endhighlight %}" -rl ./_posts`
