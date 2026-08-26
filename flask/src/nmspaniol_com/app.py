#!/usr/bin/env uv run
import os

from flask import Flask

app = Flask(__name__)

@app.route('/')
def todo():
    return "boa noite"
