source ~/.profile

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# if running interactively start fish if not already running
if [[ $(ps -p $PPID -o "comm=") != "fish" && -z ${ZSH_EXECUTION_STRING} ]]
then
  [[ -o login ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=''
	exec fish $LOGIN_OPTION
fi
