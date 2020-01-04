import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SchemaTests.allTests),
        testCase(ValidatorTests.allTests),
    ]
}
#endif
