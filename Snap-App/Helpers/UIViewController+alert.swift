//
//  UIViewController+alert.swift
//  Snap-App
//
//  Created by Tushar Gusain on 12/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import UIKit

extension UIViewController
{
    func alert(title: String?, message: String?, buttonTitle: String = "Close")
    {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: buttonTitle, style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
