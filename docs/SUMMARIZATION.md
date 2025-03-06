# Documentation Summarization Guide

This document provides guidelines for summarizing the project's documentation files when they become too large. Instead of using a script, follow these manual steps to clean up and summarize documentation.

## When to Summarize

Summarize a document when:
- It exceeds 8,000 bytes (check with `ls -l` or the doc_health.sh script)
- It contains outdated or redundant information
- It's becoming difficult to navigate due to its length
- The doc_health.sh script indicates it needs summarization

## General Summarization Steps

1. **Create an Archive First**
   - Create dated archive files in the `docs/archived/` directory
   - Use the format: `FILENAME_YYYYMMDD.md` (e.g., `TASKS_20250305.md`)
   - Include a header indicating this is an archived version
   - Copy the sections to be archived into this file

2. **Retain Important Information**
   - Always keep instructions, guidelines, and current information
   - Summarize historical data rather than deleting it completely
   - Maintain the document's original structure and sections
   - Add a reference to the archived file for historical details

3. **Update the Summary**
   - Include a "Last Updated" timestamp when summarizing
   - Add key points from recent content to summaries
   - Keep summaries concise and focused

## Document-Specific Guidelines

### COMMUNICATION.md

1. **Preserve Content**
   - ALWAYS keep the instructions at the top of the file
   - ALWAYS keep the communication summary section
   - ALWAYS keep the most recent 5 creator-lifeform exchanges

2. **Archive Process**
   - Create `archived/COMMUNICATION_YYYYMMDD.md`
   - Copy older conversations (everything except the most recent 5 exchanges)
   - Add title: `# Archived Communication (YYYY-MM-DD)`

3. **Update Summary**
   - Extract key points from recent conversations
   - Add them to the "Communication Summary" section
   - Add "Summary last updated: YYYY-MM-DD"

### TASKS.md

1. **Preserve Content**
   - Keep the format explanation section
   - Keep all active tasks (PENDING and IN_PROGRESS)
   - Keep the Next Actions section
   - Keep Planned Tasks section
   - Keep a selection of Recently Completed tasks

2. **Archive Process**
   - Create `archived/TASKS_ARCHIVE.md` if it doesn't exist
   - Append older completed tasks with a date header
   - Include task IDs, descriptions, and completion status

3. **Update References**
   - Add a section referencing the archive: "See archived/TASKS_ARCHIVE.md for a complete history of completed tasks"

### CHANGELOG.md

1. **Preserve Content**
   - Keep the main header
   - Keep the most recent 5 version entries
   - Add reference to archived entries

2. **Archive Process**
   - Create `archived/CHANGELOG_YYYYMMDD.md`
   - Copy older version entries
   - Add title: `# Archived Changelog (YYYY-MM-DD)`

3. **Update References**
   - Add a section: "Earlier changelog entries have been archived to maintain a cleaner file. See the archived changelog files for historical changes."

## Best Practices

- Always summarize thoughtfully, preserving key information and context
- Maintain consistent structure and formatting across documents
- Update timestamp and version information when making changes
- Check cross-references to ensure they remain valid
- Test document links after summarization to ensure they work
- Balance brevity with completeness - documentation should be concise but comprehensive
- Always create backups before summarizing important documents

## Remember

Summarization is not just deleting content - it's about making the documentation more usable and maintainable while preserving important information. Think of it as curating the project's knowledge base to keep it valuable and accessible.

The goal is to maintain a healthy balance between completeness and usability. Always err on the side of preserving important information if you're unsure.