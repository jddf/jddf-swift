enum JDDFError: Error, Equatable {
    case invalidSchema(String)
    case maxDepthExceeded
}
