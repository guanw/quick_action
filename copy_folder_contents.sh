#!/bin/bash
set -euo pipefail

echo "Starting copy_folder_contents.sh" >> /tmp/copy_folder_contents.log

FOLDER_PATH="$1"
cd "$FOLDER_PATH" || exit 1

echo "FOLDER_PATH: $FOLDER_PATH" >> /tmp/copy_folder_contents.log

# ===== EXCLUSIONS CONFIGURATION - MODIFY THESE =====
EXCLUDE_DIRS=(".git" ".vscode" "node_modules" "__pycache__" ".idea" "dist" "build" ".next", "gpt_env")
EXCLUDE_FILES=("package-lock.json" "yarn.lock" ".DS_Store" "*.pyc" ".env" ".env.*" "*.min.js" "*.log" "pnpm-lock.yaml", "*.txt")
# ===================================================

# Build find command using arrays (safer)
find_args=("." "-type" "f")
echo "Find command: find ${find_args[*]}" >> /tmp/copy_folder_contents.log

# Add directory exclusions
for dir in "${EXCLUDE_DIRS[@]}"; do
  find_args+=("-not" "-path" "./$dir/*")
done

# Add file exclusions
if [ ${#EXCLUDE_FILES[@]} -gt 0 ]; then
  find_args+=("(")
  for file in "${EXCLUDE_FILES[@]}"; do
    find_args+=("-not" "-name" "$file")
  done
  find_args+=(")")
fi

find_args+=("-print0")

# Debug: Print the command
echo "Running: find ${find_args[*]}"
echo "Running: find ${find_args[*]}" >> /tmp/copy_folder_contents.log

# Process files
output=""
file_count=0

while IFS= read -r -d '' file; do
  rel_path="${file#./}"
  echo "Processing: $rel_path"
  echo "Processing $rel_path" >> /tmp/copy_folder_contents.log
  
  # Skip unreadable/empty files
  if [[ ! -r "$file" ]]; then
    echo "  Skipping: Not readable"
    echo "$file Skipping: Not readable" >> /tmp/copy_folder_contents.log
    continue
  fi
  
  if [[ ! -s "$file" ]]; then
    echo "  Skipping: Empty file"
    echo "$file Skipping: Empty file" >> /tmp/copy_folder_contents.log
    continue
  fi
  
  # Try to detect binary files
  if file "$file" | grep -q "binary"; then
    echo "$file Skipping: Binary file" >> /tmp/copy_folder_contents.log
    echo "  Skipping: Binary file"
    continue
  fi
  
  # Add file header and content
  output+="--- $rel_path ---"$'\n'
  if content=$(cat -- "$file" 2>/dev/null); then
    output+="$content"$'\n\n'
    ((file_count++))
  else
    echo "  Error reading file"
    output+="[Error reading file]"$'\n\n'
    echo "$file Error reading file" >> /tmp/copy_folder_contents.log
  fi
done < <(find "${find_args[@]}" 2>/dev/null)

echo "Processed $file_count files"

# Handle no files found
if [ -z "$output" ]; then
  echo "No files found to copy!"
  echo "No files found to copy" >> /tmp/copy_folder_contents.log
  osascript -e 'display notification "No readable files found to copy!" with title "Folder Copier"' 2>/dev/null
  exit 0
fi

# Copy to clipboard
printf "%s" "$output" | pbcopy
echo "Copied $file_count files to clipboard"
osascript -e "display notification \"Copied $file_count files to clipboard!\" with title \"Folder Copier\"" 2>/dev/null