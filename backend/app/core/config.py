import os
from pathlib import Path
from dotenv import load_dotenv

# Search for .env in current directory or root workspace
env_path = Path(__file__).resolve().parent.parent.parent.parent / ".env"
if env_path.exists():
    load_dotenv(dotenv_path=env_path)
else:
    load_dotenv()

class Settings:
    PROJECT_NAME: str = "PRAMAAN AgTech AI Platform"
    API_V1_STR: str = "/api/v1"
    METEOBLUE_API_KEY: str = os.getenv("METEOBLUE_API_KEY", "")
    CEHUB_API_KEY: str = os.getenv("CEHUB_API_KEY", "")
    GEMINI_API_KEY: str = os.getenv("GEMINI_API_KEY", "")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    DATA_DIR: Path = Path(__file__).resolve().parent.parent / "data"

settings = Settings()
settings.DATA_DIR.mkdir(parents=True, exist_ok=True)
