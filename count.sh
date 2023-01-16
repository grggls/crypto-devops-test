#!/bin/bash
#
# take an interesting string (bitcoin.txt) |
# break it up into unigrams (strings delimited by spaces) 
# and print one unigram per line |
# sort them (alphabetically) |
# count up the occurences of each |
# pretty print this information 
#
cat bitcoin.txt | tr ' ' '\n' | sort | uniq -c | awk '{print "\x27"$2"\x27: "$1}'
