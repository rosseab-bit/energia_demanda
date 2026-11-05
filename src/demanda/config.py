"""Carga de configuración y resolución de rutas."""
from __future__ import annotations

from pathlib import Path

import yaml

PROJECT_ROOT = Path(__file__).resolve().parents[2]
DEFAULT_CONFIG = PROJECT_ROOT / "config" / "config.yaml"


def load_config(path: str | Path | None = None) -> dict:
    """Lee config.yaml y agrega `_root` (carpeta raíz del proyecto) para resolver rutas relativas."""
    cfg_path = Path(path) if path else DEFAULT_CONFIG
    with open(cfg_path, encoding="utf-8") as fh:
        cfg = yaml.safe_load(fh)
    cfg["_root"] = str(cfg_path.resolve().parents[1])
    return cfg


def resolve(cfg: dict, relative: str | Path) -> Path:
    """Convierte una ruta relativa del config en absoluta (respecto a la raíz del proyecto)."""
    p = Path(relative)
    return p if p.is_absolute() else Path(cfg["_root"]) / p
