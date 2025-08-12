#!/bin/bash

board=(
    r n b q k b n r
    p p p p p p p p
    . . . . . . . .
    . . . . . . . .
    . . . . . . . .
    . . . . . . . .
    P P P P P P P P
    R N B Q K B N R
)
starting_board=("${board[@]}")                  # Save initial board state

# Print Metadata from PGN file, return its length (in lines)
print_metadata() {
    cd $1                                       # Change to PGN directory
    i=0                                         # Init. line counter
    echo "Metadata from PGN file:" >&2          # Print to stderr
    while read -r line
    do
        first_char=${line:0:1}                  # Extract first character in line
        if test "$first_char" != ""             # If first character is not empty
        then
            echo $line >&2                      # Print to stderr
        else
            break                               # Break while loop when reached delimiter
        fi
        i=$[$i + 1]                             # Inc. line counter
    done < "$2"                                 # Read from PGN file
    cd ..                                       # Change to parent directory
    echo $i                                     # Return Metadata length
}

# Append all moves from PGN file to moves string, return string
get_moves() {
    cd $1                                       # Change to PGN directory
    j=0                                         # Init. line counter
    while read -r line
    do
        j=$[$j + 1]                             # Inc. line counter
        if test $j -gt $3                       # (Skipping the Metadata)
        then
            for word in "0-1" "1-0" "1/2-1/2"   # For each possible result
            do
                line=${line//$word}             # Remove result from line
            done
            moves+="$line "                     # Append line to moves string
        fi
    done < "$2"                                 # Read from PGN file
    cd ..                                       # Change to parent directory
    echo $moves                                 # Return moves string
}

# Print move status + board
print_board() {
    echo "Move $1/$2"                   
    echo "  a b c d e f g h"
    for row in {0..7}                           # For each row
    do
        echo -n "$[8 - $row] "                  # Print rev. row number at start of line
        for col in {0..7}                       # For each column
        do
            index=$[$row * 8 + $col]            # Calc. index in board array
            echo -n "${board[$index]} "         # Print piece at index
        done
        echo "$[8 - $row]"                      # Print rev. row number at end of line
    done
    echo "  a b c d e f g h"
}

# Convert square in chess board to index in board array, return index
sqaure_to_index() {
    col=${1:0:1}                                # Extract column in letter form
    col=$(echo $col | tr 'a-h' '0-7')           # Translate {a..h} to {0..7}
    row=$[8 - ${1:1:1}]                         # Extract row in rev. form
    index=$[$row * 8 + $col]                    # Calc. index in board array
    echo $index                                 # Return index
}

# Check if <from> and <to> squares are diagonal
diag_move() {
    test $1 -eq $[$2 + 7] \
         -o $1 -eq $[$2 - 7] \
         -o $1 -eq $[$2 + 9] \
         -o $1 -eq $[$2 - 9]
    echo $?                                     # Return 0 if diagonal, 1 if not
}

# Update board based on a given move
update_board() {
    moves_arr=($1)                              # Convert string to array
    move=${moves_arr[$2]}                       # Extract move from array
    from=${move:0:2}                            # Extract <from> square
    from_idx=$(sqaure_to_index $from)           # Convert <from> square to index in board array
    to=${move:2:2}                              # Extract <to> square
    to_idx=$(sqaure_to_index $to)               # Convert <to> square to index in board array
    promo=${move:4:1}                           # Extract <promotion> piece (can be empty)
    if test "$promo" = ""                       # If no promotion (i.e. regular / castle / en passant)
    then
        # [White Kingside Castle] <-> king moves from e1 to g1
        if test "${board[$from_idx]}" = "K" -a "$from" = "e1" -a "$to" = "g1"
        then
            board[$from_idx]="."                # Set <from> square to empty
            board[$to_idx]="K"                  # Set <to> square to king
            board[$[$to_idx+1]]="."             # Set rightward square to <to> to empty
            board[$[$to_idx-1]]="R"             # Set leftward square to <to> to rook
        # [Black Kingside Castle] <-> king moves from e8 to g8
        elif test "${board[$from_idx]}" = "k" -a "$from" = "e8" -a "$to" = "g8"
        then
            board[$from_idx]="."                # Set <from> square to empty
            board[$to_idx]="k"                  # Set <to> square to king
            board[$[$to_idx+1]]="."             # Set rightward square to <to> to empty
            board[$[$to_idx-1]]="r"             # Set leftward square to <to> to rook
        # [White Queenside Castle] <-> king moves from e1 to c1
        elif test "${board[$from_idx]}" = "K" -a "$from" = "e1" -a "$to" = "c1"
        then
            board[$from_idx]="."                # Set <from> square to empty
            board[$to_idx]="K"                  # Set <to> square to king
            board[$[$to_idx-2]]="."             # Set square 2-times-to-the-left of <to> to empty
            board[$[$to_idx+1]]="R"             # Set rightward square to <to> to rook
        # [Black Queenside Castle] <-> king moves from e8 to c8
        elif test "${board[$from_idx]}" = "k" -a "$from" = "e8" -a "$to" = "c8"
        then
            board[$from_idx]="."                # Set <from> square to empty
            board[$to_idx]="k"                  # Set <to> square to king
            board[$[$to_idx-2]]="."             # Set square 2-times-to-the-left of <to> to empty
            board[$[$to_idx+1]]="r"             # Set rightward square to <to> to rook
        else
            # [En-Passant] <-> pawn + diagonal move (= capture) + <to> square is empty
            if test "${board[$from_idx]^^}" = "P" \
               -a "$(diag_move $from_idx $to_idx)" = "0" \
               -a "${board[$to_idx]}" = "."
            then
                if test $from_idx -gt $to_idx   # If white's move
                then
                    board[$[$to_idx+8]]="."     # Set square below <to> to empty
                else
                    board[$[$to_idx-8]]="."     # Set square above <to> to empty
                fi
            fi
            # [Regular]
            board[$to_idx]=${board[$from_idx]}  # Set <to> square to <from> piece
            board[$from_idx]="."                # Set <from> square to empty
        fi
    # [Promotion] <-> promo = q/r/b/n
    else
        if test "${to:1:1}" = "8"               # If white's move
        then
            promo="${promo^^}"                  # Set promotion to uppercase
        fi
        board[$from_idx]="."                    # Set <from> square to empty 
        board[$to_idx]="$promo"                 # Set <to> square to promotion piece
    fi
}

# Main
if test $# -ne 1                                # If num. of arguments is not 1
then
    echo "Usage: $0 <PGN_file>"
    exit 1
elif test ! -e $1                               # Else if file in arg. $1 does not exist
then
    echo "File does not exist: $1"
    exit 1
fi
directory=${1%/*}                               # Extract directory from given path
file_name=$(basename "$1")                      # Extract file name from given path
metadata_len=$(print_metadata $directory $file_name) # Print + get Metadata length (in lines)
moves=$(get_moves $directory $file_name $metadata_len) # Get moves in PGN form
moves=$(python3 parse_moves.py "$moves")        # Parse moves
moves_len=$(echo $moves | wc -w)                # Get number of moves
i=0                                             # Init. current move
print_board $i $moves_len                       # Print initial board
while true
do
    echo -n "Press 'd' to move forward, 'a' to move back, 'w' to go to the start, 's' to go to the end, 'q' to quit: "
    read key                                    # Read user input
    case $key in
        "d")
            if test $i -lt $moves_len           # If there are moves available
            then
                update_board "$moves" $i        # Update board to next move
                i=$[$i + 1]                     # Inc. current move
                print_board $i $moves_len       # Print updated board
            else
                echo "No more moves available."
            fi ;;
        "a")
            if test $i -gt 0                    # If a move back is available 
            then
                board=("${starting_board[@]}")  # Go to the start
                j=0                             # Init. temp. current move
                i=$[$i - 1]                     # Dec. actual current move
                while test $j -lt $i            # While hasn't reached current move
                do
                    update_board "$moves" $j    # Update board to next move
                    j=$[$j + 1]                 # Inc. temp. current move
                done
            fi
            print_board $i $moves_len ;;        # Print updated board
        "w")
            board=("${starting_board[@]}")      # Go to the start
            i=0                                 # Reset current move
            print_board $i $moves_len ;;        # Print starting board
        "s")
            while test $i -lt $moves_len        # While there are moves available
            do
                update_board "$moves" $i        # Update board to next move
                i=$[$i + 1]                     # Inc. current move
            done
            print_board $i $moves_len ;;        # Print final board
        "q")
            echo -e "Exiting.\nEnd of game."
            break ;;                            # Exit loop
        *)
            echo "Invalid key pressed: $key" ;;
    esac
done
exit 0