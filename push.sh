#/bin/bash
echo "替换图片路径......"
sh hide.sh
echo "替换成功!"
echo "同步中......"
git add *
git commit -m "同步blog"
git status
git push
echo "同步完毕！"
