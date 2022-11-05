from fastapi import FastAPI, status
from fastapi.responses import FileResponse, RedirectResponse
from pydantic import BaseModel

import routes.auth

app = FastAPI()


app.include_router(routes.auth.router)
