# if running interactively start fish if not already running
if [[ $(ps -p $PPID -o "comm=") != "fish" && -z ${ZSH_EXECUTION_STRING} ]]
then
  [[ -o login ]] && LOGIN_OPTION='--login' || LOGIN_OPTION=''
	exec fish $LOGIN_OPTION
fi

