#!/bin/sh

poetry run uvicorn --port 8076 pita:app --log-level warning
