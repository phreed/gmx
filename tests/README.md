# GMX Test Suite

This directory contains comprehensive tests for the GMX (Graphical Message eXchange) application.

## Test Structure

```
tests/
├── __init__.py         # Test package initialization
├── test_gmx.py         # Main test suite
└── README.md           # This file
```

## Test Coverage

The test suite covers the following components:

### 1. Project Structure Tests
- Verifies required directories exist (`haxe/`, `examples/`, etc.)
- Checks for essential files (`pixi.toml`, `README.asciidoc`, etc.)
- Validates Haxe source structure

### 2. XML Validation Tests
- **Layout files**: `examples/layouts/*.xml`
- **Record files**: `examples/records/*.xml`
- **Collection files**: `examples/collections/*.xml` (multi-document format)
- Ensures all XML is well-formed and parseable

### 3. Server Functionality Tests
- **Layout Server** (port 12345): Tests layout retrieval and management
- **Data Server** (port 12346): Tests record and collection operations
- Socket communication and message protocols
- Server startup, response validation, and cleanup

### 4. Build System Tests
- **Pixi configuration**: Validates task definitions and dependencies
- **Haxe compilation**: Checks code compilation (with known limitations)
- Task execution and error handling

### 5. Integration Tests
- Cross-server communication
- Layout-to-record binding validation
- End-to-end message flow testing

## Running Tests

### Quick Start
```bash
# Run all tests
python tests/test_gmx.py

# Verbose output
python tests/test_gmx.py --verbose

# Server tests only (fastest)
python tests/test_gmx.py --server-only

# Quick tests (skips compilation)
python tests/test_gmx.py --quick
```

### Test Modes

| Mode | Description | Duration | Use Case |
|------|-------------|----------|----------|
| **Default** | Full test suite | ~15-20s | Complete validation |
| **Server-only** | Server tests only | ~7-10s | CI/CD pipelines |
| **Quick** | Skips compilation tests | ~10-12s | Development |
| **Verbose** | Detailed output | Variable | Debugging |

### Expected Results

#### Fully Functional (Server-side)
- ✅ Project structure validation
- ✅ XML file validation
- ✅ Layout server functionality
- ✅ Data server functionality
- ✅ Pixi configuration
- ✅ Server integration

#### Known Limitations (Client-side)
- ⚠️ Haxe compilation (API compatibility issues)

## Test Examples

### Server Communication Test
```python
from tests import GMXTester

tester = GMXTester(verbose=True)
success = tester.test_server_functionality()
```

### XML Validation Test
```python
tester = GMXTester()
success = tester.test_xml_validation()
```

## Test Configuration

### Ports Used
- Layout Server: `12345` (production), `12347-12349` (testing)
- Data Server: `12346` (production), `12348-12350` (testing)

### Dependencies
- Python 3.6+
- Standard library modules (xml.etree.ElementTree, socket, subprocess)
- GMX servers (layout_server.py, data_server.py)

### Environment Requirements
- Network access for server testing
- Write permissions for temporary files
- Access to project directories

## Continuous Integration

The test suite is designed for CI/CD integration:

```bash
# CI-friendly command
python tests/test_gmx.py --server-only --quick
```

### Exit Codes
- `0`: All tests passed
- `1`: One or more tests failed

### Test Output Format
- Standard logging format with timestamps
- Summary table with pass/fail counts
- Detailed error messages for failures
- Performance timing information

## Extending Tests

### Adding New Tests
1. Add test methods to `GMXTester` class
2. Call from `run_all_tests()` method
3. Use `log_test_result()` for consistent reporting

### Test Naming Convention
- Method names: `test_<component>_<functionality>`
- Test descriptions: Brief, descriptive strings
- Error messages: Include context and resolution hints

### Best Practices
- Keep tests isolated and repeatable
- Use appropriate timeouts for network operations
- Clean up resources (servers, temp files, etc.)
- Provide meaningful error messages

## Troubleshooting

### Common Issues

**Port conflicts**:
```bash
# Check for processes using test ports
lsof -i :12345 -i :12346
```

**Permission errors**:
- Ensure write access to project directory
- Check that test ports are available

**Server startup failures**:
- Verify Python path includes project directory
- Check that server dependencies are installed

### Debug Mode
```bash
# Run with maximum verbosity
python tests/test_gmx.py --verbose
```

This will show detailed server logs and communication traces.