# AI Skills

This directory contains custom AI skills for the project.

## Available Skills

### `golang-standards.md`
Reviews Go code for idiomatic patterns, best practices, and coding standards. Use this for human-readable feedback on code quality that goes beyond what automated linters provide.

## How to Use Skills

Skills are invoked by referencing them in your conversation with the AI. The AI will follow the instructions in the skill file to provide specialized assistance.

Example:
```
Using the golang-standards skill, review this function:
[paste your code]
```

## Creating New Skills

To create a new skill:
1. Create a new `.md` file in this directory
2. Include a clear description and usage instructions
3. Provide specific instructions for the AI on how to execute the skill
4. Document any standards, references, or examples

