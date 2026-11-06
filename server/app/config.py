"""
Configuration management using pydantic-settings.

Sources, highest priority first:
  1. process environment variables (in Docker: compose `environment:` and `env_file: .env.secrets`)
  2. server/.env.secrets  (sops-managed secrets: DB_PASSWORD, SECRET, CERTIFICATE_PASSWORD)
  3. server/.env          (plain configuration)
  4. field defaults below

Both files are resolved relative to server/, not the current directory, so scripts and
tests can run from anywhere. Values in them are taken literally: `${VAR}` is NOT expanded
(python-dotenv would expand it by default, even inside single quotes).
"""
from collections.abc import Mapping
from pathlib import Path
from typing import Optional

from pydantic_settings import (
    BaseSettings,
    DotEnvSettingsSource,
    PydanticBaseSettingsSource,
    SettingsConfigDict,
)
from pydantic_settings.sources.utils import parse_env_vars
from dotenv import dotenv_values

SERVER_DIR = Path(__file__).resolve().parent.parent  # server/app -> server

# Keys that must come from .env.secrets (or the environment) - see Settings.missing_secrets()
REQUIRED_SECRETS = ("DB_PASSWORD", "SECRET")


class LiteralDotEnvSettingsSource(DotEnvSettingsSource):
    """Dotenv source that never interpolates ${VAR}: secrets can contain `$` safely."""

    def _read_env_file(self, file_path: Path) -> Mapping[str, str | None]:
        file_vars = dotenv_values(
            file_path, encoding=self.env_file_encoding or "utf8", interpolate=False
        )
        return parse_env_vars(
            file_vars, self.case_sensitive, self.env_ignore_empty, self.env_parse_none_str
        )


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        # plain config, then the sops-managed secrets file; later files win on duplicates
        env_file=(SERVER_DIR / ".env", SERVER_DIR / ".env.secrets"),
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    @classmethod
    def settings_customise_sources(
        cls,
        settings_cls: type[BaseSettings],
        init_settings: PydanticBaseSettingsSource,
        env_settings: PydanticBaseSettingsSource,
        dotenv_settings: PydanticBaseSettingsSource,
        file_secret_settings: PydanticBaseSettingsSource,
    ) -> tuple[PydanticBaseSettingsSource, ...]:
        # Same order as the default, with the dotenv source swapped for a non-interpolating
        # one (keeps any _env_file override passed to Settings()).
        assert isinstance(dotenv_settings, DotEnvSettingsSource)
        literal_dotenv = LiteralDotEnvSettingsSource(
            settings_cls,
            env_file=dotenv_settings.env_file,
            env_file_encoding=dotenv_settings.env_file_encoding,
        )
        return init_settings, env_settings, literal_dotenv, file_secret_settings

    def missing_secrets(self) -> list[str]:
        """Names of REQUIRED_SECRETS that are empty (e.g. .env.secrets missing)."""
        return [name for name in REQUIRED_SECRETS if not getattr(self, name)]

    # Base directory (for relative paths)
    BASE_DIR: Path = Path(__file__).parent.parent

    # Database Configuration
    DB_HOST: str = "localhost"
    DB_PORT: int = 3306
    DB_USER: str = ""
    DB_PASSWORD: str = ""
    DB_NAME: str = "flyfunboarding"

    # Apple Wallet PKPass Configuration
    CERTIFICATE_PATH: Path = BASE_DIR / "certs" / "certificate.pem"
    CERTIFICATE_PASSWORD: str = ""
    WWDR_PATH: Path = BASE_DIR / "certs" / "AppleWWDRCA.pem"

    # File Paths
    KEYS_PATH: Path = BASE_DIR / "keys"
    IMAGES_PATH: Path = BASE_DIR / "images"
    AIRPORT_DB_PATH: Path = BASE_DIR / "data" / "airports.db"  # Used by euro_aip library (DO NOT read directly)

    # Security
    SECRET: str = ""
    USE_PUBLIC_KEY_SIGNATURE: bool = True

    # API Configuration
    API_VERSION: str = "v1"
    DEBUG: bool = False

    @property
    def api_prefix(self) -> str:
        """API route prefix: /api/v1, /api/v2, etc."""
        return f"/api/{self.API_VERSION}"

    # CORS Configuration
    CORS_ORIGINS: str = "*"  # Comma-separated list, or "*" for all

    # Logging Configuration
    LOG_LEVEL: str = "INFO"
    LOG_FILE: Optional[Path] = None  # None = stdout, or specify file path

    @property
    def cors_origins_list(self) -> list[str]:
        """Parse CORS_ORIGINS into a list."""
        if self.CORS_ORIGINS == "*":
            return ["*"]
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    def get_database_url(self) -> str:
        """Get the database connection URL."""
        return (
            f"mysql+aiomysql://{self.DB_USER}:{self.DB_PASSWORD}"
            f"@{self.DB_HOST}:{self.DB_PORT}/{self.DB_NAME}"
        )


# Global settings instance
settings = Settings()

