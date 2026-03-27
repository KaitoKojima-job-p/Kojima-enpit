//
//  HimaTimeTableViewCell.swift
//  finderTest
//
//  Created by Tetsu Sasaki on 2023/12/30.
//

import UIKit

class HimaTimeTableViewCell: UITableViewCell, UIScrollViewDelegate {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var swichbutton: UISwitch!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var squareField: UIScrollView!
    
    var horizontalScrollHandler: ((CGFloat) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        squareField.delegate = self
        squareField.isPagingEnabled = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    // UIScrollViewDelegateのメソッド
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == squareField {
            // squareFieldのスクロールイベントを検知したら、horizontalScrollHandlerを呼び出して他のセルを同期させる
            horizontalScrollHandler?(scrollView.contentOffset.x)
        }
    }
}
