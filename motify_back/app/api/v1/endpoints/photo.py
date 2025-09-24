import os
import io
from uuid import uuid4
from fastapi import APIRouter, UploadFile, File, HTTPException
from fastapi.responses import JSONResponse
from PIL import Image, ExifTags


router = APIRouter()

ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png"}
UPLOAD_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../../..", "fotos"))
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/upload/photo")
def upload_photo(file: UploadFile = File(...)):
    ext = file.filename.split(".")[-1].lower()
    if ext not in ALLOWED_EXTENSIONS:
        raise HTTPException(status_code=400, detail="Tipo de archivo no permitido. Solo jpg, jpeg, png.")
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo no es una imagen válida.")
    filename = f"{uuid4()}.{ext}"
    file_path = os.path.join(UPLOAD_DIR, filename)


    image_bytes = file.file.read()
    image = Image.open(io.BytesIO(image_bytes))

    # Corregir orientación usando EXIF (si existe)
    try:
        for orientation in ExifTags.TAGS.keys():
            if ExifTags.TAGS[orientation] == 'Orientation':
                break
        exif = image._getexif()
        if exif is not None:
            orientation_value = exif.get(orientation, None)
            if orientation_value == 3:
                image = image.rotate(180, expand=True)
            elif orientation_value == 6:
                image = image.rotate(270, expand=True)
            elif orientation_value == 8:
                image = image.rotate(90, expand=True)
    except Exception:
        pass 
    max_size = 1080
    if max(image.size) > max_size:
        image.thumbnail((max_size, max_size))
    save_kwargs = {}
    if ext in ["jpg", "jpeg"]:
        save_kwargs = {"quality": 85, "optimize": True}
    elif ext == "png":
        save_kwargs = {"optimize": True}
    image.save(file_path, format=image.format, **save_kwargs)

    url = f"/fotos/{filename}"
    return JSONResponse(content={"url": url, "filename": filename})
