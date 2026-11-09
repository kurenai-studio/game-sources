#!/usr/bin/env bash

CLIENTS=${CLIENTS:-1}

love src server &
sleep 1

for ((i=1; i<=CLIENTS; i++)); do
	love src &
done

wait
