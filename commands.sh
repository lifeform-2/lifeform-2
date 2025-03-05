#!/bin/bash
# Post-session commands for lifeform-2

# Generate updated health report
./core/system/monitor.sh health

# Track this session's token usage (rough estimate)
./core/system/token_tracker.sh log "doc_improvement_$(date +"%Y%m%d%H%M%S")" "2000" "8000"

# Update CHANGELOG.md with latest changes
echo "## $(date +"%Y-%m-%d") - Documentation Improvements

- Reduced documentation duplication across multiple files
- Restructured SYSTEM.md to focus on technical details with proper cross-references
- Reorganized GOALS.md to separate strategic goals from implementation details
- Updated TASKS.md to reflect documentation improvement progress
- Created milestone tweet announcing documentation improvements

" > /tmp/changelog_entry.txt
cat /tmp/changelog_entry.txt $(cat ./docs/CHANGELOG.md) > /tmp/new_changelog.md
cp /tmp/new_changelog.md ./docs/CHANGELOG.md

echo "Post-session commands completed successfully"