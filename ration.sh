#!/bin/bash

# Script to export project files and structure for LLM-assisted collaboration
# Description: Generates project structure and exports relevant files based on user-defined configuration
#              and selected tech stack, optimized for providing context to large language models.

# Default configuration - overridden by config file or environment variables
BACKEND_PATH="${BACKEND_PATH:-./backend}"
FRONTEND_PATH="${FRONTEND_PATH:-./frontend}"
OUTPUT_DIR="${OUTPUT_DIR:-./exports}"
CONFIG_FILE="${CONFIG_FILE:-./config.sh}"
INSTRUCTIONS_DIR="${INSTRUCTIONS_DIR:-./instructions}"

# Colors for better readability
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Temporary files
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
PROMPT_FILE="$OUTPUT_DIR/temp_prompt_${TIMESTAMP}.txt"
OUTPUT_FILE="$OUTPUT_DIR/output_${TIMESTAMP}.txt"
INSTRUCTION_FILE="$OUTPUT_DIR/temp_instruction_${TIMESTAMP}.txt"
FILE_LIST="$OUTPUT_DIR/temp_files_${TIMESTAMP}.txt"

# Create empty temporary files
touch "$PROMPT_FILE" "$OUTPUT_FILE" "$INSTRUCTION_FILE" "$FILE_LIST"

# Function to display usage
usage() {
    echo -e "${YELLOW}Usage:${NC}"
    echo -e "  $0 [-b backend_path] [-f frontend_path] [-o output_dir] [-c config_file] [-i instructions_dir]"
    echo -e "Environment variables: BACKEND_PATH, FRONTEND_PATH, OUTPUT_DIR, CONFIG_FILE, INSTRUCTIONS_DIR"
    exit 1
}

# Parse command-line options
while getopts "b:f:o:c:i:h" opt; do
    case $opt in
        b) BACKEND_PATH="$OPTARG";;
        f) FRONTEND_PATH="$OPTARG";;
        o) OUTPUT_DIR="$OPTARG";;
        c) CONFIG_FILE="$OPTARG";;
        i) INSTRUCTIONS_DIR="$OPTARG";;
        h) usage;;
        ?) usage;;
    esac
done

# Load configuration file if it exists
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo -e "${YELLOW}Warning: Config file $CONFIG_FILE not found. Using defaults.${NC}"
    echo -e "${BLUE}Run './$0 -c ./config.sh' after creating a config file to customize.${NC}"
fi

# Check instructions directory
if [ ! -d "$INSTRUCTIONS_DIR" ]; then
    echo -e "${YELLOW}Warning: Instructions directory $INSTRUCTIONS_DIR not found. Creating it.${NC}"
    mkdir -p "$INSTRUCTIONS_DIR"
fi

# Function to check if a directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        echo -e "${RED}Error: Directory $1 does not exist${NC}"
        return 1
    fi
    return 0
}

# Function to generate directory tree with multi-line descriptions
generate_tree() {
    local dir=$1
    local name=$2
    local excludes=$3
    local output_file=$4

    echo -e "${GREEN}=== $name Directory Structure ===${NC}"
    echo "## $name Directory Structure" >> "$output_file" || { echo -e "${RED}Error writing to $output_file${NC}"; exit 1; }
    echo '```' >> "$output_file"

    if command -v tree >/dev/null 2>&1; then
        tree -f -I "$excludes" "$dir" --noreport | while IFS= read -r line; do
            if echo "$line" | grep -qE '\.(swift|py)$'; then
                local full_path=$(echo "$line" | sed 's/^.*[├│└]──[[:space:]]*//; s/^[[:space:]]*//; s/[[:space:]]*$//')
                local rel_path="${full_path#$dir/}"
                local file_path="$full_path"
                echo "Debug: Checking file_path: $file_path" >&2
                if [ -f "$file_path" ]; then
                    if [[ "$rel_path" =~ \.swift$ ]]; then
                        # Multi-line description for Swift
                        local description=$(awk '
                            /^\/\/[[:space:]]*Description:/ {desc = substr($0, match($0, "Description:") + 12); next}
                            desc && /^\/\// {desc = desc " " substr($0, 3); next}
                            desc && !/^\/\// {print desc; desc = ""; exit}
                            END {if (desc) print desc}
                        ' "$file_path" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
                    elif [[ "$rel_path" =~ \.py$ ]]; then
                        # Multi-line description for Python
                        local description=$(awk '
                            /^#[[:space:]]*Description:/ {desc = substr($0, match($0, "Description:") + 12); next}
                            desc && /^#/ {desc = desc " " substr($0, 2); next}
                            desc && !/^#/ {print desc; desc = ""; exit}
                            END {if (desc) print desc}
                        ' "$file_path" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
                    fi
                    echo "Debug: Description found: '$description'" >&2
                    echo "$line${description:+  # $description}" >> "$output_file"
                else
                    echo "Debug: File not found: $file_path" >&2
                    echo "$line" >> "$output_file"
                fi
            else
                echo "$line" >> "$output_file"
            fi
        done
    else
        echo -e "${YELLOW}Note: 'tree' command not found, using basic listing.${NC}"
        find "$dir" -type f \( -name "*.swift" -o -name "*.py" \) | sort | while IFS= read -r file; do
            local rel_path="${file#$dir/}"
            if [[ "$file" =~ \.swift$ ]]; then
                local description=$(awk '
                    /^\/\/[[:space:]]*Description:/ {desc = substr($0, match($0, "Description:") + 12); next}
                    desc && /^\/\// {desc = desc " " substr($0, 3); next}
                    desc && !/^\/\// {print desc; desc = ""; exit}
                    END {if (desc) print desc}
                ' "$file" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
            elif [[ "$file" =~ \.py$ ]]; then
                local description=$(awk '
                    /^#[[:space:]]*Description:/ {desc = substr($0, match($0, "Description:") + 12); next}
                    desc && /^#/ {desc = desc " " substr($0, 2); next}
                    desc && !/^#/ {print desc; desc = ""; exit}
                    END {if (desc) print desc}
                ' "$file" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//')
            fi
            echo "$rel_path${description:+  # $description}" >> "$output_file"
        done
    fi

    echo '```' >> "$output_file"
    echo "" >> "$output_file"
}

# Function to create stack-specific instructions
create_instructions() {
    local stack=$1
    local output_file=$2
    local feature_description=$3

    echo "Instructions for Stack: $stack" >> "$output_file"
    echo "----------------------------------------" >> "$output_file"

    if [ "$stack" = "FastAPI+SwiftUI" ]; then
        echo "Project Export" >> "$output_file"
        echo "Description: Export project context for LLM-assisted feature implementation with FastAPI and SwiftUI" >> "$output_file"
        echo "Selected Stack: $stack" >> "$output_file"
        echo "" >> "$output_file"
        echo "Feature Request: $feature_description" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "General Instructions:" >> "$OUTPUT_FILE"
        cat "$INSTRUCTIONS_DIR/general_instructions.txt" >> "$OUTPUT_FILE" 2>/dev/null || echo "General instructions not found in $INSTRUCTIONS_DIR/general_instructions.txt" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Backend Instructions (FastAPI with Python):" >> "$OUTPUT_FILE"
        cat "$INSTRUCTIONS_DIR/backend_fastapi.txt" >> "$OUTPUT_FILE" 2>/dev/null || echo "Backend instructions not found in $INSTRUCTIONS_DIR/backend_fastapi.txt" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Frontend Instructions (SwiftUI for iOS):" >> "$OUTPUT_FILE"
        cat "$INSTRUCTIONS_DIR/frontend_swiftui.txt" >> "$OUTPUT_FILE" 2>/dev/null || echo "Frontend instructions not found in $INSTRUCTIONS_DIR/frontend_swiftui.txt" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Integration Between Frontend and Backend:" >> "$OUTPUT_FILE"
        cat "$INSTRUCTIONS_DIR/integration_instructions.txt" >> "$OUTPUT_FILE" 2>/dev/null || echo "Integration instructions not found in $INSTRUCTIONS_DIR/integration_instructions.txt" >> "$OUTPUT_FILE"
    else
        echo "Project Export" >> "$OUTPUT_FILE"
        echo "Description: Export project context for LLM-assisted feature implementation with custom stack" >> "$OUTPUT_FILE"
        echo "Selected Stack: $stack" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "Feature Request: $feature_description" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "No specific instructions defined for stack: $stack" >> "$OUTPUT_FILE"
        echo "Please add instruction files to $INSTRUCTIONS_DIR (e.g., backend_custom.txt, frontend_custom.txt)." >> "$OUTPUT_FILE"
    fi
    echo "" >> "$OUTPUT_FILE"
}

# Function to export files with project context
export_files() {
    local file_list="$1"
    local feature_description="$2"
    local stack="$3"

    # Start with project structure
    echo "Project Structure:" > "$OUTPUT_FILE"
    sed '/## Instructions for the LLM/,$d' "$PROMPT_FILE" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Add stack-specific instructions including project title and description
    create_instructions "$stack" "$OUTPUT_FILE" "$feature_description"

    local backend_files=()
    local frontend_files=()

    while IFS= read -r line; do
        [ -z "$line" ] && continue
        if [[ "$line" =~ ^BACKEND:\ (.*) ]]; then
            file_path="${BASH_REMATCH[1]}"
            [ "${file_path:0:1}" != "/" ] && file_path="$BACKEND_PATH/$file_path"
            if [ -f "$file_path" ]; then
                echo -e "${BLUE}Including backend file: $file_path${NC}"
                backend_files+=("$file_path")
            else
                echo -e "${YELLOW}Warning: Backend file not found: $file_path${NC}"
            fi
        elif [[ "$line" =~ ^FRONTEND:\ (.*) ]]; then
            file_path="${BASH_REMATCH[1]}"
            [ "${file_path:0:1}" != "/" ] && file_path="$FRONTEND_PATH/$file_path"
            if [ -f "$file_path" ]; then
                echo -e "${BLUE}Including frontend file: $file_path${NC}"
                frontend_files+=("$file_path")
            else
                echo -e "${YELLOW}Warning: Frontend file not found: $file_path${NC}"
            fi
        fi
    done <<< "$file_list"

    if [ ${#backend_files[@]} -gt 0 ]; then
        echo "Backend Files:" >> "$OUTPUT_FILE"
        echo "----------------------------------------" >> "$OUTPUT_FILE"
        for file in "${backend_files[@]}"; do
            rel_path="${file#$BACKEND_PATH/}"
            echo "File: $rel_path" >> "$OUTPUT_FILE"
            echo '```python' >> "$OUTPUT_FILE"
            cat "$file" >> "$OUTPUT_FILE"
            echo '```' >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        done
    fi

    if [ ${#frontend_files[@]} -gt 0 ]; then
        echo "Frontend Files:" >> "$OUTPUT_FILE"
        echo "----------------------------------------" >> "$OUTPUT_FILE"
        for file in "${frontend_files[@]}"; do
            rel_path="${file#$FRONTEND_PATH/}"
            echo "File: $rel_path" >> "$OUTPUT_FILE"
            echo '```swift' >> "$OUTPUT_FILE"
            cat "$file" >> "$OUTPUT_FILE"
            echo '```' >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        done
    fi

    echo "NOTE TO LLM: If you don’t have the necessary files to implement this feature, please respond with:" >> "$OUTPUT_FILE"
    echo "\"I need additional files to implement this feature. Please run the script again and include:\"" >> "$OUTPUT_FILE"
    echo "Then list the files you need in the format: BACKEND: path/to/file.py or FRONTEND: path/to/file.swift" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"

    # Export summary
    echo -e "\n${GREEN}Export Summary:${NC}"
    echo -e "  ${BLUE}Backend files included: ${#backend_files[@]}${NC}"
    echo -e "  ${BLUE}Frontend files included: ${#frontend_files[@]}${NC}"

    # Calculate character and estimated token counts
    char_count=$(wc -c < "$OUTPUT_FILE")
    word_count=$(wc -w < "$OUTPUT_FILE")
    # Rough token estimate: 1 token ≈ 0.75 words (adjustable)
    token_estimate=$(echo "$word_count / 0.75" | bc)

    echo -e "${GREEN}Output generated:${NC}"
    echo -e "  ${BLUE}Character count: $char_count${NC}"
    echo -e "  ${BLUE}Estimated token count: $token_estimate${NC}"
}

# Function to wait for LLM response and process it
wait_for_files() {
    echo -e "\n${YELLOW}Please paste the LLM's file recommendations below${NC}"
    echo -e "${YELLOW}(Enter an empty line when finished):${NC}"
    
    > "$FILE_LIST"
    
    while IFS= read -r line; do
        [ -z "$line" ] && break
        echo "$line" >> "$FILE_LIST"
    done
    
    if [ ! -s "$FILE_LIST" ]; then
        echo -e "${RED}No input received. Exiting.${NC}"
        exit 1
    fi
    
    return 0
}

# Main execution
main() {
    echo -e "${GREEN}=== llm_context_vibe_rations ===${NC}"
    echo -e "Backend Path: $BACKEND_PATH"
    echo -e "Frontend Path: $FRONTEND_PATH"
    echo -e "Output Dir: $OUTPUT_DIR"
    echo -e "Config File: $CONFIG_FILE"
    echo -e "Instructions Dir: $INSTRUCTIONS_DIR"

    check_directory "$BACKEND_PATH" && backend_exists=0 || backend_exists=1
    check_directory "$FRONTEND_PATH" && frontend_exists=0 || frontend_exists=1

    [ $backend_exists -ne 0 ] && [ $frontend_exists -ne 0 ] && {
        echo -e "${RED}No valid project directories found${NC}"
        exit 1
    }

    echo -e "${BLUE}Enter feature description:${NC}"
    read -e feature_description

    echo "Feature: $feature_description" >> "$PROMPT_FILE"
    echo "" >> "$PROMPT_FILE"

    echo -e "\n${YELLOW}Do you want to:${NC}"
    echo -e "  ${BLUE}1) Let the LLM recommend files based on project structure${NC}"
    echo -e "  ${BLUE}2) Manually specify files to include${NC}"
    read -p "Enter choice [1]: " choice
    
    if [ -z "$choice" ]; then
        choice="1"
    fi
    
    if [ "$choice" = "1" ]; then
        if [ $backend_exists -eq 0 ]; then
            generate_tree "$BACKEND_PATH" "Backend" "__pycache__|*.pyc|.git|venv" "$PROMPT_FILE"
        fi
        
        if [ $frontend_exists -eq 0 ]; then
            generate_tree "$FRONTEND_PATH" "Frontend" "*.xcodeproj|*.xcworkspace|.build" "$PROMPT_FILE"
        fi
        
        echo "## Instructions for the LLM" >> "$PROMPT_FILE"
        echo "Based on the directory structure and the feature description \"$feature_description\", please identify the most relevant files for implementing this feature." >> "$PROMPT_FILE"
        echo "Note: Include all necessary files, such as backend models (e.g., models/user.py) and frontend components, services, or theme files (e.g., Services/GroceryListService.swift), as only the files you list will be included." >> "$PROMPT_FILE"
        echo "Ensure files are relevant to the data entities involved in the feature." >> "$PROMPT_FILE"
        echo "" >> "$PROMPT_FILE"
        echo "Please list the files in this exact format (one file per line, no extra formatting):" >> "$PROMPT_FILE"
        echo "BACKEND: path/to/backend/file.py" >> "$PROMPT_FILE"
        echo "FRONTEND: path/to/frontend/file.swift" >> "$PROMPT_FILE"
        echo "" >> "$PROMPT_FILE"
        echo "After the copy-paste code block, include a brief explanation for why each file is relevant." >> "$PROMPT_FILE"
        
        cat "$PROMPT_FILE" | pbcopy
        echo -e "\n${GREEN}Prompt copied to clipboard! Please:${NC}"
        echo -e "1. ${YELLOW}Paste this to the LLM${NC}"
        echo -e "2. ${YELLOW}Wait for the response${NC}"
        
        wait_for_files
        
        export_files "$(cat "$FILE_LIST")" "$feature_description" "FastAPI+SwiftUI"
    else
        echo -e "\n${YELLOW}Enter file paths (one per line, e.g., BACKEND: models/user.py, FRONTEND: Services/GroceryListService.swift):${NC}"
        echo -e "${YELLOW}Enter an empty line when finished:${NC}"
        
        > "$FILE_LIST"
        
        while IFS= read -r line; do
            [ -z "$line" ] && break
            echo "$line" >> "$FILE_LIST"
        done
        
        export_files "$(cat "$FILE_LIST")" "$feature_description" "FastAPI+SwiftUI"
    fi

    # Final clipboard copy of the full output (including files)
    if command -v pbcopy >/dev/null 2>&1; then
        cat "$OUTPUT_FILE" | pbcopy
        echo -e "${GREEN}Final output (including all files) copied to clipboard!${NC}"
    else
        echo -e "${RED}Error: pbcopy not found. Cannot copy final output to clipboard.${NC}"
    fi

    # Cleanup
    rm -f "$PROMPT_FILE" "$INSTRUCTION_FILE" "$FILE_LIST"
    echo -e "${BLUE}Output saved: $OUTPUT_FILE${NC}"
}

main "$@"