# workaround for Terminal.app, where every shell is a login shell
if [ -r ~/.bashrc ]; then
  source ~/.bashrc
fi
