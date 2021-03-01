#!/usr/bin/env bash

#
# Copyright (c) 2020-2021 IAR Systems AB
#
# iarbuild-autocompletion.bash
#
# Provides Bash Autocompletion for IARBuild
#
# See LICENSE.md for detailed license information
#

__iarbuild()
{
	local cur prev cmds msgs nprocs 
	local ewp
	local opts
	COMPREPLY=()

	cur="${COMP_WORDS[COMP_CWORD]}"
	prev="${COMP_WORDS[COMP_CWORD-1]}"
	cmds="-clean -build -make -cstat_analyze -cstat_clean"
	msgs="error warnings info all"
	opts="-parallel -log -varfile"
	nprocs=$(echo $(seq 2 $(nproc)))

	case $COMP_CWORD in
	1)
		compopt -o nospace
		local IFS=$'\n'
		local LASTCHAR=' '
		COMPREPLY=($(compgen -o plusdirs -f -X '!*.@(EWP|ewp)' -- "${COMP_WORDS[COMP_CWORD]}"))
		if [ ${#COMPREPLY[@]} = 1 ]; then
			[ -d "$COMPREPLY" ] && LASTCHAR=/
			COMPREPLY=$(printf %q%s "$COMPREPLY" "$LASTCHAR")
		else
			for ((i=0; i < ${#COMPREPLY[@]}; i++)); do
				[ -d "${COMPREPLY[$i]}" ] && COMPREPLY[$i]=${COMPREPLY[$i]}/
			done
		fi
		return 0
		;;
	2)
		COMPREPLY=( $(compgen -W "${cmds}" -- ${cur}) )
		return 0
		;;
	3)
		ewp=${COMP_WORDS[1]}
		buildcfg=$( echo $(grep -A1 '<configuration>' ${ewp} | grep -oP '(?<=<name>).*?(?=</name>)') )
		COMPREPLY=( $(compgen -W "${buildcfg}" -- ${cur}) )
		return 0
		;;
	*) 
		case ${prev} in
		"-parallel")
			COMPREPLY=( $(compgen -W "${nprocs}" -- ${cur} ))
			return 0
			;;
		"-log")
			COMPREPLY=( $(compgen -W "${msgs}" -- ${cur} ))
			return 0
			;;
		"-varfile")
			COMPREPLY=( $(compgen -f -X '!*.@(argvars|ARGVARS)' -- ${cur} ))
			return 0
			;;
		esac

		# prevent repeated suggetions
		for removal in "${COMP_WORDS[@]}"; do
			case ${removal} in
			"-parallel")
				opts=${opts//-parallel/}
				;;
			"-log")
				opts=${opts//-log/}
				;;
			"-varfile")
				opts=${opts//-varfile/}
				;;
			esac
		done
		
		COMPREPLY=( $(compgen -W "${opts}" -- ${cur} ))
		return 0
		;;
	esac
}

complete -F __iarbuild iarbuild

