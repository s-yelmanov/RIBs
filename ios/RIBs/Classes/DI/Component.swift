//
//  Copyright (c) 2017. Uber Technologies
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation

/// The base class for all components.
///
/// A component defines private properties a RIB provides to its internal `Router`, `Interactor`, `Presenter` and
/// view units, as well as public properties to its child RIBs.
///
/// A component subclass implementation should conform to child 'Dependency' protocols, defined by all of its immediate
/// children.
open class Component<DependencyType>: Dependency {

    /// The dependency of this `Component`.
    public let dependency: DependencyType

    /// Initializer.
    ///
    /// - parameter dependency: The dependency of this `Component`, usually provided by the parent `Component`.
    public init(dependency: DependencyType) {
        self.dependency = dependency
    }

    /// Used to create a shared dependency in your `Component` sub-class. Shared dependencies are retained and reused
    /// by the component. Each dependent asking for this dependency will receive the same instance while the component
    /// is alive.
    ///
    /// - note: Any shared dependency's constructor may not switch threads as this might cause a deadlock.
    ///
    /// - parameter factory: The closure to construct the dependency.
    /// - returns: The instance.
    public final func shared<T>(__function: String = #function, tag: String = "", _ factory: () -> T) -> T {
        lock.lock()
        defer {
            lock.unlock()
        }

        // Additional nil coalescing is needed to mitigate a Swift bug appearing in Xcode 10.
        // see https://bugs.swift.org/browse/SR-8704.
        // Without this measure, calling `shared` from a function that returns an optional type
        // will always pass the check below and return nil if the instance is not initialized.
        let key = __function + tag
        if let instance = (sharedStrongInstances[key] as? T?) ?? nil {
            return instance
        }

        let instance = factory()
        sharedStrongInstances[key] = instance

        return instance
    }

    /// Used to create a weak shared dependency in your `Component` sub-class.
    /// Weak shared dependencies are not retained and reused by the component only if there is at least one instance owner.
    /// Each dependent asking for this dependency will receive the same instance while the other owner is alive.
    /// Otherwise a new instance is created.
    ///
    /// - note: Any shared dependency's constructor may not switch threads as this might cause a deadlock.
    /// - note: Weak shared scope is separated from the common one.
    ///
    /// - parameter factory: The closure to construct the dependency.
    /// - returns: The instance.
    public final func sharedWeak<T>(__function: String = #function, tag: String = "", _ factory: () -> T) -> T {
        lock.lock()
        defer {
            lock.unlock()
        }

        // Additional nil coalescing is needed to mitigate a Swift bug appearing in Xcode 10.
        // see https://bugs.swift.org/browse/SR-8704.
        // Without this measure, calling `shared` from a function that returns an optional type
        // will always pass the check below and return nil if the instance is not initialized.
        let key = __function + tag
        if let instance = (sharedWeakInstances.object(forKey: key as NSString) as? T?) ?? nil {
            return instance
        }

        let instance = factory()
        sharedWeakInstances.setObject(instance as AnyObject, forKey: key as NSString)

        return instance
    }

    // MARK: - Private

    private var sharedStrongInstances = [String: Any]()
    private var sharedWeakInstances = NSMapTable<NSString, AnyObject>(keyOptions: .strongMemory, valueOptions: .weakMemory)
    private let lock = NSRecursiveLock()
}

/// The special empty component.
open class EmptyComponent: EmptyDependency {

    /// Initializer.
    public init() {}
}
