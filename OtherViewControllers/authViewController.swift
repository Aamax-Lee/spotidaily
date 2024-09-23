//
//  ViewController.swift
//  musictime
//
//  Created by Aamax Lee on 20/4/2024.
//

import UIKit
import SafariServices
import WebKit

// This view controller handles user authentication using a web view to sign in to Spotify
class authViewController: UIViewController, WKNavigationDelegate {
    
//    creates a webview that fits the screen width
    private let webView: WKWebView = {
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        let config = WKWebViewConfiguration()
        
        config.defaultWebpagePreferences = prefs
        
        let webView = WKWebView(frame: .zero, configuration: config)
        
        return webView
    }()
    
//    A completion handler that is called when the authentication process is complete.
    public var completionHandler: ((Bool) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        when view loads, set title, background color, and webview
        title = "Sign In"
        view.backgroundColor = .systemBackground
        webView.navigationDelegate = self
        view.addSubview(webView)
        
//  Load sign in url into webview after ensuring it is valid
        guard let url = AuthManager.shared.signInURL else {
            print("url = AuthManager.shared.signInURL has error")
            return
        }
        
        webView.load(URLRequest(url: url))
    }
    
//  Called to notify the view controller that its view's bounds have changed
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        webView.frame = view.bounds
    }
    
//    Called when the web view begins to load a new web page
//    spotify loads a new webpage with the authorization code in its query parameters
//    we use this code to obtain the temporary access token
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        url = current URL from webview
        guard let url = webView.url else {
            return
        }

//        Extract the authorization code from the URL's query parameters
        guard let code = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("code not right")
            return
        }
        
        webView.isHidden = true

//        Exchange the authorization code for an access token
        AuthManager.shared.exchangeCodeForToken(code: code) { [weak self] success in
            DispatchQueue.main.async {
                print("success in exchange code for token")
                // Perform segue to pop back to root view controller
                self?.performSegue(withIdentifier: "toWelcomeVCSegue", sender: success)
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toWelcomeVCSegue" {
//            Pass the success flag to the welcome view controller
            if let success = sender as? Bool, success {
                self.completionHandler?(true)
            }
        }
    }
    
    }

    
