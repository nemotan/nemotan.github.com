#/bin/bash
#把文件中所有的字符串替换
sed -i "s/\/Users\/nemo\/07blog\/imgs/{{site.iurl}}/g" `grep "/Users/nemo/07blog/imgs" -rl ./_posts/2015/`
