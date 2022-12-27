import datetime
from fastapi import APIRouter
from fastapi.responses import HTMLResponse, RedirectResponse
import state

template = state.TEMPLATE_LOADER.get_template("diary.html")


router = APIRouter()


@router.get("/diary")
async def diary(week_bias: int = 0):
    if state.sgo_client is None:
        return RedirectResponse("/")
    today = datetime.date.today() + datetime.timedelta(weeks=week_bias)
    week_start = today - datetime.timedelta(days=today.weekday())
    week_end = week_start + datetime.timedelta(days=6)
    diary = await state.sgo_client.diary(start=week_start, end=week_end)
    return HTMLResponse(template.render(diary=diary))
