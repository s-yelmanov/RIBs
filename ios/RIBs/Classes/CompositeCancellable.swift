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
import Combine

/// A `CompositeCancellable` represents a group of cancellable resources that are cancelled together.
public final class CompositeCancellable: Cancellable {

    /// The number of elements in a composite cancellable set
    public var count: Int {
        cancellableItems.count
    }

    /// Indicates whether the cancellableItems is empty
    public var isEmpty: Bool {
        cancellableItems.isEmpty
    }

    /// Indicates whether the cancellableItems is not empty
    public var isNotEmpty: Bool {
        cancellableItems.isEmpty == false
    }

    public init() {}

    /// Insert a cancellable to cancellableItems
    ///
    /// - parameter cancellable: to add to a composite cancellable set
    public func insert(_ cancellable: AnyCancellable) {
        guard !isCancelled else {
            cancellable.cancel()
            return
        }
        cancellableItems.insert(cancellable)
    }
    
    /// Remove a cancellable from cancellableItems
    ///
    /// - parameter cancellable: to remove from a composite cancellable set
    /// - returns The value of the cancellable parameter if it was a cancellable of the set; otherwise, nil.
    @discardableResult
    public func remove(_ cancellable: AnyCancellable) -> AnyCancellable? {
        guard !isCancelled else {
            cancellable.cancel()
            return nil
        }
        return cancellableItems.remove(cancellable)
    }

    /// Cancel all cancellableItems in a composite cancellable set
    public func cancel() {
        guard !isCancelled else { return }
        isCancelled = true
        cancellableItems.forEach { $0.cancel() }
    }

    public func asAnyCancellable() -> AnyCancellable {
        AnyCancellable(self)
    }

    // MARK: - Private

    private var isCancelled: Bool = false
    fileprivate var cancellableItems: Set<AnyCancellable> = .init()
}

public extension AnyCancellable {
    func store(in composite: CompositeCancellable) {
        store(in: &composite.cancellableItems)
    }
}
