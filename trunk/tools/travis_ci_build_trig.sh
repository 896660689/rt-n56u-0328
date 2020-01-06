#!/bin/sh
TRIGS="pdv-7621-ad"

git config --global user.name "896660689"
git config --global user.email "896660689@github.com"

gitver="$(git rev-parse --short=7 HEAD 2>/dev/null)"
msg="build trigger: $gitver"

for repo in $TRIGS ; do
	cd /opt
	if [ -f /opt/${repo}.yml ]; then
		git clone --depth=1 https://896660689:$ad@github.com/896660689/$repo.git && cd $repo
		echo "$(LANG=C date) $gitver" >> Build.log
		cp -f /opt/${repo}.yml .travis.yml
		git add .
		git commit -m "$msg"
		git remote set-url origin https://896660689:$ad@github.com/896660689/$repo.git
		git push
	fi
done
