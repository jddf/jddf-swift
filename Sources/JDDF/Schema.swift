struct Schema: Equatable, Hashable {
    public let definitions: [String: Schema]?
    public let form: Form

    init() {
        self.definitions = nil
        self.form = Form.empty
    }

    init(definitions: [String: Schema]?, form: Form) {
        self.definitions = definitions
        self.form = form
    }

    init(json: Any) throws {
        if let json = json as? [String: Any] {
            if let definitions = json["definitions"] {
                if let definitions = definitions as? [String: Any] {
                    self.definitions = try definitions.mapValues { try Schema(json: $0)}
                } else {
                    throw JDDFError.invalidSchema("definitions must be object")
                }
            } else {
                self.definitions = nil
            }

            var form = Form.empty

            if let ref = json["ref"] {
                if let ref = ref as? String {
                    form = .ref(ref)
                } else {
                    throw JDDFError.invalidSchema("ref must be string")
                }
            }

            if let type = json["type"] {
                if form != .empty {
                    throw JDDFError.invalidSchema("invalid form")
                }

                if let type = type as? String {
                    if let type = Type(rawValue: type) {
                        form = .type(type)
                    } else {
                        throw JDDFError.invalidSchema("invalid type")
                    }
                } else {
                    throw JDDFError.invalidSchema("type must be string")
                }
            }

            if let `enum` = json["enum"] {
                if form != .empty {
                    throw JDDFError.invalidSchema("invalid form")
                }

                if let `enum` = `enum` as? [String] {
                    let values = Set(`enum`)
                    if `enum`.count != values.count {
                        throw JDDFError.invalidSchema("enum contains repeated values")
                    }

                    form = .enum(values)
                } else {
                    throw JDDFError.invalidSchema("enum must be array")
                }
            }

            if let elements = json["elements"] {
                if form != .empty {
                    throw JDDFError.invalidSchema("invalid form")
                }

                form = try .elements(Schema(json: elements))
            }

            if json["properties"] != nil || json["optionalProperties"] != nil || json["additionalProperties"] != nil {
                if form != .empty {
                    throw JDDFError.invalidSchema("invalid form")
                }

                var `required`: [String: Schema] = [:]
                if let properties = json["properties"] {
                    if let properties = properties as? [String: Any] {
                        `required` = try properties.mapValues { try Schema(json: $0)}
                    } else {
                        throw JDDFError.invalidSchema("properties must be object")
                    }
                }

                var `optional`: [String: Schema] = [:]
                if let properties = json["optionalProperties"] {
                    if let properties = properties as? [String: Any] {
                        `optional` = try properties.mapValues { try Schema(json: $0)}
                    } else {
                        throw JDDFError.invalidSchema("optionalProperties must be object")
                    }
                }

                var additional = false
                if let properties = json["additionalProperties"] {
                    if let properties = properties as? Bool {
                        additional = properties
                    } else {
                        throw JDDFError.invalidSchema("additionalProperties must be boolean")
                    }
                }

                form = .properties(
                    required: `required`,
                    optional: `optional`,
                    additional: additional
                )
            }

            if let values = json["values"] {
                if form != .empty {
                    throw JDDFError.invalidSchema("invalid form")
                }

                form = try .values(Schema(json: values))
            }

            if let discriminator = json["discriminator"] {
                if form != .empty {
                    throw JDDFError.invalidSchema("invalid form")
                }

                if let discriminator = discriminator as? [String: Any] {
                    var discriminatorTag = ""
                    var discriminatorMapping: [String: Schema] = [:]

                    if let tag = discriminator["tag"] {
                        if let tag = tag as? String {
                            discriminatorTag = tag
                        } else {
                            throw JDDFError.invalidSchema("tag must be string")
                        }
                    } else {
                        throw JDDFError.invalidSchema("tag is required")
                    }

                    if let mapping = discriminator["mapping"] {
                        if let mapping = mapping as? [String: Any] {
                            discriminatorMapping = try mapping.mapValues {
                                try Schema(json: $0)
                            }
                        } else {
                            throw JDDFError.invalidSchema("mapping must be object")
                        }
                    } else {
                        throw JDDFError.invalidSchema("mapping is required")
                    }

                    form = .discriminator(
                        tag: discriminatorTag,
                        mapping: discriminatorMapping
                    )
                } else {
                    throw JDDFError.invalidSchema("discriminator must be object")
                }
            }

            self.form = form
        } else {
            throw JDDFError.invalidSchema("schema must be object")
        }
    }

    public func validate() throws {
        if let definitions = self.definitions {
            for (_, value) in definitions {
                try value.validate(root: self)
            }
        }

        try self.validate(root: self)
    }

    private func validate(root: Schema) throws {
        if self != root && self.definitions != nil {
            throw JDDFError.invalidSchema("definitions must only appear in root schemas")
        }

        switch self.form {
        case .empty:
            break
        case .type:
            break
        case .ref(let ref):
            if root.definitions == nil || root.definitions![ref] == nil {
                throw JDDFError.invalidSchema("ref to non-existent definition")
            }
        case .enum(let values):
            if values.isEmpty {
                throw JDDFError.invalidSchema("enum must be non-empty")
            }
        case .elements(let schema):
            try schema.validate(root: root)
        case .properties(let required, let optional, _):
            if !Set((required ?? [:]).keys).intersection(Set((optional ?? [:]).keys)).isEmpty {
                throw JDDFError.invalidSchema("properties and optionalProperties share key")
            }
        case .values(let schema):
            try schema.validate(root: root)
        case .discriminator(let tag, let mapping):
            for (_, value) in mapping {
                try value.validate(root: root)
                switch value.form {
                case .properties(let required, let optional, _):
                    if required != nil && required![tag] != nil {
                        throw JDDFError.invalidSchema("discriminator mapping value has a property equal to tag's value")
                    }

                    if optional != nil && optional![tag] != nil {
                        throw JDDFError.invalidSchema("discriminator mapping value has an optional property equal to tag's value")
                    }
                default:
                    throw JDDFError.invalidSchema("discriminator mapping value is not of properties form")
                }
            }
        }
    }
}

enum Form: Equatable, Hashable {
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
