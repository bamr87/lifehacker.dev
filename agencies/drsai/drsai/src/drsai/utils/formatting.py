"""Output formatting utilities for DrSAI."""

from typing import Optional

from rich.console import Console
from rich.panel import Panel
from rich.text import Text

from drsai.models.schemas import GenerationResponse

console = Console()


def format_poem(content: str, title: Optional[str] = None) -> str:
    """Format a poem for terminal display."""
    lines = content.strip().split("\n")
    formatted_lines = []

    for line in lines:
        line = line.strip()
        if line:
            formatted_lines.append(f"  {line}")

    formatted_content = "\n".join(formatted_lines)

    if title:
        return f"\n✨ {title} ✨\n\n{formatted_content}\n"
    return f"\n{formatted_content}\n"


def format_story(content: str, title: Optional[str] = None) -> str:
    """Format a story for terminal display."""
    paragraphs = content.strip().split("\n\n")
    formatted_paragraphs = []

    for para in paragraphs:
        # Wrap paragraphs nicely
        lines = para.strip().split("\n")
        formatted_lines = [f"  {line.strip()}" for line in lines if line.strip()]
        formatted_paragraphs.append("\n".join(formatted_lines))

    formatted_content = "\n\n".join(formatted_paragraphs)

    if title:
        return f"\n📖 {title} 📖\n\n{formatted_content}\n"
    return f"\n{formatted_content}\n"


def format_output(
    response: GenerationResponse,
    show_metrics: bool = False,
    show_prompts: bool = False,
) -> str:
    """Format a generation response for terminal display."""
    output_parts = []

    # Format content based on mode
    if response.mode.value == "poem":
        output_parts.append(format_poem(response.content))
    elif response.mode.value == "story":
        output_parts.append(format_story(response.content))
    else:
        output_parts.append(f"\n{response.content}\n")

    # Add moral if present
    if response.moral:
        output_parts.append(f"\n💡 Moral: {response.moral}\n")

    # Add warning if present
    if response.warning:
        output_parts.append(f"\n⚠️  {response.warning}\n")

    # Add metrics if requested
    if show_metrics:
        output_parts.append(f"\n📊 Meter Score: {response.meter_score:.1%}")
        output_parts.append(f"   Generation Attempts: {response.generation_attempts}")

    # Add illustration prompts if requested and present
    if show_prompts and response.illustration_prompts:
        output_parts.append("\n\n🎨 Illustration Prompts:")
        for i, prompt in enumerate(response.illustration_prompts, 1):
            output_parts.append(f"\n  {i}. {prompt}")

    return "".join(output_parts)


def print_response(
    response: GenerationResponse,
    show_metrics: bool = False,
    show_prompts: bool = False,
) -> None:
    """Print a formatted generation response to the console."""
    formatted = format_output(response, show_metrics, show_prompts)

    # Determine panel style based on warnings
    if response.warning:
        style = "yellow"
        title = "🎩 DrSAI (with warnings)"
    else:
        style = "green"
        title = "🎩 DrSAI"

    panel = Panel(
        Text(formatted),
        title=title,
        border_style=style,
        padding=(1, 2),
    )
    console.print(panel)


def print_error(message: str, code: Optional[str] = None) -> None:
    """Print a formatted error message to the console."""
    error_text = f"❌ Error: {message}"
    if code:
        error_text += f" [{code}]"

    panel = Panel(
        Text(error_text, style="bold red"),
        title="DrSAI Error",
        border_style="red",
        padding=(0, 2),
    )
    console.print(panel)


def print_generating() -> None:
    """Print a generating message."""
    console.print("🎩 [bold cyan]Generating whimsical Seuss magic...[/bold cyan]")


def print_validating() -> None:
    """Print a validating message."""
    console.print("📏 [dim]Validating meter and rhyme...[/dim]")


def print_success(message: str) -> None:
    """Print a success message."""
    console.print(f"✅ [green]{message}[/green]")
