# ♟️ Chess Simulator

## 📁 Files Included

- `parse_moves.py` — An helper script for parsing the PGN file's UCI moves into an array.
- `chess_sim.sh` — The script for simulating a single chess game from a PGN file.
- `split_pgn.sh` — The script for splitting a PGN file with multiple games into multiple PGN files.

## ❓ How To Run

### Splitter

Navigate to the folder containing `split_pgn.sh` and run:

```
./split_pgn.sh <source_pgn_file> <destination_directory>
```

**Note:** The destination directory can be missing (and will be created), but the source PGN file must exist.

### Simulator

#### 1. Prepare the Folder

Place both `chess_sim.sh` and `parse_moves.py` in the same folder, and navigate to it.

#### 2. Create a Python Virtual Environment

Recent Python versions enforce *externally managed environments* on most WSL distros, so as not to install packages with pip directly and avoid messing with the OS-managed packages.
Therefore, we will need to create a virtual environment:

```
sudo apt install python3-venv # if not installed yet
python3 -m venv myenv
```

We will then activate it:

```
source myenv/bin/activate
```

#### 3. Install Dependency

Now that we are in a contained environment, we can use pip and install our sole dependency:

```
pip install python-chess
```

#### 4. Run

```
./chess_sim.sh <pgn_file>
```

## 🙃 Enjoy!

Feel free to modify the scripts.
