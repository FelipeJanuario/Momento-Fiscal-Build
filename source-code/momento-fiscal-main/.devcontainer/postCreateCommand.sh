#!/bin/bash

# Config bash
echo "alias ll='ls -al'" >> ~/.bashrc
echo "alias l='ls -l'" >> ~/.bashrc
echo "force_color_prompt=yes" >> ~/.bashrc
echo "color_prompt=yes" >> ~/.bashrc

echo "
parse_git_branch() {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}
" >> ~/.bashrc
echo "PS1='\[\033[01;34m\]\w\[\033[01;32m\]\$(parse_git_branch)\[\033[00m\] \$ '" >> ~/.bashrc

# Setup git hooks
cd .devcontainer/hooks && ls | xargs chmod +x
cd ../../.git/hooks && find ../../.devcontainer/hooks -type f -exec ln -sf {} /app/.git/hooks/ \;
cd ../../

# Setup core API
# cd core-api
# bundle install
# cd ..
