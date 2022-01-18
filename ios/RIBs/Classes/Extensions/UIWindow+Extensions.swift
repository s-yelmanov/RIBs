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

public extension UIWindow {
    struct Transition {
        public enum Style {
            case fade, toTop, toBottom, toLeft, toRight

            func transition() -> CATransition {
                let transition = CATransition()
                transition.type = CATransitionType.push

                switch self {
                case .fade:
                    transition.type = CATransitionType.fade
                    transition.subtype = nil
                case .toLeft:
                    transition.subtype = CATransitionSubtype.fromLeft
                case .toRight:
                    transition.subtype = CATransitionSubtype.fromRight
                case .toTop:
                    transition.subtype = CATransitionSubtype.fromTop
                case .toBottom:
                    transition.subtype = CATransitionSubtype.fromBottom
                }
                return transition
            }
        }

        public var duration: TimeInterval
        public var timingFunction: CAMediaTimingFunctionName
        public var style: Transition.Style

        public init(
            duration: TimeInterval,
            style: Transition.Style = .fade,
            timingFunction: CAMediaTimingFunctionName = .linear) {
            self.duration = duration
            self.style = style
            self.timingFunction = timingFunction
        }

        var animation: CATransition {
            let transition = style.transition()
            transition.duration = duration
            transition.timingFunction = CAMediaTimingFunction(name: timingFunction)
            return transition
        }
    }

    // http://stackoverflow.com/a/27153956/849645
    func set(
        rootViewController newRootViewController: UIViewController,
        withTransition transition: Transition? = nil
    ) {
        let previousViewController = rootViewController

        if let animation = transition?.animation {
            // Add the animation
            layer.add(animation, forKey: kCATransition)
        }

        rootViewController = newRootViewController

        // Update status bar appearance using the new view controllers appearance - animate if needed
        if UIView.areAnimationsEnabled {
            UIView.animate(withDuration: CATransaction.animationDuration()) {
                newRootViewController.setNeedsStatusBarAppearanceUpdate()
            }
        } else {
            newRootViewController.setNeedsStatusBarAppearanceUpdate()
        }

        if let previousViewController = previousViewController {
            // Allow the view controller to be deallocated
            previousViewController.dismiss(animated: false) {
                // Remove the root view in case its still showing
                previousViewController.view.removeFromSuperview()
            }
        }
    }
}
