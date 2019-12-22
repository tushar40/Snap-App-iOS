//
//  ShowMessageImageViewController.swift
//  Snap-App
//
//  Created by Tushar Gusain on 18/12/19.
//  Copyright © 2019 Hot Cocoa Software. All rights reserved.
//

import UIKit

class ShowMessageImageViewController: UIViewController {

    //MARK:- IBOutlets
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var progressView: UIProgressView!
    
    //MARK:- Member Variables
    var timeToDismissPhotoInSecondes: Float = 5.0
    var count: Float = 0.0
    var timeInterval: Float = 0.1
    
    var deleteMessage: ((JSQMessage) -> Void)!
    var message: JSQMessage!
    
    var isIncomingMessage = false
    
    var timer: Timer? = nil
    
    //MARK:- Lifecycle hooks
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.image = (message.media as! JSQPhotoMediaItem).image
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress)))
        startTimer()
    }

    //MARK:- Custom methods
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(timeInterval), repeats: true) { [weak self] (timer) in
            guard let self = self else { return }
            self.count += self.timeInterval
            self.progressView.isHidden = false
            self.progressView.progress = (self.count/self.timeToDismissPhotoInSecondes)
            print(self.count)
            if self.timeToDismissPhotoInSecondes - self.count < 0.1 {
                self.count = 0.0
                self.dismiss(animated: true, completion: {
                    if self.isIncomingMessage {
                        self.deleteMessage(self.message)
                    }
                })
            }
        }
    }
    
    private func stopTimer() {
        if timer != nil {
            timer?.invalidate()
            progressView.isHidden = true
        }
    }
    
    @objc func handleLongPress(gestureReconizer: UILongPressGestureRecognizer) {
        if gestureReconizer.state != UIGestureRecognizer.State.ended {
            stopTimer()
        }
        else {
            startTimer()
        }
    }
}
