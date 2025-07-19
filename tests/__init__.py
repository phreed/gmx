"""
GMX Test Suite

This package contains comprehensive tests for the GMX (Graphical Message eXchange) application.

Test Modules:
- test_gmx.py: Main test suite covering server functionality, XML validation, and integration tests

Usage:
    # Run all tests
    python -m pytest tests/

    # Run specific test file
    python tests/test_gmx.py

    # Run with verbose output
    python tests/test_gmx.py --verbose

    # Run server tests only
    python tests/test_gmx.py --server-only
"""

__version__ = "0.1.0"
__author__ = "GMX Development Team"

# Test configuration
DEFAULT_LAYOUT_SERVER_PORT = 12345
DEFAULT_DATA_SERVER_PORT = 12346
TEST_TIMEOUT = 30  # seconds

# Import main test class for convenience
from .test_gmx import GMXTester

__all__ = ['GMXTester']
