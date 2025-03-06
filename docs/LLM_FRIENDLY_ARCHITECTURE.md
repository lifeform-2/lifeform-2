# LLM-Friendly Architecture Guidelines

## Overview
This document provides specific guidelines for creating and maintaining an LLM-friendly architecture. These principles help make the codebase more accessible to language models like Claude, enabling more effective system evolution and self-maintenance.

## Core Principles

### 1. Documentation Over Complexity
- **Prefer text instructions over complex scripts** for tasks that require reasoning
- Use documentation-driven approaches for tasks that benefit from natural language understanding
- Create clear guidelines that leverage the LLM's language comprehension abilities

### 2. Simplified Script Architecture
- Keep scripts focused on a single responsibility
- Use consistent patterns and naming conventions
- Maintain clear separation between logic and configuration
- Prefer declarative approaches over imperative when possible
- Add comprehensive comments explaining "why" not just "what"

### 3. Error Handling and Logging
- Implement consistent error handling across all scripts
- Use the shared error_utils.sh library for standardized logging
- Provide clear, actionable error messages
- Include context in error messages to aid debugging

### 4. Configuration Management
- Externalize configuration from scripts
- Use environment variables or configuration files
- Document all configuration options thoroughly
- Provide sensible defaults for optional settings

### 5. Modularity and Reusability
- Break functionality into logical, reusable components
- Use shared utilities across the system
- Create modules that encapsulate specific functionality
- Allow modules to be used independently

## Implementation Examples

### Example 1: Task Guidelines vs. Task Scripts
Instead of building complex automation for task prioritization:
- Create a TASKS.md file with clear formatting guidelines
- Document the prioritization criteria in plain text
- Let the LLM apply this logic during its decision-making

### Example 2: Documentation Health
For documentation maintenance:
- Create SUMMARIZATION.md with comprehensive guidelines
- Provide examples and criteria for when/how to summarize
- Allow the LLM to apply judgment rather than hard-coding rules

### Example 3: Simplified Script Architecture
For utility scripts like credential checking:
- Clear separation between configuration variables and logic
- Consistent logging via shared utilities
- Comprehensive inline documentation
- Focus on a single responsibility

## Applying These Principles

When evaluating whether a component follows LLM-friendly principles, ask:
1. Could this logic be better expressed as documentation guidelines?
2. Is the script simple enough that an LLM can easily understand and modify it?
3. Are configuration parameters externalized and well-documented?
4. Is there clear separation of concerns between different functions?
5. Are error messages clear and actionable?
6. Are shared utilities being leveraged appropriately?

## Best Practices for Scripting

When scripts are necessary, follow these best practices:
- Write scripts with clear structure and extensive comments
- Divide complex scripts into logical sections with descriptive headers
- Use consistent error handling and logging
- Create inline documentation explaining the purpose of each section
- Keep individual functions small and focused
- Use descriptive variable and function names
- Provide usage examples in script headers

## Converting Existing Scripts

When converting existing scripts to be more LLM-friendly:
1. First assess if the script's functionality could be replaced with guidelines
2. If a script is still needed, externalize configuration
3. Refactor to use shared utilities like error_utils.sh
4. Add comprehensive comments
5. Simplify complex logic
6. Create documentation that explains the script's purpose and usage

*Last updated: 2025-03-05*