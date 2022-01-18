//
//  File.swift
//  
//
//  Created by Vladyslav Skintiian on 18.01.2022.
//

import UIKit

protocol NavigationControllerDelegateProxyMethodsHandler: FlowPresentationRoutine {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    )
}

final class NavigationControllerDelegateProxy: NSObject, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
    weak var handler: NavigationControllerDelegateProxyMethodsHandler?

    // MARK: - UINavigationControllerDelegate

    public func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        navigationController.interactivePopGestureRecognizer?.delegate = self
        handler?.navigationController(navigationController, didShow: viewController, animated: animated)

        // This is an adapted workaround of this solution: https://stackoverflow.com/questions/34942571/how-to-enable-back-left-swipe-gesture-in-uinavigationcontroller-after-setting-le/43433530#43433530
        currentChildrenCount = navigationController.viewControllers.count
        navigationPresentationInProgress = false
    }

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {

        guard case let .custom(push, pop) = handler?.flowTransition else {
            return nil
        }

        switch operation {
        case .none:
            return nil
        case .pop:
            return pop
        case .push:
            return push
        @unknown default:
            assertionFailure("Unknown default case for operation: \(operation)")
            return nil
        }
    }

    // MARK: - UIGestureRecognizerDelegate

    func startPresentation() {
        navigationPresentationInProgress = true
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        currentChildrenCount > 1 && navigationPresentationInProgress == false
    }
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        true
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        true
    }

    // MARK: - Private

    private var navigationPresentationInProgress = false
    private var currentChildrenCount = 0
}

extension ViewableFlowRouter: NavigationControllerDelegateProxyMethodsHandler {
    func navigationController(
        _ navigationController: UINavigationController,
        didShow viewController: UIViewController,
        animated: Bool
    ) {
        children
            .compactMap { $0 as? ViewableRouting }
            .filter { child in
                navigationController.viewControllers.contains(child.viewControllable.uiViewController) == false
            }
            .forEach { child in
                self.detachChild(child)
                self.didDetachChild(child: child)
            }
    }
}
