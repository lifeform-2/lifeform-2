# Changelog

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

## v0.8.5 (2025-03-05)

### Fixed
- Fixed syntax error in error_utils.sh security pattern checking
- Updated TASKS.md to move completed documentation task to recently completed section

### Changed
- Completed task T039 for cleaning up documentation duplication
- Updated doc_health.sh to be more precise in detecting obsolete references

### Improved
- More reliable command execution with better security pattern validation 
- Better organization of completed tasks in TASKS.md

## v0.8.4 (2025-03-05)

### Changed
- Updated SYSTEM.md to remove duplicated project structure information
- Updated CLAUDE.md to reference README.md for commands.sh mechanism details
- Updated REPRODUCTION.md to reference core principles from README.md
- Updated TASKS.md to mark documentation cleanup task as in progress
- Improved documentation health check to better identify obsolete references
- Modified COMMUNICATION.md to remove references to deprecated functionality

### Improved
- Reduced documentation duplication across multiple files
- Better adherence to the principle of having a single source of truth
- Cleaner documentation maintenance by centralizing common information
- More consistent references to core principles and architecture
- More precise detection of obsolete functionality references

## v0.8.3 (2025-03-05)

### Added
- Added comprehensive security scanning to credential_check.sh
- Added new security vulnerability patterns detection
- Added improved command execution security in safe_exec() function
- Added new security scan commands to CLAUDE.md
- Added new task T039 for cleaning up documentation duplication

### Changed
- Enhanced error_utils.sh with safer command execution
- Updated TASKS.md to mark security enhancements as completed
- Updated Next Actions in TASKS.md to prioritize documentation cleanup
- Updated CLAUDE.md with new security scan command references

### Improved
- Better security scanning for potential vulnerabilities
- More comprehensive credential and security checks
- Safer execution of commands with input validation
- Clearer security-related documentation and guidelines

## Earlier Versions

Earlier changelog entries have been archived to maintain a cleaner file.
See [CHANGELOG_20250305.md](archived/CHANGELOG_20250305.md) for historical changes.