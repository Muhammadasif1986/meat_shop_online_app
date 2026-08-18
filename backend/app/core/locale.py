from fastapi import Request


SUPPORTED_LOCALES = ("en", "ur")
DEFAULT_LOCALE = "en"


def get_locale(request: Request) -> str:
    lang = request.headers.get("Accept-Language", "")
    accept = request.headers.get("X-Locale", "")
    if accept in SUPPORTED_LOCALES:
        return accept
    for locale in SUPPORTED_LOCALES:
        if lang.startswith(locale) or lang.startswith(locale.replace("_", "-")):
            return locale
    return DEFAULT_LOCALE


def localized_field(obj, field_en: str, field_ur: str, locale: str) -> str:
    if locale == "ur":
        return getattr(obj, field_ur, None) or getattr(obj, field_en, "")
    return getattr(obj, field_en, "")


def localized_dict(fields: dict, locale: str) -> dict:
    result = {}
    for key, (val_en, val_ur) in fields.items():
        result[key] = val_ur if locale == "ur" and val_ur else val_en
    return result
