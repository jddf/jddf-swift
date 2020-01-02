import XCTest
import SwiftyJSON
@testable import jddf

final class SchemaTests: XCTestCase {
    func testSerializeDeserialize() {
        XCTAssertEqual(
            Schema(json: JSON([
                "definitions": [
                    "foo": [],
                ],
            ])),
            Schema(definitions: ["foo": Schema()], form: Form.empty)
        )

        XCTAssertEqual(
            Schema(json: JSON([
                "definitions": [
                    "foo": [],
                ],
                "ref": "foo",
            ])),
            Schema(definitions: ["foo": Schema()], form: Form.ref("foo"))
        )

        XCTAssertEqual(
            Schema(json: JSON([
                "definitions": [
                    "foo": [],
                ],
                "type": "uint8",
            ])),
            Schema(definitions: ["foo": Schema()], form: Form.type(Type.uint8))
        )

        XCTAssertEqual(
            Schema(json: JSON([
                "definitions": [
                    "foo": [],
                ],
                "enum": ["foo"],
            ])),
            Schema(definitions: ["foo": Schema()], form: Form.enum(["foo"]))
        )

        XCTAssertEqual(
            Schema(json: JSON([
                "definitions": [
                    "foo": [],
                ],
                "elements": [],
            ])),
            Schema(definitions: ["foo": Schema()], form: Form.elements(Schema()))
        )

        XCTAssertEqual(
            Schema(json: JSON([
                "definitions": [
                    "foo": [],
                ],
                "properties": [
                    "foo": [],
                ],
                "optionalProperties": [
                    "foo": [],
                ],
                "additionalProperties": true
            ])),
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
            Schema(json: JSON([
                "definitions": [
                    "foo": [],
                ],
                "values": [],
            ])),
            Schema(definitions: ["foo": Schema()], form: Form.values(Schema()))
        )

        XCTAssertEqual(
            Schema(json: JSON([
                "definitions": [
                    "foo": [],
                ],
                "discriminator": [
                    "tag": "foo",
                    "mapping": [
                        "foo": [],
                    ],
                ],
            ])),
            Schema(
                definitions: ["foo": Schema()],
                form: Form.discriminator(tag: "foo", mapping: ["foo": Schema()])
            )
        )
    }

    static var allTests = [
        ("testSerializeDeserialize", testSerializeDeserialize),
    ]
}
