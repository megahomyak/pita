from io import BytesIO
from fastapi import APIRouter
from fastapi.responses import HTMLResponse, RedirectResponse, StreamingResponse
import state
from urllib.parse import quote


router = APIRouter()


template = state.TEMPLATE_LOADER.get_template("announcements.html")


@router.get("/announcements")
async def announcements():
    if state.sgo_client is None:
        return RedirectResponse("/")
    announcements = await state.sgo_client.announcements()
    return HTMLResponse(template.render(announcements=announcements))


@router.get("/attachments/{attachment_id}/{filename}")
async def attachment(attachment_id: int, filename: str):
    if state.sgo_client is None:
        return RedirectResponse("/")
    attachment = BytesIO()
    await state.sgo_client.download_attachment(
        attachment_id, attachment
    )
    attachment.seek(0)
    return StreamingResponse(
        attachment,
        headers={
            'Content-Disposition': f'attachment; filename="{quote(filename)}"'
        }
    )


@router.get("/profile_picture/{user_id}")
async def profile_picture(user_id: int):
    if state.sgo_client is None:
        return RedirectResponse("/")
    profile_picture = BytesIO()
    await state.sgo_client.download_profile_picture(user_id, profile_picture)
    profile_picture.seek(0)
    return StreamingResponse(profile_picture)
