#!/bin/sh

################################################################################
#                                                                              #
#	rnspacy.sh
#
#	author:	Erfan Shoara (erfan@shoara.net)
#	date:	Aug 27, 2023
#	description:
#		it fixes annoying file/dir names that have bad characters in them
#		it replaces them with a good char, by default it removes only spaces
#		' ' to '_'.
#
#		config:
#			can edit this file to change the default options
#			(read #var section)
#			or one can use the command flags (args) to change the options at
#			runtime.
#
#		note:
#			the only important note is about the lst_bad_char
#			(list of cad characters) it is used as regexp char class,
#			so follow that; e.g.
#				"1-4" will be treated as [1-4] which is {1,2,3,4}
#				and NOT {'1', '-', '4'}
#                                                                              #
################################################################################


#
# var
#

# list of characters to be replaced - it should be treated as regexp char class
# can change it using -b "new bad char"
lst_bad_char=" "

# the new char subbing bad charachters
# can change it using -g "good char"
char_good='_'

# it's used to know which part of given path should not 'rnspacy'
origin_dir=""

# verbose is false by default
# verbose indicates if rnspacy should print out what's happening
# can be set using -v
is_verbose=0

# false by default and set by passing -r
# desc:
# 	( NOTE -R will lead to ignoring -r )
# 	if -r is set, and [path] points to a file, -r will be ignored
# 	and will rnspacy on that file only
# 	elif [path] points to a dir, it will rnspacy all (even hidden files)
# 	if not set, it will only rnspacy either file or dir pointing to
is_recursive=0

# false by default and set by passing -R
# desc:
# 	( NOTE -R will lead to ignoring -r )
# 	if -R is set, and [path] points to a file, -R will be ignored and
# 	will rnspacy on that file only
# 	elif [path] points to a dir, it will rnspacy all (even hidden files)
# 	under the dir tree - even files in the subdir of dir
# 	if not set, depends on -r state
is_deep_recursive=0

# false by default - use -f to set it
# desc:
# 	if unset, it will skip files those their new name already exist,
# 	and will print a Warning
# 	if set, it will overwrite the existing file, but also prints
# 	a warning message if -v is set
is_forced=0

# false by default - use -p to set it
# it's used to only print the files about to move - checking
# it will overwrite -v (-v will be true if -p is passed)
# it will not make any changes
is_print=0


#
# func
#

# used to print different messages:
# 	Error
# 	Warning
# 	Info
# 	Success
#
# 	usually Info and Success are printed if -v is set
rnspacy_print ()
{
	str_head=""
	str_code="$2"
	str_body="$3"
	str_tail="\033[0m"

	ansi_red="\033[0;31m"
	ansi_ylw="\033[1;33m"
	ansi_grn="\033[0;32m"

	_fd=1

	case $1 in
		1)
			str_head="${ansi_red}rnspacy:[Error]($str_code):"
			_fd=2
			;;
		2)
			str_head="${ansi_ylw}rnspacy:[Warning]($str_code):"
			;;
		3)
			str_head="${ansi_grn}rnspacy:[Success]($str_code):"
			;;
		*)
			str_head="rnspacy:[Info]:"
			str_tail=""
			;;
	esac

	echo -e "$str_head $str_body $str_tail" >&$_fd
}


# ret:
# 	-1:	Error - $1 not recognized
# 	0:	Success - $1 is an option
# 	0<:	optional param :
# 		1:	new lst_bad_char
# 		2:	new char_good
rnspacy_checkout_option ()
{
	if [ "$1" = "-v" ]
	then
		# if verbose
		is_verbose=1
	elif [ "$1" = "-p" ]
	then
		# if print_mode
		is_verbose=1
		is_print=1
	elif [ "$1" = "-r" ]
	then
		# if recursive
		is_recursive=1
	elif [ "$1" = "-f" ]
	then
		# if forced
		is_forced=1
	elif [ "$1" = "-R" ]
	then
		# if deep recursive
		is_deep_recursive=1
	elif [ "$1" = "-b" ]
	then
		# if user setting lst_bad_char
		return 1;
	elif [ "$1" = "-g" ]
	then
		# if user setting char_good
		return 2;
	else
		# invalid option
		return -1;
	fi

	return 0;
}


rnspacy_single_item ()
{
	#
	# var
	#
	
	# each bad_name is:
	# 	"$origin_dir$new_dir$just_file"
	# 	and this func is supposed to only change the char in just_file
	bad_name="$1"

	new_dir="$(echo "$bad_name" | sed -e "s*^$origin_dir**" | \
		grep -Eo ".*/" | sed -e "s/[$lst_bad_char]/$char_good/g")"
	just_file="$(echo "$bad_name" | grep -Eo "[^/]*$")"
	
	new_name="$origin_dir$new_dir$just_file"
	new_file="$origin_dir$new_dir$(echo "$just_file" | \
		sed -e "s/[$lst_bad_char]/$char_good/g")"


	if ! [ -e "$new_file" ]
	then
		# if new name is unique

		if [ $is_print -eq 0 ]
		then
			# if not in print mode
			mv -i "$new_name" "$new_file"
		fi

		if [ $is_verbose -eq 1 ]
		then
			rnspacy_print 0 0 "renamed \"$new_name\" to \"$new_file\"" 
		fi
	elif [ $is_forced -eq 1 ]
	then
		# if there's already a file with that name
		# but overwrite is forced

		if [ $is_print -eq 0 ]
		then
			# if not in print mode
			mv -f "$new_name" "$new_file"
		fi

		if [ $is_verbose -eq 1 ]
		then
			rnspacy_print 0 0 \
				"renamed(OVERWRITE) \"$new_name\" to \"$new_file\"" 
		fi
	else
		# if there's already a file with that name
		if [ $is_verbose -eq 1 ]
		then
			rnspacy_print 2 1 \
				"can't rename \"$new_name\" to \"$new_file\" - skipping it\n"`
				`"\t\"$new_file\" already exist. you can use -f to overwrite."
		fi
	fi
}


rnspacy_deep ()
{
	if [ $is_deep_recursive -eq 1 ]
	then
		# do deep
		find "$1" -name "*[$lst_bad_char]*" | while read file
		do
			rnspacy_single_item "$file"
		done
	elif [ $is_recursive -eq 1 ]
	then
		# do only dir items
		find "$1" -maxdepth 1 -name "*[$lst_bad_char]*" | while read file
		do
			rnspacy_single_item "$file"
		done
	else
		# do only the given dir if has bad char
		if [[ "$1" =~ [$lst_bad_char] ]]
		then
			rnspacy_single_item "$1"
		fi
	fi
}


#
# main
#

main ()
{
	#
	# var
	#

	num_args=$#
	is_path_given=0
	_i=1
	_i_n=0
	lst_path=()
	_arg=""
	ret_arg=0
	num_path=0


	#
	# main
	#
	
	# proccessing all arguments
	while [ $_i -le $num_args ]
	do
		# going through the args
		_arg="${!_i}"

		# checking if [path] given or an option
		if [ "${_arg:0:1}" = "-" ]
		then
			_i_n=$((_i + 1))

			rnspacy_checkout_option "$_arg"
			ret_arg=$?

			case $ret_arg in
				1)	
					if [ $_i_n -le $num_args ]
					then
						# check out next arg
						lst_bad_char="${!_i_n}"

						# increment index
						_i=$_i_n
					else
						rnspacy_print 2 2 "Invalid Use of Option ($_arg):\n"`
							`"\twhen using ($_arg) should provide new char."

						exit 1
					fi
					;;
				
				2)
					if [ $_i_n -le $num_args ]
					then
						# check out next arg
						char_good="${!_i_n}"

						# increment index
						_i=$_i_n
					else
						rnspacy_print 2 2 "Invalid Use of Option ($_arg):\n"`
							`"\twhen using ($_arg) should provide new char."

						exit 1
					fi
					;;
				255)
					# error - invalid option
					rnspacy_print 1 1 "Invalid Option ($1)"
					exit 1
					;;
			esac
		else
			# if it's not an option - but supposedly a path
			# will check if it's valid path later
			lst_path+=("$_arg")
		fi
		
		# incrementing _i
		_i=$((_i + 1))
	done

	
	if [[ "$lst_bad_char" =~ [/] ]]
	then
		# error -  lst_bad_char cannot have '/' in it
		rnspacy_print 2 3 "Invalid Bad_Char ($lst_bad_char)\n"`
			`"\tBad_Char cannot contain '/'."

		exit 1
	fi
	
	# rnspacing all pathes
	# {
	num_path=${#lst_path[@]}

	for ((_i = 0; _i < num_path; _i++))
	do
		# setting the origin_dir for each path
		origin_dir="$(echo "${lst_path[_i]}" | grep -Eo ".*/")"


		if [ -f "${lst_path[_i]}" ]
		then
			# it's file, only if it's bad
			if [[ "${lst_path[_i]}" =~ [$lst_bad_char] ]]
			then
				rnspacy_single_item "${lst_path[_i]}"
			fi
		elif [ -d "${lst_path[_i]}" ]
		then
			# it's a dir
			rnspacy_deep "${lst_path[_i]}"
		else
			# it's neither - invalid
			rnspacy_print 2 4 "Invalid Path (${lst_path[_i]})"
			exit 1
		fi
	done
}
main "$@"
