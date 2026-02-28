# Project Packager (PP)

## Project Overview

**Project Packager** is an automated Bash utility that traverses a multi-file codebase to generate a highly structured, file-by-file summary in JSON format, using the Google Gemini API.

Navigating a new or undocumented project can be time-consuming. This tool solves that problem by automatically documenting the high-level architecture, including core responsibilities, key functions/classes, dependencies, and side effects, for every file. The resulting `output.json` file can be read by developers to quickly grasp a project's structure, or fed into AI coding assistants to effectively prime them with comprehensive project context.

## Key Learnings

- **REST API Integration & Authentication:** Configured and sent secure HTTP requests to the Google Gemini API using `curl`, managing payload structures and API keys.    
- **Robust Data Handling with `jq`:** Learned to use `jq` not just for parsing API responses, but for safely building nested JSON output. This ensures that shell variables and raw code strings are properly escaped, avoiding injection vulnerabilities or syntax errors.
- **Advanced Bash Scripting:** Utilized `globstar` for recursive file traversal, implemented command-line argument parsing (e.g., custom ignore lists via flags), and managed temporary files (`mktemp`) for safe, in-place file updates.
- **Prompt Engineering & Output Enforcement:** Designed dense system prompts to constrain a Generative AI model into returning strict, machine-readable JSON rather than conversational markdown, utilizing tools like `sed` as a fallback to strip out unwanted formatting artifacts.

## Technical Details

- **Language:** Bash
- **External APIs:** Google Gemini API (`gemini-2.5-flash`)
- **Core Tools:** 
	- `curl` (Network requests)
    - `jq` (JSON construction, parsing, and modification)
    - `sed` / `grep` (Text processing and pattern matching)
- **Environment:** Linux / Unix environments (The script includes automatic dependency resolution for Debian/Ubuntu systems via `apt`).

### Important Design Decisions

- **File-by-File Processing:** Instead of dumping an entire repository into an LLM (which risks exceeding token limits or losing detail), this script processes files individually. It incrementally builds a master JSON object mapping file paths to their structural summaries.
- **JSON Parsing:** LLMs occasionally wrap JSON in markdown blockquotes (` ```json `). The script anticipates this and uses `sed -n '/^{/,/^}/p'` to automatically extract only the valid JSON payload from the raw text response before writing to the output file.
- **Custom Ignore Logic:** Automatically ignores hidden files (e.g., `.git/`), its own source code, and dynamically accepts a custom exclusion list via the CLI to skip dependencies like `node_modules` or `.env` files.

## How to Run / Use the Project

### Prerequisites

1. A Linux/Unix environment (or WSL on Windows).
2. A valid **Google Gemini API Key**. You can create one [here.](https://aistudio.google.com/api-keys)

### Setup

1. You will simply need the `main.sh` file from this repository. Download it.
2. Open the script file (`main.sh`) and insert your API key into the `API_KEY` variable at the top of the file:
``` bash
API_KEY="your_api_key_here"
```
3. Make the script executable:
```bash
chmod +x main.sh
```
### Usage

Make sure you are not out of API credits/usage. Run the script in the root directory of the project you want to summarize.

**Basic Run:**
```bash
./main.sh
```

_Note: If `jq` is not installed on your system, the script will automatically prompt you to install it._

**Using a Custom Ignore File:** If you want to ignore specific files or directories, you can pass a text file containing the paths to ignore using the `-i` flag:

```bash
./main.sh -i myignorefile.txt
```

### Output

The script will process your files and generate an `output.json` file in the root directory. This file will contain a structured map of your project, formatted like this:

```json
{
  "./src/app.py": {
    "purpose": "Initialises the main web server and routing.",
    "key_entities": [...],
    "dependencies": [...],
    "side_effects": [...]
  },
  "./src/database.py": { ... }
}
```
