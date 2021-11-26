import SwiftUI
import Combine

// Renamed from https://github.com/quickbirdstudios/XUI/blob/main/Sources/XUI/Store/Store.swift

public protocol AnyObservableObject: AnyObject {
    var objectWillChange: ObservableObjectPublisher { get }
}

@propertyWrapper
public struct StateDependency<Model>: DynamicProperty {

    // MARK: Nested types
    @dynamicMemberLookup
    public struct Wrapper {

        fileprivate var store: StateDependency

        public subscript<Value>(dynamicMember keyPath: ReferenceWritableKeyPath<Model, Value>) -> Binding<Value> {
            Binding(get: { self.store.wrappedValue[keyPath: keyPath] },
                    set: { self.store.wrappedValue[keyPath: keyPath] = $0 })
        }

    }

    // MARK: Stored properties
    public let wrappedValue: Model

    @ObservedObject
    private var observableObject: ErasedObservableObject

    // MARK: Computed Properties
    public var projectedValue: Wrapper {
        Wrapper(store: self)
    }

    // MARK: Initialization
    public init(wrappedValue: Model) {
        self.wrappedValue = wrappedValue // TODO: Perform resolving, need to extract resolver?

        if let objectWillChange = (wrappedValue as? AnyObservableObject)?.objectWillChange {
            self.observableObject = .init(objectWillChange: objectWillChange.eraseToAnyPublisher())
        } else {
            assertionFailure("Only use the `StateDependency` property wrapper with instances conforming to `AnyObservableObject`.")
            self.observableObject = .empty()
        }
    }

    // MARK: Methods
    public mutating func update() {
        _observableObject.update()
    }

}

class ErasedObservableObject: ObservableObject {

    let objectWillChange: AnyPublisher<Void, Never>

    init(objectWillChange: AnyPublisher<Void, Never>) {
        self.objectWillChange = objectWillChange
    }

    static func empty() -> ErasedObservableObject {
        .init(objectWillChange: Empty().eraseToAnyPublisher())
    }

}
