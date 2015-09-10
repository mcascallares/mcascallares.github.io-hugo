#!/bin/bash

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

# Build the project, if using a theme replace by 'hugo -t <yourtheme'
hugo

# Go To Public folder
cd public

# commit and push 
git commit -am "new version"
git push origin master

# Come Back
cd ..
