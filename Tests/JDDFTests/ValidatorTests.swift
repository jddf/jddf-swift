import XCTest
@testable import JDDF

final class ValidatorTests: XCTestCase {
    @available(macOS 10.13, *)
    func testValidationMaxDepth() throws {
        let schema = try! Schema(json: [
            "definitions": [
                "": ["ref": ""],
            ],
            "ref": "",
        ])

        let validator = Validator(maxDepth: 3, maxErrors: 0)
        XCTAssertThrowsError(try validator.validate(schema: schema, instance: 1 as Any)) { error in
            XCTAssertEqual(error as! JDDFError, JDDFError.maxDepthExceeded)
        }
    }

    @available(macOS 10.13, *)
    func testValidationMaxErrors() throws {
        let schema = try! Schema(json: [
            "elements": [
                "type": "string",
            ],
        ])

        let validator = Validator(maxDepth: 0, maxErrors: 3)
        let instance = [1, 1, 1, 1, 1] as Any
        let errors = try validator.validate(schema: schema, instance: instance)

        XCTAssertEqual(errors.count, 3)
    }

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
