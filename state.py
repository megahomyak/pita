from typing import Optional
from pydantic import BaseModel
from netschoolapi import NetSchoolAPI
import os
import jinja2
import html

import utils


class Credentials(BaseModel):
    sgo_url: str
    school_name: str
    username: str
    password: str


TEMPLATE_LOADER = jinja2.Environment(loader=jinja2.FileSystemLoader(searchpath="./static/routes/"))
TEMPLATE_LOADER.filters["unescape"] = html.unescape


_CREDENTIALS_DIRECTORY = "data"
_CREDENTIALS_FILE_NAME = "credentials.json"


def save_credentials():
    utils.superwrite(_CREDENTIALS_DIRECTORY, _CREDENTIALS_FILE_NAME, credentials.json(ensure_ascii=False))


def load_credentials():
    global credentials
    try:
        credentials = Credentials.parse_file(os.path.join(_CREDENTIALS_DIRECTORY, _CREDENTIALS_FILE_NAME))
    except FileNotFoundError:
        credentials = Credentials(sgo_url="", school_name="", username="", password="")


load_credentials()


sgo_client: Optional[NetSchoolAPI] = None
