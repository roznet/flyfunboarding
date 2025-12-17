"""
Configuration management using pydantic-settings.

Loads configuration from environment variables and .env file.
"""
from pathlib import Path
from typing import Optional
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

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

