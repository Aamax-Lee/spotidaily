//
//  WebViewViewController.swift
//  musictime
//
//  Created by Aamax Lee on 7/6/2024.
//

import UIKit
import WebKit

class WebViewViewController: UIViewController {

    var ticketWebViewUrl: String?
    
    @IBOutlet weak var ticketWebView: WKWebView!
    
    
    func checkURL(url: URL, completion: @escaping (Bool) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        
        let task = URLSession.shared.dataTask(with: request) { (_, response, error) in
            if let error = error {
                print("Error: \(error)")
                completion(false)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                // Check if the response status code is in the 2xx range (indicating success)
//                print(httpResponse.statusCode)
                let isSuccess = (200...499).contains(httpResponse.statusCode)
                completion(isSuccess)
            } else {
                // Handle non-HTTP responses
                completion(false)
            }
        }
        
        task.resume()
    }

    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let urlString = ticketWebViewUrl, let url = URL(string: urlString) {
            
            checkURL(url: url) { isSuccess in
                if isSuccess {
                    // URL is reachable, proceed to load it in your web view
                    DispatchQueue.main.async {
                        // Load the URL in your web view
                        let request = URLRequest(url: url)
                        self.ticketWebView.load(request)
                        // webView.load(URLRequest(url: url))
                    }
                } else {
                    // URL is not reachable, handle the error (e.g., display an alert)
                    DispatchQueue.main.async {
                        // Show an alert to the user
                        let alert = UIAlertController(title: "Error", message: "Unable to load URL due to restrictions", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(alert, animated: true, completion: nil)
                        
//                        self.dismiss(animated: true)
                    }
                    
                }
            }
        }
        
        
//        if let urlString = ticketWebViewUrl, let url = URL(string: urlString) {
//            print(urlString)
//            let request = URLRequest(url: url)
//            ticketWebView.load(request)
//        }
//        ticketWebView.load(<#T##request: URLRequest##URLRequest#>)
        // Do any additional setup after loading the view.
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
