#!/usr/bin/env bash
set -euo pipefail

SKILLS_DIR="skills"
OUTPUT_DIR="packaged"

usage() {
    echo "Usage: $0 <skill-name>"
    echo ""
    echo "Packages a skill into a .zip file ready for upload."
    echo "The zip contains the skill folder as root (e.g., dax-optimizer/SKILL.md)."
    echo ""
    echo "Examples:"
    echo "  $0 dax-optimizer"
    echo "  $0 database-designer"
    echo ""
    echo "Available skills:"
    for dir in "$SKILLS_DIR"/*/; do
        [ -d "$dir" ] && echo "  - $(basename "$dir")"
    done
    exit 1
}

if [ $# -ne 1 ]; then
    usage
fi

SKILL_NAME="$1"
SKILL_PATH="$SKILLS_DIR/$SKILL_NAME"

if [ ! -d "$SKILL_PATH" ]; then
    echo "Error: Skill '$SKILL_NAME' not found in $SKILLS_DIR/"
    echo ""
    echo "Available skills:"
    for dir in "$SKILLS_DIR"/*/; do
        [ -d "$dir" ] && echo "  - $(basename "$dir")"
    done
    exit 1
fi

if [ ! -f "$SKILL_PATH/SKILL.md" ]; then
    echo "Error: $SKILL_PATH/SKILL.md not found. Every skill must have a SKILL.md file."
    exit 1
fi

mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/$SKILL_NAME.zip"

# Remove old package if it exists
rm -f "$OUTPUT_FILE"

# Create zip from the skills directory so the skill folder is the root entry
# e.g., database-designer/SKILL.md, database-designer/references/...
(cd "$SKILLS_DIR" && zip -r "../$OUTPUT_FILE" "$SKILL_NAME/")

echo ""
echo "Packaged: $OUTPUT_FILE"
echo "Contents:"
unzip -l "$OUTPUT_FILE"
