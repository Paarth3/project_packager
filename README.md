# Project Packager (PP)

## Overview

**Project Packager (PP)** is an automated Bash utility that traverses a multi-file codebase and leverages the Google Gemini API to generate a highly structured, file-by-file summary in JSON format.

Navigating a new or undocumented project can be time-consuming. This tool solves that problem by automatically documenting the high-level architecture, including core responsibilities, key functions/classes, dependencies, assumptions, and side effects, for every file. The resulting `output.json` file can be read by developers to quickly grasp a project's structure, or fed into AI coding assistants to effectively prime them with comprehensive project context without exceeding prompt limits.

## Key Learnings

- **REST API Integration & Authentication:** Configured and sent secure HTTP requests to the Google Gemini API using `curl`, managing payload structures and API keys.
- **Defensive Bash Scripting:** Implemented robust CLI argument parsing using `while` and `shift` loops, managed script exit codes effectively, and added strict pre-flight checks to verify file existence and read permissions before processing.
- **Robust Data Handling with `jq`:** Learned to use `jq` not just for parsing API responses, but for safely constructing nested JSON payloads. This ensures that shell variables and raw code strings are properly escaped, avoiding injection vulnerabilities or syntax errors.
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
- **Resilient JSON Parsing:** LLMs occasionally wrap JSON in markdown blockquotes (` ```json `). The script anticipates this and uses `sed -n '/^{/,/^}/p'` to dynamically extract only the valid JSON payload from the raw text response before writing to the output file.
- **Strict CLI & Error Handling:** The script features explicit command-line validation. It actively guards against invalid arguments, missing file paths, and unreadable files, throwing descriptive standard error (`stderr`) messages rather than failing mid-execution silently.
- **Custom Ignore Logic:** Automatically ignores the tool's own source files and dynamically accepts a custom exclusion list via the `-i` CLI flag to skip dependencies like `node_modules` or `.env` files.

## How to Run / Use the Project

### Prerequisites

1. A Linux/Unix environment (or WSL on Windows).
2. A valid **Google Gemini API Key** (with enough API credits). You can get one for free at [Google Gemini API](https://aistudio.google.com/api-keys)

### Setup

1. Download the `main.sh` file from this repository.
2. Open the `main.sh` and insert your API key into the `API_KEY` variable at the top of the file:   
```bash
API_KEY="your_api_key_here"
```
3. Place the `main.sh` file into your project's root folder.
4. Make the script executable by running the following command in your terminal. Ensure you provide the correct file path for `main.sh`.
```bash
chmod +x main.sh
```

### Usage

Run the script in the root directory of the project you want to summarise.
**Basic Run:**
```bash
./main.sh
```

_Note: If `jq` is not installed on your system, the script will automatically prompt you to install it._

**Using a Custom Ignore File:** If you want to ignore specific files or directories, you can pass a text file containing the paths to ignore using the `-i` flag:

```bash
./main.sh -i .myignorefile
```

**Error Handling:** The script will safely abort and provide an error message if:
- You provide an unrecognised argument.
- You use the `-i` flag without providing a file path.
- The specified ignore file does not exist or lacks read permissions.

### Output

The script will process your readable files and generate an `output.json` file in the root directory. This file will contain a structured map of your project, formatted as shown below. You may read the `output.json` sample provided in the repository.

#### ⚠️ Note
If you see the value for a certain file(s) as `null`, there is a high chance you ran out of Gemini API credits for the day. The API credits should reset the next day.

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
