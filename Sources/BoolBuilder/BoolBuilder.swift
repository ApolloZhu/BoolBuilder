extension Bool {
    /// `false` if `self` is `true`; `true` if `self` is `false`.
    public var inverted: Bool {
        !self
    }
}

/// Performs an eXclusive OR operation on two Boolean conditions.
///
/// - Parameters:
///   - condition: A function producing one of the two conditions to check.
///   - theOtherCondition: A function producing the other condition to check.
/// - Returns: `true` if `condition` and `theOtherCondition` return different
///   values, otherwise `false`.
public func either(_ condition: () throws -> Bool,
                   or theOtherCondition: () throws -> Bool) rethrows -> Bool {
    try condition() != theOtherCondition()
}

// MARK: - && and ||

public protocol _BoolBuilder {
    typealias Component = () -> Bool
    typealias Operator = (Bool, Component) -> Bool
    static var combinePartialResult: Operator { get }
}

extension _BoolBuilder {
    public static func buildExpression(
        _ expression: @escaping @autoclosure Component
    ) -> Component {
        expression
    }
    
#if swift(>=5.7)
    public static func buildPartialBlock(first: Component) -> Bool {
        first()
    }
    
    public static func buildPartialBlock(
        accumulated: Bool, next: Component
    ) -> Bool {
        combinePartialResult(accumulated, next)
    }
#else
    public static func buildBlock(
        _ first: Component, _ remaining: Component...
    ) -> Bool {
        remaining.reduce(first(), combinePartialResult)
    }
#endif
}

@resultBuilder
public enum AndBuilder: _BoolBuilder {
    public static let combinePartialResult: Operator = { $0 && $1() }
    
#if canImport(PlaygroundBluetooth)
    // Swift Playgrounds doesn't show compiler warnings, so
    // we need to promote this to a compiler error instead.
    // Since PlaygroundBluetooth is a Swift Playgrounds only framework, it's
    // a good indicator for if we are compiling for Swift Playgrounds or not.
    
    @available(*, unavailable, message: """
    Replace empty BoolBuilder with true instead.
    """)
    public static func buildBlock() -> Bool { true }
#else
    @available(*, deprecated, message: """
    Empty BoolBuilder always evaluates to true.
    Consider replacing with true instead.
    """)
    public static func buildBlock() -> Bool { true }
#endif
}

@resultBuilder
public enum OrBuilder: _BoolBuilder {
    public static let combinePartialResult: Operator = { $0 || $1() }
    
#if canImport(PlaygroundBluetooth)
    @available(*, unavailable, message: """
    Replace empty BoolBuilder with false instead.
    """)
    public static func buildBlock() -> Bool { false }
#else
    @available(*, deprecated, message: """
    Empty BoolBuilder always evaluates to false.
    Consider replacing with false instead.
    """)
    public static func buildBlock() -> Bool { false }
#endif
}

/// Performs logical AND operations on the provided Boolean conditions
/// with short-circuit semantics.
///
/// - Parameter conditions: Conditions to check.
/// - Returns: `true` if all the `conditions` are `true`, otherwise `false`.
public func all(@AndBuilder conditions makeResult: () -> Bool) -> Bool {
    makeResult()
}

/// Performs logical OR operations on the provided Boolean conditions
/// with short-circuit semantics.
///
/// - Parameter conditions: Conditions to check.
/// - Returns: `true` if at least one of the `conditions` are `true`,
///   otherwise `false`.
public func any(@OrBuilder conditions makeResult: () -> Bool) -> Bool {
    makeResult()
}

// MARK: - && and || with try expressions

public protocol _ThrowingBoolBuilder {
    typealias Component = () throws -> Bool
    typealias Operator = (Bool, Component) throws -> Bool
    static var combinePartialResult: Operator { get }
}

extension _ThrowingBoolBuilder {
    public typealias FinalResult = Result<Bool, Error>
    
    public static func buildExpression(
        _ expression: @escaping @autoclosure Component
    ) -> Component {
        expression
    }
    
#if swift(>=5.7)
    public static func buildPartialBlock(first: Component) -> FinalResult {
        FinalResult {
            try first()
        }
    }
    
    public static func buildPartialBlock(
        accumulated: FinalResult, next: Component
    ) -> FinalResult {
        accumulated.flatMap { result in
            FinalResult {
                try combinePartialResult(result, next)
            }
        }
    }
#else
    public static func buildBlock(
        _ first: Component, _ remaining: Component...
    ) -> FinalResult {
        remaining.reduce(FinalResult {
            try first()
        }) { accumulated, next in
            accumulated.flatMap { result in
                FinalResult {
                    try combinePartialResult(result, next)
                }
            }
        }
    }
#endif
}

@resultBuilder
public enum ThrowingAndBuilder: _ThrowingBoolBuilder {
    public static let combinePartialResult: Operator = (&&)
    
    @available(*, unavailable, message: """
    Empty throwing BoolBuilder can never throw.
    Replace with true instead and file a bug report to BoolBuilder authors \
    with example code that reproduces this error message.
    """)
    public static func buildBlock() -> FinalResult { .success(true) }
}

@resultBuilder
public enum ThrowingOrBuilder: _ThrowingBoolBuilder {
    public static let combinePartialResult: Operator = (||)
    
    @available(*, unavailable, message: """
    Empty throwing BoolBuilder can never throw.
    Replace with false instead and file a bug report to BoolBuilder authors \
    with example code that reproduces this error message.
    """)
    public static func buildBlock() -> FinalResult { .success(false) }
}

/// Performs logical AND operations on the provided Boolean conditions
/// with short-circuit semantics.
///
/// - Parameter conditions: Conditions to check.
/// - Throws: Re-throws the first error thrown by the conditions to check.
/// - Returns: `true` if all the `conditions` are `true`, otherwise `false`.
@_disfavoredOverload
public func all(
    @ThrowingAndBuilder conditions makeResult: () throws
    -> ThrowingAndBuilder.FinalResult
) throws -> Bool {
    try makeResult().get()
}

/// Performs logical OR operations on the provided Boolean conditions
/// with short-circuit semantics.
///
/// - Parameter conditions: Conditions to check.
/// - Throws: Re-throws the first error thrown by the conditions to check.
/// - Returns: `true` if at least one of the `conditions` are `true`,
///   otherwise `false`.
@_disfavoredOverload
public func any(
    @ThrowingOrBuilder conditions makeResult: () throws
    -> ThrowingOrBuilder.FinalResult
) throws -> Bool {
    try makeResult().get()
}
