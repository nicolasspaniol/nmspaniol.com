#!/usr/bin/env uv run
import os

from flask import Flask, render_template

app = Flask(__name__)

@app.get('/')
def todo():
    return render_template('base.html')
