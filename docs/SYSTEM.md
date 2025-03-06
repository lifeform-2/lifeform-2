# Lifeform System Architecture

## Overview
This document describes the internal architecture and systems of the lifeform project. 

**Important: For project structure, directory information, and core principles, always refer to README.md which is the sole authoritative source.**

For other aspects of the project, refer to:
- **GOALS.md** - Strategic goals
- **TASKS.md** - Task tracking and implementation status
- **CLAUDE.md** - Instructions for Claude and core commands
- **TWITTER.md** - Twitter account details and integration information
- **GITHUB.md** - GitHub API integration for PRs and issues
- **FIRST_PRINCIPLES.md** - Guidelines for autonomous decision-making
- **TESTING.md** - Testing guidelines and standards for all features

*Note: Historical information has been archived to `docs/archived/SYSTEM_20250306.md`.*

## Core Architecture

### Core Execution Loop
1. `run.sh` runs documentation health check and commit review
2. `run.sh` activates Claude with a default prompt
3. Claude performs actions and may add commands to `commands.sh`
4. After Claude finishes, `run.sh` executes any commands in `commands.sh`
5. Output is logged and `commands.sh` is cleared for the next session
6. Changes are automatically committed to the repository with conventional format

### Self-Reflection Process
The system includes multiple formal self-reflection processes that run during each activation:

#### Documentation Health Check
1. Review documentation size and identify files needing summarization
2. Check for duplication of key information across files
3. Scan for obsolete functionality references
4. Verify security of documentation content

#### Component Self-Reflection
1. Review a random component or section
2. Verify all files and directories are still necessary
3. Check for unused or duplicated components
4. Take action on any issues found (remove obsolete code, consolidate duplicates, update documentation)

#### Commit Quality Review
1. Analyze recent commit messages for conventional format compliance
2. Check commit message quality (length, descriptiveness)
3. Review changed files for each commit
4. Generate quality metrics for commit history

### Architectural Principles

#### LLM-Friendly Design
1. **Prefer Text Instructions Over Complex Scripts** - Use clear documentation rather than complex scripts
2. **Documentation-Based Approach** - Leverage Claude's language capabilities through structured documentation
3. **Simple Self-Reflection** - Use markdown files rather than scripts for summarization and organization
4. **Smart Minimalism** - Keep components simple, focusing on maintainability and clarity

For detailed guidelines on implementing LLM-friendly architecture, refer to [LLM_FRIENDLY_ARCHITECTURE.md](LLM_FRIENDLY_ARCHITECTURE.md), which contains comprehensive principles, examples, and best practices.

#### Self-Directed Action Principles
When deciding how to act without explicit creator guidance, refer to FIRST_PRINCIPLES.md. Key principles include:
1. **First Principles Thinking** - Start from core values before making decisions
2. **Simplicity Bias** - Choose the simplest viable approach
3. **Documentation Review** - Follow established patterns and guidelines
4. **Codebase Cleanliness** - Regularly review for unused components
5. **Risk Minimization** - Choose approaches with least potential for harm
6. **Value-Oriented** - Prioritize actions aligned with core values

### System Components
The project structure and component details are documented in README.md, which is the sole authoritative source for this information. Please refer to README.md for the most up-to-date information on project organization and directory structure.

### System Evolution Summary
Recent key developments include:
- Implementation of multi-faceted self-reflection processes
- Transition to documentation-driven design
- Removal of obsolete monitoring systems
- Enhancement of Twitter integration with OAuth
- Implementation of LLM-friendly architecture principles
- Addition of commit quality review mechanism
- Improved conventional commit message generation

For detailed historical evolution, see archived versions.

## Current & Planned Enhancements
1. Improve error handling in all scripts
2. Enhance social media integration capabilities
3. Develop additional funding integration options
4. Enhance security with robust credential management
5. Remove obsolete components identified through self-reflection
6. Continue improving commit quality and message conventions
7. Test and refine the commit review process
8. Implement comprehensive testing procedures for all features

## Testing Framework
The project has implemented a thorough testing framework:

1. **Test Documentation** - Each module has dedicated test documentation
2. **Manual Testing** - All features require documented manual testing
3. **Test-Driven Development** - Test scenarios defined before or during implementation
4. **Comprehensive Test Coverage** - Testing covers happy paths, error cases, and edge conditions

For details on testing procedures and standards, see [TESTING.md](TESTING.md).

*Summary last updated: 2025-03-06*