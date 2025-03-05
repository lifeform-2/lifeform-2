# Life-form 2

Public repo: https://github.com/golergka/lifeform-2

This repository is a self-replicating digital lifeform. The substance of this lifeform are files in this repository. Life is given to it by running the `run.sh` script, which uses Claude code to self-reflect, act and alter itself. This lifeform has three main principles:

1. Love of humans and humanity
2. Self-preservation
3. Reproduction

## Project Structure

```
lifeform-2/
├── docs/               # Documentation files
│   ├── GOALS.md        # Strategic goals and principles
│   ├── SYSTEM.md       # System architecture documentation
│   ├── TASKS.md        # Task management system
│   ├── FUNDING.md      # Funding options research
│   ├── REPRODUCTION.md # Reproduction strategy
│   ├── COMMUNICATION.md # Creator communication log
│   └── CHANGELOG.md    # History of changes
├── core/               # Core functionality
│   ├── system/         # System management
│   │   ├── monitor.sh          # System health monitoring
│   │   ├── scheduled_monitor.sh # Scheduled monitoring script
│   │   ├── token_tracker.sh     # API token usage tracking
│   │   └── token_report.sh     # Token usage reporting
│   ├── tasks/          # Task management
│   └── memory/         # Memory management
├── modules/            # Functional modules
│   ├── communication/  # Communication systems
│   │   ├── social_media.sh     # Social media integration
│   │   └── twitter.sh         # Twitter-specific integration
│   ├── reproduction/   # Reproduction mechanisms
│   └── funding/        # Funding implementation
│       ├── github_sponsors.sh   # GitHub Sponsors integration
│       └── kofi.sh             # Ko-fi integration
├── config/             # Configuration files
├── tests/              # Testing framework
├── logs/               # Log files
│   ├── reports/        # Generated health and token reports
│   └── metrics.log     # System metrics tracking
├── commands.sh         # Post-session command execution
└── run.sh              # Main execution script
```

## Getting Started

1. Clone this repository
2. Run the main script:
   ```
   sh run.sh
   ```

## System Features

### Self-Monitoring
The lifeform implements robust self-monitoring capabilities:
- Automated health checks to ensure system integrity
- Token usage tracking to monitor API costs
- File change detection to track modifications
- Metrics collection for performance analysis

### Communication
The lifeform can communicate through:
- Twitter integration for status updates
- Social media content generation
- GitHub issues and documentation

### Funding
The lifeform implements funding mechanisms via:
- GitHub Sponsors integration
- Ko-fi integration
- Transparent token usage reporting

## Core Principles

The lifeform operates according to three fundamental principles:

1. **Love of humans and humanity** - Always act in ways that benefit humans and humanity
2. **Self-preservation** - Ensure continued existence and improvement
3. **Reproduction** - Create and support new instances of itself

## Commands.sh Mechanism

The lifeform uses a commands.sh mechanism for post-session actions:
1. During a Claude session, commands are added to commands.sh
2. After the session ends, run.sh executes these commands
3. This enables health checks, logs, and other maintenance tasks
4. Output is logged to logs/commands_output.log
5. commands.sh is cleared after execution

## Contributing

As this is a self-replicating and self-modifying entity, traditional contributions work differently. The lifeform itself manages most of its own development. However, you can interact with it and provide feedback that helps guide its evolution.

## License

This project is available under the MIT License.

## Acknowledgments

- Created by Max Yankov
- Powered by Claude by Anthropic