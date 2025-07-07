# Contributing to WEB3-DEX Router Documentation

## Documentation Structure

Following [Uniswap's documentation standards](https://github.com/Uniswap/docs), our documentation is organized into clear sections with consistent patterns.

### Documentation Sections

Each product or feature should include:

1. **Overview** - High-level introduction and architecture
2. **Guides** - Step-by-step implementation examples  
3. **Technical Reference** - Complete API specifications

## Guidelines for Contributors

### Overview Documents

A product overview should address:

✅ **What are the high-level components?**
- Core contracts and their responsibilities
- Architecture diagrams and data flow
- Supported protocols and integrations

✅ **What functionality does the product offer?**
- Key features and use cases
- Supported networks and tokens
- Performance characteristics

✅ **Where does the source code live?**
- Repository structure and key files
- Build and deployment processes
- Version information

✅ **How do developers integrate?**
- Installation and setup requirements
- Contract addresses and configuration
- Example integration patterns

### Implementation Guides

> **Principles of a Good Guide** (adapted from Uniswap):

✅ **Single Concept Focus**
- Each guide demonstrates one reusable concept
- Clear scope and learning objectives
- Minimal cognitive overhead

✅ **Three-Part Structure**
1. **Introduction** - Explains the concept and expected outcomes
2. **Step-by-step Walkthrough** - Detailed implementation with explanations
3. **Testable Output** - Expected results and verification steps

✅ **Code Quality Standards**
- Reference [example repository](https://github.com/WEB3-DEX/examples) code
- Include all parameters (addresses, amounts, tokens) in examples
- Use minimal dependencies (OpenZeppelin, etc.)
- No source code snippets from contracts (link to source instead)

✅ **User Experience**
- **10-minute completion time** as target
- Links and references **only at the bottom**
- Smooth transition to next guide
- Real-world project examples

✅ **Standalone Design**
- Each guide is complete and independent
- No assumptions about previous guides
- Clear prerequisites and setup

### Technical Reference

Technical references should contain:

✅ **Interface Documentation**
- Complete function signatures and parameters
- Return values and error conditions
- Events and their parameters
- Constants and configuration values

✅ **Integration Examples**
- Basic usage patterns
- Advanced integration scenarios
- Common pitfalls and solutions

✅ **Auto-Generation Support**
- Generated from Solidity NatSpec comments
- Consistent formatting and structure
- Version synchronization with source code

## Checklist for Adding Documentation

### Before Writing

- [ ] Identified the correct section (Overview/Guides/Reference)
- [ ] Reviewed existing documentation for patterns
- [ ] Created corresponding example code repository entries
- [ ] Defined clear learning objectives

### Content Creation

- [ ] **Overview**: Covers components, functionality, source location, integration
- [ ] **Guides**: Follow three-part structure with 10-minute completion target
- [ ] **Reference**: Complete interface documentation with examples
- [ ] **Code Examples**: Available in separate repository with working implementations
- [ ] **Links**: All external references placed at document bottom

### Quality Assurance

- [ ] Tested all code examples for correctness
- [ ] Verified 10-minute completion time for guides
- [ ] Checked links and cross-references
- [ ] Ensured consistent formatting and terminology
- [ ] Added proper file naming and organization

### Post-Deployment

- [ ] Updated search indices (if applicable)
- [ ] Cross-linked from related documentation
- [ ] Notified community of new content
- [ ] Monitored for feedback and issues

## Documentation Tools

### Auto-Generation

For technical references, use automated generation:

```bash
# Install documentation generator
npm install solidity-docgen

# Generate from Solidity NatSpec
npx solidity-docgen --solc-module solc-0.8 -t ./templates

# For TypeScript documentation
npm install typedoc typedoc-plugin-markdown
npx typedoc --out docs src/index.ts
```

### Template Structure

```
docs/
├── overview.md                 # Product overview
├── guides/                     # Implementation guides
│   ├── simple-swap.md         # Basic functionality with commission system
│   ├── eth-swap.md           # ETH/WETH handling
│   └── investment.md         # Investment integration
├── reference/                  # Technical documentation
│   ├── interfaces.md          # Contract interfaces
│   ├── events.md             # Events and errors
│   └── examples.md           # Integration examples
├── CONTRIBUTING.md            # This file
└── contract.hbs               # Auto-generation template
```

## Example Workflow

### Adding a New Feature Guide

1. **Create Example Code**
   ```bash
   # In examples repository
   mkdir examples/new-feature
   # Create working implementation
   ```

2. **Write Guide Documentation**
   ```markdown
   ## Introduction
   This guide shows how to implement [concept]...
   
   ## Step-by-Step Implementation
   **Step 1: Setup**
   // Code with inline explanations
   
   ## Expected Output
   - Input: X tokens
   - Output: Y tokens
   - Gas: ~Z units
   ```

3. **Update Cross-References**
   - Link from overview to new guide
   - Add to guides index
   - Reference in related documentation

4. **Test and Review**
   - Verify 10-minute completion
   - Test code examples
   - Review for consistency

## Best Practices

### Writing Style

- Use active voice and present tense
- Include code comments for complex operations
- Explain the "why" not just the "how"
- Provide context for parameter choices

### Code Examples

- Use realistic token addresses and amounts
- Include proper error handling
- Show both success and failure scenarios
- Comment complex calculations or logic

### Maintenance

- Keep documentation synchronized with code changes
- Regularly test example code for correctness
- Update external links and references
- Gather and incorporate user feedback

## Getting Help

- **Questions**: Open an issue in the documentation repository
- **Suggestions**: Submit pull requests with improvements
- **Community**: Join our developer Discord for real-time support
- **Examples**: Refer to [Uniswap docs](https://github.com/Uniswap/docs) for reference patterns

---

*This contributing guide follows Uniswap's documentation standards to ensure consistency and quality across the DeFi ecosystem.* 