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

import UIKit
import Foundation

public extension FlowPresentationRoutine where Self: Routing {
    func pushAttached(
        router: ViewableRouting,
        transition: FlowTransition = .default,
        completion: BaseCompletion? = nil,
        unique: Bool = true
    ) {
        if unique, viewableChildren.map(\.routeIdentifier).contains(router.routeIdentifier) { return }

        attachChild(router)
        push(viewController: router.viewControllable, transition: transition, completion: completion)
    }

    func popDetached(animated: Bool = true, completion: BaseCompletion? = nil) {
        detachCurrentChild()
        pop(animated: animated, completion: completion)
    }
}

public extension FlowPresentationRoutine where Self: Routing & NavigationContainable {
    /// Pops all children but the first one this subflow owns, which controller exists in the navigation stack
    func popToRoot(animated: Bool = true, transition: FlowTransition = .default, completion: BaseCompletion? = nil) {
        var childViewableRouters = childViewableRoutersInFlow
        guard !childViewableRouters.isEmpty else { return }
        let root = childViewableRouters.remove(at: 0)

        flowTransition = transition
        navigationViewControllable.uiViewController.popToViewController(
            root.viewControllable.uiViewController,
            animated: animated,
            completion: completion
        )
    }

    /// Pops all children this subflow owns after the one with specified identifier
    func pop(
        to identifier: String,
        animated: Bool = true,
        transition: FlowTransition = .default,
        completion: BaseCompletion? = nil
    ) {
        var childrenAfterIdentifier = children.drop(while: { $0.routeIdentifier != identifier })

        guard !childrenAfterIdentifier.isEmpty else {
            return assertionFailure("Attempt to pop non-existent child with identifier: \(identifier)")
        }
        _ = childrenAfterIdentifier.removeFirst()

        let remainingViewControllers = childrenAfterIdentifier.reduce(.init()) { result, next -> [UIViewController] in
            if let subflow = next as? ViewableSubflowRouting {
                return result + subflow.allChildViewControllers
            } else if let viewableChild = next as? ViewableRouting {
                return result + [viewableChild.viewControllable.uiViewController]
            }
            return result
        }

        flowTransition = transition
        navigationViewControllable.uiViewController.replaceViewControllers(
            with: parentViewControllersStack.filter { remainingViewControllers.contains($0) == false },
            animated: animated,
            completion: completion
        )
    }

    /// Pops the subflow with the specified `identifier` from children
    func popSubflow(
        with identifier: String,
        animated: Bool = true,
        transition: FlowTransition = .default,
        completion: BaseCompletion? = nil
    ) {
        let subflow = viewableSubflowChildren.first(where: { $0.routeIdentifier == identifier })
        guard let allChildViewControllers = subflow?.allChildViewControllers else { return }

        flowTransition = transition
        navigationViewControllable.uiViewController.replaceViewControllers(
            with: parentViewControllersStack.filter { allChildViewControllers.contains($0) == false },
            animated: animated,
            completion: completion
        )
    }

    /// Pops child with the specified `identifier` from children
    func popModule(
        with identifier: String,
        animated: Bool = true,
        transition: FlowTransition = .default,
        completion: BaseCompletion? = nil
    ) {
        guard let module = viewableChildren.first(where: { $0.routeIdentifier == identifier }) else { return }

        flowTransition = transition
        navigationViewControllable.uiViewController.replaceViewControllers(
            with: parentViewControllersStack.filter { $0 !== module.viewControllable.uiViewController },
            animated: animated,
            completion: completion
        )
    }

    /// Replaces the last child in navigation stack with the specified `ViewableRouting`
    func replaceLast(
        with router: ViewableRouting,
        animated: Bool = true,
        transition: FlowTransition = .default,
        completion: BaseCompletion? = nil
    ) {
        var childViewableRouters = childViewableRoutersInFlow

        guard !childViewableRouters.isEmpty else {
            return pushAttached(router: router, transition: transition, completion: completion)
        }

        detachChild(childViewableRouters.removeLast())
        var newChildren = Array(parentViewControllersStack.dropLast(1))
        newChildren.append(router.viewControllable.uiViewController)
        attachChild(router)

        flowTransition = transition
        navigationViewControllable.uiViewController.replaceViewControllers(
            with: newChildren,
            animated: true,
            completion: completion
        )
    }

    /// Replaces the child with specified `identifier` in navigation stack with the specified `ViewableRouting`
    func replaceModule(
        with identifier: String,
        with router: ViewableRouting,
        animated: Bool = true,
        transition: FlowTransition = .default,
        completion: BaseCompletion? = nil
    ) {
        guard let currentChild = viewableChildren.first(where: { $0.routeIdentifier == identifier }),
              let currentChildIndex = children.firstIndex(where: { $0 === currentChild }),
              let viewControllerIndex = parentViewControllersStack.firstIndex(where: { $0 === currentChild.viewControllable.uiViewController }) else { return }

        var newViewControllersStack = parentViewControllersStack
        newViewControllersStack[viewControllerIndex] = router.viewControllable.uiViewController
        attachChild(router, at: currentChildIndex)

        flowTransition = transition
        navigationViewControllable.uiViewController.replaceViewControllers(
            with: newViewControllersStack,
            animated: animated,
            completion: completion
        )
    }
}

extension FlowPresentationRoutine where Self: Routing {
    var viewableSubflowChildren: [ViewableSubflowRouting] {
        children.compactMap({ $0 as? ViewableSubflowRouting })
    }

    var viewableChildren: [ViewableRouting] {
        children.compactMap({ $0 as? ViewableRouting })
    }
}

extension FlowPresentationRoutine where Self: Routing & NavigationContainable {
    var childViewableRoutersInFlow: [ViewableRouting] {
        viewableChildren.filter {
            navigationViewControllable.uiViewController.children.contains($0.viewControllable.uiViewController)
        }
    }

    var parentViewControllersStack: [UIViewController] {
        navigationViewControllable.uiViewController.viewControllers
    }
}
