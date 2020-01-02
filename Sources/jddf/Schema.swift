import SwiftyJSON

struct Schema: Equatable {
    public let definitions: [String: Schema]?
    public let form: Form

    init() {
        self.definitions = nil
        self.form = Form.empty
    }

    init(definitions: [String: Schema]?, form: Form) {
        self.definitions = definitions;
        self.form = form;
    }

    init(json: JSON) {
        if let definitions = json["definitions"].dictionary {
            self.definitions = definitions.mapValues { Schema(json: $0) }
        } else {
            self.definitions = nil
        }

        var form = Form.empty

        if let ref = json["ref"].string {
            form = Form.ref(ref)
        }

        if let type = json["type"].string {
            form = Form.type(Type(rawValue: type)!)
        }

        if let `enum` = json["enum"].array {
            form = Form.enum(Set(`enum`.map { $0.stringValue }))
        }

        if json["elements"].exists() {
            form = Form.elements(Schema(json: json["elements"]))
        }

        if json["properties"].exists() || json["optionalProperties"].exists() {
            var `required`: [String: Schema]? = nil
            if let properties = json["properties"].dictionary {
                `required` = properties.mapValues { Schema(json: $0) }
            }

            var `optional`: [String: Schema]? = nil
            if let properties = json["optionalProperties"].dictionary {
                `optional` = properties.mapValues { Schema(json: $0) }
            }

            let additional = json["additionalProperties"].bool ?? false

            form = Form.properties(required: `required`, optional: `optional`, additional: additional)
        }

        if json["values"].exists() {
            form = Form.values(Schema(json: json["values"]))
        }

        if json["discriminator"].exists() {
            form = Form.discriminator(
                tag: json["discriminator"]["tag"].stringValue,
                mapping: json["discriminator"]["mapping"].dictionaryValue.mapValues {
                    Schema(json: $0)
                }
            )
        }

        self.form = form
    }
}

enum Form: Equatable {
    case empty
    case ref(String)
    case type(Type)
    case `enum`(Set<String>)
    indirect case elements(Schema)
    case properties(required: [String: Schema]?, optional: [String: Schema]?, additional: Bool)
    indirect case values(Schema)
    case discriminator(tag: String, mapping: [String: Schema])
}

enum Type: String {
    case boolean
    case float32
    case float64
    case int8
    case uint8
    case int16
    case uint16
    case int32
    case uint32
    case string
    case timestamp
}
