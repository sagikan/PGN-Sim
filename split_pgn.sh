#!/bin/bash

# Split PGN file into multiple PGN files
split() {
    cd $2                               # Change to dest. directory
    i=0                                 # Init. split file counter
    delim="\[Event "                    # Delimeter
    while read -r line
    do
        if [[ "$line" == $delim* ]]     # If line starts with delimeter
        then
            i=$[$i + 1]                 # Inc. split file counter
            echo "Saved game to $2/$1_$i.pgn"
        fi
        echo "$line" >> "$1_$i.pgn"     # Append line to current split file
    done < "../pgns/$1.pgn"             # Read from source file
    cd ..                               # Change to parent directory
}

# Main
if test $# -ne 2                        # If num. of arguments is not 2
then
    echo "Usage: $0 <source_pgn_file> <destination_directory>"
    exit 1
elif test ! -e $1                       # Else if file in arg. $1 does not exist
then
    echo "Error: File '$1' does not exist."
    exit 1
elif test ! -d $2                       # Else if directory in arg. $2 does not exist
then
    mkdir $2                            # Create directory
    echo "Created directory '$2'."
fi
file_name=$(basename "$1")              # Extract file name from given path
split ${file_name%.*} $2                # (Arg. 1: file name w/o extension)
echo "All games have been split and saved to '$2'."
exit 0