#!/bin/bash

# Modules path
search_dir=$1
work_dir=$2

# Find files matching timing name pattern
found_files=$(find "$search_dir" -type f -name "*.timing.ini")
echo $found_files
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
        # Duplicate names allowed for multiple test files in same module subdirectory
        module_name=$(basename "$(dirname "$file")")
        module_grps+=("$module_name" "$count")
    done
    # Run python script to define job matrix based on found tests
    python3 $work_dir/Group_Tests.py "${module_grps[@]}"
fi