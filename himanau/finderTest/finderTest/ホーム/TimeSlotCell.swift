//
//  TimeSlotCell.swift
//  finderTest
//
//  Created by 宮脇拓真 on 2023/12/01.
//

import UIKit

class TimeSlotCell: UICollectionViewCell {
    // 時刻を表示するためのUILabel
    let timeLabel: UILabel

    override init(frame: CGRect) {
        timeLabel = UILabel()
        super.init(frame: frame)

        // UILabelの設定
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.systemFont(ofSize: 16)
        // 他に必要な設定があればここに追加

        // UILabelをセルのcontentViewに追加
        contentView.addSubview(timeLabel)

        // オートレイアウト制約の設定
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            timeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
            // 他に必要な制約があればここに追加
        ])
        // セルの境界線の設定
        self.layer.borderWidth = 0.5
        self.layer.borderColor = UIColor.black.cgColor
    }

    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // セルに表示する時刻を設定するメソッド
    func configure(with time: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        timeLabel.text = formatter.string(from: time)
    }
}

