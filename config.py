from pydantic_settings import BaseSettings
import os


class Settings(BaseSettings):
    DATABASE_URL: str = os.getenv(
        "DATABASE_URL",
        "postgresql://slip_user:slip_password@localhost:5432/slip_db"
    )
    PROJECT_NAME: str = "PromptPay Payment System"
    PROJECT_VERSION: str = "1.0.0"
    API_PREFIX: str = "/api"


settings = Settings()
