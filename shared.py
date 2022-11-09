from typing import Optional
from pydantic import BaseModel
from netschoolapi import NetSchoolAPI
import os

import utils


class Credentials(BaseModel):
    sgo_url: str
    school_name: str
    username: str
    password: str


_CREDENTIALS_DIRECTORY = "data"
_CREDENTIALS_FILE_NAME = "credentials.json"


def save_credentials():
    utils.superwrite(_CREDENTIALS_DIRECTORY, _CREDENTIALS_FILE_NAME, credentials.json())


def load_credentials():
    global credentials
    try:
        credentials = Credentials.parse_file(os.path.join(_CREDENTIALS_DIRECTORY, _CREDENTIALS_FILE_NAME))
    except FileNotFoundError:
        credentials = Credentials(sgo_url="", school_name="", username="", password="")


load_credentials()


sgo_client: Optional[NetSchoolAPI] = None
