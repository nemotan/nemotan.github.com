#/bin/bash
#把文件中所有的字符串替换,前面为啥加“”：http://blog.csdn.net/loveaborn/article/details/41706029
#sed -i "" 's/hello/word/g' public.txt
#sed -i 's/123/1234/g' public.txt 
sed -i "" "s/\/Users\/nemo\/07blog\/imgs/{{site.iurl}}/g" `grep /Users/nemo/07blog/imgs -rl ./_posts/`
#替换java高亮
sed -i "" "s/\`\`\`java/{% highlight java %}/g" `grep \`\`\`java -rl ./_posts/`
#替换bash高亮
sed -i "" "s/\`\`\`bash/{% highlight bash %}/g" `grep \`\`\`bash -rl ./_posts/`
#替换js高亮
sed -i "" "s/\`\`\`js/{% highlight js %}/g" `grep \`\`\`js -rl ./_posts/`
#替换sql高亮
sed -i "" "s/\`\`\`sql/{% highlight sql %}/g" `grep \`\`\`sql -rl ./_posts/`
#替换所有结束符
sed -i "" "s/\`\`\`/{% endhighlight %}/g" `grep \`\`\` -rl ./_posts/`


#sed -i "s/\/Users\/nemo\/07blog\/imgs/{{site.iurl}}/g" `grep "/Users/nemo/07blog/imgs" -rl ./_posts/2015/`

