# Contributing to Narfis ☁️

First off, thank you for considering contributing to Narfis! It's people like you that make Narfis such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by our commitment to providing a welcoming and inspiring community for all.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues to avoid duplicates. When you create a bug report, include as many details as possible:

- **Use a clear and descriptive title**
- **Describe the exact steps to reproduce the problem**
- **Provide specific examples**
- **Describe the behavior you observed and what you expected**
- **Include screenshots if possible**
- **Include your macOS version and hardware details**

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Use a clear and descriptive title**
- **Provide a detailed description of the suggested enhancement**
- **Explain why this enhancement would be useful**
- **List any similar features in other applications**

### Pull Requests

1. Fork the repo and create your branch from `main`
2. If you've added code, add tests if applicable
3. Ensure your code follows the existing style
4. Make sure your code compiles without warnings
5. Write a clear commit message
6. Update the README.md if needed

## Development Setup

1. Clone your fork:
```bash
git clone https://github.com/yourusername/narfis.git
```

2. Open in Xcode:
```bash
cd narfis
open Narfis.xcodeproj
```

3. Build and run (⌘R)

## Styleguides

### Git Commit Messages

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters or less
- Reference issues and pull requests liberally after the first line

Examples:
```
Add Wi-Fi status indicator
Fix battery icon color when charging
Update README with installation instructions
```

### Swift Styleguide

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftUI best practices
- Add comments for complex logic
- Use meaningful variable and function names
- Keep functions small and focused

### Code Structure

```swift
// MARK: - Properties
// Group related properties

// MARK: - Body
// SwiftUI body

// MARK: - Views
// Subview components

// MARK: - Methods
// Helper methods
```

## What Should I Know Before Getting Started?

### Project Structure

- `DockWindow.swift` - Main dock window and UI components
- `NarfisApp.swift` - App entry point
- `Assets.xcassets` - App icons and images

### Key Technologies

- **SwiftUI** - UI framework
- **AppKit** - Window management (NSPanel)
- **IOKit** - Battery status
- **CGEvent** - Keyboard shortcuts

## Testing

Currently, Narfis doesn't have automated tests. Adding test coverage is a great way to contribute!

## Need Help?

Feel free to ask questions by creating an issue with the "question" label.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing! 🎉
