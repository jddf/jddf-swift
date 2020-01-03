import XCTest
@testable import JDDF

final class SchemaTests: XCTestCase {
    func testSerializeDeserialize() {
        XCTAssertEqual(
            try! Schema(json: [
                "definitions": [
                    "foo": [:],
                ],
            ]),
            Schema(definitions: ["foo": Schema()], form: Form.empty)
        )

        XCTAssertEqual(
            try! Schema(json: [
                "definitions": [
                    "foo": [:],
                ],
                "ref": "foo",
            ]),
            Schema(definitions: ["foo": Schema()], form: Form.ref("foo"))
        )

        XCTAssertEqual(
            try! Schema(json: [
                "definitions": [
                    "foo": [:],
                ],
                "type": "uint8",
            ]),
            Schema(definitions: ["foo": Schema()], form: Form.type(Type.uint8))
        )

        XCTAssertEqual(
            try! Schema(json: [
                "definitions": [
                    "foo": [:],
                ],
                "enum": ["foo"],
            ]),
            Schema(definitions: ["foo": Schema()], form: Form.enum(["foo"]))
        )

        XCTAssertEqual(
            try! Schema(json: [
                "definitions": [
                    "foo": [:],
                ],
                "elements": [:],
            ]),
            Schema(definitions: ["foo": Schema()], form: Form.elements(Schema()))
        )

        XCTAssertEqual(
            try! Schema(json: [
                "definitions": [
                    "foo": [:],
                ],
                "properties": [
                    "foo": [:],
                ],
                "optionalProperties": [
                    "foo": [:],
                ],
                "additionalProperties": true
            ]),
            Schema(
                definitions: ["foo": Schema()],
                form: Form.properties(
                    required: ["foo": Schema()],
                    optional: ["foo": Schema()],
                    additional: true
                )
            )
        )

        XCTAssertEqual(
            try! Schema(json: [
                "definitions": [
                    "foo": [:],
                ],
                "values": [:],
            ]),
            Schema(definitions: ["foo": Schema()], form: Form.values(Schema()))
        )

        XCTAssertEqual(
            try! Schema(json: [
                "definitions": [
                    "foo": [:],
                ],
                "discriminator": [
                    "tag": "foo",
                    "mapping": [
                        "foo": [:],
                    ],
                ],
            ]),
            Schema(
                definitions: ["foo": Schema()],
                form: Form.discriminator(tag: "foo", mapping: ["foo": Schema()])
            )
        )
    }

    func testInvalidSchemas() throws {
        let testCaseData = try! String(contentsOfFile: "spec/tests/invalid-schemas.json")
        let testCases = try! JSONSerialization.jsonObject(with: testCaseData.data(using: .utf8)!)

        for testCase in testCases as! [[String: Any]] {
            var ok = false

            do {
                try Schema(json: testCase["schema"]!).validate()
            } catch JDDFError.invalidSchema(_) {
                ok = true
            } catch {
                throw error
            }

            XCTAssert(ok, testCase["name"]! as! String)
        }
    }

    static var allTests = [
        ("testSerializeDeserialize", testSerializeDeserialize),
        ("testInvalidSchemas", testInvalidSchemas),
    ]
}
