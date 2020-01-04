import XCTest
@testable import JDDF

final class ValidatorTests: XCTestCase {
    @available(macOS 10.13, *)
    func testValidationSpec() throws {
        let paths = try! FileManager.default.contentsOfDirectory(atPath: "spec/tests/validation")
        for path in paths {
            if path != "003-type.json" {
                continue
            }

            let suitesData = try! String(contentsOfFile: "spec/tests/validation/\(path)")
            let suites = try! JSONSerialization.jsonObject(with: suitesData.data(using: .utf8)!)

            for suite in suites as! [[String: Any]] {
                let schema = try! Schema(json: suite["schema"]!)
                for (index, testCase) in (suite["instances"] as! [[String: Any]]).enumerated() {
                    let expected = (testCase["errors"] as! [[String: Any]]).map({ (error: Any) -> ValidationError in
                        let error = error as! [String: String]
                        let instancePath = error["instancePath"]!
                        let schemaPath = error["schemaPath"]!

                        return ValidationError(
                            instancePath: instancePath.split(separator: "/").map { String($0)},
                            schemaPath: schemaPath.split(separator: "/").map { String($0)}
                        )
                    })

                    let actual = try! Validator().validate(
                        schema: schema,
                        instance: testCase["instance"]!
                    )

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
