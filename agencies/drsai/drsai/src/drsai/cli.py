"""DrSAI CLI - Generate Dr. Seuss-style content from the command line."""

from typing import Optional

import typer
from rich.console import Console

from drsai import __version__
from drsai.commands.generate import GenerateCommand
from drsai.core.config import Config, LLMProvider
from drsai.models.schemas import GenerationMode
from drsai.utils.errors import ConfigurationError, DrSAIError
from drsai.utils.formatting import print_error, print_generating, print_response

console = Console()

# Main CLI app for generation - single command app
app = typer.Typer(
    name="drsai",
    help=(
        "🎩 DrSAI – Doctor Seuss Artificial Intelligence\n\n"
        "Generate whimsical, rhyming content in the style of Dr. Seuss."
    ),
    add_completion=False,
    no_args_is_help=True,
)


def version_callback(value: bool) -> None:
    """Show version and exit."""
    if value:
        console.print(f"🎩 DrSAI version {__version__}")
        raise typer.Exit()


@app.command()
def generate(
    topic: Optional[str] = typer.Argument(
        None,
        help="The topic to generate Seuss-style content about (or use --file)",
    ),
    file: Optional[str] = typer.Option(
        None,
        "--file",
        "-f",
        help="Read content from a markdown file as context/input",
    ),
    mode: str = typer.Option(
        "poem",
        "--mode",
        "-m",
        help="Generation mode: poem, explain, or story",
    ),
    lines: int = typer.Option(
        32,
        "--lines",
        "-l",
        min=16,
        max=48,
        help="Number of lines for poem mode (16-48)",
    ),
    age: Optional[int] = typer.Option(
        None,
        "--age",
        "-a",
        min=5,
        max=95,
        help="Target age for explanation mode (5-95)",
    ),
    length: str = typer.Option(
        "short",
        "--length",
        help="Story length: short (500 words) or long (800 words)",
    ),
    provider: Optional[str] = typer.Option(
        None,
        "--provider",
        "-p",
        help="LLM provider: openai, anthropic, xai, or mock",
    ),
    verbose: bool = typer.Option(
        False,
        "--verbose",
        "-v",
        help="Show detailed output including metrics",
    ),
    show_prompts: bool = typer.Option(
        False,
        "--prompts",
        help="Show illustration prompts in output",
    ),
    output: Optional[str] = typer.Option(
        None,
        "--output",
        "-o",
        help="Save output to file (e.g., poem.txt or poem.md)",
    ),
    version: Optional[bool] = typer.Option(
        None,
        "--version",
        "-V",
        callback=version_callback,
        is_eager=True,
        help="Show version and exit",
    ),
) -> None:
    """Generate Dr. Seuss-style content about any topic.

    Examples:

        drsai generate "explain recursion"

        drsai generate "photosynthesis" --mode explain --age 8

        drsai generate --file newsletter.md --mode poem

        drsai generate "quantum computing" --mode poem --lines 24

        drsai generate --file story.md "make it about friendship" --mode story
    """
    try:
        # Handle file input
        if file:
            from pathlib import Path

            file_path = Path(file)
            if not file_path.exists():
                print_error(f"File not found: {file}", code="FILE_NOT_FOUND")
                raise typer.Exit(1)

            file_content = file_path.read_text(encoding="utf-8")

            # If topic is also provided, use it as additional instructions
            if topic:
                topic = f"Based on this content:\n\n{file_content}\n\nInstructions: {topic}"
            else:
                topic = f"Transform this content into Dr. Seuss style:\n\n{file_content}"

            console.print(f"📄 [dim]Reading from: {file_path}[/dim]")

        # Require either topic or file
        if not topic:
            print_error(
                "Please provide a topic or use --file to read from a file",
                code="MISSING_INPUT",
            )
            raise typer.Exit(1)
        # Validate mode
        try:
            gen_mode = GenerationMode(mode.lower())
        except ValueError:
            print_error(
                f"Invalid mode '{mode}'. Valid modes: poem, explain, story",
                code="INVALID_MODE",
            )
            raise typer.Exit(1)

        # Validate length
        if length not in ("short", "long"):
            print_error(
                f"Invalid length '{length}'. Valid lengths: short, long",
                code="INVALID_LENGTH",
            )
            raise typer.Exit(1)

        # Build config with optional provider override
        config_kwargs: dict = {"verbose": verbose}
        if provider:
            try:
                config_kwargs["llm_provider"] = LLMProvider(provider.lower())
            except ValueError:
                print_error(
                    f"Invalid provider '{provider}'. Valid providers: openai, anthropic, xai, mock",
                    code="INVALID_PROVIDER",
                )
                raise typer.Exit(1)

        # Load config from environment and apply overrides
        config = Config.from_env()
        for key, value in config_kwargs.items():
            setattr(config, key, value)

        # Show generating message
        print_generating()

        # Execute generation
        command = GenerateCommand(config)
        response = command.execute(
            topic=topic,
            mode=gen_mode,
            lines=lines,
            age=age,
            length=length,
        )

        # Print formatted response
        print_response(
            response,
            show_metrics=verbose,
            show_prompts=show_prompts,
        )

        # Save to file if requested
        if output:
            from pathlib import Path

            output_path = Path(output)

            # Build file content
            file_content = response.content
            if response.moral:
                file_content += f"\n\n---\nMoral: {response.moral}"
            if show_prompts and response.illustration_prompts:
                file_content += "\n\n---\nIllustration Prompts:\n"
                for i, prompt in enumerate(response.illustration_prompts, 1):
                    file_content += f"{i}. {prompt}\n"

            output_path.write_text(file_content)
            console.print(f"\n💾 [green]Saved to: {output_path}[/green]")

    except ConfigurationError as e:
        print_error(e.message, code=e.code)
        console.print(
            "\n[dim]Tip: Set your API key in environment variables:[/dim]"
            "\n  export OPENAI_API_KEY=your-key-here"
            "\n  export ANTHROPIC_API_KEY=your-key-here"
            "\n  export XAI_API_KEY=your-key-here"
            "\n\n[dim]Or use mock mode for testing:[/dim]"
            '\n  drsai "topic" --provider mock'
        )
        raise typer.Exit(1)

    except DrSAIError as e:
        print_error(e.message, code=e.code)
        raise typer.Exit(1)

    except KeyboardInterrupt:
        console.print("\n[yellow]Generation cancelled.[/yellow]")
        raise typer.Exit(130)

    except Exception as e:
        print_error(f"Unexpected error: {e}")
        if verbose:
            console.print_exception()
        raise typer.Exit(1)


@app.command()
def validate(
    text: str = typer.Argument(
        ...,
        help="Text to validate for Seuss-style meter",
    ),
    verbose: bool = typer.Option(
        False,
        "--verbose",
        "-v",
        help="Show detailed analysis",
    ),
) -> None:
    """Validate text for anapestic tetrameter compliance.

    Example:

        drsai validate "The cat in the hat sat on a mat"
    """
    from drsai.validation.scansion import scan_line, validate_meter

    # Validate meter
    meter_score = validate_meter(text)

    console.print("\n📊 [bold]Meter Analysis[/bold]")
    console.print(f"   Compliance: {meter_score.compliance:.1%}")
    console.print(f"   Total lines: {meter_score.total_lines}")
    console.print(f"   Compliant lines: {meter_score.compliant_lines}")

    if meter_score.is_acceptable:
        console.print("   Status: ✅ [green]Acceptable[/green]")
    elif meter_score.is_degraded:
        console.print("   Status: ⚠️ [yellow]Degraded (below target)[/yellow]")
    else:
        console.print("   Status: ❌ [red]Below minimum[/red]")

    if verbose and meter_score.violations:
        console.print("\n   [dim]Violations:[/dim]")
        for v in meter_score.violations[:5]:
            console.print(f"   - {v}")

    if verbose:
        console.print("\n📏 [bold]Line-by-line analysis:[/bold]")
        lines = [line.strip() for line in text.split("\n") if line.strip()]
        for line in lines[:10]:
            analysis = scan_line(line)
            status = "✅" if analysis.is_anapestic else "❌"
            console.print(f"   {status} [{analysis.compliance_score:.0%}] {line[:50]}...")
            console.print(f"      Pattern: {analysis.stress_pattern}")


# For running as module
if __name__ == "__main__":
    app()
