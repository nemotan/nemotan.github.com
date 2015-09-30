#/bin/bash
#把文件中所有的字符串替换,前面为啥加“”：http://blog.csdn.net/loveaborn/article/details/41706029
sed -i "" "s/\/Users\/nemo\/07blog\/imgs/{{site.iurl}}/g" `grep /Users/nemo/07blog/imgs -rl ./_posts/`

NGURAGE_ARR=(java bash js sql)
for LANG in ${LANGURAGE[@]}
do
  echo ${LANG}
  sed -i "" "s/\`\`\`${LANG}/{% highlight ${LANG} %}/g" `grep -n "\`\`\`${LANG}" -rl ./_posts/`
done
sed -i "" "s/\`\`\`/{% endhighlight %}/g" `grep -n "\`\`\`" -rl ./_posts/`
