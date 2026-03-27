//
//  VerticalDateCell.swift
//  ReservationGanttChart
//
//  Created by Hoang Luong on 26/5/20.
//  Copyright © 2020 Hoang Luong. All rights reserved.
//

import UIKit

class VerticalDateCell: UICollectionViewCell {
    
    var borderColor: UIColor = .darkGray
    var borderWidth: CGFloat = 0.5
    var date: Date = Date() {
        didSet {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH"
            timeLabel.text = dateFormatter.string(from: date)
        }
    }
    
    @IBOutlet weak var timeLabel: UILabel!// 時刻を表示するためのラベル
    
    override func awakeFromNib() {
        super.awakeFromNib()
    
        self.layer.borderWidth = borderWidth
        self.layer.borderColor = borderColor.cgColor
        timeLabel.textColor = .black  // ダークモードに関わらず初期のテキストカラーを設定
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        backgroundColor = .white
        timeLabel.textColor = .black  // 再利用時にテキストカラーをリセット
    }
    func set(selected: Bool, darkModeOn: Bool) {
        backgroundColor = selected ? UIColor(named: "grayLightest") : darkModeOn ? .black : .white
        timeLabel.textColor = darkModeOn ? .white : .black  // ダークモードの際のテキストカラーを切り替え
    }
}


