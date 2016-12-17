# Time Machine: Delete unwanted backups
This bash script deletes a certain amount of Time Machine backups that are no longer needed. If there are important backups you never want to delete, add them to the saved_backup_names array in this file.

##Options
* -a (--amount-to-delete) <n>
  + This required option specifies how many backups should be deleted. n should be an integer greater than 0 or "all" to delete all unwanted backups.
* -n (--newest-to-oldest)
  + This optional option changes the delete order from the default of oldest to newest.
* -t (--test-run)
  + This optional option runs the entire script as normal but substitutes the "delete" verb of the deletion command with a fake verb so the deletions do not occur.
  + This is the closest you can get to seeing what will happen without actually performing the deletes.

##Example usage
    sudo bash ./delete_unwanted_backups.sh -a 4 -t
    sudo bash ./delete_unwanted_backups.sh -a all --newest-to-oldest

##Note
After running, you may still see deleted backups in the history timeline while in Time Machine. To fix this, open Time Machine preferences, choose Select Disk, and in the "Available Disks" section update to the disk that matches to your original disk's name but has more free space.
