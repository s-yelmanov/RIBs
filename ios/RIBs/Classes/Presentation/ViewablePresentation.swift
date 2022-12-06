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

public enum ViewablePresentation {
    public typealias BaseCompletion = () -> Void
    public typealias ViewControllableCompletion = (ViewControllable) -> Void

    case asRoot(in: UIWindow, with: UIWindow.Transition? = nil)
    case embedded(in: ViewControllable, contentView: UIView, completion: ViewControllableCompletion? = nil)
    case modally(
        on: AdaptiveViewableRouting,
        presentationStyle: UIModalPresentationStyle = .automatic,
        animated: Bool = true,
        completion: BaseCompletion? = nil
    )

    public func execute(with viewController: ViewControllable) {
        switch self {
        case .asRoot(let window, let transition):
            window.set(rootViewController: viewController.uiViewController, withTransition: transition)
            window.makeKeyAndVisible()

        case .embedded(let parent, let contentView, let completion):
            contentView.addSubview(viewController.uiViewController.view)
            viewController.uiViewController.view.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                viewController.uiViewController.view.topAnchor.constraint(equalTo: contentView.topAnchor),
                viewController.uiViewController.view.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                viewController.uiViewController.view.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                viewController.uiViewController.view.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])

            parent.uiViewController.addChild(viewController.uiViewController)
            viewController.uiViewController.didMove(toParent: parent.uiViewController)
            completion?(viewController)

        case .modally(let router, let presentationStyle, let animated, let completion):
            viewController.uiViewController.modalPresentationStyle = presentationStyle
            viewController.uiViewController.presentationController?.delegate = router
            router.viewControllable.uiViewController.present(
                viewController.uiViewController,
                animated: animated,
                completion: completion
            )
        }
    }

    public enum RawValue {
        case asRoot, embedded, modally
    }

    var rawValue: RawValue {
        switch self {
        case .asRoot:
            return .asRoot
        case .embedded:
            return .embedded
        case .modally:
            return .modally
        }
    }
}

