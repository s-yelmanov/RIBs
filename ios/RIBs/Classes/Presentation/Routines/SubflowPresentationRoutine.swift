//
//  SubflowPresentationRoutine.swift
//  
//
//  Created by Vladyslav Skintiian on 7/25/22.
//

import UIKit
import Foundation

public protocol SubflowPresentationRoutine: FlowPresentationRoutine { }

public extension SubflowPresentationRoutine where Self: ViewableSubflowRouting {
    /// Pops all children but the first one this subflow owns, which controller exists in the navigation stack
    func popToRoot(animated: Bool = true, transition: FlowTransition = .default, completion: BaseCompletion? = nil) {
        var childViewableRouters = childViewableRoutersInFlow
        guard !childViewableRouters.isEmpty else { return }
        let root = childViewableRouters.remove(at: 0)

        for child in childViewableRouters.reversed() {
            detachChild(child)
        }

        flowTransition = transition
        navigationViewControllable.uiViewController.popToViewController(
            root.viewControllable.uiViewController,
            animated: animated,
            completion: completion
        )
        ensureViewStackConsistency()
    }

    /// Pops all children this subflow owns after the one with specified identifier
    func pop(
        to identifier: String,
        animated: Bool = true,
        transition: FlowTransition = .default,
        completion: BaseCompletion? = nil
    ) {
        var childViewableRouters = childViewableRoutersInFlow
        guard !childViewableRouters.isEmpty else {
            return assertionFailure("Attempt to pop non-existent child with identifier: \(identifier)")
        }

        var childrenAfterIdentifier = childViewableRouters.drop(while: { $0.routeIdentifier != identifier })
        guard !childrenAfterIdentifier.isEmpty else { return }
        _ = childrenAfterIdentifier.removeFirst()

        for child in childrenAfterIdentifier.reversed() {
            detachChild(child)
        }

        let remainingViewControllers = childrenAfterIdentifier.map(\.viewControllable.uiViewController)

        flowTransition = transition
        navigationViewControllable.uiViewController.replaceViewControllers(
            with: parentViewControllersStack.filter { remainingViewControllers.contains($0) == false },
            animated: animated,
            completion: completion
        )
        ensureViewStackConsistency()
    }

    /// Pops the subflow with the specified `identifier` from children
    func popSubflow(
        with identifier: String,
        animated: Bool = true,
        transition: FlowTransition = .default,
        completion: BaseCompletion? = nil
    ) {
        guard let subflow = viewableSubflowChildren.first(where: { $0.routeIdentifier == identifier }) else { return }

        flowTransition = transition
        navigationViewControllable.uiViewController.replaceViewControllers(
            with: parentViewControllersStack.filter { subflow.allChildViewControllers.contains($0) == false },
            animated: animated,
            completion: completion
        )
        detachChild(subflow)
        ensureViewStackConsistency()
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
        detachChild(module)
        ensureViewStackConsistency()
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
        ensureViewStackConsistency()
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
        ensureViewStackConsistency()
    }
}

extension SubflowPresentationRoutine where Self: ViewableSubflowRouting {
    var viewableSubflowChildren: [ViewableSubflowRouting] {
        children.compactMap({ $0 as? ViewableSubflowRouting })
    }

    var viewableChildren: [ViewableRouting] {
        children.compactMap({ $0 as? ViewableRouting })
    }

    var childViewableRoutersInFlow: [ViewableRouting] {
        viewableChildren.filter {
            navigationViewControllable.uiViewController.children.contains($0.viewControllable.uiViewController)
        }
    }

    var parentViewControllersStack: [UIViewController] {
        navigationViewControllable.uiViewController.viewControllers
    }
}
