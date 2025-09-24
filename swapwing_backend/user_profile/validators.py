"""Validation helpers for profile document uploads."""

from __future__ import annotations

from pathlib import Path
from typing import Iterable

from django.conf import settings
from django.core.exceptions import ValidationError

from PIL import Image, UnidentifiedImageError


DEFAULT_ALLOWED_AVATAR_FORMATS = {"JPEG", "PNG", "WEBP"}
DEFAULT_ALLOWED_ID_IMAGE_FORMATS = {"JPEG", "PNG", "WEBP"}
DEFAULT_ALLOWED_ID_DOCUMENT_EXTENSIONS = {"jpg", "jpeg", "png", "webp", "pdf"}


def _get_setting(name: str, default):
    return getattr(settings, name, default)


def _validate_max_size(file_obj, max_size_mb: float, label: str) -> None:
    size = getattr(file_obj, "size", None)
    if size is None:
        return
    bytes_allowed = int(max_size_mb * 1024 * 1024)
    if size > bytes_allowed:
        raise ValidationError(f"{label} must be smaller than {max_size_mb} MB.")


def _validate_image_content(file_obj, label: str, allowed_formats: Iterable[str]) -> None:
    allowed_formats = {fmt.upper() for fmt in allowed_formats}
    position = None
    if hasattr(file_obj, "tell"):
        try:
            position = file_obj.tell()
        except OSError:
            position = None

    try:
        image = Image.open(file_obj)
        image.verify()
        fmt = (image.format or "").upper()
    except UnidentifiedImageError as exc:
        raise ValidationError(f"{label} must be a valid image file.") from exc
    finally:
        if hasattr(file_obj, "seek") and position is not None:
            file_obj.seek(position)
        elif hasattr(file_obj, "seek"):
            try:
                file_obj.seek(0)
            except OSError:
                pass

    if fmt not in allowed_formats:
        allowed_display = ", ".join(sorted(allowed_formats))
        raise ValidationError(f"{label} must be one of the following formats: {allowed_display}.")


def validate_avatar_file(file_obj) -> None:
    """Validate trader avatar uploads."""

    if not file_obj:
        return

    max_size = float(_get_setting("PROFILE_AVATAR_MAX_SIZE_MB", 5))
    allowed_formats = _get_setting(
        "PROFILE_ALLOWED_AVATAR_FORMATS", DEFAULT_ALLOWED_AVATAR_FORMATS
    )

    _validate_max_size(file_obj, max_size, "Avatar")
    _validate_image_content(file_obj, "Avatar", allowed_formats)


def validate_id_document(file_obj) -> None:
    """Validate uploaded government ID documents."""

    if not file_obj:
        return

    max_size = float(_get_setting("PROFILE_ID_DOCUMENT_MAX_SIZE_MB", 10))
    allowed_image_formats = _get_setting(
        "PROFILE_ALLOWED_ID_IMAGE_FORMATS", DEFAULT_ALLOWED_ID_IMAGE_FORMATS
    )
    allowed_extensions = {
        ext.lower()
        for ext in _get_setting(
            "PROFILE_ALLOWED_ID_DOCUMENT_EXTENSIONS",
            DEFAULT_ALLOWED_ID_DOCUMENT_EXTENSIONS,
        )
    }

    _validate_max_size(file_obj, max_size, "Identification document")

    name = getattr(file_obj, "name", "")
    extension = Path(name).suffix.lower().lstrip(".")

    if extension not in allowed_extensions:
        allowed_display = ", ".join(sorted(allowed_extensions))
        raise ValidationError(
            f"Identification document must have one of the following extensions: {allowed_display}."
        )

    if extension in {"jpg", "jpeg", "png", "webp"}:
        _validate_image_content(file_obj, "Identification document", allowed_image_formats)
