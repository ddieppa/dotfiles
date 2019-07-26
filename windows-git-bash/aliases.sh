# Some good standards, which are not used if the user
# creates his/her own .bashrc/.bash_profile

# --show-control-chars: help showing Korean or accented characters
alias ls='ls -F --color=auto --show-control-chars'
alias ll='ls -l'
alias d='docker'

case "$TERM" in
xterm*)
	# The following programs are known to require a Win32 Console
	# for interactive usage, therefore let's launch them through winpty
	# when run inside `mintty`.
	for name in node ipython php php5 psql python2.7
	do
		case "$(type -p "$name".exe 2>/dev/null)" in
		''|/usr/bin/*) continue;;
		esac
		alias $name="winpty $name.exe"
	done
	;;
esac

## Utils
alias updalias='source "/c/Program Files/Git/etc/profile.d/aliases.sh"'
alias src='cd /c/src/'

## Docker and Docker Compose aliases
source "/c/Program Files/Git/etc/profile.d/docker-compose.aliases.sh"

## Git Aliases
source "/c/Program Files/Git/etc/profile.d/git.aliases.sh"

## Yarn Aliases
source "/c/Program Files/Git/etc/profile.d/yarn.aliases.sh"

## npm Aliases
source "/c/Program Files/Git/etc/profile.d/npm.aliases.sh"
