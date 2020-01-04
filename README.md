# jddf-swift

This package is a Swift implementation of **JSON Data Definition Format**. You
can use this package to:

1. Validate input data against a schema,
2. Get a list of validation errors from that input data, or
3. Build your own tooling on top of JSON Data Definition Format

## Installation

### CocoaPods

You can install `jddf-swift` using CocoaPods by adding this to your `Podfile`:

```ruby
pod 'JDDF', :git => 'https://github.com/jddf/jddf-swift.git'
```

### Carthage

You can install `jddf-swift` using Carthage by adding this to your `Cartfile`:

```text
github "jddf/jddf-swift"
```

### Swift Package Manager

You can install `jddf-swift` using the Swift Package Manager by adding it as a
dependency in your `Package.swift`:

```swift
// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "YOUR_PACKAGE_NAME",
    dependencies: [
        .package(url: "https://github.com/jddf/jddf-swift.git")
    ],
)
```

## Usage

Here's how you parse schemas and validate input data against them:

```swift
import JDDF

// To keep things simple in this example, we'll pass a dictionary straight into
// the Schema initializer. But do note that this sort of dictionary is exactly
// what you get from calling `JSONSerialization.jsonObject`.
let schema = Schema(json: [
    "properties": [
        "name": ["type": "string"],
        "age": ["type": "uint32"],
        "phones": [
            "elements": ["type": "string"]
        ],
    ],
])

// To keep this example simple, we'll construct this data by hand. But you could
// also parse this data from JSON, using `JSONSerialization.jsonObject`.
//
// This input data is perfect. It satisfies all the schema requirements.
let inputOk = [
    "name": "John Doe",
    "age": 42,
    "phones": [
        "+44 1234567",
        "+44 2345678",
    ],
]

// This input data has problems. "name" is missing, "age" has the wrong type,
// and "phones[1]" has the wrong type.
let inputBad = [
    "age": "43",
    "phones": [
        "+44 1234567",
        442345678,
    ],
]

// To keep things simple, we'll ignore errors here. In this example, errors are
// impossible. The docs explain in detail why an error might arise from
// validation.
let validator = Validator()
let resultOk = try! validator.validate(schema: schema, instance: inputOk)
let resultBad = try! validator.validate(schema: schema, instance: inputBad)

// inputOk is correct, so no validation errors are returned.
print(resultOk) // []

// The first error indicates that "name" is missing:
//
// [] ["properties", "name"]
print(resultBad[0].instancePath, resultBad[0].schemaPath)

// The second error indicates that "age" has the wrong type:
//
// ["age"] ["properties", "age", "type"]
print(resultBad[1].instancePath, resultBad[1].schemaPath)

// The third error dinciates that "phones[1]" has the wrong type:
//
// ["phones", "1"] ["properties", "phones", "elements", "type"]
print(resultBad[2].instancePath, resultBad[2].schemaPath)
```
