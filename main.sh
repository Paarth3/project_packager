#!/bin/bash

shopt -s globstar

API_KEY=""
MODEL="gemini-2.5-flash"
API_URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${API_KEY}"
OUTPUT_FILE_PATH="output.json"
DEFAULT_IGNORES="
./README.md
./main.sh
./output.json
"
IGNORE_FILE_PATH=""

if ! command -v jq > /dev/null 2>&1; then
	read -rp "'jq' not installed. Do you want to install it (Y/N): " user_install

	if [ "$user_install" == "Y" ] || [ "$user_install" == "y" ]; then
		(sudo apt update && sudo apt install -y jq) || exit $?
	else
		echo "Abort!"
		exit 3
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

if [ ! -s "$OUTPUT_FILE_PATH" ]; then
	jq -n '{ }' > "$OUTPUT_FILE_PATH"
fi

while [ $# -ne  0 ]; do
	if [ "$1" == "-i" ]; then
		shift
		if [ $# -eq 0 ]; then
			echo "ERROR: -i flag must be followed by an argument specifying the file path of the file containing information about files to ignore." >&2
			exit 1
		else
			IGNORE_FILE_PATH="$1"
			shift
			continue
		fi
	fi

	if [ $# -ne 0 ]; then
		echo "ERROR: Invalid arguments provided." >&2
		exit 1
	fi
done

if [ -n "$IGNORE_FILE_PATH" ] && ([ ! -f "$IGNORE_FILE_PATH" ] || [ ! -r "$IGNORE_FILE_PATH" ]); then
	echo "ERROR: The file containing information about other files to ignore either does not exists on the specified path or is not readable." >&2
	exit 1
fi

for file_path in **/*; do

	if [ ! -f "$file_path" ] || [ ! -r "$file_path" ]; then
		continue
	fi

	if echo "$DEFAULT_IGNORES" | grep -Fq "${file_path#./}"; then
		continue
	elif [ "${file_path#./}" == "${IGNORE_FILE_PATH#./}" ]; then
		continue
	elif grep -Fq "${file_path#./}" "$IGNORE_FILE_PATH"; then
		continue
	elif [ "$file_path" == \.\.?.* ]; then
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

	RAW_RESPONSE="$(curl -s -X POST "$API_URL" -H 'Content-Type: application/json' -d "$PAYLOAD")"
	CLEAN_RESPONSE=$(echo "$RAW_RESPONSE" | jq -r '.candidates[0].content.parts[0].text' | sed -n '/^{/,/^}/p')

	tmp=$(mktemp)
	jq --arg file_path "$file_path" --argjson response "$CLEAN_RESPONSE" '.[$file_path] = $response' "$OUTPUT_FILE_PATH" > "$tmp"
	mv "$tmp" "$OUTPUT_FILE_PATH"
	echo "Done: $file_path"
done
