from fastapi import APIRouter, status
from fastapi.responses import HTMLResponse
import httpx
from netschoolapi import NetSchoolAPI
from netschoolapi.errors import SchoolNotFoundError, AuthError

import state
from utils import error, ok

router = APIRouter()


auth_template = state.TEMPLATE_LOADER.get_template("auth.html")


@router.get("/")
async def authentication():
    return HTMLResponse(auth_template.render(
        sgo_url=state.credentials.sgo_url,
        school_name=state.credentials.school_name,
        username=state.credentials.username,
        password=state.credentials.password
    ))


@router.post("/")
async def authenticate(credentials: state.Credentials):
    try:
        state.sgo_client = NetSchoolAPI(credentials.sgo_url)
        await state.sgo_client.login(
            user_name=credentials.username,
            password=credentials.password,
            school_name_or_id=credentials.school_name,
        )
        if state.credentials != credentials:
            state.credentials = credentials
            state.save_credentials()
    except (httpx.InvalidURL, httpx.UnsupportedProtocol, httpx.ConnectError):
        return error(status.HTTP_404_NOT_FOUND, "bad_sgo_url")
    except AuthError:
        return error(status.HTTP_401_UNAUTHORIZED, "bad_credentials")
    except SchoolNotFoundError:
        return error(status.HTTP_400_BAD_REQUEST, "school_not_found", {"school_name": credentials.school_name})
    return ok
