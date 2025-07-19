# GMX Test Suite

This directory contains the comprehensive test suite for the GMX (Graphical Message eXchange) application.

## Quick Start

```bash
# Run all tests
python tests/test_gmx.py

# Server-only tests (faster)
python tests/test_gmx.py --server-only

# Verbose output for debugging
python tests/test_gmx.py --verbose
```

## Test Coverage

The test suite validates:
- Project structure and configuration
- XML file validation (layouts, records, collections)
- Server functionality (layout and data servers)
- Build system and Haxe compilation
- Cross-server integration

## Expected Results

- ✅ Server-side functionality: All tests passing (31/31)
- ⚠️ Client-side compilation: Known API compatibility issues with current Heaps.io

## Documentation

For complete testing documentation, development workflows, and troubleshooting, see:

**[Developer's Guide - Testing Section](../docs/developer_guide.asciidoc)**

The comprehensive testing guide covers:
- Test structure and organization
- Running different test modes
- Adding new tests
- CI/CD integration
- Debugging test failures
- Performance testing

## Files

- `test_gmx.py` - Main test suite implementation
- `__init__.py` - Test package initialization
- `README.md` - This file

---

*This is a simplified overview. For detailed testing information, refer to the Developer's Guide documentation.*