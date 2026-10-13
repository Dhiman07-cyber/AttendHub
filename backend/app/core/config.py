from typing import List, Union
from pydantic import AnyHttpUrl, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
import json
import os

class Settings(BaseSettings):
    PROJECT_NAME: str = "AttendHub API"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api/v1"
    
    # Database (Supabase PostgreSQL via .env / Render env vars)
    DATABASE_URL: str = ""

    @field_validator("DATABASE_URL", mode="before")
    def normalize_database_url(cls, v: str) -> str:
        if not isinstance(v, str):
            return ""
        v = v.strip()
        if v.startswith("postgres://"):
            return "postgresql+asyncpg://" + v[len("postgres://"):]
        if v.startswith("postgresql://"):
            return "postgresql+asyncpg://" + v[len("postgresql://"):]
        return v
    
    # Security (Strictly loaded from .env; never hardcoded in source)
    JWT_SECRET: str = ""
    REFRESH_TOKEN_SECRET: str = ""
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7  # 7 days for seamless student mobile/web experience
    REFRESH_TOKEN_EXPIRE_DAYS: int = 60  # 60 days
    GOOGLE_CLIENT_ID: str = ""
    
    # CORS
    CORS_ORIGINS: List[str] = ["*"]

    @field_validator("CORS_ORIGINS", mode="before")
    def assemble_cors_origins(cls, v: Union[str, List[str]]) -> List[str]:
        if isinstance(v, str) and not v.startswith("["):
            return [i.strip() for i in v.split(",")]
        elif isinstance(v, str) and v.startswith("["):
            try:
                return json.loads(v)
            except Exception:
                return ["*"]
        return v or ["*"]

    @field_validator("JWT_SECRET", "REFRESH_TOKEN_SECRET", mode="before")
    def validate_jwt_secrets(cls, v: str) -> str:
        if not v or not v.strip():
            import secrets
            return secrets.token_urlsafe(64)
        return v.strip()
    
    # Supabase Configuration
    SUPABASE_URL: str = ""
    SUPABASE_PUBLISHABLE_KEY: str = ""
    
    model_config = SettingsConfigDict(
        env_file=(".env", "../.env"),
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()
