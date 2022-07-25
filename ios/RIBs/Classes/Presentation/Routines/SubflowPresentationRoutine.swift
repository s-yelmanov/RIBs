//
//  SubflowPresentationRoutine.swift
//  
//
//  Created by Vladyslav Skintiian on 7/25/22.
//

import Foundation

public protocol SubflowPresentationRoutine: FlowPresentationRoutine { }

public extension SubflowPresentationRoutine where Self: ViewableSubflowRouting {
    func popToRoot(animated: Bool = true, completion: BaseCompletion? = nil) {
        var childViewableRouters = childViewableRouters
        guard !childViewableRouters.isEmpty else { return }
        let root = childViewableRouters.remove(at: 0)

        for child in childViewableRouters.reversed() {
            detachChild(child)
        }

        navigationViewControllable.uiViewController.popToViewController(
            root.viewControllable.uiViewController,
            animated: animated,
            completion: completion
        )

        ensureViewStackConsistency()
    }

    func pop(with identifier: String, animated: Bool = true, completion: BaseCompletion? = nil) {
        var childViewableRouters = childViewableRouters
        guard !childViewableRouters.isEmpty else {
            return assertionFailure("Attempt to pop non-existent child with identifier: \(identifier)")
        }

        guard let lastModuleIndex = childViewableRouters.lastIndex(where: { $0.routeIdentifier == identifier }),
              let firstModuleIndex = childViewableRouters.firstIndex(where: { $0.routeIdentifier == identifier })
        else {
            return
        }

        var childrenToRemove: [ViewableRouting] = []
        var currentIndex = lastModuleIndex

        while currentIndex >= firstModuleIndex {
            let removedModule = childViewableRouters.remove(at: currentIndex)
            childrenToRemove.append(removedModule)
            currentIndex -= 1
        }

        var currentChildren = navigationViewControllable.uiViewController.children
        childrenToRemove.forEach { [unowned self] router in
            detachChild(router)

            if let index = currentChildren.firstIndex(of: router.viewControllable.uiViewController) {
                currentChildren.remove(at: index)
            }
        }

        navigationViewControllable.uiViewController.replaceViewControllers(
            with: currentChildren,
            animated: animated,
            completion: completion
        )

        ensureViewStackConsistency()
    }

    func pop(to identifier: String, animated: Bool = true, completion: BaseCompletion? = nil) {
        var childViewableRouters = childViewableRouters
        guard !childViewableRouters.isEmpty else {
            return assertionFailure("Attempt to pop non-existent child with identifier: \(identifier)")
        }

        guard childViewableRouters.contains(where: { $0.routeIdentifier == identifier }) else {
            return
        }

        while childViewableRouters.last?.routeIdentifier != identifier {
            detachChild(childViewableRouters.removeLast())
        }

        guard let targetViewController = childViewableRouters.last?.viewControllable.uiViewController,
              navigationViewControllable.uiViewController.children.contains(targetViewController) else { return }

        navigationViewControllable.uiViewController.popToViewController(
            targetViewController,
            animated: animated,
            completion: completion
        )

        ensureViewStackConsistency()
    }

    private var childViewableRouters: [ViewableRouting] {
        children
            .compactMap({ $0 as? ViewableRouting })
            .filter { [unowned self] router in
                navigationViewControllable.uiViewController.children.contains(router.viewControllable.uiViewController)
            }
    }
}
