#!/bin/bash

dmenu -p "Emoji Menu" < "$(dirname $0)"/emojis.txt | awk '{print $1}' | wl-copy
