//
//  OnboardingPageViewController.swift
//  Cornell Sun
//
//  Created by Mindy Lou on 3/19/18.
//  Copyright © 2018 cornell.sun. All rights reserved.
//

import UIKit
import OneSignal

class OnboardingPageViewController: UIPageViewController {

    var pageControl: UIPageControl!
    var nextButton: Button!
    var loadingIndicator: UIActivityIndicatorView!
    var pages = [UIViewController]()

    let pageControlBottomInset: CGFloat = 20
    let pageControlSize: CGSize = CGSize(width: 20, height: 9)
    let nextButtonSize: CGSize = CGSize(width: 14.5, height: 12)
    let nextButtonInset: CGFloat = 30
    let nextButtonBottomInset: CGFloat = 20

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pages = [OnboardingViewController(type: .welcome), OnboardingViewController(type: .notifications)]
        setViewControllers([pages[0]], direction: .forward, animated: true, completion: nil)
        delegate = self
        dataSource = self

        pageControl = UIPageControl()
        pageControl.currentPage = 0
        pageControl.currentPageIndicatorTintColor = .white
        pageControl.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.5)
        pageControl.numberOfPages = pages.count
        view.addSubview(pageControl)

        var bottomArea = view.layoutMarginsGuide.snp.bottom
        if #available(iOS 11, *) {
            bottomArea = view.safeAreaLayoutGuide.snp.bottom
        }
        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.size.equalTo(pageControlSize)
            make.bottom.equalTo(bottomArea).inset(pageControlBottomInset)
        }

        nextButton = Button()
        nextButton.setImage(#imageLiteral(resourceName: "arrowThinCopy"), for: .normal)
        nextButton.addTarget(nil, action: #selector(pageNextTapped(_:)), for: .touchUpInside)
        view.addSubview(nextButton)
        nextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(nextButtonInset)
            make.size.equalTo(nextButtonSize)
            make.bottom.equalTo(bottomArea).inset(nextButtonBottomInset)
        }

        loadingIndicator = UIActivityIndicatorView()
        loadingIndicator.style = .whiteLarge
        view.addSubview(loadingIndicator)
        loadingIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    @objc func pageNextTapped(_ sender: UIButton) {
        if let viewController = viewControllers?.first, let index = pages.index(of: viewController) {
            if index == 1 {
                dismissOnboarding()
            } else {
                setViewControllers([pages[index + 1]], direction: .forward, animated: true, completion: nil)
                pageControl.currentPage = index + 1
            }
        }
    }

    @objc func dismissOnboarding() {
        OneSignal.promptForPushNotifications(userResponse: { accepted in
            print("User accepted notifications: \(accepted)")
            let userDefaults = UserDefaults.standard
            userDefaults.setValue(accepted, forKey: breakingNewsKey)
            userDefaults.setValue(true, forKey: hasOnboardedKey)
            if accepted {
                OneSignal.sendTag(NotificationType.breakingNews.rawValue, value: NotificationType.breakingNews.rawValue)
            }
            self.loadingIndicator.startAnimating()
            prepareInitialPosts { posts, mainHeadlinePost in
                let tabBarController = TabBarViewController(with: posts, mainHeadlinePost: mainHeadlinePost)
                guard let appDelegate = UIApplication.shared.delegate, let window = appDelegate.window else { return }
                window?.rootViewController = tabBarController
                self.loadingIndicator.stopAnimating()
                self.dismiss(animated: true, completion: nil)
            }
        })
    }

}

extension OnboardingPageViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = pages.index(of: viewController), index != 0 {
            return pages[index - 1]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = pages.index(of: viewController), index < pages.count - 1 {
            return pages[index + 1]
        }
        return nil
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let viewControllers = pageViewController.viewControllers, let index = pages.index(of: viewControllers[0]) {
            pageControl.currentPage = index
        }
    }

}
