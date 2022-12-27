#!/bin/sh

sleep 2 && xdg-open 127.0.0.1:8076 &
poetry run uvicorn --port 8076 pita:app --log-level warning
