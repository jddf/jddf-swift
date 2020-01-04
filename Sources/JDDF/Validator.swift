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

        try vm.validate(schema: schema, instance: instance)

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
    public mutating func validate(schema: Schema, instance: Any) throws {
        switch schema.form {
        case .empty:
            break
        case .ref(let ref):
            self.schemaTokens.append(["definitions", ref])
            try self.validate(schema: self.root.definitions![ref]!, instance: instance)
            _ = self.schemaTokens.popLast()
        case .type(let type):
            self.pushSchemaToken("type")
            switch type {
            case .boolean:
                if !(instance is Bool) {
                    self.pushError()
                }
            case .float32, .float64:
                if !(instance is Double) {
                    self.pushError()
                }
            case .int8:
                self.validateInt(min: -128, max: 127, instance: instance)
            case .uint8:
                self.validateInt(min: 0, max: 255, instance: instance)
            case .int16:
                self.validateInt(min: -32768, max: 32767, instance: instance)
            case .uint16:
                self.validateInt(min: 0, max: 65535, instance: instance)
            case .int32:
                self.validateInt(min: -2147483648, max: 2147483647, instance: instance)
            case .uint32:
                self.validateInt(min: 0, max: 4294967295, instance: instance)
            case .string:
                if !(instance is String) {
                    self.pushError()
                }
            case .timestamp:
                if let instance = instance as? String {
                    let formatter = ISO8601DateFormatter()
                    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                    if formatter.date(from: instance) == nil {
                        self.pushError()
                    }
                } else {
                    self.pushError()
                }
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
                self.pushError()
            }
            self.popSchemaToken()
        default:
            break // TODO
        }
    }

    private mutating func validateInt(min: Double, max: Double, instance: Any) {
        if let instance = instance as? Double {
            if instance.rounded() != instance || instance < min || instance > max {
                self.pushError()
            }
        } else {
            self.pushError()
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

    private mutating func pushError() {
        self.errors.append(ValidationError(
            instancePath: self.instanceTokens,
            schemaPath: self.schemaTokens.last!
        ))
    }
}
