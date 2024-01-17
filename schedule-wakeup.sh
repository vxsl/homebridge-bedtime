#!/bin/bash

WEBHOOK_PORT="51828"
ACCESSORY_ID="wakeup-webhooks"
BUTTON1_NAME="button1"
BUTTON2_NAME="button2"

doLog() {
    echo $1
    echo $1 >>log
}

# if there aren't exactly three arguments, print usage and exit
if [ "$#" -ne 4 ]; then
    doLog "Sorry, something went wrong. Please try again."
    exit
fi

COFFEE_BUFFER=15

WEBHOOK_BASE="http://localhost:$WEBHOOK_PORT/?accessoryId=$ACCESSORY_ID"
WEBHOOK_BUTTON1_BASE="$WEBHOOK_BASE&buttonName=$BUTTON1_NAME"
WEBHOOK_BUTTON2_BASE="$WEBHOOK_BASE&buttonName=$BUTTON2_NAME"

# thanks ChatGPT
verbal_to_boolean() {
    # Convert input to lower case and strip punctuation
    local input=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]')

    # Array of positive phrases
    local positive=("yes" "yeah" "sure" "ok" "yep" "absolutely" "definitely" "i think so" "of course" "right" "indeed" "certainly" "exactly" "affirmative")

    # Array of negative phrases
    local negative=("no" "nah" "nope" "not at all" "never" "not really" "i don't think so" "negative" "not likely" "unlikely")

    # Check if input is in positive array
    for i in "${positive[@]}"; do
        if [ "$input" == "$i" ]; then
            _verbal_to_boolean_return="true"
            return
        fi
    done

    # Check if input is in negative array
    for i in "${negative[@]}"; do
        if [ "$input" == "$i" ]; then
            _verbal_to_boolean_return="false"
            return
        fi
    done

    # If input is neither positive nor negative, print an error message
    doLog "Sorry, I didn't understand that. Please try again."
    exit
}

validate_time_format() {
    local time_pattern='^([01]?[0-9]|2[0-3]):[0-5][0-9]$'
    if [[ ! $1 =~ $time_pattern ]]; then
        doLog "Sorry, I didn't understand that. Please try again."
        exit
    fi
}

# thanks ChatGPT
adjust_time() {
    # $1 is time string, $2 is minutes to add/subtract
    if [ $2 -lt 0 ]; then
        date -u -d"$1 $(echo $2 | sed 's/-//') minutes ago" "+%H:%M"
    else
        date -u -d"$1 $2 minutes" "+%H:%M"
    fi
}

convert_to_12h() {
    date -d "$1" "+%l:%M %p" | tr -d ' '
}

# thanks ChatGPT
to_boolean() {
    # iOS Shortcuts sends "1" for on and "0" for off, but bash interprets "0" as true and "1" as false. So we need to do manual "casting".
    case "$1" in
    "0") echo "false" ;;
    "1") echo "true" ;;
    *) if [ -z "$1" ]; then
        echo "false"
    else
        echo "true"
    fi ;;
    esac
}

schedule() {
    # $1 is time string, $2 is command
    at $1 <<<"$2"
}

COFFEE_PREPARED=$(to_boolean "$1")
verbal_to_boolean "$2"
SLEEP_IN="$_verbal_to_boolean_return"
validate_time_format "$3"
WAKEUP_TIME="$3"
ONLY_ONE_PERSON="$4"

RESP="OK, I'll wake "
if [ $ONLY_ONE_PERSON == "1" ]; then
    RESP+="you"
elif [ $SLEEP_IN == "true" ]; then
    RESP+="one person"
else
    RESP+="everyone"
fi
RESP+=" up at $(convert_to_12h $WAKEUP_TIME)"

if [ $COFFEE_PREPARED == "true" ]; then
    curl -s "$WEBHOOK_BUTTON2_BASE&event=0" >/dev/null
    COFFEE_TIME=$(adjust_time $WAKEUP_TIME "-$COFFEE_BUFFER")
    schedule $COFFEE_TIME "curl \"$WEBHOOK_BUTTON1_BASE&event=0\""
    RESP+=", and coffee will be ready"
# else
#     RESP+=". Coffee has not been prepared"
fi

if [ $SLEEP_IN == "true" ]; then
    schedule $WAKEUP_TIME "curl \"$WEBHOOK_BUTTON1_BASE&event=1\""
else
    schedule $WAKEUP_TIME "curl \"$WEBHOOK_BUTTON1_BASE&event=2\""
fi

doLog "$RESP. Goodnight."

