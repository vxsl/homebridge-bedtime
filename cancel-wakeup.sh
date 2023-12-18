#!/bin/bash

getJobs() {
    # jobs=$(at -l | awk '{ if ($NF == "'"$(whoami)"'") print $1 }')
    jobs=$(at -l | awk -v user="$(whoami)" '$NF == user {job_id=$1; gsub(/^[[:space:]]+|[[:space:]]+$/, "", job_id); print job_id}')
}

# get the jobs before we cancel them
getJobs

# if there are no jobs, panic
if [ -z "$jobs" ]; then
    echo "Nothing to cancel"
    exit 1
fi

oldJobs=$jobs
echo $jobs

# echo $jobs | xargs -d ' ' -I {} atrm {}
echo $jobs | xargs atrm
# echo $jobs | while read -r job_id; do atrm "$job_id"; done

getJobs

# jobs should be empty now
if [ -n "$jobs" ]; then
    echo "Failed to cancel"
    exit 1
fi

# echo an english sentence describing the alarms that were cancelled, respecting singular/plural
if [ $(echo $oldJobs | wc -w) -eq 1 ]; then
    echo "Cancelled wakeup routine"
else
    echo "Cancelled wakeup routines"
fi
