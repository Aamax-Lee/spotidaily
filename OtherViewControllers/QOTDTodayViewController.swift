//
//  QOTDTodayViewController.swift
//  musictime
//
//  Created by Aamax Lee on 30/4/2024.
//

import UIKit

class QOTDTodayViewController: UIViewController {
    
    @IBOutlet weak var QOTDlabel: UILabel!
    @IBOutlet weak var QOTDImage: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0)
        let layer = CAGradientLayer()
        layer.frame = view.bounds
        layer.colors = [UIColor(red: 98/255, green: 98/255, blue: 98/255, alpha: 1.0), UIColor.black.cgColor]
        
        view.layer.insertSublayer(layer, at: 0)
        
        //        getSOTDofTheDay
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        
        appDelegate?.databaseController?.getSOTDofTheDay{ qotd in
            if let qotd = qotd {
                self.QOTDlabel.text = qotd.quote
            }
        }
          
    }
    
    @IBAction func readyButton(_ sender: Any) {
        self.dismiss(animated: true)
    }
}
        
        
        /*
         // MARK: - Navigation
         
         // In a storyboard-based application, you will often want to do a little preparation before navigation
         override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
         // Get the new view controller using segue.destination.
         // Pass the selected object to the new view controller.
         }
         */
        
    

