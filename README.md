
# rnspacy

## Table of Contents
- [Info](#info)
- [Description](#description)
- [Config](#config)
- [Use](#use)
- [Install](#install)
- [Contact](#contact)


## Info

- **Name:**         rnspacy
- **Author:**       Erfan Shoara
- **Version:**      1.0
- **Release Date:** Aug 30, 2023
- **Repository:**   [link to github repo](https://github.com/erfanshoara/rnspacy.git)
- **Language:**     shell
- **Platform:**     Unix, Linux


## Description

it fixes annoying file/dir names that have *bad* characters in them
it replaces them with a *good* character, by default it removes only spaces
' ' to '\_' but user can either configure it [see how to config](#config)
and/or change it at runtime [see how to use cmd](#use)

it has some basic features such as renaming files and dir recursively.
it can also be used to only print the *bad* files/dirs

it's meant to do a simple job using other basic shell commands:

- grep
- find
- sed
- mv
- echo
- ...


## Config

rnspacy is not a program, it's a script, so if need to change any default stuff,
change the main (only) rnspacy.sh file.

currently it's not using any environment variable.


## Use

usage is very simple:

> rnspacy \[options\] path \[options\]

*path* is restricted but options are not. *path* is obviously the path to
either a file or dir based on given options it will either do a recursive or
deep\_recursive if *path* is a dir, it it's a file it will ignore any recursive
flag.

### Options

1. **-v**

verbose: -v will set the verbose flag
if set, rnspacy will print messages at *Info* level - for every rename


2. **-p**

print\_mode: -p will set rnspacy in print mode
if set, rnspacy will only print the file/dir with *bad* name, and their new
*good* name. it will also inform user if there will be any overwrite.
This option is mainly used if user is not sure what will happen when
*rnspacy*ing a dir for example.


3. **-r**

shallow\_recursive: -r will set the shalow recursive flag
if set, rnspacy will rename the given dir and all the items inside that
dir - effectivvely level\_1 deep.
if *path* is a file, -r will be ignored.
if -R is given, -r will be ignored.


4. **-R**

deep\_recursive: -r will set the deep recursive flag
if set, rnspacy will rename the given dir and all the items underneath it
\- max level.
if *path* is a file, -R will be ignored.
given -R will ignore -r if given.


5. **-f**

forced: -f will set the forced flag.
by default rnspacy will not overwrite a file or dir, if the new *good* is not
unique, and it will skip it - it will also print out a *Warning* message.
if -f is passed, it will overwirte, and in verbose mode, it will indicate
the renaming of the file was an overwrite.


6. **-b** *list_bad_char*

list of bad characters: -b will update the list of bad characters at runtime.
*list_bad_char* is restricted, and if missing it will be fatal.
*list_bad_char* is effectively a <u>bracket expression</u> in regex 
[see POSIX regex documentation 9.3.5](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap09.html#tag_09_03_05)


7. **-g** *good_char*

good char: it changes the good character that replaces the bad characters
by default is '\_', and if it's changed to mutiple char each bad char will be
replaced by all good char.
*good_char* is restricted, and it will fetal it it's not given.


## Install

again,
> rnspacy is not a program, it's a script

so just place it somewhere included in <code>$PATH</code>, and call it when
need it.


## Contact

> **Email:** erfan@shoara.net
>> i don't know why one would need it, but ...

