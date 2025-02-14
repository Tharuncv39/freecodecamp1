#!/bin/bash

# Determine which database to connect to
if [[ $1 == "test" ]]
then
  PSQL="psql --username=postgres --dbname=worldcuptest -t --no-align -c"
else
  PSQL="psql --username=freecodecamp --dbname=worldcup -t --no-align -c"
fi

# Create tables if they don't exist
$PSQL "
CREATE TABLE IF NOT EXISTS teams (
    team_id SERIAL PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS games (
    game_id SERIAL PRIMARY KEY,
    year INT NOT NULL,
    round VARCHAR(50) NOT NULL,
    winner_id INT REFERENCES teams(team_id),
    opponent_id INT REFERENCES teams(team_id),
    winner_goals INT NOT NULL,
    opponent_goals INT NOT NULL
);
"

# Read CSV file and insert data into tables
while IFS=, read -r year round winner opponent winner_goals opponent_goals
do
    # Skip header line
    if [[ $year != "year" ]]; then
        # Insert winner and opponent teams if they don't already exist
        $PSQL "
        INSERT INTO teams (name) VALUES ('$winner')
        ON CONFLICT (name) DO NOTHING;

        INSERT INTO teams (name) VALUES ('$opponent')
        ON CONFLICT (name) DO NOTHING;
        "

        # Get the team IDs for the winner and opponent
        winner_id=$($PSQL "SELECT team_id FROM teams WHERE name = '$winner';")
        opponent_id=$($PSQL "SELECT team_id FROM teams WHERE name = '$opponent';")

        # Insert game data into games table
        $PSQL "
        INSERT INTO games (year, round, winner_id, opponent_id, winner_goals, opponent_goals)
        VALUES ($year, '$round', $winner_id, $opponent_id, $winner_goals, $opponent_goals);
        "
    fi
done < games.csv

echo "Data has been inserted into the teams and games tables."
