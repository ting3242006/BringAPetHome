//
//  PrivacyPolicyViewController.swift
//  BringAPetHome
//
//  Created by Ting on 2022/7/5.
//

import UIKit
import WebKit

class PrivacyPolicyViewController: UIViewController, WKNavigationDelegate {
    
//    let fullScreenSize = UIScreen.main.bounds.size
    var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // style
        view.backgroundColor = .white
        title = "隱私權政策"
        webView = WKWebView(frame: CGRect(x: 0, y: 0,
                                          width: UIScreen.fullScreenSize.width,
                                          height: UIScreen.fullScreenSize.height))
        webView.navigationDelegate = self
        self.view.addSubview(webView)
        self.start()
        layout()
    }
    
    @objc func start() {
        self.view.endEditing(true)
        let url = URL(string: "https://www.privacypolicies.com/live/d5b73a39-6c8b-46b0-9777-9756338ecff8")
        let urlRequest = URLRequest(url: url!)
        webView.load(urlRequest)
    }
    
    @objc private func didTapClose() {
        dismiss(animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        print(error.localizedDescription)
    }
    
    func layout() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left")?
                .withTintColor(UIColor.darkGray)
                .withRenderingMode(.alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(didTapClose)
        )
    }
}
