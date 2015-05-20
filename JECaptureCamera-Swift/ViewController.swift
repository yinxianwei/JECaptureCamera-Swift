//
//  ViewController.swift
//  JECaptureCamera-Swift
//
//  Created by 尹现伟 on 15/5/20.
//  Copyright (c) 2015年 尹现伟. All rights reserved.
//

import UIKit

class ViewController: UIViewController,JESPViewControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    @IBAction func openClick(sender: AnyObject) {
        
        self.test()
    }
    
    func test(){
        var flowlayout:UICollectionViewFlowLayout = UICollectionViewFlowLayout();
        flowlayout.scrollDirection = UICollectionViewScrollDirection.Vertical;
        
        var s = JESPViewController(collectionViewLayout:flowlayout)
        s.delegate = self
        s.allowsMultipleSelection = false
        s.maximumOfSelected = 6;

        self.presentViewController(UINavigationController(rootViewController: s), animated: true, completion: nil)
        
    }
    
    func SPViewControllerdidSelectImages(images: NSArray) {
       
        self.imageView.image = images.firstObject as? UIImage
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

