#!/usr/bin/env python3
"""
Repository Scanner with Vibe Explore Subagent

This script demonstrates how to drive Vibe Code from Python using the explore
subagent. It recursively explores a codebase and creates AI-readable summaries
at each directory level.

Usage:
    python scan-repository.py /path/to/repo [--output .vibe-summaries] [--max-depth 3]

The explore subagent is a built-in read-only subagent that uses grep and read_file
to analyze codebases. It's perfect for this kind of hierarchical scanning task.

Requirements:
    - Vibe must be installed (the Python package, not just the CLI)
    - Python version must match Vibe's installation
"""

import asyncio
from pathlib import Path
from contextlib import aclosing
import sys
import os

# Add Vibe to path (adjust based on your installation)
# Common locations:
# - ~/.local/share/uv/tools/mistral-vibe/lib/pythonX.Y/site-packages
# - ~/.vibe/venv/lib/pythonX.Y/site-packages
# - Check with: which vibe && cat $(which vibe)

VIBE_INSTALL_PATHS = [
    Path.home() / ".local/share/uv/tools/mistral-vibe/lib",
    Path.home() / ".vibe/venv/lib",
]

vibe_lib_path = None
for base in VIBE_INSTALL_PATHS:
    for python_lib in base.glob("python*"):
        vibe_pkg = python_lib / "site-packages" / "vibe"
        if vibe_pkg.exists():
            vibe_lib_path = str(python_lib / "site-packages")
            break
    if vibe_lib_path:
        break

if vibe_lib_path:
    sys.path.insert(0, vibe_lib_path)
else:
    # Fallback: try to import vibe directly
    try:
        import vibe
    except ImportError:
        print("Error: Could not find vibe Python package.")
        print("Please ensure Vibe is installed as a Python package.")
        print("Installation path not found in:")
        for p in VIBE_INSTALL_PATHS:
            print(f"  - {p}")
        sys.exit(1)

from vibe.core.config import VibeConfig
from vibe.core.agent_loop import AgentLoop
from vibe.core.agents.models import BuiltinAgentName
from vibe.core.telemetry.build_metadata import build_entrypoint_metadata
from vibe.core.types import LLMMessage, Role
from vibe.core.config.harness_files._harness_manager import init_harness_files_manager

def create_explore_loop() -> AgentLoop:
    """
    Create an AgentLoop configured for the explore subagent.
    
    The explore subagent is:
    - A SUBAGENT type (can be spawned by other agents)
    - Read-only (enabled tools: grep, read_file)
    - Designed for codebase exploration
    - Uses the 'explore' system prompt (minimal, code-first responses)
    """
    
    print(dir(VibeConfig))

    config = VibeConfig.load()
    
    return AgentLoop(
        config=config,
        agent_name=BuiltinAgentName.EXPLORE,
        entrypoint_metadata=build_entrypoint_metadata(
            agent_entrypoint="programmatic",
            client_name="repo_scanner",
            client_version="1.0",
        ),
        enable_streaming=False,
        is_subagent=True,
    )


async def scan_directory(
    repo_path: Path,
    output_dir: Path,
    loop: AgentLoop,
    max_depth: int = 3,
    current_depth: int = 0,
) -> None:
    """
    Recursively scan a directory and create AI-generated summaries.
    
    Args:
        repo_path: The repository root to scan
        output_dir: Where to write summary files
        loop: Configured AgentLoop for explore subagent
        max_depth: Maximum recursion depth
        current_depth: Current depth (internal use)
    """
    output_dir.mkdir(parents=True, exist_ok=True)
    
    # Get all immediate subdirectories (excluding hidden ones)
    items = sorted(repo_path.iterdir())
    directories = [
        d for d in items 
        if d.is_dir() and not d.name.startswith((".", "__", "node_modules", "venv", ".git"))
    ]
    
    for dir_path in directories:
        relative_path = dir_path.relative_to(repo_path)
        
        # Create a safe filename (replace / with _)
        safe_name = str(relative_path).replace("/", "_")
        summary_file = output_dir / f"{safe_name}.summary.md"
        
        # Skip if summary already exists
        if summary_file.exists():
            print(f"  Skipping {relative_path} (already summarized)")
            continue
        
        # Get files in this directory (limit to avoid overwhelming the agent)
        files_in_dir = []
        for ext in ["*.py", "*.md", "*.toml", "*.yaml", "*.yml", "*.json", "*.txt"]:
            files_in_dir.extend(dir_path.glob(ext))
        
        # Limit to most recent/modified files if too many
        files_in_dir = sorted(files_in_dir, key=lambda f: f.stat().st_mtime, reverse=True)[:50]
        
        if not files_in_dir:
            # Empty directory, but might have subdirectories
            if current_depth < max_depth:
                await scan_directory(
                    dir_path, output_dir, loop, 
                    max_depth, current_depth + 1
                )
            continue
            
        # Build a task for the explore subagent
        files_list = "\n".join(
            f"  - {f.relative_to(repo_path)}" 
            for f in files_in_dir
        )
        
        # Count lines of code
        total_lines = sum(
            len(f.read_text().splitlines()) 
            for f in files_in_dir 
            if f.suffix in [".py", ".md", ".toml", ".yaml", ".yml"]
        )
        
        task = f"""
Analyze the codebase directory: {relative_path}

Context:
- Path: {dir_path}
- Files: {len(files_in_dir)}
- Total lines: ~{total_lines}

Files to examine:
{files_list}

Create a concise, structured summary suitable for AI agents. Follow these guidelines:

1. **PURPOSE FIRST**: Start with a one-sentence purpose of this directory
2. **KEY FILES**: List 3-5 most important files with their roles
3. **STRUCTURE**: Note any subdirectories and their purposes
4. **PATTERNS**: Identify any important patterns, configurations, or conventions
5. **DEPENDENCIES**: Note external or internal dependencies
6. **NOTEWORTHY**: Flag anything unusual, complex, or noteworthy

Format:
- Use code blocks for file paths: `path/to/file.py`
- Use ASCII trees for hierarchy: `├── └──`
- Use tables for comparisons if applicable
- Keep total response under 1500 words
- No greetings, no summaries, no fluff

Begin analysis now.
        """.strip()
        
        print(f"  Summarizing {relative_path}...")
        
        # Clear previous messages for a fresh context
        loop.messages.clear()
        
        # Run the explore subagent on this task
        accumulated_response: list[str] = []
        try:
            async with aclosing(loop.act(task)) as events:
                async for event in events:
                    if hasattr(event, 'content') and event.content:
                        accumulated_response.append(event.content)
        except Exception as e:
            print(f"    Error analyzing {relative_path}: {e}")
            accumulated_response.append(f"Error during analysis: {e}")
        
        summary = "\n".join(accumulated_response)
        summary_file.write_text(summary)
        print(f"    -> Written to {summary_file.name}")
        
        # Recurse into subdirectories if within depth limit
        if current_depth < max_depth:
            await scan_directory(
                dir_path, output_dir, loop,
                max_depth, current_depth + 1
            )


async def scan_with_programmatic_api(repo_path: Path, output_file: Path) -> None:
    """
    Alternative approach using the high-level run_programmatic API.
    
    This is simpler but gives you less control over the agent loop.
    """
    from vibe.core.programmatic import run_programmatic
    from vibe.core.types import OutputFormat
    
    config = VibeConfig.load()
    
    # List all Python files
    py_files = list(repo_path.rglob("*.py"))
    file_list = "\n".join(f"  - {f.relative_to(repo_path)}" for f in py_files[:100])
    
    prompt = f"""
Analyze this Python codebase: {repo_path}

Files found ({len(py_files)} total, showing first 100):
{file_list}

Provide a high-level overview:
1. Project structure and main components
2. Key modules and their purposes
3. Entry points
4. Notable patterns or architectures
5. Anything unusual or important to know

Format: Code-first, minimal context, structured output.
    """.strip()
    
    result = run_programmatic(
        config=config,
        prompt=prompt,
        agent_name=BuiltinAgentName.EXPLORE,
        max_turns=10,
        headless=True,
        output_format=OutputFormat.TEXT,
    )
    
    if result:
        output_file.write_text(result)
        print(f"  High-level summary written to {output_file.name}")

def ensure_api_key() -> None:
    if not "MISTRAL_API_KEY" in os.environ:
        config = open(Path.home() / ".vibe/.env")
        line = "s"
        while line != "":
            line = config.readline()
            if line.startswith("MISTRAL_API_KEY"):
                key = line.removeprefix("MISTRAL_API_KEY").replace("=", "").replace("'","").replace(" ","")
                print(key)
                os.environ["MISTRAL_API_KEY"] = key

async def main_async(args: list[str]) -> None:
    """Async main function."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Scan repository with Vibe explore subagent"
    )
    parser.add_argument(
        "repo_path", 
        type=Path, 
        help="Repository root to scan"
    )
    parser.add_argument(
        "--output", 
        type=Path, 
        default=".vibe-summaries",
        help="Output directory for summaries (default: .vibe-summaries)"
    )
    parser.add_argument(
        "--max-depth", 
        type=int, 
        default=3,
        help="Maximum directory depth to recurse (default: 3)"
    )
    parser.add_argument(
        "--quick",
        action="store_true",
        help="Use quick high-level scan instead of hierarchical"
    )
    
    parsed_args = parser.parse_args(args)
    
    repo_path = parsed_args.repo_path.resolve()
    output_dir = parsed_args.output.resolve()
    
    if not repo_path.exists():
        print(f"Error: Repository path does not exist: {repo_path}")
        sys.exit(1)
    
    print(f"Scanning repository: {repo_path}")
    print(f"Output directory: {output_dir}")
    print(f"Max depth: {parsed_args.max_depth}")
    print()

    ensure_api_key()
    init_harness_files_manager()

    # Create the explore agent loop
    loop = create_explore_loop()
    
    try:
        if parsed_args.quick:
            # Quick high-level scan
            output_file = output_dir / "quick-summary.md"
            await scan_with_programmatic_api(repo_path, output_file)
        else:
            # Hierarchical scan
            await scan_directory(
                repo_path, 
                output_dir, 
                loop,
                max_depth=parsed_args.max_depth
            )
        
        print(f"\nSummaries written to {output_dir.resolve()}")
        
        # Print summary of what was created
        summaries = list(output_dir.rglob("*.md"))
        print(f"\nCreated {len(summaries)} summary files:")
        for s in sorted(summaries):
            size = s.stat().st_size
            print(f"  - {s.relative_to(output_dir)} ({size} bytes)")
            
    finally:
        # Clean up
        await loop.aclose()


def main() -> None:
    """Entry point."""
    asyncio.run(main_async(sys.argv[1:]))


if __name__ == "__main__":
    main()
