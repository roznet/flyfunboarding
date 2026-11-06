"""
Settings loading: secrets reach Settings verbatim, and file precedence is as documented.

No database needed: these build Settings() directly against temp env files.
"""
from pathlib import Path

import pytest

from app.config import SERVER_DIR, Settings

# $, ${X}, #, a space and a double quote; written single-quoted in the files
TRICKY = 'p$a${X}#b c"d'
# a literal single quote, written \' inside single quotes
TRICKY_QUOTE = "it's"


@pytest.fixture
def clean_env(monkeypatch: pytest.MonkeyPatch) -> pytest.MonkeyPatch:
    """Drop any real settings from the process env so only the test files count."""
    for name in ("DB_USER", "DB_PASSWORD", "SECRET", "CERTIFICATE_PASSWORD", "X", "a"):
        monkeypatch.delenv(name, raising=False)
    # a value that ${X} would expand to if interpolation were on
    monkeypatch.setenv("X", "EXPANDED")
    return monkeypatch


def write_env_files(tmp_path: Path, env: str, secrets: str) -> tuple[Path, Path]:
    env_file = tmp_path / ".env"
    secrets_file = tmp_path / ".env.secrets"
    env_file.write_text(env)
    secrets_file.write_text(secrets)
    return env_file, secrets_file


def test_secret_from_files_is_literal(tmp_path: Path, clean_env: pytest.MonkeyPatch) -> None:
    files = write_env_files(
        tmp_path,
        "X=FROM_DOTENV\nDB_USER=plain\n",
        f"DB_PASSWORD='{TRICKY}'\nSECRET='it\\'s'\nCERTIFICATE_PASSWORD='{TRICKY}'\n",
    )
    s = Settings(_env_file=files)
    assert s.DB_PASSWORD == TRICKY
    assert s.SECRET == TRICKY_QUOTE
    assert s.CERTIFICATE_PASSWORD == TRICKY
    assert s.DB_USER == "plain"


def test_secret_from_environment_is_literal(tmp_path: Path, clean_env: pytest.MonkeyPatch) -> None:
    clean_env.setenv("DB_PASSWORD", TRICKY)
    clean_env.setenv("SECRET", TRICKY_QUOTE)
    clean_env.setenv("CERTIFICATE_PASSWORD", TRICKY)
    s = Settings(_env_file=None)
    assert s.DB_PASSWORD == TRICKY
    assert s.SECRET == TRICKY_QUOTE
    assert s.CERTIFICATE_PASSWORD == TRICKY


def test_precedence(tmp_path: Path, clean_env: pytest.MonkeyPatch) -> None:
    files = write_env_files(
        tmp_path,
        "DB_USER=from_env\nDB_PASSWORD='from_env'\nSECRET='from_env'\n",
        "DB_PASSWORD='from_secrets'\nSECRET='from_secrets'\n",
    )
    # .env.secrets beats .env
    s = Settings(_env_file=files)
    assert s.DB_USER == "from_env"
    assert s.DB_PASSWORD == "from_secrets"
    assert s.SECRET == "from_secrets"
    # a real environment variable beats both (this is how compose env_file arrives)
    clean_env.setenv("SECRET", "from_process")
    assert Settings(_env_file=files).SECRET == "from_process"


def test_env_files_resolved_from_server_dir() -> None:
    env_files = Settings.model_config["env_file"]
    assert env_files == (SERVER_DIR / ".env", SERVER_DIR / ".env.secrets")
    assert all(Path(p).is_absolute() for p in env_files)
    assert (SERVER_DIR / "app" / "config.py").is_file()


def test_missing_secrets(clean_env: pytest.MonkeyPatch) -> None:
    assert Settings(_env_file=None).missing_secrets() == ["DB_PASSWORD", "SECRET"]
    clean_env.setenv("DB_PASSWORD", "x")
    clean_env.setenv("SECRET", "y")
    assert Settings(_env_file=None).missing_secrets() == []
