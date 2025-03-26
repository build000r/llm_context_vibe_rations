# llm_context_vibe_rations

A Bash script designed to export project structures and files, optimized for vibe coders to provide context to Large Language Models (LLMs) for feature implementation and collaboration. It supports customizable tech stacks and coding instructions, making it adaptable to various projects.

## Tagline

"rations for token hungry llms"

## Features

- **Project Structure Generation**: Creates a tree-like view of backend and frontend directories.
- **File Export**: Exports specified files with their content in a formatted output.
- **Stack-Specific Instructions**: Includes customizable coding guidelines (default: FastAPI + SwiftUI).
- **Configurable Paths**: Define backend, frontend, and output directories via a config file or command-line options.
- **Clipboard Support**: Copies output to the clipboard (on systems with `pbcopy`) for easy sharing with LLMs or collaborators.

## Prerequisites

- **Bash**: Runs on Unix-like systems (Linux, macOS, WSL on Windows).
- **Tree (optional)**: For enhanced directory structure visualization (`sudo apt install tree` on Debian/Ubuntu, `brew install tree` on macOS).
- **pbcopy (optional)**: For clipboard support (available on macOS; alternatives like `xclip` or `wl-copy` can be adapted).

## Installation

1. **Clone or Download**:

   ```bash
   git clone https://github.com/build000r/llm_context_vibe_rations.git
   cd llm_context_vibe_rations
   ```

2. **Make Executable**:
   chmod +x ration.sh

3. **Edit Config**:
   BACKEND_PATH="/path/to/your/backend"
   FRONTEND_PATH="/path/to/your/frontend"
   OUTPUT_DIR="./exports"
   INSTRUCTIONS_DIR="./instructions"

4. **Set up the Instructions Folder**:
   Customize for your stack.
   Current instructions are for swift / python
   Edit /general_instructions project and description

## Usage

- **Default Run**: (uses llm_context_vibe_rations_config.sh and ./instructions):
  1. $ ./rations.sh
  2. Type feature description
  3. Get suggested files from LLM
  4. Get feature + relevant files
  5. Give to LLM

## Contributing

    Fork the repository.
    Create a feature branch (git checkout -b feature/your-feature).
    Commit changes (git commit -m "Add your feature").
    Push to the branch (git push origin feature/your-feature).
    Open a pull request.
