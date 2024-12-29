#!/bin/bash

# Database query setup
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if username exists in the database
USER_DATA=$($PSQL "SELECT games_played, best_game FROM games WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO games (username, games_played, best_game) VALUES ('$USERNAME', 0, NULL)")
else
  # Returning user
  GAMES_PLAYED=$(echo $USER_DATA | cut -d '|' -f 1)
  BEST_GAME=$(echo $USER_DATA | cut -d '|' -f 2)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0
while true; do
  read GUESS
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  else
    NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
    if [[ $GUESS -lt $SECRET_NUMBER ]]; then
      echo "It's higher than that, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      echo "It's lower than that, guess again:"
    else
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      break
    fi
  fi
done

# Update user stats in the database
if [[ -z $USER_DATA ]]; then
  # First-time user: set games_played to 1 and best_game to the current game
  UPDATE_RESULT=$($PSQL "UPDATE games SET games_played = 1, best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME'")
else
  # Update games_played and best_game if the current game is better
  NEW_GAMES_PLAYED=$((GAMES_PLAYED + 1))
  if [[ $BEST_GAME == "" || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
    UPDATE_RESULT=$($PSQL "UPDATE games SET games_played = $NEW_GAMES_PLAYED, best_game = $NUMBER_OF_GUESSES WHERE username = '$USERNAME'")
  else
    UPDATE_RESULT=$($PSQL "UPDATE games SET games_played = $NEW_GAMES_PLAYED WHERE username = '$USERNAME'")
  fi
fi
