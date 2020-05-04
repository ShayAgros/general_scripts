#!/bin/bash

# This does the folowing:
# 1) output the content of the file as it is in the latest commit
# 2) changes the name of the driver
# 3) stashes this changed content as an object (git's representation
# of files)
blobid=$(git show HEAD:linux/ena_netdev.h | sed '/#define DRV_MODULE_NAME/s/ena/testing_ena/' | git hash-object -w --stdin)

# This makes the staged verison of the patch to be like the one we
# just modified
git update-index --cacheinfo 100644 "$blobid" linux/ena_netdev.h

# This makes the same change for the "unstaged" version of the file
sed -i '/#define DRV_MODULE_NAME/s/ena/testing_ena/' ena_netdev.h

# commit this change
git commit -m "Changed driver name to testing_ena"
