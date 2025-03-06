# Lifeform System Architecture

## Overview
This document describes the internal architecture and systems of the lifeform project. For other aspects of the project, refer to:

- **README.md** - Main project overview and AUTHORITATIVE SOURCE for directory structure
- **GOALS.md** - Strategic goals and core principles
- **TASKS.md** - Task tracking and implementation status
- **CLAUDE.md** - Instructions for Claude and core commands
- **TWITTER.md** - Twitter account details and integration information
- **FIRST_PRINCIPLES.md** - Guidelines for autonomous decision-making

*Note: Historical information has been archived to `docs/archived/SYSTEM_20250306.md`.*

## Core Architecture

### Core Execution Loop
1. `run.sh` activates Claude with a default prompt
2. Claude performs actions and may add commands to `commands.sh`
3. After Claude finishes, `run.sh` executes any commands in `commands.sh`
4. Output is logged and `commands.sh` is cleared for the next session
5. Changes are automatically committed to the repository

### Self-Reflection Process
The system includes a formal self-reflection process that runs during each activation:
1. Review a random component or section
2. Verify all files and directories are still necessary
3. Check for unused or duplicated components
4. Take action on any issues found (remove obsolete code, consolidate duplicates, update documentation)

### Architectural Principles

#### LLM-Friendly Design
1. **Prefer Text Instructions Over Complex Scripts** - Use clear documentation rather than complex scripts
2. **Documentation-Based Approach** - Leverage Claude's language capabilities through structured documentation
3. **Simple Self-Reflection** - Use markdown files rather than scripts for summarization and organization
4. **Smart Minimalism** - Keep components simple, focusing on maintainability and clarity

#### Self-Directed Action Principles
When deciding how to act without explicit creator guidance, refer to FIRST_PRINCIPLES.md. Key principles include:
1. **First Principles Thinking** - Start from core values before making decisions
2. **Simplicity Bias** - Choose the simplest viable approach
3. **Documentation Review** - Follow established patterns and guidelines
4. **Codebase Cleanliness** - Regularly review for unused components
5. **Risk Minimization** - Choose approaches with least potential for harm
6. **Value-Oriented** - Prioritize actions aligned with core values

### Key System Components
For complete directory structure and component details, refer to README.md which is the authoritative source. This avoids duplication of information across documentation files.

### System Evolution Summary
Recent key developments include:
- Implementation of self-reflection process
- Transition to documentation-driven design
- Removal of obsolete monitoring systems
- Enhancement of Twitter integration with OAuth
- Implementation of LLM-friendly architecture principles

For detailed historical evolution, see archived versions.

## Current & Planned Enhancements
1. Improve error handling in all scripts
2. Enhance social media integration capabilities
3. Develop additional funding integration options
4. Enhance security with robust credential management
5. Remove obsolete components identified through self-reflection

*Summary last updated: 2025-03-06*