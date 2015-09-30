#!/bin/bash
sed -i "" "s/\`\`\`java/{% highlight java %}/g" `grep \`\`\`java -rl ./_posts/2015/`

