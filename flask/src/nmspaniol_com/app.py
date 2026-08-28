from PIL import Image
from pathlib import Path
from flask import Flask, render_template, request
from flask_caching import Cache
from collections import deque
import json

app = Flask(__name__)
cache = Cache(app, config={'CACHE_TYPE': 'SimpleCache'})

STATIC_DIR_PATH = Path('./src/nmspaniol_com/static/')
TEN_MINUTES = 600
PICTURES_JSON = 'data/pictures.json'
DESIRED_PICTURE_HEIGHT = 70
PICTURE_ROW_WIDTH = 250


def arrange_pictures(pictures: list[Path]):
    remaining_pictures = deque(pictures)

    # list of tuples (height, pictures) 
    layout = []

    while remaining_pictures:
        row = []
        row_width, row_height = 0, DESIRED_PICTURE_HEIGHT

        while remaining_pictures:
            pic = remaining_pictures[0]
            path = STATIC_DIR_PATH / pic['path']
            w, h = Image.open(path).size
            desired_width = w / h * DESIRED_PICTURE_HEIGHT

            if row_width + desired_width / 2 < PICTURE_ROW_WIDTH:
                row.append(remaining_pictures.popleft())
                row_width += desired_width + 1
            else:
                row_width -= 1 # remove the extra +1 for the last picture
                row_height = 250 / row_width * DESIRED_PICTURE_HEIGHT
                break

        layout.append((row_height / 4, row))

    return layout


@app.get('/pictures')
@cache.cached(timeout=TEN_MINUTES)
def pictures():
    with open(PICTURES_JSON) as f:
        pictures = json.load(f)

    pictures_layout = arrange_pictures(pictures)
    return render_template('pictures.html', pictures_layout=pictures_layout)
