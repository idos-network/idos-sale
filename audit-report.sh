#!/usr/bin/env bash

# Fetch all open issues tagged with "audit" and generate a markdown report

# Fetch issues as JSON
ISSUES=$(gh issue list --label "audit" --state open --json number,title,body,url --limit 1000)

# Check if we got any issues
if [ "$(echo "$ISSUES" | jq '. | length')" -eq 0 ]; then
    echo "No audit issues found."
    exit 0
fi

# Start writing the markdown file
echo << 'EOF'
# Audit Issues

EOF

# Process each issue
echo "$ISSUES" | jq -r '.[] | "## Issue #\(.number): \(.title)\n\n**URL**: \(.url)\n\n\(.body)\n\n---\n"'

echo "Audit report generated successfully: $OUTPUT_FILE"
echo "Found $(echo "$ISSUES" | jq '. | length') issue(s)"
