#/bin/bash
echo "同步中......"
git add *
git commit -m "同步blog"
git push
echo "同步完毕！"
