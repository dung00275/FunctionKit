//
//  Comparator.swift
//  FunctionKit
//
//  Created by Michael Pangburn on 4/13/18.
//

import Foundation

/// A function that compares two values of the same type.
public typealias Comparator<T> = Function<(T, T), ComparisonResult>

fileprivate extension Comparable {
    func compare(to other: Self) -> ComparisonResult {
        if self < other {
            return .orderedAscending
        } else if self > other {
            return .orderedDescending
        } else {
            return .orderedSame
        }
    }
}

extension Function where Output == ComparisonResult {
    /// Compares the two arguments for order.
    /// - Parameter lhs: The left argument to compare.
    /// - Parameter rhs: The right argument to compare.
    /// - Returns: The result of the comparison.
    public func compare<T>(_ lhs: T, _ rhs: T) -> ComparisonResult where Input == (T, T) {
        return call(with: (lhs, rhs))
    }

    /// Returns a comparator that compares `Comparable` instances in natural order.
    public static func naturalOrder<T: Comparable>() -> Comparator<T> where Input == (T, T) {
        return .init { lhs, rhs in
            lhs.compare(to: rhs)
        }
    }

    /// Returns a comparator that compares `Comparable` instances in reverse order.
    public static func reverseOrder<T: Comparable>() -> Comparator<T> where Input == (T, T) {
        return .init { lhs, rhs in
            rhs.compare(to: lhs)
        }
    }

    /// Returns a comparator that compares by extracting a `Comparable` key using the given function.
    /// - Parameter comparableProvider: A function providing a `Comparable` value by which to compare.
    /// - Returns: A comparator that compares the values extracted using the given function.
    public static func comparing<T, Value: Comparable>(by comparableProvider: Function<T, Value>) -> Comparator<T> where Input == (T, T) {
        return Comparator<Value>.naturalOrder()
            .composing(with: { (comparableProvider.call(with: $0), comparableProvider.call(with: $1)) })
    }

    /// Returns a comparator that compares by extracting a `Comparable` key using the given function.
    /// - Parameter comparableProvider: A function providing a `Comparable` value by which to compare.
    /// - Returns: A comparator that compares the values extracted using the given function.
    public static func comparing<T, Value: Comparable>(by comparableProvider: @escaping (T) -> Value) -> Comparator<T> where Input == (T, T) {
        return comparing(by: .init(comparableProvider))
    }

    /// Returns a new comparator that first compares using this comparator, then by the given comparator in the case where operands are ordered the same.
    /// - Parameter nextComparator: The comparator to use to compare in the case where this comparator determines the operands are ordered the same.
    /// - Returns: A new comparator using the given comparator to secondarily compare.
    public func thenComparing<T>(by nextComparator: Comparator<T>) -> Comparator<T> where Input == (T, T) {
        return .init { lhs, rhs in
            let primaryResult = self.compare(lhs, rhs)
            if primaryResult == .orderedSame {
                return nextComparator.compare(lhs, rhs)
            } else {
                return primaryResult
            }
        }
    }

    /// Returns a new comparator that first compares using this comparator, then by the given comparator in the case where operands are ordered the same.
    /// - Parameter nextComparator: The comparator to use to compare in the case where this comparator determines the operands are ordered the same.
    /// - Returns: A new comparator using the given comparator to secondarily compare.
    public func thenComparing<T, Value: Comparable>(by comparableProvider: Function<T, Value>) -> Comparator<T> where Input == (T, T) {
        return thenComparing(by: .comparing(by: comparableProvider))
    }

    /// Returns a new comparator that first compares using this comparator, then by the given comparator in the case where operands are ordered the same.
    /// - Parameter nextComparator: The comparator to use to compare in the case where this comparator determines the operands are ordered the same.
    /// - Returns: A new comparator using the given comparator to secondarily compare.
    public func thenComparing<T, Value: Comparable>(by comparableProvider: @escaping (T) -> Value) -> Comparator<T> where Input == (T, T) {
        return thenComparing(by: .comparing(by: comparableProvider))
    }

    /// Returns a comparator that imposes the reverse ordering of this comparator.
    public func reversed<T>() -> Comparator<T> where Input == (T, T) {
        return .init { lhs, rhs in
            switch self.compare(lhs, rhs) {
            case .orderedAscending:
                return .orderedDescending
            case .orderedSame:
                return .orderedSame
            case .orderedDescending:
                return .orderedAscending
            }
        }
    }
}

// MARK: - Optional Comparators

extension Function where Output == ComparisonResult {
    /// Returns an optional-friendly comparator that orders `nil` values before non-`nil` values.
    public static func nilValuesFirst<T: Comparable>() -> Comparator<T?> where Input == (T?, T?) {
        return .nilValuesFirst(by: .naturalOrder())
    }

    /// Returns an optional-friendly comparator that orders `nil` values before non-`nil` values.
    /// - Parameter comparator: The comparator to use in cases where both values are non-`nil`.
    /// - Returns: An optional-friendly comparator that orders `nil` values before non-`nil` values.
    public static func nilValuesFirst<T>(by comparator: Comparator<T>) -> Comparator<T?> where Input == (T?, T?) {
        return .init { lhs, rhs in
            switch (lhs, rhs) {
            case (nil, nil):
                return .orderedSame
            case (nil, _):
                return .orderedAscending
            case (_, nil):
                return .orderedDescending
            case (let lhs?, let rhs?):
                return comparator.compare(lhs, rhs)
            }
        }
    }

    /// Returns an optional-friendly comparator that compares by extracting a an optional `Comparable` key using the given function,
    /// ordering `nil` values before non-`nil` values.
    /// - Parameter optionalComparableProvider: A function providing an optional `Comparable` value by which to compare.
    /// - Returns: A comparator that compares the values extracted using the given function, ordering `nil` values before non-`nil` values.
    public static func nilValuesFirst<T, Value: Comparable>(by optionalComparableProvider: Function<T, Value?>) -> Comparator<T> where Input == (T, T) {
        return Comparator<Value?>.nilValuesFirst()
            .composing(with: { (optionalComparableProvider.call(with: $0), optionalComparableProvider.call(with: $1)) })
    }

    /// Returns an optional-friendly comparator that compares by extracting a an optional `Comparable` key using the given function,
    /// ordering `nil` values before non-`nil` values.
    /// - Parameter optionalComparableProvider: A function providing an optional `Comparable` value by which to compare.
    /// - Returns: A comparator that compares the values extracted using the given function, ordering `nil` values before non-`nil` values.
    public static func nilValuesFirst<T, Value: Comparable>(by optionalComparableProvider: @escaping (T) -> Value?) -> Comparator<T> where Input == (T, T) {
        return .nilValuesFirst(by: .init(optionalComparableProvider))
    }

    /// Returns an optional-friendly comparator that orders `nil` values after non-`nil` values.
    public static func nilValuesLast<T: Comparable>() -> Comparator<T?> where Input == (T?, T?) {
        return .nilValuesLast(by: .naturalOrder())
    }

    /// Returns an optional-friendly comparator that orders `nil` values after non-`nil` values.
    /// - Parameter comparator: The comparator to use in cases where both values are non-`nil`.
    /// - Returns: An optional-friendly comparator that orders `nil` values after non-`nil` values.
    public static func nilValuesLast<T>(by comparator: Comparator<T>) -> Comparator<T?> where Input == (T?, T?) {
        return .init { lhs, rhs in
            switch (lhs, rhs) {
            case (nil, nil):
                return .orderedSame
            case (nil, _):
                return .orderedDescending
            case (_, nil):
                return .orderedAscending
            case (let lhs?, let rhs?):
                return comparator.compare(lhs, rhs)
            }
        }
    }

    /// Returns an optional-friendly comparator that compares by extracting a an optional `Comparable` key using the given function,
    /// ordering `nil` values after non-`nil` values.
    /// - Parameter optionalComparableProvider: A function providing an optional `Comparable` value by which to compare.
    /// - Returns: A comparator that compares the values extracted using the given function, ordering `nil` values after non-`nil` values.
    public static func nilValuesLast<T, Value: Comparable>(by optionalComparableProvider: Function<T, Value?>) -> Comparator<T> where Input == (T, T) {
        return Comparator<Value?>.nilValuesLast()
            .composing(with: { (optionalComparableProvider.call(with: $0), optionalComparableProvider.call(with: $1)) })
    }

    /// Returns an optional-friendly comparator that compares by extracting a an optional `Comparable` key using the given function,
    /// ordering `nil` values after non-`nil` values.
    /// - Parameter optionalComparableProvider: A function providing an optional `Comparable` value by which to compare.
    /// - Returns: A comparator that compares the values extracted using the given function, ordering `nil` values after non-`nil` values.
    public static func nilValuesLast<T, Value: Comparable>(by optionalComparableProvider: @escaping (T) -> Value?) -> Comparator<T> where Input == (T, T) {
        return .nilValuesLast(by: .init(optionalComparableProvider))
    }
}
