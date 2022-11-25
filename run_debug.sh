#!/bin/sh

poetry run uvicorn --port 8076 pita:app --reload --reload-include 'static/**' --reload-include 'routes/**'
