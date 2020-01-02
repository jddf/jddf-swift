import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(jddfTests.allTests),
        testCase(SchemaTests.allTests),
    ]
}
#endif
