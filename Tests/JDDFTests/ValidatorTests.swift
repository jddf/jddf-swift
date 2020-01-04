import XCTest
@testable import JDDF

final class ValidatorTests: XCTestCase {
    @available(macOS 10.13, *)
    func testValidationSpec() throws {
        let paths = try! FileManager.default.contentsOfDirectory(atPath: "spec/tests/validation")
        for path in paths {
            let suitesData = try! String(contentsOfFile: "spec/tests/validation/\(path)")
            let suites = try! JSONSerialization.jsonObject(with: suitesData.data(using: .utf8)!)

            for suite in suites as! [[String: Any]] {
                let schema = try! Schema(json: suite["schema"]!)
                for (index, testCase) in (suite["instances"] as! [[String: Any]]).enumerated() {
                    var expected = (testCase["errors"] as! [[String: Any]]).map({ (error: Any) -> ValidationError in
                        let error = error as! [String: String]
                        let instancePath = error["instancePath"]!
                        let schemaPath = error["schemaPath"]!

                        return ValidationError(
                            instancePath: instancePath.split(separator: "/").map { String($0)},
                            schemaPath: schemaPath.split(separator: "/").map { String($0)}
                        )
                    })

                    var actual = try! Validator().validate(
                        schema: schema,
                        instance: testCase["instance"]!
                    )

                    expected.sort {
                        $0.schemaPath.joined() + $0.instancePath.joined()
                            > $1.schemaPath.joined() + $1.instancePath.joined()
                    }

                    actual.sort {
                        $0.schemaPath.joined() + $0.instancePath.joined()
                            > $1.schemaPath.joined() + $1.instancePath.joined()
                    }

                    XCTAssertEqual(actual, expected, "\(suite["name"] as! String)/\(index)")
                }
            }
        }
    }

    @available(macOS 10.13, *)
    static var allTests = [
        ("testValidationSpec", testValidationSpec),
    ]
}
