import Foundation

struct Validator {
    public let maxDepth: Int
    public let maxErrors: Int

    init() {
        self.maxDepth = 0
        self.maxErrors = 0
    }

    init(maxDepth: Int, maxErrors: Int) {
        self.maxDepth = maxDepth
        self.maxErrors = maxErrors
    }

    @available(macOS 10.13, *)
    public func validate(schema: Schema, instance: Any) throws -> [ValidationError] {
        var vm = VM(
            maxDepth: self.maxDepth,
            maxErrors: self.maxErrors,
            root: schema,
            instanceTokens: [],
            schemaTokens: [[]],
            errors: []
        )

        do {
            try vm.validate(schema: schema, instance: instance)
        } catch MaxErrorsError.maxErrors {
            // Intentionally left blank. This is just a circuit-breaker, not an
            // actual error condition.
        } catch {
            throw error
        }

        return vm.errors
    }
}

struct ValidationError: Equatable {
    public let instancePath: [String]
    public let schemaPath: [String]

    init(instancePath: [String], schemaPath: [String]) {
        self.instancePath = instancePath
        self.schemaPath = schemaPath
    }
}

private struct VM {
    public let maxDepth: Int
    public let maxErrors: Int
    public let root: Schema
    public var instanceTokens: [String]
    public var schemaTokens: [[String]]
    public var errors: [ValidationError]

    @available(macOS 10.13, *)
    public mutating func validate(schema: Schema, instance: Any, parentTag: String? = nil) throws {
        switch schema.form {
        case .empty:
            break
        case .ref(let ref):
            if self.schemaTokens.count == self.maxDepth {
                throw JDDFError.maxDepthExceeded
            }

            self.schemaTokens.append(["definitions", ref])
            try self.validate(schema: self.root.definitions![ref]!, instance: instance)
            _ = self.schemaTokens.popLast()
        case .type(let type):
            self.pushSchemaToken("type")
            switch type {
            case .boolean:
                if !(instance is Bool) {
                    try self.pushError()
                }
            case .float32, .float64:
                if !(instance is Double) {
                    try self.pushError()
                }
            case .int8:
                try self.validateInt(min: -128, max: 127, instance: instance)
            case .uint8:
                try self.validateInt(min: 0, max: 255, instance: instance)
            case .int16:
                try self.validateInt(min: -32768, max: 32767, instance: instance)
            case .uint16:
                try self.validateInt(min: 0, max: 65535, instance: instance)
            case .int32:
                try self.validateInt(min: -2147483648, max: 2147483647, instance: instance)
            case .uint32:
                try self.validateInt(min: 0, max: 4294967295, instance: instance)
            case .string:
                if !(instance is String) {
                    try self.pushError()
                }
            case .timestamp:
                if let instance = instance as? String {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                    if formatter.date(from: instance) == nil {
                        try self.pushError()
                    }
                } else {
                    try self.pushError()
                }
            }
            self.popSchemaToken()
        case .enum(let values):
            self.pushSchemaToken("enum")
            if let instance = instance as? String {
                if !values.contains(instance) {
                    try self.pushError()
                }
            } else {
                try self.pushError()
            }
            self.popSchemaToken()
        case .elements(let subSchema):
            self.pushSchemaToken("elements")
            if let instance = instance as? [Any] {
                for (index, element) in instance.enumerated() {
                    self.pushInstanceToken(String(index))
                    try self.validate(schema: subSchema, instance: element)
                    self.popInstanceToken()
                }
            } else {
                try self.pushError()
            }
            self.popSchemaToken()
        case .properties(let required, let optional, let additional):
            if let instance = instance as? [String: Any] {
                if let required = required {
                    self.pushSchemaToken("properties")
                    for (key, subSchema) in required {
                        self.pushSchemaToken(key)
                        if let subInstance = instance[key] {
                            self.pushInstanceToken(key)
                            try self.validate(schema: subSchema, instance: subInstance)
                            self.popInstanceToken()
                        } else {
                            try self.pushError()
                        }
                        self.popSchemaToken()
                    }
                    self.popSchemaToken()
                }

                if let optional = optional {
                    self.pushSchemaToken("optionalProperties")
                    for (key, subSchema) in optional {
                        self.pushSchemaToken(key)
                        if let subInstance = instance[key] {
                            self.pushInstanceToken(key)
                            try self.validate(schema: subSchema, instance: subInstance)
                            self.popInstanceToken()
                        }
                        self.popSchemaToken()
                    }
                    self.popSchemaToken()
                }

                if !additional {
                    for key in instance.keys {
                        let inRequired = required != nil && required![key] != nil
                        let inOptional = optional != nil && optional![key] != nil
                        let isParentTag = parentTag != nil && key == parentTag

                        if !inRequired && !inOptional && !isParentTag {
                            self.pushInstanceToken(key)
                            try self.pushError()
                            self.popInstanceToken()
                        }
                    }
                }
            } else {
                if required != nil {
                    self.pushSchemaToken("properties")
                } else {
                    self.pushSchemaToken("optionalProperties")
                }

                try self.pushError()
                self.popSchemaToken()
            }
        case .values(let subSchema):
            self.pushSchemaToken("values")
            if let instance = instance as? [String: Any] {
                for (key, subInstance) in instance {
                    self.pushInstanceToken(key)
                    try self.validate(schema: subSchema, instance: subInstance)
                    self.popInstanceToken()
                }
            } else {
                try self.pushError()
            }
            self.popSchemaToken()
        case .discriminator(let tag, let mapping):
            self.pushSchemaToken("discriminator")
            if let instance = instance as? [String: Any] {
                if let tagValue = instance[tag] {
                    if let tagValue = tagValue as? String {
                        if let subSchema = mapping[tagValue] {
                            self.pushSchemaToken("mapping")
                            self.pushSchemaToken(tagValue)
                            try self.validate(schema: subSchema, instance: instance, parentTag: tag)
                            self.popSchemaToken()
                            self.popSchemaToken()
                        } else {
                            self.pushSchemaToken("mapping")
                            self.pushInstanceToken(tag)
                            try self.pushError()
                            self.popInstanceToken()
                            self.popSchemaToken()
                        }
                    } else {
                        self.pushSchemaToken("tag")
                        self.pushInstanceToken(tag)
                        try self.pushError()
                        self.popInstanceToken()
                        self.popSchemaToken()
                    }
                } else {
                    self.pushSchemaToken("tag")
                    try self.pushError()
                    self.popSchemaToken()
                }
            } else {
                try self.pushError()
            }
            self.popSchemaToken()
        }
    }

    private mutating func validateInt(min: Double, max: Double, instance: Any) throws {
        if let instance = instance as? Double {
            if instance.rounded() != instance || instance < min || instance > max {
                try self.pushError()
            }
        } else {
            try self.pushError()
        }
    }

    private mutating func pushInstanceToken(_ token: String) {
        self.instanceTokens.append(token)
    }

    private mutating func popInstanceToken() {
        _ = self.instanceTokens.popLast()
    }

    private mutating func pushSchemaToken(_ token: String) {
        var tokens = self.schemaTokens.last!
        tokens.append(token)
        self.schemaTokens[self.schemaTokens.count - 1] = tokens
    }

    private mutating func popSchemaToken() {
        var tokens = self.schemaTokens.last!
        _ = tokens.popLast()

        self.schemaTokens[self.schemaTokens.count - 1] = tokens
    }

    private mutating func pushError() throws {
        self.errors.append(ValidationError(
            instancePath: self.instanceTokens,
            schemaPath: self.schemaTokens.last!
        ))

        if self.errors.count == self.maxErrors {
            throw MaxErrorsError.maxErrors
        }
    }
}

private enum MaxErrorsError: Error {
    case maxErrors
}
