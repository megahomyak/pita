from fastapi import Response, status
from fastapi.responses import JSONResponse
import os


def error(status_code, type_=None, data=None):
    if not type_:
        return Response(status_code=status_code)
    else:
        if not data:
            data = {}
        return JSONResponse({"error_type": type_, **data}, status_code=status_code)


ok = Response(status_code=status.HTTP_200_OK)


def superwrite(directory, name, contents):
    """
    Write text to file and create all the subdirectories if necessary
    """
    os.makedirs(directory, exist_ok=True)
    with open(os.path.join(directory, name), "w", encoding="utf-8") as f:
        f.write(contents)
