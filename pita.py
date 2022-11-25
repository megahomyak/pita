from fastapi import FastAPI
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles

import routes.auth
import routes.announcements

app = FastAPI()


app.mount("/static", StaticFiles(directory="static"))


@app.get("/favicon.ico")
async def favicon():
    return FileResponse("static/images/favicon.ico")


app.include_router(routes.auth.router)
app.include_router(routes.announcements.router)
