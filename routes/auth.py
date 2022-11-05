from fastapi import APIRouter, status
from fastapi.responses import FileResponse, RedirectResponse
from pydantic import BaseModel

router = APIRouter()


@router.get("/")
def authentication():
    return FileResponse("frontend/auth.html")


class Credentials(BaseModel):
    sgo_url: str
    school_name: str
    username: str
    password: str


@router.post("/")
def authenticate(credentials: Credentials):
    return RedirectResponse("/main", status_code=status.HTTP_308_PERMANENT_REDIRECT)
