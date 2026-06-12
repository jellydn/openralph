#!/bin/bash
# Quick Start - Set up Ralph in a new project
# Usage: ./quick-start.sh [project-name] [cli_tool]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           Ralph Quick Start Setup                     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""

# Parse arguments
PROJECT_NAME=${1:-$(basename "$PWD")}
CLI_TOOL=${2:-amp}

# Validate CLI tool
VALID_TOOLS="amp opencode mino mimo kilo pi agy cmd codex copilot claude"
if ! echo "$VALID_TOOLS" | grep -qw "$CLI_TOOL"; then
    echo -e "${YELLOW}Warning: Unknown tool '$CLI_TOOL'. Using 'amp' as default.${NC}"
    CLI_TOOL="amp"
fi

echo -e "${GREEN}Project:${NC} $PROJECT_NAME"
echo -e "${GREEN}CLI Tool:${NC} $CLI_TOOL"
echo ""

# Step 1: Initialize git if needed
if [ ! -d ".git" ]; then
    echo -e "${BLUE}[1/4]${NC} Initializing git repository..."
    git init
    echo -e "${GREEN}✓${NC} Git initialized"
else
    echo -e "${BLUE}[1/4]${NC} Git repository already exists"
fi
echo ""

# Step 2: Create PRD from template
echo -e "${BLUE}[2/4]${NC} Setting up PRD..."

if [ -f "prd.json" ]; then
    echo -e "${YELLOW}⚠${NC}  prd.json already exists, skipping..."
else
    cat > prd.json << 'PRD_EOF'
{
  "featureName": "PROJECT_NAME_PLACEHOLDER",
  "branchName": "ralph/PROJECT_NAME_PLACEHOLDER",
  "description": "Describe your feature here",
  "technicalNotes": "Any technical context or constraints",
  "userStories": [
    {
      "id": "S1",
      "title": "Set up project structure",
      "description": "Initialize the project with basic files and configuration",
      "acceptanceCriteria": [
        "Project has a working build",
        "Basic folder structure is in place",
        "README.md exists with project description"
      ],
      "passes": false
    },
    {
      "id": "S2",
      "title": "Implement core functionality",
      "description": "Add the main feature implementation",
      "acceptanceCriteria": [
        "Core feature works as described",
        "Basic error handling is in place",
        "Code follows project conventions"
      ],
      "passes": false
    },
    {
      "id": "S3",
      "title": "Add tests",
      "description": "Write tests for the implemented functionality",
      "acceptanceCriteria": [
        "Unit tests cover main functionality",
        "Tests pass",
        "Edge cases are handled"
      ],
      "passes": false
    }
  ]
}
PRD_EOF

    # Replace placeholder with project name
    sed -i.bak "s/PROJECT_NAME_PLACEHOLDER/$PROJECT_NAME/g" prd.json && rm -f prd.json.bak
    
    echo -e "${GREEN}✓${NC} Created prd.json with template"
    echo -e "${YELLOW}→${NC} Edit prd.json to add your feature requirements"
fi
echo ""

# Step 3: Set up Ralph scripts
echo -e "${BLUE}[3/4]${NC} Setting up Ralph scripts..."

mkdir -p scripts/ralph

# Copy ralph.sh
if [ -f "$SCRIPT_DIR/ralph.sh" ]; then
    cp "$SCRIPT_DIR/ralph.sh" scripts/ralph/ralph.sh
    chmod +x scripts/ralph/ralph.sh
    echo -e "${GREEN}✓${NC} Copied ralph.sh"
fi

# Copy prompt files
for prompt_file in "$SCRIPT_DIR"/prompt-*.md "$SCRIPT_DIR"/CLAUDE.md; do
    if [ -f "$prompt_file" ]; then
        cp "$prompt_file" scripts/ralph/
        echo -e "${GREEN}✓${NC} Copied $(basename "$prompt_file")"
    fi
done

# Copy progress template
if [ ! -f "progress.txt" ]; then
    cat > progress.txt << 'PROGRESS_EOF'
# Ralph Progress Log
Started: $(date)
---
PROGRESS_EOF
    echo -e "${GREEN}✓${NC} Created progress.txt"
fi

echo ""

# Step 4: Create initial commit
echo -e "${BLUE}[4/4]${NC} Creating initial commit..."

if [ -z "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}⚠${NC}  No changes to commit"
else
    git add -A
    git commit -m "chore: initial project setup with Ralph

- Initialize git repository
- Add PRD template (prd.json)
- Set up Ralph scripts for $CLI_TOOL
- Create progress.txt for tracking learnings"
    echo -e "${GREEN}✓${NC} Created initial commit"
fi
echo ""

# Summary
echo -e "${GREEN}╔═══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           Setup Complete! 🎉                          ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Next steps:"
echo ""
echo "  1. Edit prd.json to define your feature requirements"
echo ""
echo "  2. Run Ralph:"
echo -e "     ${BLUE}./scripts/ralph/ralph.sh${NC}                    # Default: amp, 10 iterations"
echo -e "     ${BLUE}./scripts/ralph/ralph.sh 10 $CLI_TOOL${NC}       # With $CLI_TOOL"
echo ""
echo "  3. Monitor progress:"
echo -e "     ${BLUE}cat progress.txt${NC}                           # See learnings"
echo -e "     ${BLUE}cat prd.json | jq '.userStories[] | .passes'${NC}  # Check story status"
echo ""
echo "Useful commands:"
echo -e "  ${BLUE}./scripts/ralph/ralph.sh --help${NC}              # Show all options"
echo -e "  ${BLUE}git log --oneline${NC}                         # View commit history"
echo ""
