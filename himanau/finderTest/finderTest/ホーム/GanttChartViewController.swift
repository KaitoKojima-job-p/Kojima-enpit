//
//  GanttChartViewController.swift
//  ReservationGanttChartTest
//
//  Created by 宮脇拓真 on 2024/01/06.
//


import UIKit
import Firebase

// ガントチャートのアイテムを表す構造体
struct GanttChartItem: Comparable {
    let startDate: Date  // 開始日
    let endDate: Date    // 終了日
    var imageName: String?  // イメージ名（オプショナル）
    let mainString: String  // メインの文字列
    let contentString: String  // コンテンツの文字列
    let state: Int  // 状態を表す整数
    let key: String //DBのkey番号
    let tag: Int //tag
    let startDateString: String
    let endDateString: String
    
    // 比較関数の定義
    static func < (lhs: GanttChartItem, rhs: GanttChartItem) -> Bool {
        if lhs.startDate < rhs.startDate {
            return true
        } else if lhs.startDate == rhs.startDate && lhs.endDate < rhs.endDate {
            return true
        }
        
        return false
    }
}

class GanttChartViewController: UIViewController {
    @IBOutlet weak var headerView: UIView!
    //  セルレイアウト
    let columnWidth: CGFloat = 30//セル幅
    let pillHeight: CGFloat = 20//セル高さ
    let topMargin: CGFloat = 60//セル上部の余白
    let verticalSpacing: CGFloat = 10//セル垂直方向の間隔
    
    var ganttChartViewControllerValue = ""
    var user: DatabaseReference!
    var userId: DatabaseReference!
    
    var isOverlay: Bool = false
    
    var verticalItemLimit: Int {
        switch activePinchScale {
        case 1.9...2.0: return 6
        case 1.7..<1.9: return 8
        case 1.5..<1.7: return 10
        case 1.2..<1.5: return 12
        case 0.9..<1.2: return 15
        case 0.5..<0.9: return 20
        default: return 15
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    var registerScheduleViewController: RegisterScheduleViewController?
    static var reloadButtonTappedIs: Bool = false

    var dateRange = [Date]()
    var items = [GanttChartItem]()
    static var gantItemViews = [(view: GanttItemView, heightConstraint: NSLayoutConstraint)]()
    
    var selectedIndexPath: IndexPath?
    
    var topConstraint: NSLayoutConstraint?
    
    var currentZoomScale: CGFloat = 1.0 {
        didSet {
            collectionView.collectionViewLayout.invalidateLayout()
            GanttChartViewController.gantItemViews.forEach( { $0.view.removeFromSuperview() })
            GanttChartViewController.gantItemViews.removeAll()
            self.topConstraint = nil
            loadItemsIntoView()
        }
    }
    var minZoomScale: CGFloat = 0.55
    var maxZoomScale: CGFloat = 5.0
    
    var activePinchScale: CGFloat = 1.0
    
    var hasScrolledInitially = false
    
    var visibleModalView: UIView?
    
    var darkModeOn = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = Database.database().reference().child("user")
        
        setupDates()
        collectionView.register(UINib(nibName: "VerticalDateCell", bundle: nil), forCellWithReuseIdentifier: "verticalDateCellID")
        collectionView.register(VerticalDateCell.self, forCellWithReuseIdentifier: "identifier")
        collectionView.alwaysBounceVertical = false
        collectionView.alwaysBounceHorizontal = false
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        if darkModeOn {
            headerView.backgroundColor = .black
            navigationController?.navigationBar.backgroundColor = .black
        }
        
        removeAllItems()
        removeAllGanttItemViews()
        self.topConstraint = nil
        
        print("Boolean:",GanttChartViewController.reloadButtonTappedIs)
        if !GanttChartViewController.reloadButtonTappedIs {
            self.setupData {
                // 非同期処理が完了した後に実行したいコードをここに記述
                print("Setup data completed!")
            }
        }
    }
    
    func removeAllGanttItemViews() {
        guard !GanttChartViewController.gantItemViews.isEmpty else {
            print("gantt item views is empty")
            return // 要素がない場合は何もせずにリターン
        }
        
        print("before:",GanttChartViewController.gantItemViews)
        
        for (ganttItemView, heightConstraint) in GanttChartViewController.gantItemViews {
            ganttItemView.removeFromSuperview()
            NSLayoutConstraint.deactivate([heightConstraint])
        }
        
        GanttChartViewController.gantItemViews.removeAll()
        
        print("after:",GanttChartViewController.gantItemViews)
    }
    
    func removeAllItems() {
        guard !items.isEmpty else {
            print("items is empty")
            return // 要素がない場合は何もせずにリターン
        }
        
        items.removeAll()
        collectionView.reloadData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !hasScrolledInitially {
            let initialVisibleIndexPath = IndexPath(item: 23, section: 0)
            collectionView.scrollToItem(at: initialVisibleIndexPath, at: [.centeredHorizontally, .top], animated: false)
            hasScrolledInitially.toggle()
        }
        if let indexPath = middleIndexPath {
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        }
    }
    
    /// Gesture Setup
    
    var isZooming: Bool = false
    var isSwiping: Bool = false
    
    private func setupZoomGesture() {
        let gesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture))
        gesture.cancelsTouchesInView = false
        view.isMultipleTouchEnabled = true
        view.addGestureRecognizer(gesture)
        
        let swipeGesture = UIPanGestureRecognizer(target: self, action: #selector(handleSwipeGesture))
        swipeGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(swipeGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture))
        tapGesture.cancelsTouchesInView = false
        collectionView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleTapGesture(sender: UITapGestureRecognizer) {
        if visibleModalView != nil {
            visibleModalView?.removeFromSuperview()
            collectionView.alpha = 1
            visibleModalView = nil
        }
    }
    
    var currentYOffset: CGFloat = 60
    
    @objc private func handleSwipeGesture(sender: UIPanGestureRecognizer) {
        guard !isZooming else { return }
        
        if sender.translation(in: nil) != .zero {
            isSwiping = true
        }
        
        let translationY = sender.translation(in: nil).y
        topConstraint?.constant  = -translationY + currentYOffset
        
        if sender.state == .cancelled || sender.state == .ended {
            currentYOffset = topConstraint?.constant ?? 0.0
        }
        
        if sender.state == .cancelled || sender.state == .failed {
            isSwiping = false
        }
    }
    
    var middleIndexPath: IndexPath?
    
    @objc private func handlePinchGesture(sender: UIPinchGestureRecognizer) {
        if sender.state == .began {
            isZooming = true
            middleIndexPath = collectionView.indexPathForItem(at: view.convert(view.center, to: collectionView))
        }
        
        if sender.scale > 1 {
            let newScale = currentZoomScale + (sender.scale * 0.03)
            if newScale <= maxZoomScale {
                currentZoomScale = newScale
            }
        } else {
            let newScale = currentZoomScale - (sender.scale * 0.06)
            if newScale >= minZoomScale {
                currentZoomScale = newScale
            }
        }
        
        if sender.state == .cancelled || sender.state == .ended {
            isZooming = false
            middleIndexPath = nil
        }
        
    }

    // データの設定
    func setupData(completion: @escaping () -> Void) {
        print("called 1")
        print("ganttChartViewControllerValue",ganttChartViewControllerValue)
        self.userId = self.user.child(ganttChartViewControllerValue)
        
        self.collectionView.collectionViewLayout.invalidateLayout()
        GanttChartViewController.gantItemViews.forEach { $0.view.removeFromSuperview() }
        GanttChartViewController.gantItemViews.removeAll()
        self.topConstraint = nil
        
        // 指定された時間帯に基づくアイテムを作成
        //タプルを[(初時間、終時間、初分、終分、初年日, 終年日)]で作る
        var timeIntervals: [(Int, Int, Int, Int, Int, Int, String)] = []
                                        
        self.userId.child("himaTime").observeSingleEvent(of: .value) { (snapshot) in
            guard let value = snapshot.value as? [String: Any] else {
                print("key not exist or value is not [String: Any]")
                return
            }
            
            var himatimes: [(String, String, String)] = []
            
            for (key, _) in value {
                if key != "count" {
                    let himaStartTimeRef = self.userId.child("himaTime").child(key).child("startTime")
                    let himaEndTimeRef = self.userId.child("himaTime").child(key).child("endTime")
                    // "startTime"の値を取得
                    himaStartTimeRef.observeSingleEvent(of: .value) { (startTimeSnapshot) in
                        if let startTimeValue = startTimeSnapshot.value as? String {
                            // "endTime"の値を取得
                            himaEndTimeRef.observeSingleEvent(of: .value) { [self] (endTimeSnapshot) in
                                if let endTimeValue = endTimeSnapshot.value as? String {
                                    // タプルとして配列に追加
                                    himatimes.append((startTimeValue, endTimeValue, key))
                                    print("himatimes.count",himatimes.count)
                                    print("value.count",value.count)
                                    
                                    if himatimes.count == value.count - 1 {
                                        print("called 2")
                                        print("himatimes:",himatimes)
                                        timeIntervals = self.createTimeIntervals(himatimes: himatimes)
                                        print("timeIntervals:",timeIntervals)
                                        
                                        self.removeAllItems()
                                        self.removeAllGanttItemViews()
                                        
                                        self.createItems(timeIntervals: timeIntervals)

                                        self.loadItemsIntoView()
                                        self.setupZoomGesture()
                                        self.collectionView.reloadData()
                                        
                                        completion()
                                        return
                                    }
                                    return
                                } else {
                                    print("convert error")
                                    completion()
                                    return
                                }
                            }
                        } else {
                            print("convert error")
                            completion()
                            return
                        }
                        return
                    }
                } else if key == "count"{
                    print("key is count")
                    if value.count == 1 {
                        completion()
                    }
                }
            }
        }
    }
    
    //timeintervalsを作成する関数
    func createTimeIntervals(himatimes: [(String, String, String)]) -> [(Int, Int, Int, Int, Int, Int, String)] {
        var timeIntervals: [(Int, Int, Int, Int, Int, Int, String)] = []
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMddHHmm"
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        
        // 現在の年月日時分を取得
        let currentDate = Date()
        let currentDateTimeString = dateFormatter.string(from: currentDate)
        let currentYearMonthDay = String(currentDateTimeString.prefix(8))
        
        for himatime in himatimes {
            // himatimeの0と1の上からyyyyMMddを取得
            let startTimeString = himatime.0.prefix(8)
            let endTimeString = himatime.1.prefix(8)
            
            // yyyyMMddが現在の年月日と等しい場合
            if startTimeString == "\(currentYearMonthDay)" || endTimeString == "\(currentYearMonthDay)" {
                // stringからintに変換 (01, 02, 03 -> 1, 2, 3)
                let startHour = Int(himatime.0.suffix(4).prefix(2)) ?? 0
                let startMinute = Int(himatime.0.suffix(2)) ?? 0
                let startYearAndDay = Int(himatime.0.prefix(8)) ?? 0
                let endHour = Int(himatime.1.suffix(4).prefix(2)) ?? 0
                let endMinute = Int(himatime.1.suffix(2)) ?? 0
                let endYearAndDay = Int(himatime.1.prefix(8)) ?? 0
                
                // TimeIntervalsに追加
                let timeInterval: (Int, Int, Int, Int, Int, Int, String) = (startHour, endHour, startMinute, endMinute, startYearAndDay, endYearAndDay, himatime.2)
                timeIntervals.append(timeInterval)
            }
        }
        return timeIntervals
    }
    
    func createItems(timeIntervals: [(Int, Int, Int, Int, Int, Int, String)]) {
        
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let currentDate = Calendar.current.startOfDay(for: Date()) // 現在の日付の開始時間
        
        for (index, interval) in timeIntervals.enumerated() {
            let startDate = Calendar.current.date(byAdding: .hour, value: interval.0, to: currentDate)!
            let endDate = Calendar.current.date(byAdding: .hour, value: interval.1, to: currentDate)!
            
            let item = GanttChartItem(
                startDate: startDate,
                endDate: endDate,
                imageName: nil, // 画像名（オプショナル）
                mainString: "イベント \(interval.0)-\(interval.1)", // メインの文字列
                contentString: "詳細情報", // コンテンツの文字列
                state: 0, // 状態を表す整数
                key: interval.6, //key番号
                tag: index,
                startDateString: String(format: "%02d:%02d", interval.0, interval.2), //始まりのdate
                endDateString: String(format: "%02d:%02d", interval.1, interval.3) //終わりのdate
                
            )
            items.append(item)
        }
        
        items.sort() // アイテムを開始日時でソート
    }
    
    // ガントチャートアイテムをビューに読み込む
    func loadItemsIntoView() {
        for (num, item) in items.enumerated() {
            _ = Calendar.current.startOfDay(for: Date())
            // 現在の日付の開始時間からの時間数を計算
            let hoursFromStartOfDay = Calendar.current.dateComponents([.hour], from: Calendar.current.startOfDay(for: Date()), to: item.startDate).hour!
            // アイテムの持続時間（時間単位）を計算
            let durationInHours = Calendar.current.dateComponents([.hour], from: item.startDate, to: item.endDate).hour!


            let ganttItem = GanttItemView()
            ganttItem.tag = item.tag
            ganttItem.backgroundColor = .black
            collectionView.addSubview(ganttItem)
            ganttItem.layer.cornerRadius = pillHeight / 2
            ganttItem.layer.masksToBounds = true
            ganttItem.translatesAutoresizingMaskIntoConstraints = false
            ganttItem.set(item)
            ganttItem.delegate = self
            ganttItem.ganttChartItem = item // GanttItemViewのプロパティにGanttChartItemを設定する
            
            // すべての GanttItemView を同じ行に配置するように変更
            let topAnchor = ganttItem.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: topMargin + currentYOffset - 60)
            topAnchor.isActive = true

            if num == 0 {
                topConstraint = topAnchor
            }
            //高さ制約の設定
            let heightConstraint = ganttItem.heightAnchor.constraint(equalToConstant: pillHeight)
            heightConstraint.isActive = true
            
            // 横方向の開始位置の修正
            // 1時間あたりの幅を計算し、それに基づいて開始位置を設定
            let horizontalStartPosition = columnWidth * CGFloat(hoursFromStartOfDay) * currentZoomScale
            ganttItem.leadingAnchor.constraint(equalTo: collectionView.leadingAnchor, constant: horizontalStartPosition).isActive = true

            // ganttItemの幅の修正
            // アイテムの持続時間に基づいて幅を設定
            let itemWidth = columnWidth * CGFloat(durationInHours) * currentZoomScale
            ganttItem.widthAnchor.constraint(equalToConstant: itemWidth).isActive = true
            //ganttItemのビューと制約の保存
            GanttChartViewController.gantItemViews.append((view: ganttItem, heightConstraint: heightConstraint))
        }
        print("items:")
        print(items,"\n")
        print("gantItemViews:")
        print(GanttChartViewController.gantItemViews,"\n")
    }
    
    //ビューの最後を表示
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // すべてのセルがロードされた後、最後のセルにスクロール
        if let section = collectionView.numberOfSections > 0 ? collectionView.numberOfSections - 1 : nil {
            let lastItemIndex = collectionView.numberOfItems(inSection: section) - 1
            if lastItemIndex >= 0 {
                let lastIndexPath = IndexPath(item: lastItemIndex, section: section)
                collectionView.scrollToItem(at: lastIndexPath, at: .right, animated: true)
            }
        }
    }
    
    // 日付範囲の設定
    func setupDates() {
        var date = Calendar.current.startOfDay(for: Date())
        while dateRange.count < 24 { // 1日は24時間
            dateRange.append(date)
            date = Calendar.current.date(byAdding: .hour, value: 1, to: date)!
        }
    }


}

// UICollectionViewDelegate, UICollectionViewDataSource の拡張
extension GanttChartViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    //ガントカレンダーのセルの数を返す
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dateRange.count
    }
    
    //セルが表示される直前に呼び出されるメソッド
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? VerticalDateCell {
            cell.set(selected: selectedIndexPath == indexPath, darkModeOn: darkModeOn)
        }
    }
    
    //選択されたセルの場合は選択状態のスタイルを設定
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "verticalDateCellID", for: indexPath) as! VerticalDateCell
        cell.date = dateRange[indexPath.row]
        if selectedIndexPath == indexPath {
            cell.set(selected: true, darkModeOn: darkModeOn)
        }
        
        return cell
    }
    
    //ユーザーがセルをタップした際
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? VerticalDateCell {
            cell.set(selected: true, darkModeOn: darkModeOn)
            if let selectedIndexPath = selectedIndexPath, let previousSelectedCell = collectionView.cellForItem(at: selectedIndexPath) as? VerticalDateCell {
                previousSelectedCell.set(selected: false, darkModeOn: darkModeOn)
            }
            self.selectedIndexPath = indexPath
            collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        }
    }
}

// UICollectionViewDelegateFlowLayout の拡張
extension GanttChartViewController: UICollectionViewDelegateFlowLayout {
    //、指定されたズーム倍率に基づいて調整し、それに合わせてセルの高さを設定
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = columnWidth * currentZoomScale
        return CGSize(width: width, height: collectionView.frame.height)
    }
    
    // セル間の水平方向の最小間隔を0に設定
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }

    // セル間の垂直方向の最小間隔を0に設定
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}



// ItemViewDelegate の拡張
extension GanttChartViewController: ItemViewDelegate {
    func didTap(item: GanttItemView) {
        if let selectedItem = item.ganttChartItem {
            print("Tapped Item: \(selectedItem)")
            
            // すでに追加されている deleteButton を取得
            if let existingDeleteButton = self.collectionView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                existingDeleteButton.removeFromSuperview()
            }
            
            showDetails(for: item, with: selectedItem)
        }
    }
    
    func didLongPress(item: GanttItemView) {
        if let selectedItem = item.ganttChartItem {
            print("Long Pressed Item: \(selectedItem)")
            
            // すでに追加されている deleteButton を取得
            if let existingDeleteButton = self.collectionView.subviews.first(where: { $0 is UIButton }) as? UIButton {
                existingDeleteButton.removeFromSuperview()
            }
            
            let deleteButton = UIButton(type: .system)
            deleteButton.frame = CGRect(x: item.frame.origin.x + item.frame.size.width / 2 - 15,
                                        y: item.frame.origin.y - 30,
                                        width: 30,
                                        height: 30)
            deleteButton.setImage(UIImage(systemName: "trash"), for: .normal) // "trash"はシステムアイコンの名前
            deleteButton.addTarget(self, action: #selector(deleteButtonTapped(_:)), for: .touchUpInside)
            deleteButton.tag = selectedItem.tag
            
            print("deleteButton.tag",deleteButton.tag)
            
            self.collectionView.addSubview(deleteButton)
        }
    }
    
    @objc func deleteButtonTapped(_ sender: UIButton) {
        print("Delete Button Tapped")
        let tag = sender.tag
        
        // タグに対応するアイテムを取得
        if let item = self.collectionView.subviews.compactMap({ $0 as? GanttItemView }).first(where: { $0.tag == tag }),
           let selectedItem = item.ganttChartItem {
            print("Delete Button Tapped for Item: \(selectedItem)")
            // 削除処理を非同期で行う
            deleteHimaTime(for: item, with: selectedItem) { error in
                if let error = error {
                    // エラーが発生した場合の処理を追加するか、アラートを表示するなど適切な対応を行う
                    print("Error: \(error.localizedDescription)")
                } else {
                    if self.isOverlay {
                        print("fade out")
                        UIView.animate(withDuration: 0.3, animations: {
                            self.visibleModalView?.alpha = 0
                        }) { _ in
                            self.visibleModalView?.removeFromSuperview()
                            self.collectionView.alpha = 1
                        }
                    }
                    // ボタンを削除
                    self.setupData {
                        print("suc")
                        sender.removeFromSuperview()
                    }
                }
            }
        } else {
            print("Error: Unable to retrieve item for tag \(tag)")
        }
    }

    
    func showDetails(for itemView: GanttItemView, with item: GanttChartItem) {
        if visibleModalView != nil {
            visibleModalView?.removeFromSuperview()
        }
        
        isOverlay = true
        
        let overlay = UIView()
        overlay.frame = collectionView.convert(itemView.frame, to: view)
        view.addSubview(overlay)
        overlay.backgroundColor = UIColor.black
        overlay.layer.cornerRadius = pillHeight / 2
        overlay.layer.masksToBounds = true
        overlay.backgroundColor = itemView.contentView.backgroundColor
        
        UIView.animate(withDuration: 0.3, animations: {
            overlay.frame.size = CGSize(width: 300, height: 300)
            overlay.center = self.view.center
            overlay.layer.cornerRadius = 8
            self.collectionView.alpha = 0.6
        }) { (_) in
            let contentView = UIView()
            overlay.addSubview(contentView)
            contentView.frame = overlay.bounds
            contentView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            contentView.backgroundColor = self.darkModeOn ? .black : .white
            contentView.layer.cornerRadius = 8
            contentView.alpha = 0
            
            let label = UILabel()
            label.text = "\(item.startDateString)~\(item.endDateString)"
            if self.darkModeOn { label.textColor = .white }
            
            label.translatesAutoresizingMaskIntoConstraints = false
            
            let contentLabel = UITextView()
            contentLabel.translatesAutoresizingMaskIntoConstraints = false
            contentLabel.text = "暇時間が登録されているDBのhimaTime内のキー番号(削除用):\(item.key)"
            if self.darkModeOn { contentLabel.textColor = .white }
            contentLabel.backgroundColor = .clear
            
            // 削除ボタンの追加
            let deleteButton = UIButton(type: .system)
            deleteButton.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
            deleteButton.addTarget(self, action: #selector(self.deleteButtonTapped(_:)), for: .touchUpInside)
            deleteButton.tag = item.tag
            if self.darkModeOn { contentLabel.textColor = .white }
            
            contentView.addSubview(label)
            contentView.addSubview(contentLabel)
            contentView.addSubview(deleteButton)
            
            label.textColor = self.darkModeOn ? .white : .black
            label.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10).isActive = true
            label.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
            label.heightAnchor.constraint(equalToConstant: 30).isActive = true
            label.widthAnchor.constraint(equalToConstant: 200).isActive = true
            label.backgroundColor = .clear
            
            contentLabel.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 0).isActive = true
            contentLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10).isActive = true
            contentLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10).isActive = true
            contentLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10).isActive = true
            
            deleteButton.trailingAnchor.constraint(equalTo: overlay.trailingAnchor, constant: -10).isActive = true
            deleteButton.topAnchor.constraint(equalTo: overlay.topAnchor, constant: 10).isActive = true
            
            UIView.animate(withDuration: 0.3) {
                contentView.alpha = 1
            }
            
        }
        visibleModalView = overlay
    }
    
    func deleteHimaTime(for itemView: GanttItemView, with item: GanttChartItem, completion: @escaping (Error?) -> Void) {
        // user.child("himatime") から指定された key のデータを削除
        let himaTimeRef = self.userId.child("himaTime").child(item.key)
        
        himaTimeRef.removeValue { error, _ in
            if let error = error {
                print("Error deleting himaTime data: \(error.localizedDescription)")
                // エラーが発生した場合の処理を追加するか、アラートを表示するなど適切な対応を行う
                completion(error)
            } else {
                print("HimaTime data deleted successfully")
                completion(nil)
            }
        }
    }
    
}


