//
//  StartViewController.swift
//  finderTest
//
//  Created by ヒロ N on 2024/01/03.
//

import UIKit

class StartViewController: UIViewController {

    var imageView: UIImageView!

        override func viewDidLoad() {
            super.viewDidLoad()
                    
            //imageView作成
            self.imageView = UIImageView(frame: CGRectMake(0, 0, 200, 200))
            //中央寄せ
            self.imageView.center = self.view.center
            //画像を設定
            self.imageView.image = UIImage(named: "hrog")
            //viewに追加
            self.view.addSubview(self.imageView)
        }
    
    // CGRectMakeをwrap
    func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            
            //80%まで縮小させて・・・
            UIView.animate(withDuration: 0.3,
                           delay: 1.0,
                           options: UIView.AnimationOptions.curveEaseOut,
                           animations: { () in
                            self.imageView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }, completion: { (Bool) in
                
            })
            
            //8倍まで拡大！
            UIView.animate(withDuration: 0.2,
                           delay: 1.3,
                           options: UIView.AnimationOptions.curveEaseOut,
                           animations: { () in
                            self.imageView.transform = CGAffineTransform(scaleX: 8.0, y: 8.0)
                            self.imageView.alpha = 0
            }, completion: { (Bool) in
                //で、アニメーションが終わったらimageViewを消す
                self.imageView.removeFromSuperview()
            })
        }

}
