#/bin/bash
#把文件中所有的字符串替换,前面为啥加“”：http://blog.csdn.net/loveaborn/article/details/41706029
#sed -i "" 's/hello/word/g' public.txt
#sed -i 's/123/1234/g' public.txt 
sed -i "" "s/\/Users\/nemo\/07blog\/imgs/{{site.iurl}}/g" `grep /Users/nemo/07blog/imgs -rl ./_posts/`
#sed -i "s/\/Users\/nemo\/07blog\/imgs/{{site.iurl}}/g" `grep "/Users/nemo/07blog/imgs" -rl ./_posts/2015/`
