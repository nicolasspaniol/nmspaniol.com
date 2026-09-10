from PIL import Image, ImageOps
from pathlib import Path
from flask import Flask, render_template, request
from flask_caching import Cache
from collections import deque
from dataclasses import dataclass
import json

app = Flask(__name__)
app.config['TEMPLATES_AUTO_RELOAD'] = True
cache = Cache(app, config={
    'CACHE_TYPE': 'NullCache' if app.debug else 'SimpleCache'
})

FOREVER = None
DESIRED_PICTURE_HEIGHT = 70
PICTURE_ROW_WIDTH = 250


@dataclass
class Project:
    title: str
    link: str
    image_link: str
    description: str


@dataclass
class Picture:
    path: str
    thumb: str
    title: str
    width: int
    height: int


# arranges a collection of pictures with different sizes in a grid, preserving
# aspect ratios and ensuring the rows have the same width. inspired by google photos
def arrange_pictures(pictures: list[Picture]):
    remaining_pictures = deque(pictures)

    # list of tuples (height, pictures) 
    layout = []

    while remaining_pictures:
        row = []
        row_width, row_height = 0, DESIRED_PICTURE_HEIGHT

        while remaining_pictures:
            pic = remaining_pictures[0]

            # check wheter it's better to add the picture or to leave it to
            # the next row. this only adds if the row width with the image
            # is closer to the desired width than the width without it
            desired_width = pic.width / pic.height * DESIRED_PICTURE_HEIGHT
            if row_width + desired_width / 2 < PICTURE_ROW_WIDTH:
                row.append(remaining_pictures.popleft())
                row_width += desired_width + 1
            else:
                row_width -= 1 # remove the extra +1 for the last picture
                row_height = 250 / row_width * DESIRED_PICTURE_HEIGHT
                break

        # NOTE: divided by 4 because we use "rem" in the css, and tailwind's "1" equals "0.25rem"
        layout.append((row_height / 4, row))

    return layout


# ROUTES ------------------------------------------------------

@app.get('/pictures')
@cache.cached(timeout=FOREVER)
def page_pictures():
    with open('data/pictures.json') as f:
        pictures = [Picture(**o) for o in json.load(f)]

    return render_template('pictures.html', layout=arrange_pictures(pictures))


@app.get('/')
def page_homepage():
    return render_template('homepage.html')


@app.get('/projects')
@cache.cached(timeout=FOREVER)
def page_projects():
    with open('data/projects.json') as f:
        projects = [Project(**o) for o in json.load(f)]

    return render_template('projects.html', projects=projects)
