import XCTest

import JDDFTests

var tests = [XCTestCaseEntry]()
tests += jddfTests.allTests()
XCTMain(tests)
