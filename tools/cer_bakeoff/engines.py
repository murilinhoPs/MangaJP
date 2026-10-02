#!/usr/bin/env python3
"""OCR engine adapters for the M0.3 CER bake-off.

Live calls:
  - manga_ocr: kha-white/manga-ocr (Linux OK)
  - cloud_vision: DOCUMENT_TEXT_DETECTION + languageHints=["ja"] (needs GCP)
  - mlkit_ja: not runnable here; pass --predictions mlkit_ja=file.json
"""

from __future__ import annotations

import base64
import json
import os
import subprocess
import urllib.error
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Mapping

ENGINE_IDS = ("mlkit_ja", "cloud_vision", "manga_ocr")

VISION_ENDPOINT = "https://vision.googleapis.com/v1/images:annotate"
VISION_SCOPE = "https://www.googleapis.com/auth/cloud-vision"


class EngineUnavailable(Exception):
    """Engine cannot run in this environment (not a CER number)."""


@dataclass(frozen=True)
class EngineInfo:
    engine_id: str
    status: str  # ready | skipped
    skip_reason: str = ""
    version: str = ""


class OcrEngine:
    engine_id: str

    def info(self) -> EngineInfo:
        raise NotImplementedError

    def prepare(self) -> None:
        """Load heavy weights / clients. No-op if skipped."""

    def recognize(self, image_path: Path) -> str:
        raise NotImplementedError


class SkippedEngine(OcrEngine):
    def __init__(self, engine_id: str, reason: str) -> None:
        self.engine_id = engine_id
        self.reason = reason

    def info(self) -> EngineInfo:
        return EngineInfo(self.engine_id, "skipped", skip_reason=self.reason)

    def recognize(self, image_path: Path) -> str:
        raise EngineUnavailable(self.reason)


class PredictionsFileEngine(OcrEngine):
    """Replay a device/cloud dump: {\"predictions\": {\"crop_id\": \"text\"}}."""

    def __init__(self, engine_id: str, path: Path, version: str = "") -> None:
        self.engine_id = engine_id
        self.path = path
        self._version = version or f"file:{path}"
        self._preds: dict[str, str] | None = None

    def info(self) -> EngineInfo:
        return EngineInfo(self.engine_id, "ready", version=self._version)

    def prepare(self) -> None:
        data = json.loads(self.path.read_text(encoding="utf-8"))
        if isinstance(data, dict) and "predictions" in data:
            raw = data["predictions"]
        elif isinstance(data, dict):
            raw = data
        else:
            raise ValueError(f"{self.path}: expected object map of crop_id → text")
        self._preds = {str(k): "" if v is None else str(v) for k, v in raw.items()}
        file_id = data.get("engine_id") if isinstance(data, dict) else None
        if file_id and file_id != self.engine_id:
            raise ValueError(
                f"{self.path}: engine_id {file_id!r} != requested {self.engine_id!r}"
            )

    def recognize(self, image_path: Path) -> str:
        if self._preds is None:
            self.prepare()
        assert self._preds is not None
        crop_id = image_path.stem
        if crop_id not in self._preds:
            raise KeyError(f"no prediction for {crop_id} in {self.path}")
        return self._preds[crop_id]


class MangaOcrEngine(OcrEngine):
    engine_id = "manga_ocr"

    def __init__(self, model: str = "kha-white/manga-ocr-base") -> None:
        self.model_name = model
        self._mocr = None
        self._version = ""

    def info(self) -> EngineInfo:
        return EngineInfo(self.engine_id, "ready", version=self._version or self.model_name)

    def prepare(self) -> None:
        try:
            from manga_ocr import MangaOcr
        except ImportError as exc:
            raise EngineUnavailable(
                "manga-ocr not installed (pip install -r tools/cer_bakeoff/requirements.txt)"
            ) from exc
        try:
            from importlib.metadata import version

            pkg = version("manga-ocr")
        except Exception:
            pkg = "unknown"
        self._version = f"manga-ocr {pkg}; model={self.model_name}; device=cpu"
        self._mocr = MangaOcr(pretrained_model_name_or_path=self.model_name, force_cpu=True)

    def recognize(self, image_path: Path) -> str:
        if self._mocr is None:
            self.prepare()
        return self._mocr(str(image_path))


class CloudVisionEngine(OcrEngine):
    engine_id = "cloud_vision"

    def __init__(self, api_key: str | None = None, access_token: str | None = None) -> None:
        self.api_key = api_key
        self.access_token = access_token
        self._version = "DOCUMENT_TEXT_DETECTION languageHints=[ja]"

    def info(self) -> EngineInfo:
        return EngineInfo(self.engine_id, "ready", version=self._version)

    def recognize(self, image_path: Path) -> str:
        content = base64.b64encode(image_path.read_bytes()).decode("ascii")
        payload = {
            "requests": [
                {
                    "image": {"content": content},
                    "features": [{"type": "DOCUMENT_TEXT_DETECTION"}],
                    "imageContext": {"languageHints": ["ja"]},
                }
            ]
        }
        url = VISION_ENDPOINT
        headers = {"Content-Type": "application/json; charset=utf-8"}
        if self.api_key:
            url = f"{VISION_ENDPOINT}?key={self.api_key}"
        elif self.access_token:
            headers["Authorization"] = f"Bearer {self.access_token}"
        else:
            raise EngineUnavailable("Cloud Vision: no API key or access token")
        body = json.dumps(payload).encode("utf-8")
        req = urllib.request.Request(url, data=body, headers=headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read().decode("utf-8"))
        except urllib.error.HTTPError as exc:
            detail = exc.read().decode("utf-8", errors="replace")
            raise RuntimeError(f"Cloud Vision HTTP {exc.code}: {detail[:500]}") from exc
        responses = data.get("responses") or [{}]
        first = responses[0]
        if first.get("error"):
            raise RuntimeError(f"Cloud Vision error: {first['error']}")
        annotation = first.get("fullTextAnnotation") or {}
        text = annotation.get("text")
        if text:
            return text
        annotations = first.get("textAnnotations") or []
        if annotations:
            return annotations[0].get("description") or ""
        return ""


def _cloud_vision_api_key() -> str | None:
    for name in ("CLOUD_VISION_API_KEY", "GOOGLE_CLOUD_VISION_API_KEY", "GOOGLE_API_KEY"):
        val = os.environ.get(name, "").strip()
        if val:
            return val
    return None


def _gcloud_access_token() -> str | None:
    try:
        proc = subprocess.run(
            ["gcloud", "auth", "application-default", "print-access-token"],
            check=False,
            capture_output=True,
            text=True,
            timeout=15,
        )
        token = (proc.stdout or "").strip()
        if proc.returncode == 0 and token:
            return token
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return None


def _service_account_token() -> str | None:
    cred_path = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", "").strip()
    if not cred_path or not Path(cred_path).is_file():
        return None
    try:
        from google.oauth2 import service_account
        import google.auth.transport.requests
    except ImportError:
        return None
    creds = service_account.Credentials.from_service_account_file(
        cred_path, scopes=[VISION_SCOPE]
    )
    creds.refresh(google.auth.transport.requests.Request())
    return creds.token


def resolve_cloud_vision(
    api_key: str | None = None,
) -> CloudVisionEngine | SkippedEngine:
    key = (api_key or _cloud_vision_api_key() or "").strip() or None
    if key:
        return CloudVisionEngine(api_key=key)
    token = _service_account_token() or _gcloud_access_token()
    if token:
        return CloudVisionEngine(access_token=token)
    return SkippedEngine(
        "cloud_vision",
        "SKIPPED (no GCP credentials: set CLOUD_VISION_API_KEY or "
        "GOOGLE_APPLICATION_CREDENTIALS, or `gcloud auth application-default login`)",
    )


def resolve_manga_ocr(model: str = "kha-white/manga-ocr-base") -> OcrEngine:
    try:
        import manga_ocr  # noqa: F401
    except ImportError:
        return SkippedEngine(
            "manga_ocr",
            "SKIPPED (manga-ocr not installed; pip install -r tools/cer_bakeoff/requirements.txt)",
        )
    return MangaOcrEngine(model=model)


def resolve_mlkit(predictions_path: Path | None) -> OcrEngine:
    if predictions_path is not None:
        return PredictionsFileEngine("mlkit_ja", predictions_path)
    return SkippedEngine(
        "mlkit_ja",
        "SKIPPED (google_mlkit_text_recognition is Android/iOS-only; this Linux "
        "agent has no emulator. Re-run with --predictions mlkit_ja=dump.json — "
        "see tools/cer_bakeoff/README.md)",
    )


def parse_predictions_args(items: list[str]) -> dict[str, Path]:
    out: dict[str, Path] = {}
    for item in items:
        if "=" not in item:
            raise ValueError(f"--predictions expects engine_id=path, got {item!r}")
        engine_id, path_s = item.split("=", 1)
        engine_id = engine_id.strip()
        if engine_id not in ENGINE_IDS:
            raise ValueError(f"unknown engine {engine_id!r}; choose from {ENGINE_IDS}")
        path = Path(path_s).expanduser()
        if not path.is_file():
            raise FileNotFoundError(f"predictions file not found: {path}")
        out[engine_id] = path
    return out


def build_engines(
    wanted: list[str],
    predictions: Mapping[str, Path],
    *,
    cloud_vision_api_key: str | None = None,
    manga_ocr_model: str = "kha-white/manga-ocr-base",
) -> list[OcrEngine]:
    engines: list[OcrEngine] = []
    for engine_id in wanted:
        if engine_id in predictions:
            engines.append(PredictionsFileEngine(engine_id, predictions[engine_id]))
            continue
        if engine_id == "manga_ocr":
            engines.append(resolve_manga_ocr(manga_ocr_model))
        elif engine_id == "cloud_vision":
            engines.append(resolve_cloud_vision(cloud_vision_api_key))
        elif engine_id == "mlkit_ja":
            engines.append(resolve_mlkit(None))
        else:
            raise ValueError(f"unknown engine {engine_id!r}")
    return engines
