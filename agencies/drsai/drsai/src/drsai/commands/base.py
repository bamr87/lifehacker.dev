"""Base command class for DrSAI."""

from abc import ABC, abstractmethod
from typing import Optional

from drsai.core.config import Config, get_config
from drsai.models.schemas import GenerationResponse


class BaseCommand(ABC):
    """Abstract base class for commands."""

    def __init__(self, config: Optional[Config] = None):
        self.config = config or get_config()

    @abstractmethod
    def execute(self, **kwargs) -> GenerationResponse:
        """Execute the command and return a response."""
        pass
