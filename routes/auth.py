from fastapi import APIRouter, status
from fastapi.responses import HTMLResponse
import httpx
from netschoolapi import NetSchoolAPI
from netschoolapi.errors import SchoolNotFoundError, AuthError
import jinja2

import shared
from utils import error, ok

router = APIRouter()


with open("static/routes/auth.html", encoding="utf-8") as f:
    auth_template = jinja2.Template(f.read())


@router.get("/")
async def authentication():
    return HTMLResponse(auth_template.render(sgo_url=shared.credentials.sgo_url, school_name=shared.credentials.school_name, username=shared.credentials.username, password=shared.credentials.password))


@router.post("/")
async def authenticate(credentials: shared.Credentials):
    try:
        shared.sgo_client = NetSchoolAPI(credentials.sgo_url)
        await shared.sgo_client.login(
            user_name=credentials.username,
            password=credentials.password,
            school=credentials.school_name,
        )
        shared.credentials = credentials
        shared.save_credentials()
    except (httpx.InvalidURL, httpx.UnsupportedProtocol, httpx.ConnectError):
        return error(status.HTTP_404_NOT_FOUND, "bad_sgo_url")
    except AuthError:
        return error(status.HTTP_401_UNAUTHORIZED, "bad_credentials")
    except SchoolNotFoundError:
        return error(status.HTTP_400_BAD_REQUEST, "school_not_found", {"school_name": credentials.school_name})
    shared.credentials.json()
    return ok
