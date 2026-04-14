# Contributing to notApollo

Thank you for your interest in contributing to the notApollo network diagnostic tool! This document provides guidelines for contributing to the project.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment for all contributors. Please be respectful and constructive in all interactions.

## Getting Started

### Prerequisites

- OpenWrt development environment or access to OpenWrt router
- Basic knowledge of shell scripting, HTML/CSS/JavaScript
- Git for version control
- Understanding of networking concepts (helpful but not required)

### Development Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/yourusername/notapollo.git
   cd notapollo
   ```

2. **Set up development environment:**
   ```bash
   cd www/notapollo
   ./scripts/setup-build.sh
   ./scripts/download-assets.sh
   ```

3. **Start local development server:**
   ```bash
   ./scripts/serve-local.sh
   ```

## Development Workflow

### Branch Strategy

- `main` - Production-ready code
- `develop` - Integration branch for features
- `feature/feature-name` - Individual feature development
- `bugfix/issue-description` - Bug fixes
- `hotfix/critical-fix` - Critical production fixes

### Automated Builds

The project uses GitHub Actions for continuous integration:

- **Pull Requests**: Automatically build and test packages for all supported platforms
- **Main Branch**: Build packages and create development releases
- **Tagged Releases**: Create official releases with pre-built packages and installation scripts

**Supported Platforms:**
- OpenWrt 23.05.4 and 24.10.0
- Architectures: ramips/mt76x8 (ASUS RT-AX53U), x86/64

### Making Changes

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Set up development environment:**
   ```bash
   ./scripts/quick-start.sh --setup-only
   ```

3. **Make your changes following our coding standards**

4. **Test your changes thoroughly:**
   ```bash
   ./scripts/test.sh
   ```

5. **Commit with descriptive messages:**
   ```bash
   git commit -m "feat: add DNS cache performance monitoring
   
   - Implement cache hit rate calculation
   - Add performance optimization logic
   - Update API response format"
   ```

6. **Push and create a pull request**

The GitHub Actions workflow will automatically:
- Build packages for all supported platforms
- Run tests and quality checks
- Verify asset downloads work correctly
- Test installation scripts

## Coding Standards

### Google Code Style Guidelines

This project follows Google's coding style guidelines:

#### JavaScript
- Use 2-space indentation
- Use single quotes for strings
- Use camelCase for variables and functions
- Use PascalCase for constructors and classes
- Maximum line length: 80 characters
- Use JSDoc for function documentation

```javascript
/**
 * Calculates DNS cache hit rate from log data.
 * @param {Array<string>} logLines - Array of log entries
 * @return {number} Cache hit rate as decimal (0.0 to 1.0)
 */
function calculateCacheHitRate(logLines) {
  const totalQueries = logLines.length;
  const cacheHits = logLines.filter(line => line.includes('cached')).length;
  return totalQueries > 0 ? cacheHits / totalQueries : 0;
}
```

#### CSS
- Use 2-space indentation
- Use kebab-case for class names
- Group related properties together
- Use CSS custom properties for theming

```css
.diagnostic-card {
  background: var(--md-sys-color-surface);
  border-radius: 12px;
  padding: 16px;
  margin: 8px;
  
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.12);
  transition: box-shadow 0.2s ease;
}

.diagnostic-card:hover {
  box-shadow: 0 4px 8px rgba(0, 0, 0, 0.12);
}
```

#### Shell Scripts
- Use 2-space indentation
- Use lowercase with underscores for variables
- Quote all variable expansions
- Use `#!/bin/sh` for maximum compatibility

```bash
#!/bin/sh
# DNS monitoring script with cache integration

get_cache_performance() {
  local log_file="/tmp/dnsmasq.log"
  local total_queries=0
  local cache_hits=0
  
  if [ -f "$log_file" ]; then
    total_queries=$(grep -c "query" "$log_file")
    cache_hits=$(grep -c "cached" "$log_file")
  fi
  
  if [ "$total_queries" -gt 0 ]; then
    echo "scale=2; $cache_hits / $total_queries" | bc
  else
    echo "0"
  fi
}
```

#### HTML
- Use 2-space indentation
- Use semantic HTML5 elements
- Include proper ARIA attributes for accessibility
- Use lowercase for element and attribute names

```html
<section class="diagnostic-section" role="region" aria-labelledby="dns-heading">
  <h2 id="dns-heading" class="section-title">DNS Services</h2>
  <div class="diagnostic-card" role="article">
    <div class="status-indicator" aria-label="DNS status: healthy">🟢</div>
    <p class="status-message">Website lookups are working fast</p>
  </div>
</section>
```

### Material 3 Design Compliance

- Use Material 3 color tokens and design tokens
- Implement proper elevation and shadows
- Follow Material 3 typography scale
- Use appropriate motion and transitions
- Ensure 44px minimum touch targets for mobile

### User-Friendly Language Requirements

All user-facing text must be in plain, non-technical language:

```javascript
// Good: User-friendly language
const statusMessages = {
  wan_up: "Internet connection is working",
  wan_down: "Internet connection is not working",
  high_latency: "Websites are loading slowly",
  packet_loss: "Some data is getting lost on the way"
};

// Bad: Technical jargon
const statusMessages = {
  wan_up: "WAN interface operational",
  wan_down: "WAN link down",
  high_latency: "RTT exceeds baseline threshold",
  packet_loss: "Packet drop rate elevated"
};
```

## Testing Guidelines

### Unit Testing

Write tests for all new functionality:

```javascript
// Example test structure
describe('DNS Cache Performance', () => {
  it('should calculate cache hit rate correctly', () => {
    const logLines = [
      'query google.com',
      'cached google.com',
      'query facebook.com',
      'query twitter.com'
    ];
    
    const hitRate = calculateCacheHitRate(logLines);
    expect(hitRate).toBe(0.25);
  });
  
  it('should handle empty logs gracefully', () => {
    const hitRate = calculateCacheHitRate([]);
    expect(hitRate).toBe(0);
  });
});
```

### Integration Testing

Test complete workflows:

```bash
#!/bin/sh
# Integration test for DNS monitoring

test_dns_monitoring() {
  echo "Testing DNS monitoring functionality..."
  
  # Test API endpoint
  response=$(curl -s "http://127.0.0.1:8080/api/diagnostics/dns")
  status=$(echo "$response" | jq -r '.status')
  
  if [ "$status" = "healthy" ]; then
    echo "✓ DNS monitoring test passed"
    return 0
  else
    echo "✗ DNS monitoring test failed"
    return 1
  fi
}
```

### Manual Testing Checklist

Before submitting a pull request, verify:

- [ ] Functionality works on both network interfaces (192.168.69.1, 192.168.70.1)
- [ ] Mobile responsive design works correctly
- [ ] Real-time updates function properly
- [ ] Charts render correctly on different screen sizes
- [ ] User-friendly language is used throughout
- [ ] Dark theme displays correctly
- [ ] API endpoints return proper JSON responses
- [ ] Error handling works gracefully
- [ ] Performance is acceptable on OpenWrt hardware

## Documentation Requirements

### Code Documentation

- Document all public functions with JSDoc
- Include usage examples for complex functions
- Document API endpoints with request/response examples
- Update README.md for significant changes

### User Documentation

- Update user guides for new features
- Include screenshots for UI changes
- Provide troubleshooting information
- Update installation instructions if needed

## Submitting Changes

### Pull Request Process

1. **Ensure your branch is up to date:**
   ```bash
   git checkout main
   git pull origin main
   git checkout feature/your-feature
   git rebase main
   ```

2. **Run all tests and verify functionality**

3. **Create a detailed pull request:**
   - Use descriptive title and description
   - Reference related issues
   - Include screenshots for UI changes
   - List breaking changes if any

### Pull Request Template

```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] Bug fix (non-breaking change that fixes an issue)
- [ ] New feature (non-breaking change that adds functionality)
- [ ] Breaking change (fix or feature that would cause existing functionality to not work as expected)
- [ ] Documentation update

## Testing
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Tested on both network interfaces
- [ ] Mobile responsive design verified

## Screenshots (if applicable)
Include screenshots of UI changes.

## Checklist
- [ ] Code follows Google style guidelines
- [ ] Self-review of code completed
- [ ] Code is commented, particularly in hard-to-understand areas
- [ ] Corresponding changes to documentation made
- [ ] No new warnings introduced
- [ ] User-friendly language used for all user-facing text
```

## Issue Reporting

### Bug Reports

Use the bug report template:

```markdown
**Describe the bug**
A clear description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. See error

**Expected behavior**
What you expected to happen.

**Screenshots**
If applicable, add screenshots.

**Environment:**
- OpenWrt version: [e.g. 22.03.2]
- Router model: [e.g. ASUS RT-AX53U]
- Browser: [e.g. Chrome 91]
- Network: [Primary/Guest]

**Additional context**
Any other context about the problem.
```

### Feature Requests

Use the feature request template:

```markdown
**Is your feature request related to a problem?**
A clear description of what the problem is.

**Describe the solution you'd like**
A clear description of what you want to happen.

**Describe alternatives you've considered**
Alternative solutions or features you've considered.

**Additional context**
Any other context or screenshots about the feature request.
```

## Community Guidelines

### Communication

- Use GitHub issues for bug reports and feature requests
- Use GitHub discussions for questions and general discussion
- Be respectful and constructive in all interactions
- Help others when possible

### Recognition

Contributors will be recognized in:
- CONTRIBUTORS.md file
- Release notes for significant contributions
- Project documentation

## Development Resources

### Useful Links

- [OpenWrt Developer Guide](https://openwrt.org/docs/guide-developer/start)
- [Material 3 Design System](https://m3.material.io/)
- [Google JavaScript Style Guide](https://google.github.io/styleguide/jsguide.html)
- [Google HTML/CSS Style Guide](https://google.github.io/styleguide/htmlcssguide.html)

### Tools and Utilities

- [ESLint](https://eslint.org/) for JavaScript linting
- [Prettier](https://prettier.io/) for code formatting
- [JSDoc](https://jsdoc.app/) for documentation generation
- [Chart.js](https://www.chartjs.org/) for data visualization

### Testing Tools

- [Jest](https://jestjs.io/) for JavaScript unit testing
- [Cypress](https://www.cypress.io/) for end-to-end testing
- [Lighthouse](https://developers.google.com/web/tools/lighthouse) for performance testing

## Questions?

If you have questions about contributing:

1. Check existing documentation
2. Search existing issues and discussions
3. Create a new discussion for general questions
4. Create an issue for specific problems

Thank you for contributing to notApollo!