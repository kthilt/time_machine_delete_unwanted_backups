#!/bin/bash

###############################################################################
#2016/12/16
#Kevin Hilt
#TODO
#	- Test with multiple backup locations
#	- Test with a Time Capsule instead of a generic external drive
#	- Put $saved_backup_names in an external file or allow the names to be provided as command line options
#	- Display some sort of progress indication during a backup's deletion
#		-- Something built into tmutil?
#		-- Determine the size of the backup directory at the start and calculate the difference every few seconds?
#	- More robust error checking
###############################################################################

sudo_command="sudo bash $(cd "$(dirname "$0")" && pwd)/$(basename ${BASH_SOURCE[0]})"

while [[ $# -gt 0 ]]
do
	option_name="$1"
    case "$option_name" in
        #This many backups will be deleted
        -a|--amount-to-delete)
			shift
        	amount_of_backups_to_delete="$1"
        ;;

        #The default is to delete oldest to newest
        -n|--newest-to-oldest)
        	delete_newest_to_oldest=true
        ;;

        #Test run
        -t|--test-run)
        	test_run=true
        ;;

        #Print help
        -h|--help)
	        echo "This script deletes a certain amount of Time Machine backups that are no longer needed. If there are important backups you never want to delete, add them to the saved_backup_names array in this file."
	        echo "OPTIONS"
	        echo "-a (--amount-to-delete) <n>"
	        echo "    This required option  specifies how many backups should be deleted. n should be an integer greater than 0 or \"all\" to delete all unwanted backups."
	        echo "-n (--newest-to-oldest)"
	        echo "    This optional option changes the delete order from the default of oldest to newest."
	        echo "-t (--test-run)"
	        echo "    This optional option runs the entire script as normal but substitutes the \"delete\" verb of the deletion command with a fake verb so the deletions do not occur."
	        echo "    This is the closest you can get to seeing what will happen without actually performing the deletes."
	        echo
	        echo "EXAMPLE USAGE"
	        echo "    $sudo_command -a 4 -t"
	        echo "    $sudo_command -a all --newest-to-oldest"
	        exit
        ;;
        *)
        #Unrecognized option
        echo "'$option_name' is not a valid option."
        ;;
    esac
    #Move to the next option
    shift
done

if [[ "$EUID" -ne 0 ]]
then
  echo "You must run this as root. Use this command:"
  echo "    $sudo_command $@"
  exit
fi

#If --amount-to-delete wasn't provided, exit
if [[ -z $amount_of_backups_to_delete ]]
then
	echo "Missing required option: --amount-to-delete <n>"
	exit
fi

#If --newest-to-oldest wasn't provided, set the flag to false
if [[ -z $delete_newest_to_oldest ]]
then
	delete_newest_to_oldest=false
fi

#If --test-run wasn't provided, set the flag to false
if [[ -z $test_run ]]
then
	test_run=false
fi

#Array of backup names for backups that will NOT be deleted
#If there is a benchmark backup that should never be deleted by this script, add it to this array
saved_backup_names=(
	"2014-05-17-094303"
	"2014-06-15-093106"
	"2014-06-29-133847"
	"2015-01-02-145324"
	"2015-02-18-103203"
	"2015-07-25-001743"
	"2015-09-12-123932"
	"2015-12-12-025214"
	"2016-12-16-044517"
)

#Get an array of absolute paths to all remaining backups
all_backup_paths=($(/usr/bin/tmutil listbackups))
if [[ $amount_of_backups_to_delete == "all" ]]
then
	amount_of_backups_to_delete="${#all_backup_paths[@]}"
elif [[ $amount_of_backups_to_delete -lt 1 ]]
then
	echo "--amount-to-delete must be > 0"
	exit
fi

#Build an array of paths to the backups that will be deleted so the list can be approved by the user
amount_of_backups_added=0
for ((i = 0; i < ${#all_backup_paths[@]} && $amount_of_backups_added < $amount_of_backups_to_delete; i++))
do
	#Offset index from the last item if the newest backups should be deleted first
	index=$i
	if [[ $delete_newest_to_oldest = true ]]
	then
		index=`expr ${#all_backup_paths[@]} - 1 - $index`
	fi

	backup_name=$(basename ${all_backup_paths[$index]})
	able_to_delete=true
	for name in "${saved_backup_names[@]}"
	do
		#If the current backup trying to be deleted is in the list of saved names, don't delete it
		if [[ $name == $backup_name ]]
		then
			able_to_delete=false
		fi
	done

	if [[ $able_to_delete = true ]]
	then
		((amount_of_backups_added++))
		to_delete_backup_paths+=("${all_backup_paths[$index]}")
	fi
done

#Print a list of the protected and to-be-deleted backups and prompt for confirmation
confirmation_message="I have reviewed the deletion list."

echo "These backups are protected. They will not be deleted."
echo "--------------------------------------------------------------------------------"
for name in "${saved_backup_names[@]}"
do
  echo "$name"
done
echo

echo "These backups will be deleted."
echo "--------------------------------------------------------------------------------"
for backup_path in "${to_delete_backup_paths[@]}"
do
	basename "$backup_path"
done
echo

read -p "Enter \"$confirmation_message\" sans quotes to start the deletion.  "
echo

if [[ $REPLY == $confirmation_message ]]
then
	for ((i = 0; i < ${#to_delete_backup_paths[@]}; i++))
	do
		date=$(date)
		echo "[$date]    Starting deletion for ${to_delete_backup_paths[$i]}"

		if [[ $test_run = true ]]
		then
			sudo time /usr/bin/tmutil this_is_a_test_run ${to_delete_backup_paths[$i]}
		else
			sudo time /usr/bin/tmutil delete ${to_delete_backup_paths[$i]}
		fi

		date=$(date)
		echo "[$date]    Finished"
	done
else
	echo "The confirmation message didn't match, so nothing was deleted."
fi
