#!/usr/bin/env bash
#
# check-diff.sh - Validate git diff size and filter binary files
#
# Usage: check-diff.sh [--staged|--unstaged] [--max-lines=N] [--max-file-lines=N]
#
# Options:
#   --staged          Check staged changes (default)
#   --unstaged        Check unstaged changes
#   --max-lines=N     Maximum total diff lines (default: 500)
#   --max-file-lines=N Maximum lines per file (default: 200)
#   --quiet           Only output the filtered diff
#   --summary         Only output the summary, no diff

set -euo pipefail

# Defaults
STAGED=true
MAX_LINES=500
MAX_FILE_LINES=200
QUIET=false
SUMMARY_ONLY=false

# Binary/image file extensions to skip
BINARY_EXTENSIONS=(
    # Images
    png jpg jpeg gif bmp ico svg webp tiff psd
    # Fonts
    ttf otf woff woff2 eot
    # Archives
    zip tar gz bz2 7z rar
    # Documents
    pdf doc docx xls xlsx ppt pptx
    # Media
    mp3 mp4 wav avi mov mkv
    # Compiled/binary
    pyc pyo so dll exe bin o a
    # Lock files (often huge)
    lock
    # Data
    db sqlite sqlite3
)

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --staged)
            STAGED=true
            shift
            ;;
        --unstaged)
            STAGED=false
            shift
            ;;
        --max-lines=*)
            MAX_LINES="${1#*=}"
            shift
            ;;
        --max-file-lines=*)
            MAX_FILE_LINES="${1#*=}"
            shift
            ;;
        --quiet)
            QUIET=true
            shift
            ;;
        --summary)
            SUMMARY_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

# Build diff command
if $STAGED; then
    DIFF_CMD="git diff --cached"
else
    DIFF_CMD="git diff"
fi

# Get list of changed files
if $STAGED; then
    FILES=$(git diff --cached --name-only 2>/dev/null || true)
else
    FILES=$(git diff --name-only 2>/dev/null || true)
fi

if [[ -z "$FILES" ]]; then
    echo "No changes detected."
    exit 0
fi

# Categorize files
TEXT_FILES=()
BINARY_FILES=()
SKIPPED_FILES=()
LARGE_FILES=()

is_binary_extension() {
    local file="$1"
    local ext="${file##*.}"
    ext="${ext,,}"  # lowercase

    for bin_ext in "${BINARY_EXTENSIONS[@]}"; do
        if [[ "$ext" == "$bin_ext" ]]; then
            return 0
        fi
    done
    return 1
}

while IFS= read -r file; do
    [[ -z "$file" ]] && continue

    # Check if file has binary extension
    if is_binary_extension "$file"; then
        BINARY_FILES+=("$file")
        continue
    fi

    # Check if git detects it as binary
    if git diff --cached --numstat -- "$file" 2>/dev/null | grep -q "^-"; then
        BINARY_FILES+=("$file")
        continue
    fi

    # Check file diff size
    if $STAGED; then
        file_lines=$(git diff --cached -- "$file" 2>/dev/null | wc -l)
    else
        file_lines=$(git diff -- "$file" 2>/dev/null | wc -l)
    fi

    if [[ "$file_lines" -gt "$MAX_FILE_LINES" ]]; then
        LARGE_FILES+=("$file ($file_lines lines)")
        SKIPPED_FILES+=("$file")
    else
        TEXT_FILES+=("$file")
    fi
done <<< "$FILES"

# Calculate total diff size for text files
TOTAL_LINES=0
for file in "${TEXT_FILES[@]}"; do
    if $STAGED; then
        lines=$(git diff --cached -- "$file" 2>/dev/null | wc -l)
    else
        lines=$(git diff -- "$file" 2>/dev/null | wc -l)
    fi
    TOTAL_LINES=$((TOTAL_LINES + lines))
done

# Output summary
if ! $QUIET; then
    echo "=== Git Diff Analysis ==="
    echo ""
    echo "Text files to include: ${#TEXT_FILES[@]}"
    for f in "${TEXT_FILES[@]}"; do
        echo "  - $f"
    done

    if [[ ${#BINARY_FILES[@]} -gt 0 ]]; then
        echo ""
        echo "Binary files (skipped): ${#BINARY_FILES[@]}"
        for f in "${BINARY_FILES[@]}"; do
            echo "  - $f"
        done
    fi

    if [[ ${#LARGE_FILES[@]} -gt 0 ]]; then
        echo ""
        echo "Large files (skipped): ${#LARGE_FILES[@]}"
        for f in "${LARGE_FILES[@]}"; do
            echo "  - $f"
        done
    fi

    echo ""
    echo "Total diff lines: $TOTAL_LINES (max: $MAX_LINES)"

    if [[ "$TOTAL_LINES" -gt "$MAX_LINES" ]]; then
        echo ""
        echo "WARNING: Total diff exceeds $MAX_LINES lines."
        echo "Consider committing in smaller chunks."
        exit 1
    fi

    echo ""
fi

# Output filtered diff
if ! $SUMMARY_ONLY && [[ ${#TEXT_FILES[@]} -gt 0 ]]; then
    if ! $QUIET; then
        echo "=== Filtered Diff ==="
        echo ""
    fi

    for file in "${TEXT_FILES[@]}"; do
        if $STAGED; then
            git diff --cached -- "$file"
        else
            git diff -- "$file"
        fi
    done
fi
