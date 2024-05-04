#!/bin/bash

# Modules path
search_dir=$1
work_dir=$2

# Find files matching timing name pattern (Exclude specific files such as seq_double_table)
# This executes a bash script on the found files, wherein they are only included if the timing test file matches the parent directory name (i.e., module name)
# This includes files like seq.timing.ini but excludes seq_double_table.timing.ini
# This is important to allow for module names to be passed to make hdl_test argument
# When splitting off functionality and documentation timing.ini tests, this needs to be checked again
found_files=$(find "$search_dir" -type f -name "*.timing.ini" -exec bash -c '
    for file; do
        module_name=$(basename "$(dirname "$file")")
        module_timing_name=$(basename "$file")
        if [[ "$module_timing_name" =~ ^"$module_name".timing.ini$ ]]; then
            echo "$file"
        fi
    done
' bash {} +)

# Array of modules and their test count
module_grps=()

# Check if any files were found
if [ -z "$found_files" ]; then
    echo "No timing tests found"
else
    # Loop through each found file
    for file in $found_files; do
        # Count occurrences of [*] in the file
        # Min 5 char to filter descriptions and index
        count=$(grep -o '\[[^][]\{5,\}\]' "$file" | wc -l)
        module_name=$(basename "$file" .timing.ini)
        module_grps+=("$module_name" "$count")
    done
    # Run python script to define job matrix based on found tests
    python3 $work_dir/round_robin.py "${module_grps[@]}"

fi

