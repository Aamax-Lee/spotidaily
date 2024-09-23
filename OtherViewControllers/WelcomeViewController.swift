//
//  WelcomeViewController.swift
//  musictime
//
//  Created by Aamax Lee on 21/4/2024.
//

import UIKit

class WelcomeViewController: UIViewController {
    
//    creates sign in button at bottom of screen
    private let signInButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .white
        button.setTitle("Sign in with Spotify", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Welcome to SpotiDaily"
        
//        sets background color (gradient)
        view.backgroundColor = UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0)
        let layer = CAGradientLayer()
        layer.frame = view.bounds
        layer.colors = [UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0), UIColor.black.cgColor]

        view.layer.insertSublayer(layer, at: 0)
        
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
//    when user presses sign in button, call handlesignin helper function, then perform segue to authViewController
    @objc func didTapSignIn() {
        let vc = authViewController()
        vc.completionHandler = { [weak self] success in
            DispatchQueue.main.async {
                self?.handleSignIn(success: success)
            }
        }
        
        performSegue(withIdentifier: "toSignInVCSegue", sender: self)
        
    }
    
//    sign in process, returns whether action was successful or not
    private func handleSignIn(success: Bool) {
        guard success else {
            let alert = UIAlertController(title: "Oops", message: "Something went wrong.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))
            present(alert, animated: true)
            return
        }
        self.performSegue(withIdentifier: "toTabVCSegue", sender: nil)
        
    }
    
//    IBAction connected to the sign-in button in the storyboard
    @IBAction func signInButton(_ sender: Any) {
        didTapSignIn()
    }
    
    
    

// MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination
        // Pass the selected object to the new view controller
        if segue.identifier == "toSignInVCSegue" {
                if let vc = segue.destination as? authViewController {
                    vc.completionHandler = { [weak self] success in
                        DispatchQueue.main.async {
                            self?.handleSignIn(success: success)
                        }
                    }
                }
            }
        
    }
    

}
