#!/bin/bash

if [ ${BASH_VERSINFO:-0} -le 4 ]; then
	echo "ERROR: This script requires Bash version 4.0 or higher to use globstar." >&2
	exit 1
elif [ "${OSTYPE}" != "linux-gnu" ]; then
	echo "ERROR: This script is currently only supported on Linux (GNU) operating systems." >&2
	exit 1
fi

shopt -s globstar

API_KEY=""
MODEL="gemini-2.5-flash"
API_URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}"
OUTPUT_FILE_PATH="output.json"
DEFAULT_IGNORES="
./README.md
"
IGNORE_FILE_PATH=""

if ! command -v jq > /dev/null 2>&1; then
	read -rp "'jq' not installed. Do you want to install it (Y/N): " user_install

	if [[ "$user_install" =~ ^([Yy]|YES|yes|Yes)$ ]]; then
		if command -v apt > /dev/null 2>&1; then
			(sudo apt update && sudo apt install -y jq) || exit $?
		else
			echo "ERROR: 'apt' package manager not found. Please install 'jq' manually." >&2
			exit 1 No such file or directory
		fi
	else
		echo "Abort!"
		exit 1
	fi
fi

PROMPT=$(jq -n \
	'{
		system_context: "You are an expert software architect and systems analyzer. Your task is to analyze the provided project file and generate a dense, highly structured summary.",
		objective: "This summary will be concatenated with summaries of other files in the project to prime another AI. Your primary goal is to extract the core structure and purpose of this file.
									- For source code, map out the functional entities (classes, functions).
									- For scripts/automation, map out the execution steps.
									- For configs, logs, or data, outline the schemas, rules, or notable patterns.",
		focus: "Do not explain line-by-line; focus strictly on the high-level surface, usage mechanics, structure, and architectural context.",
		response: "Return the summary strictly as a raw JSON object. Do NOT wrap the JSON in Markdown code blocks. Your entire response must begin exactly with the opening curly brace and end exactly with the closing curly brace.",
		response_format: {
			purpose: "A 1-2 sentence high-level summary of the core responsibility of the file",
			key_entities: [
				{
					name: "Name or Identifier",
					type: "Class/Function/Script Step/Config Rule/Data Schema/Log Entry/etc.",
					description: "Brief description of what it represents or accomplishes.",
					usage_behavior: "Expected inputs/outputs, execution triggers, how the system interacts with it, or a description of the data format.",
					assumptions_context: "Any preconditions, required environment variables, data validation requirements, or context required for this to function or make sense. If none, write None.",
				}
			],
			dependencies: ["List critical internal project imports, required environment tools, or major external libraries used. E.g., api/users, React, bash, AWS CLI. If none, use an empty array"],
			side_effects: ["List any database mutations, external API calls, file system operations, or state modifications caused, or tracked, by this file. If none, use an empty array"]
		}
	}')

if [ "$(readlink -f "$(pwd)")" != "$(dirname "$(readlink -f "$0")")" ]; then
	echo "ERROR: Must be run from the script's own directory." >&2
	exit 1
fi

if [ ! -s "$OUTPUT_FILE_PATH" ]; then
	jq -n '{ }' > "$OUTPUT_FILE_PATH"
elif ! jq empty "$OUTPUT_FILE_PATH" > /dev/null 2>&1; then
	echo "ERROR: Existing $OUTPUT_FILE_PATH contains invalid JSON. Please fix or delete the entire file." >&2
    exit 1
fi

while [ $# -ne  0 ]; do
	if [ "$1" == "-i" ]; then
		shift
		if [ $# -eq 0 ]; then
			echo "ERROR: -i requires a file path argument." >&2
			exit 1
		else
			IGNORE_FILE_PATH="$1"
			shift
			continue
		fi
	fi

	if [ $# -ne 0 ]; then
		echo "ERROR: Unknown argument: ${1}" >&2
		exit 1
	fi
done

if [ -n "$IGNORE_FILE_PATH" ] && ([ ! -f "$IGNORE_FILE_PATH" ] || [ ! -r "$IGNORE_FILE_PATH" ]); then
	echo "ERROR: Ignore file not found or not readable: $IGNORE_FILE_PATH" >&2
	exit 1
fi

for file_path in **/*; do

	if [ ! -f "$file_path" ] || [ ! -r "$file_path" ]; then
		continue
	elif echo "$DEFAULT_IGNORES" | grep -Fq "${file_path#./}"; then
		continue
	elif [ "${file_path#./}" == "${IGNORE_FILE_PATH#./}" ]; then
		continue
	elif [ "${file_path#./}" == "${0#./}" ]; then
		continue
	elif [ "${file_path#./}" == "${OUTPUT_FILE_PATH#./}" ]; then
		continue
	elif [ -f "$IGNORE_FILE_PATH" ] && grep -Fq "${file_path#./}" "$IGNORE_FILE_PATH"; then
		continue
	elif [[ "$file_path" == \..* ]]; then
		continue
	fi

	PAYLOAD=$(jq -n \
	--arg prompt "$PROMPT" \
	--arg content "$(cat "$file_path")" \
	'{
		contents: [{
			parts: [
				{ text: $prompt },
				{ text: $content }
			]}
		]
	}')

	RAW_RESPONSE="$(curl -sf -X POST "$API_URL" -H 'Content-Type: application/json' -d "$PAYLOAD")"
	if [ $? -ne 0 ] || ! echo "$RAW_RESPONSE" | jq empty > /dev/null 2>&1 ; then
    	echo "ERROR: API request failed for ${file_path} --- Skipping." >&2
    	continue
	fi
	CLEAN_RESPONSE=$(echo "$RAW_RESPONSE" | jq -r '.candidates[0].content.parts[0].text' | sed -n '/^{/,/^}/p')

	tmp=$(mktemp)
	if jq --arg file_path "$file_path" --argjson response "$CLEAN_RESPONSE" '.[$file_path] = $response' "$OUTPUT_FILE_PATH" > "$tmp"; then
    	mv "$tmp" "$OUTPUT_FILE_PATH"
    	echo "Done: $file_path"
	else
		echo "ERROR: AI generated invalid JSON for ${file_path} --- Skipping." >&2
    	rm "$tmp"
	fi
done