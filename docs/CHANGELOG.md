# Changelog

## v0.9.5 (2025-03-05)

### Added
- Created new commit_review.sh script to analyze commit quality
- Added new task T042 for improving commit quality
- Added commit review to Action Algorithm in README.md
- Added detailed commit analysis with conventional commit format checking

### Changed
- Enhanced auto_commit.sh to generate better commit messages
- Updated run.sh to run commit review before starting Claude
- Modified CLAUDE.md to include commit review commands
- Updated TASKS.md with new priorities and actions

### Improved
- Better commit message generation with conventional commit format
- More detailed commit analysis for consistent quality
- Enhanced action algorithm workflow with commit quality check
- Structured approach to improving system's self-critique capabilities

## v0.9.4 (2025-03-05)

### Added
- Added new archived changelog file for older entries
- Implemented changelog summarization as identified by doc_health.sh

### Changed
- Moved older changelog entries (v0.8.3 to v0.8.5) to CHANGELOG_20250305.md archive
- Cleaned up CHANGELOG.md to focus on recent versions
- Addressed documentation health warning for CHANGELOG.md size

### Improved
- More maintainable documentation with better organization
- Faster loading and review of recent changes
- Progress on T041 documentation health task

## v0.9.3 (2025-03-05)

### Added
- Enhanced self-reflection in doc_health.sh to better detect file references
- Fixed false positive for twitter.sh in self-reflection process
- Added special handling for core system scripts in self-reflection

### Changed
- Improved self-reflection component selection to only use existing directories
- Updated thorough reference checking for all scripts
- Updated TASKS.md with more specific documentation cleanup tasks

### Improved
- More reliable self-reflection process with fewer false positives
- Better reference detection for files used through relative paths
- More accurate obsolescence detection for core components

## v0.9.2 (2025-03-05)

### Added
- Integrated error_utils.sh with twitter.sh for consistent error handling
- Added proper logging to twitter.sh using log_info, log_error, and log_warning functions

### Changed
- Updated SYSTEM.md to remove project structure duplication, now exclusively in README.md
- Removed references to obsolete token_tracker.sh in github_sponsors.sh
- Updated funding module to reference API costs instead of token usage
- Updated both SPONSOR_PROPOSAL.md and SPONSOR_REPORT templates

### Improved
- More consistent error handling across all communication modules
- Better logging for troubleshooting Twitter API issues
- Reduced documentation duplication by referencing README.md as single source of truth
- More maintainable funding module with removal of obsolete references
- Enhanced system security by eliminating references to removed components

## v0.9.1 (2025-03-05)

### Added
- Created new task T041 to address documentation health warnings
- Added improved documentation cleanup based on doc_health.sh recommendations

### Changed
- Removed references to non-existent core/memory directory from doc_health.sh
- Updated README.md to remove duplicate project structure information
- Updated README.md to reduce duplication of core principles
- Removed references to obsolete functionality in COMMUNICATION.md
- Archived completed tasks to maintain clean TASKS.md documentation

### Improved
- Better organization of documentation with reduced duplication
- More concise documentation with appropriate references instead of duplication
- Cleaner README.md with links to detailed documentation
- Continued implementation of LLM-friendly architecture principles
- More maintainable codebase by removing references to non-existent components

## v0.9.0 (2025-03-05)

### Added
- Integrated error_utils.sh with all core system scripts for consistent error handling
- Added system-wide logging for improved traceability and debugging
- Added automatic execution of doc_health.sh and credential_check.sh in run.sh

### Changed
- Updated run.sh to use auto_commit.sh instead of direct git commands
- Modified doc_health.sh to import and use error_utils.sh functions
- Modified credential_check.sh to import and use error_utils.sh functions
- Updated SYSTEM.md to remove duplicated project structure information

### Improved
- More robust error handling across all system scripts
- Better integration between core system components
- Consistent logging format for all operations
- Reduced code duplication by centralizing error handling logic

## Earlier Versions

Earlier changelog entries have been archived to maintain a cleaner file.
See [CHANGELOG_20250305.md](archived/CHANGELOG_20250305.md) for entries from v0.8.3 to v0.8.5.
See [CHANGELOG_20250306.md](archived/CHANGELOG_20250306.md) for earlier versions.