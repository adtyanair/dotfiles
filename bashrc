[[ $- != *i* ]] && return

if command -v tmux > /dev/null ; then
	case "${TERM}" in
		*screen*)
		;;
		*)
			[ -n "${DISPLAY}" ] && [ "x${TERM_PROGRAM}" != 'xvscode' ] && [ "x${TERMINAL_EMULATOR}" != 'xJetBrains-JediTerm' ] && [ -z "${TMUX}" ] && exec tmux
		;;
	esac
fi

shopt -s histappend
shopt -s checkwinsize
HISTCONTROL=ignoreboth
HISTSIZE=-1
HISTFILESIZE=-1

_is_git_dir() {
	[ "$(git rev-parse --is-inside-work-tree 2>/dev/null)" = "true" ] && \
		git rev-parse --show-toplevel 2>/dev/null
}

_get_git_branch() {
	[ "$(_is_git_dir)" ] && \
		echo -n " ($(git symbolic-ref --quiet --short HEAD 2>/dev/null))"
}

_get_git_dirty() {
	local _GITDIR="$(_is_git_dir)"
	if [ "$_GITDIR" ]; then
	{
		local _TEMP="$(_get_git_branch | sed -e 's/(//' -e 's/)//' -e 's/\ //' )"
		if [ x"$(git rev-parse $_TEMP 2>/dev/null)" = x"$(git rev-parse remotes/origin/$_TEMP 2>/dev/null)" ]
		then {
			local _OC='\033[1;32m'
			local _SYM=' ✔ '
		}
		else {
			local _OC='\033[1;33m'
			local _SYM=' ✔ '
		}
		fi

		if [ "$(git diff --name-only --cached 2>/dev/null)" ]
		then {
			local _OC='\033[1;33m'
			local _SYM=' ✘ '
		}
		fi

		if [ "$(git diff --name-only 2>/dev/null)" ] || [ "$(git ls-files --others --exclude-standard "$_GITDIR" 2>/dev/null)" ]
		then {
			local _OC='\033[1;31m'
			local _SYM=' ✘ '
		}
		fi
		local _CC='\033[0m'
		local _ARG="$1"
		case "$_ARG" in
			"-o")
				echo -ne "$_OC"
				;;
			"-c")
				echo -ne "$_CC"
				;;
			*)
				echo -ne "$_SYM"
				;;
		esac
	}
	fi
}

_find_parent_with_file() {
	if [ -z "$2" ] || ! [ -d "$1" ] ; then
		echo -n
	elif [ -r "$1/$2" ] ; then
		echo -n "$1/$2"
	elif ! [ "$1" == "/" ] ; then
		_find_parent_with_file "${1%/*}" "$2"
	fi
}

_get_golang_version() {
	GO_MOD_PATH="$(_find_parent_with_file "${PWD}" "go.mod")"
	if [ -e "${GO_MOD_PATH}" ] ; then
		echo -n "via ﳑ "
		#grep "^go " "${GO_MOD_PATH}" | sed 's/go\s//g'
		go version | awk '{print $3}' | sed 's/go//g'
	fi
}

_get_nodejs_version() {
	PKG_JSON_PATH="$(_find_parent_with_file "${PWD}" "package.json")"
	if [ -e "${PKG_JSON_PATH}" ] ; then
		echo -n "via  "
		node --version | sed 's/v//g'
	fi
}

_get_virtual_env_name() {
	[ "${VIRTUAL_ENV}" ] && echo -n "[${VIRTUAL_ENV##*/}] "
}

_get_python_version() {
	if [ "${VIRTUAL_ENV}" ] ; then
		echo -n "via  $(${VIRTUAL_ENV}/bin/python --version | sed 's/Python\ //g')"
	else
		PIPFILE_PATH="$(_find_parent_with_file "${PWD}" "Pipfile")"
		if [ -e "${PIPFILE_PATH}" ] ; then
			echo -n "via  "
			grep "python_version" "${PIPFILE_PATH}" | sed 's/.*=\s\"//g;s/\"//g' 2> /dev/null
		fi
	fi
}

_err_code() {
	local _ERR="$?"
	[ $_ERR -ne 0 ] && echo -n "${_ERR} "
}

_is_ssh() {
	[ "${SSH_CONNECTION}" ] && echo -n " "
}

# Setup colors
[ -f "${HOME}/.config/scripts/dracula.sh" ] && . "${HOME}/.config/scripts/dracula.sh"

# Setup prompt
PROMPT_COMMAND='history -a; echo -en "\033]2;$(_get_virtual_env_name)${PWD##*/}$(_get_git_branch)\007"'
PS1=" \[\033[1;31m\]\$(_err_code)\[\033[0m\]"
PS1="${PS1}\[\033[1;36m\]\$(_is_ssh)\[\033[0m\]"
PS1="${PS1}\[\033[1;33m\]\$(_get_virtual_env_name)\[\033[0m\]"
PS1="${PS1}\[\033[1;32m\]\W\[\033[0m\]"
PS1="${PS1}\[\033[1;34m\]\$(_get_git_branch)\[\033[0m\]"
PS1="${PS1}\[\$(_get_git_dirty -o)\]\$(_get_git_dirty)\[\$(_get_git_dirty -c)\]"
PS1="${PS1}\[\033[1;35m\]\$(_get_python_version)\[\033[0m\]"
PS1="${PS1}\[\033[1;35m\]\$(_get_golang_version)\[\033[0m\]"
PS1="${PS1}\[\033[1;35m\]\$(_get_nodejs_version)\[\033[0m\]"
PS1="${PS1}\n \[\033[1;37m\]\$\[\033[0m\] "
export PS1
export PS2=" \[\033[1;35m\]...\[\033[0m\] "

# Setup additional bash completion
for file in "${HOME}"/.local/etc/bash_completion.d/* ; do
	[ -r "${file}" ] && . "${file}"
done

# Misc. environment variables
export VIRTUAL_ENV_DISABLE_PROMPT=1
export GPG_TTY=$(tty)
export LESSHISTFILE="-"

# Setup aliases
[ -f "${HOME}/.bash_aliases" ] && . "${HOME}/.bash_aliases"

# source paths if not on a login shell
shopt -q login_shell || . "${HOME}/.bash_paths"

