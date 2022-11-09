from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

import routes.auth

app = FastAPI()


app.mount("/static", StaticFiles(directory="static"))


app.include_router(routes.auth.router)
