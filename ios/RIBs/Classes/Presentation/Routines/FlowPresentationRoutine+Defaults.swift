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

public extension FlowPresentationRoutine {
    func pop(animated: Bool = true, completion: BaseCompletion? = nil) {
        navigationViewControllable.uiViewController.popViewController(animated: animated, completion: completion)
    }
}

public extension FlowPresentationRoutine where Self: ViewableFlowRouting {
    func pushAttached(router: ViewableRouting, transition: FlowTransition = .default, completion: BaseCompletion? = nil) {
        attachChild(router)
        push(viewController: router.viewControllable, transition: transition, completion: completion)
    }

    func popDetached(animated: Bool = true, completion: BaseCompletion? = nil) {
        detachCurrentChild()
        pop(animated: animated, completion: completion)
    }

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
    }

    private var childViewableRouters: [ViewableRouting] {
        children
            .compactMap({ $0 as? ViewableRouting })
            .filter { [unowned self] router in
                navigationViewControllable.uiViewController.children.contains(router.viewControllable.uiViewController)
            }
    }
}
