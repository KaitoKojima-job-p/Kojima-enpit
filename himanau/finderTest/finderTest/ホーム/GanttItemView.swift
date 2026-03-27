//
//  GanttItemView.swift
//  ReservationGanttChart
//
//  Created by Hoang Luong on 27/5/20.
//  Copyright © 2020 Hoang Luong. All rights reserved.
//
import UIKit

// ItemViewDelegateプロトコルの定義。これは、GanttItemViewがタップされたことをデリゲートに通知するために使用されます。
protocol ItemViewDelegate: AnyObject {
    func didTap(item: GanttItemView)
    func didLongPress(item: GanttItemView)
}

class GanttItemView: UIView {
    
    // ビューのコンテンツを管理するためのcontentViewプロパティ。
    @IBOutlet var contentView: UIView!
    
    // ItemViewDelegate型の弱参照プロパティ。ガントアイテムがタップされた際にイベントを伝える。
    weak var delegate: ItemViewDelegate?

    // フレームを使用してビューを初期化するためのイニシャライザ。
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    // コーダを使用してビューを初期化するための必須イニシャライザ。
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        commonInit()
    }
    
    // カスタム初期化コードを実行するためのprivateメソッド。
    private func commonInit() {
        let nibView = loadFromNib()
        nibView.frame = bounds
        addSubview(nibView)
        
        // タップジェスチャーレコグナイザーをcontentViewに追加。
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(itemTapped))
        contentView.addGestureRecognizer(tapGesture)
        
        // 長押しジェスチャーレコグナイザーをcontentViewに追加。
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(itemLongPressed))
        contentView.addGestureRecognizer(longPressGesture)
    }
    
    // アイテムがタップされたときに呼び出されるメソッド。デリゲートに通知。
    @objc private func itemTapped() {
        delegate?.didTap(item: self)
    }
    
    // アイテムが長押しされたときに呼び出されるメソッド。デリゲートに通知。
    @objc private func itemLongPressed(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else {
            return
        }
        delegate?.didLongPress(item: self)
    }
    
    // ガントチャートアイテムの状態に基づいてビューを設定するメソッド。
    func set(_ item: GanttChartItem) {
        if item.state > 9 {
            contentView.backgroundColor = UIColor(named: "attentionDark")
        }
    }
    
    var ganttChartItem: GanttChartItem? // プロパティを追加
}

// UIViewの拡張。XIBファイルからビューをロードするためのメソッドを提供します。
extension UIView {
    func loadFromNib() -> UIView {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        view.autoresizingMask = [UIView.AutoresizingMask.flexibleWidth, UIView.AutoresizingMask.flexibleHeight]
        return view
    }
}
