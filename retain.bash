#!/bin/bash
#
# Copyright (C) 2019 Roman Tsykaliak
#
# This document is free software: you can
# redistribute it and/or modify it under the terms
# of the GNU General Public License as published
# by the Free Software Foundation, either version
# 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it
# will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR
# PURPOSE.  See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU
# General Public License along with this program.
# If not, see <http://www.gnu.org/licenses/>.
##################################################
# Copy files to a temporary directory.
#
# In the same directory where the file(s) is(are)
# stored, creates a temporary directory, and
# copies the file(s) only if both the time and the
# size are bigger than those in already copied
# file(s).  Between each test waits for
# `pause_interval` seconds.
#
# Usage: retain
#
# Invoke like below:
#   ./retain
#
# Return: 2 if an error occurs
##################################################
# Specify amount of time to wait between tests:
pause_interval=30 # seconds
in_quit='q' # Specify quit character
##################################################
# DO NOT MODIFY STARTING FROM HERE!!!
declare -r current_dir=$(pwd | sed 's/\/*$/\//');
declare -r retain_dir=$(printf "%s%s" "$current_dir" "$(date '+%Y_%m_%d_%H_%M_%S')" | sed 's/\/*$/\//');
if ! [[ -d "$retain_dir" ]]; then
    mkdir "$retain_dir" && chmod u+w "$retain_dir"
else
    echo "$0: terrible internal error: directory"\
         "was NOT created: \"${retain_dir}\"" 1>&2
    exit 2
fi
declare -a source_file_list
declare -a destination_file_list
printf "Type '%s' to quit:\n" ${in_quit}
while :
do
    readarray -t source_file_list <<< $(find . -maxdepth 1 -type f)
    for (( i=0; i < ${#source_file_list[@]}; i++)); do
        destination_file_list[$i]=$(printf "%s%s" "$retain_dir" "${source_file_list[$i]#./}")
    done
    # printf "source_file_list\n%s\n" "${source_file_list[@]}"
    # printf "destination_file_list\n%s\n" "${destination_file_list[@]}"
    for (( i=0; i < ${#source_file_list[@]}; i++)); do
        if [[ "${source_file_list[$i]}" -nt "${destination_file_list[$i]}" ]]; then
            # echo "source newer or dest does not exist"
            if [[ -w "${destination_file_list[$i]}" ]]; then
                # echo "dest exists and is writable"
                [[ $(stat -Lc "%s" "${source_file_list[$i]}") -gt \
                   $(stat -Lc "%s" "${destination_file_list[$i]}") ]] && {
                    # printf "copy \"%s\" into \"%s\"" "${source_file_list[$i]}" \
                    #        "${destination_file_list[$i]}";
                    rsync "${source_file_list[$i]}" "${destination_file_list[$i]}"; }
            else
                # printf "create \"%s\"" "${destination_file_list[$i]}"
                rsync "${source_file_list[$i]}" "${destination_file_list[$i]}"
            fi
        fi
    done
    read -n 1 -t $pause_interval quit
    if [[ $? -eq 0 ]] && test "${quit,,}" == "${in_quit}" ; then
        exit 0 # stop if "q" or "Q"
    else
        continue
    fi
done
##################################################
