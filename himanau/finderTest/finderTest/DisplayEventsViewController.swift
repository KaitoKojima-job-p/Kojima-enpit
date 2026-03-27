
import UIKit
import Firebase

class DisplayEventsViewController: UIViewController,  UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var eventsTableView: UITableView!
    var refreshControl: UIRefreshControl!
    var refreshflag: Bool = false
    var noEventView: UIView?
    
    var user: DatabaseReference!
    var userId: DatabaseReference!
    var allEvents: DatabaseReference!
    
    var displayEventsViewControllerValue = "" // ユーザーID用の変数
    var eventCount: Int = 0 //セルの個数を格納するための変数
    var eventIDs: [String] = [] // イベントのIDを格納するための変数
    var eventTitles: [String] = [] // イベントのタイトルを格納するための変数
    var eventPlaces: [String] = [] // イベントの場所を格納するための変数
    var eventDateAndTimeStarts: [String] = [] // イベントの開始時刻を格納するための変数
    var eventDateAndTimeEnds: [String] = [] // イベントの終了時刻を格納するための変数
    var eventDeadlineTimes: [String] = [] // イベントのしめきり時間の日時を格納するための変数
    var eventDeadlineToAdds: [String] = [] // イベントの締切時間の分数を格納するための
    var eventDeadlineIsCome: [String] = []    // イベントの主催者+イベントに参加している人用の〆切が来たイベントのIDを格納する
    var eventConnectMembersCounts: [String] = [] //いべんとのせつぞくにんずう
    var eventMembers: [[String]] = [] // イベントの全てのメンバーを格納するための変数
    var eventJoinedMembers: [[String]] = [] // イベントの参加メンバーを格納するための変数
    var isUserEqualCreators: [Bool] = [] //イベントの作成者とユーザーが一致しているかを格納する変数
    var isJoinedFlags: [Bool] = [] //ユーザーがベントにjoinしているかを格納する変数
    var creatorId: String = ""  //イベント作成者のIDを格納するための変数
    var eventId: String = ""  //イベントのIDを格納するための変数
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        eventsTableView.addSubview(refreshControl)
        
        if let customTabBarController = self.tabBarController as? CustomTabBarController {
            let sharedValueFromTabBar = customTabBarController.sharedValue
            displayEventsViewControllerValue = sharedValueFromTabBar
        }
        
        self.user = Database.database().reference().child("user")
        self.userId = user.child(displayEventsViewControllerValue)
        self.allEvents = Database.database().reference().child("allEvents")
        
        // イベントの総数を取得し、テーブルビューを更新
        deleteEvent { deletedCount in
            print("Deleted \(deletedCount) events")
            self.getEventCount { count in
                self.eventCount = count
                self.observeEventContents()
            }
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CustomTabBarController" {
            if let destinationVC = segue.destination as? CustomTabBarController {
                destinationVC.sharedValue = displayEventsViewControllerValue
            }
        }
    }
    
    // データのリフレッシュメソッド
    @objc private func refreshData(_ sender: Any) {
        refreshflag = true
        //deleteEventが完了した通知を受け取ってから次へ
        deleteEvent { deletedCount in
            print("Deleted \(deletedCount) events")
            self.getEventCount { count in
                self.eventCount = count
                //配列初期化
                self.eventIDs = [String]()
                self.eventTitles = [String]()
                self.eventPlaces = [String]()
                self.eventDateAndTimeStarts = [String]()
                self.eventDateAndTimeEnds = [String]()
                self.eventDeadlineTimes = [String]()
                self.eventDeadlineToAdds = [String]()
                self.eventDeadlineIsCome = [String]()
                self.eventConnectMembersCounts = [String]()
                self.eventMembers = [[String]]()
                self.eventJoinedMembers = [[String]]()
                self.isUserEqualCreators = [Bool]()
                self.isJoinedFlags = [Bool]()
                //データ取得
                self.observeEventContents()
            }
        }
    }

    
    //テーブルビューの初期化と再読み込みの関数
    func tableViewRefresh() {
        //deleteEventが完了した通知を受け取ってから次へ
        deleteEvent { deletedCount in
            print("Deleted \(deletedCount) events")
            self.getEventCount { count in
                self.eventCount = count
                //配列初期化
                self.eventIDs = [String]()
                self.eventTitles = [String]()
                self.eventPlaces = [String]()
                self.eventDateAndTimeStarts = [String]()
                self.eventDateAndTimeEnds = [String]()
                self.eventDeadlineTimes = [String]()
                self.eventDeadlineToAdds = [String]()
                self.eventDeadlineIsCome = [String]()
                self.eventConnectMembersCounts = [String]()
                self.eventMembers = [[String]]()
                self.eventJoinedMembers = [[String]]()
                self.isUserEqualCreators = [Bool]()
                self.isJoinedFlags = [Bool]()
                //データ取得
                self.observeEventContents()
            }
        }
    }
    
    //userのイベントの個数を返す関数
    func getEventCount(completion: @escaping (Int) -> Void) {
        userId.child("events").child("count").observeSingleEvent(of: .value) { snapshot in
            if let countString = snapshot.value as? String, let count = Int(countString) {
                completion(count)
            } else {
                completion(0)
            }
        }
    }
    
    // userの期限切れのイベントを削除する関数
    func deleteEvent(completion: @escaping (Int) -> Void) {
        let eventsIDPath = userId.child("events").child("ID")
        var deletedCount = 0 // 削除したイベントの数をカウントする変数
        var notDeletedCount = 0 // 削除されないイベントの数をカウントする変数
        
        eventsIDPath.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                    print("Error: Unable to retrieve children.")
                    completion(deletedCount)
                    return
                }
                
                for child in children {
                    guard let eventId = child.value as? String else {
                        print("Error: eventId is nil or not a String for child \(child.key).")
                        continue
                    }
                    
                    let eventDeadlineTimePath = self.allEvents.child(eventId).child("deadline").child("time")
                    
                    eventDeadlineTimePath.observeSingleEvent(of: .value) { snapshot in
                        if let deadlineTime = snapshot.value as? String {
                            let currentDate = Date()
                            let dateFormatter = DateFormatter()
                            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                            dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
                            
                            if let deadlineDate = dateFormatter.date(from: deadlineTime) {
                                if deadlineDate < currentDate {
                                    let eventJoinedPath = self.allEvents.child(eventId).child("joined")
                                    
                                    eventJoinedPath.observeSingleEvent(of: .value) { snapshot in
                                        guard let eventJoinedChildren = snapshot.children.allObjects as? [DataSnapshot] else {
                                            print("Error: Unable to retrieve children.")
                                            completion(deletedCount)
                                            return
                                        }
                                        let stringEventJoinedChildren = eventJoinedChildren.compactMap { $0.value as? String }
                                        
                                        let eventCreatorPath = self.allEvents.child(eventId).child("creator")
                                        eventCreatorPath.observeSingleEvent(of: .value) { snapshot in
                                            if let creatorId = snapshot.value as? String {
                                                if (stringEventJoinedChildren.contains(self.displayEventsViewControllerValue) || creatorId == self.displayEventsViewControllerValue) {
                                                    //イベントに参加している人or主催者はイベントを削除しない
                                                    print("eventに参加しています")
                                                    self.eventDeadlineIsCome.append(eventId)
                                                    //イベントに参加している人or主催者はイベントを削除しない
                                                    notDeletedCount += 1
                                                    // 最後のイベントの処理
                                                    if deletedCount + notDeletedCount == children.count {
                                                        // 削除処理が完了したことを通知
                                                        completion(deletedCount)
                                                    }
                                                } else {
                                                    //イベントに参加してない人はイベントを削除する
                                                    print("eventに参加していなく締切を過ぎました")
                                                    //イベントの接続者数を減らす
                                                    self.allEvents.child(eventId).child("connectMembersCount").observeSingleEvent(of: .value) { snapshot in
                                                        if let eventMembersCount = snapshot.value as? String, let eventMembersCountInt = Int(eventMembersCount) {
                                                            if eventMembersCountInt == 1 {
                                                                self.allEvents.child(eventId).removeValue { error, _ in
                                                                    if let error = error {
                                                                        print("Failed to delete event: \(error.localizedDescription)")
                                                                    } else {
                                                                        print("(auto)(last)接続人数を減らすのに成功")
                                                                    }
                                                                }
                                                            } else {
                                                                let eventMembersCountString = String(eventMembersCountInt - 1)
                                                                self.allEvents.child(eventId).child("connectMembersCount").setValue(eventMembersCountString) { error, _ in
                                                                    if let error = error {
                                                                        print("Failed to set value: \(error.localizedDescription)")
                                                                    } else {
                                                                        print("(auto)(yet)接続人数を減らすのに成功")
                                                                    }
                                                                }
                                                            }
                                                            eventsIDPath.child(child.key).removeValue()
                                                            print("eventに参加していなく締切を過ぎましたので表示できません")
                                                            deletedCount += 1
                                                            let eventsCountPath = self.userId.child("events").child("count")
                                                            eventsCountPath.setValue(String(children.count - deletedCount))
                                                            // 最後のイベントの処理
                                                            if deletedCount + notDeletedCount == children.count {
                                                                // 削除処理が完了したことを通知
                                                                completion(deletedCount)
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    //締め切りが来ていないものは削除しない
                                    notDeletedCount += 1
                                    // 最後のイベントの処理
                                    if deletedCount + notDeletedCount == children.count {
                                        // 削除処理が完了したことを通知
                                        completion(deletedCount)
                                    }
                                }
                            }
                        }
                    }
                }
            } else {
                print("No data found at the specified path.")
                completion(deletedCount)
            }
        }
    }
    
    // イベントがない場合のビュー表示
    func showNoEventView() {
        noEventView = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 70))
        noEventView?.center = view.center
        noEventView?.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        noEventView?.layer.cornerRadius = 15
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 30))
        label.center = CGPoint(x: noEventView!.bounds.width / 2, y: noEventView!.bounds.height / 2)
        label.text = "イベントがありません"
        label.textColor = UIColor.white
        label.textAlignment = .center
        noEventView?.addSubview(label)
        
        view.addSubview(noEventView!)
        
        // 3秒後に非表示にする
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.noEventView?.removeFromSuperview()
            self.noEventView = nil
            
            if self.refreshflag {
                self.refreshControl.endRefreshing()
                self.refreshflag = false
            }
        }
    }
                
    func observeEventContents() {
        var completedCount = 0 // 完了した非同期処理の数をカウントする変数
        if self.eventCount == 0 {
            print("eventなし")
            showNoEventView()
            self.eventsTableView.reloadData()
            return
        }
        let eventsIDPath = userId.child("events").child("ID")
        // イベントのIDを取得
        eventsIDPath.observeSingleEvent(of: .value) { snapshot in
            guard let children = snapshot.children.allObjects as? [DataSnapshot] else {
                print("Error: Unable to retrieve children.")
                return
            }
            
            for child in children {
                guard let eventId = child.value as? String else {
                    print("Error: eventId is nil or not a String for child \(child.key).")
                    continue
                }
                print("eventID:"+eventId)
                
                self.eventIDs.append(eventId)
                
                // イベントのIDを使ってタイトルを取得
                self.observeEventContents(eventID: eventId) {
                    completedCount += 1
                    if completedCount == self.eventCount {
                        // すべての非同期処理が完了したら reloadData を呼ぶ
                        if self.refreshflag {
                            self.refreshControl.endRefreshing()
                            self.refreshflag = false
                        }
                        self.eventsTableView.reloadData()
                    }
                }
            }
        }
    }
    
    // イベントのIDを使ってタイトルを取得
    func observeEventContents(eventID: String, completion: @escaping () -> Void) {
        let eventId = allEvents.child(eventID)
        
        eventId.child("title").observeSingleEvent(of: .value) { snapshot  in
            if let title = snapshot.value as? String {
                self.eventTitles.append(title)
                //self.eventsTableView.reloadData()
            } else {
                // タイトルが取得できなかった場合の処理
                print("Failed to retrieve title for event with ID: \(eventID)")
            }
        }
        
        eventId.child("place").observeSingleEvent(of: .value) { snapshot  in
            if let place = snapshot.value as? String {
                self.eventPlaces.append(place)
                //self.eventsTableView.reloadData()
            } else {
                // タイトルが取得できなかった場合の処理
                print("Failed to retrieve title for event with ID: \(eventID)")
            }
        }
        
        eventId.child("time").child("start").observeSingleEvent(of: .value) { snapshot  in
            if let timeStart = snapshot.value as? String {
                self.eventDateAndTimeStarts.append(timeStart)
                //self.eventsTableView.reloadData()
            } else {
                // タイトルが取得できなかった場合の処理
                print("Failed to retrieve title for event with ID: \(eventID)")
            }
        }
        
        eventId.child("time").child("end").observeSingleEvent(of: .value) { snapshot  in
            if let timeEnd = snapshot.value as? String {
                self.eventDateAndTimeEnds.append(timeEnd)
                //self.eventsTableView.reloadData()
            } else {
                print("Failed to retrieve title for event with ID: \(eventID)")
            }
        }
        
        eventId.child("deadline").child("time").observeSingleEvent(of: .value) { snapshot  in
            if let deadlineTime = snapshot.value as? String {
                self.eventDeadlineTimes.append(deadlineTime)
            } else {
                print("Failed to retrieve title for event with ID: \(eventID)")
            }
        }
        
        eventId.child("deadline").child("toAdd").observeSingleEvent(of: .value) { snapshot  in
            if let deadlineToAdd = snapshot.value as? String {
                self.eventDeadlineToAdds.append(deadlineToAdd)
            } else {
                print("Failed to retrieve title for event with ID: \(eventID)")
            }
        }
        
        eventId.child("connectMembersCount").observeSingleEvent(of: .value) { snapshot  in
            if let connectMembersCount = snapshot.value as? String {
                self.eventConnectMembersCounts.append(connectMembersCount)
            } else {
                print("(connectMemberCount)Failed to retrieve title for event with ID: \(eventID)")
            }
        }
        
        eventId.child("creator").observeSingleEvent(of  : .value) { snapshot in
            if snapshot.exists(), let creatorId = snapshot.value as? String, creatorId == self.displayEventsViewControllerValue {
                // userIdとcreatorが一致する場合
                print("userIdとcreatorが一致しました: \(self.displayEventsViewControllerValue)")
                self.isUserEqualCreators.append(true)
                self.isJoinedFlags.append(false)
            } else {
                // userIdとcreatorが一致しない場合
                print("userIdとcreatorが一致しません")
                self.isUserEqualCreators.append(false)
                
                eventId.child("joined").observeSingleEvent(of: .value) { snapshot in
                    guard let joinedDict = snapshot.value as? [String: Any] else {
                        // joinedが存在しない場合の処理
                        print("joined not exist")
                        self.isJoinedFlags.append(false)
                        return
                    }
                    
                    var isMatchFound = false
                    for (userIdKey, value) in joinedDict {
                        if let joinedValue = value as? String, joinedValue == self.displayEventsViewControllerValue {
                            // 一致が見つかった
                            print("userIdKey: \(userIdKey) で一致が見つかりました")
                            self.isJoinedFlags.append(true)
                            isMatchFound = true
                            break // 一致が見つかったらループを抜ける
                        }
                    }
                    
                    if !isMatchFound {
                        print("一致するユーザーが見つかりませんでした")
                        self.isJoinedFlags.append(false)
                    }
                }
            }
        }
        
        var eventMembersEachOther: [String] = []    //イベントごとのメンバーを格納する配列
        var eventJoinedMembersEachOther: [String] = []    //イベントごとのjoinedメンバーを格納する配列
        
        eventId.child("creator").observeSingleEvent(of: .value) { creatorSnapshot in
            if let creator = creatorSnapshot.value as? String {
                eventMembersEachOther.append(creator)
                self.creatorId = creator // クリエイターIDを大域変数に格納
                
                // creatorの処理が終わった後にinvitedの処理を行う
                eventId.child("invited").observeSingleEvent(of: .value) { invitedSnapshot in
                    // データが存在するか確認
                    guard invitedSnapshot.exists() else {
                        // テーブルビューでイベントのメンバーを表示するための配列に追加
                        self.eventMembers.append(eventMembersEachOther)
                        // 非同期処理が完了したことを通知
                        completion()
                        return
                    }
                    
                    // データを取得して配列に追加
                    for childSnapshot in invitedSnapshot.children {
                        if let membersSnapshot = childSnapshot as? DataSnapshot,
                           let member = membersSnapshot.value as? String {
                            eventMembersEachOther.append(member)
                        }
                    }
                    
                    // テーブルビューでイベントのメンバーを表示するための配列に追加
                    self.eventMembers.append(eventMembersEachOther)
                    
                    // invitedの処理が終わった後にjoinedの処理を行う
                    eventId.child("joined").observeSingleEvent(of: .value) { joinedSnapshot in
                        // データが存在するか確認
                        guard joinedSnapshot.exists() else {
                            // テーブルビューでイベントのメンバーを表示するための配列に追加
                            self.eventJoinedMembers.append(eventJoinedMembersEachOther)
                            // 非同期処理が完了したことを通知
                            completion()
                            return
                        }
                        // データを取得して配列に追加
                        for childSnapshot in joinedSnapshot.children {
                            if let membersSnapshot = childSnapshot as? DataSnapshot,
                               let member = membersSnapshot.value as? String {
                                eventJoinedMembersEachOther.append(member)
                            }
                        }
                        // テーブルビューでイベントのメンバーを表示するための配列に追加
                        self.eventJoinedMembers.append(eventJoinedMembersEachOther)
                        // 非同期処理が完了したことを通知
                        completion()
                    }
                }
            } else {
                // タイトルが取得できなかった場合の処理
                print("Failed to retrieve title for event with ID: \(eventID)")
            }
        }

    }

    /// セルの個数を指定するデリゲートメソッド（必須）
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.eventCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // セルを取得
        let cell = tableView.dequeueReusableCell(withIdentifier: "MyCell") as! DisplayEventsTableViewCell
        
        //変数をcontorllerviewから送り、cell側で利用できるように
        cell.user = self.user
        cell.userId = self.userId
        cell.allEvents = self.allEvents
        cell.displayEventTableViewCellValue = self.displayEventsViewControllerValue
        
        if indexPath.row < self.eventIDs.count {
            let eventId = self.eventIDs[indexPath.row]
            cell.eventId = eventId
        } else {
            print("eventIDを取得できません")
        }
        
        // eventTitles が indexPath.row 未満の場合は "読み込みエラー" を表示
        if indexPath.row < self.eventTitles.count {
            let eventTitle = self.eventTitles[indexPath.row]
            cell.eventTitleLabel.text = eventTitle.isEmpty ? "タイトルなし" : eventTitle
        } else {
            cell.eventTitleLabel.text = "読み込みエラー"
        }
        

        if indexPath.row < self.eventPlaces.count {
            let eventPlace = self.eventPlaces[indexPath.row]
            cell.eventPlaceLabel.text = eventPlace.isEmpty ? "場所なし" : eventPlace
        } else {
            cell.eventPlaceLabel.text = "読み込みエラー"
        }
        
        //開始時刻ラベルのセット
        if indexPath.row < self.eventDateAndTimeStarts.count {
            let eventDateAndTimeStart = self.eventDateAndTimeStarts[indexPath.row]
            // DateFormatterを使用して文字列から日付に変換
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = dateFormatter.date(from: eventDateAndTimeStart) {
                // 日付からHH:mmとMM-ddを取り出してラベルに表示
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM月dd日"
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH時mm分"
                
                cell.eventDateStartLabel.text = dateFormatter.string(from: date)
                cell.eventTimeStartLabel.text = timeFormatter.string(from: date)
            } else {
                // 日付の変換に失敗した場合の処理
                cell.eventDateStartLabel.text = "読み込みエラー"
                cell.eventTimeStartLabel.text = "読み込みエラー"
            }
        } else {
            cell.eventDateStartLabel.text = "読み込みエラー"
            cell.eventTimeStartLabel.text = "読み込みエラー"
        }
        
        //終了時刻ラベルのセット
        if indexPath.row < self.eventDateAndTimeEnds.count {
            let eventDateAndTimeEnd = self.eventDateAndTimeEnds[indexPath.row]
            // DateFormatterを使用して文字列から日付に変換
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            if let date = dateFormatter.date(from: eventDateAndTimeEnd) {
                // 日付からHH:mmとMM-ddを取り出してラベルに表示
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MM月dd日"
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH時mm分"
                
                cell.eventDateEndLabel.text = dateFormatter.string(from: date)
                cell.eventTimeEndLabel.text = timeFormatter.string(from: date)
            } else {
                // 日付の変換に失敗した場合の処理
                cell.eventDateEndLabel.text = "読み込みエラー"
                cell.eventTimeEndLabel.text = "読み込みエラー"
            }
        } else {
            cell.eventDateEndLabel.text = "読み込みエラー"
            cell.eventTimeEndLabel.text = "読み込みエラー"
        }
        
        if indexPath.row < self.eventDeadlineToAdds.count {
            let eventDeadlineToAdd = self.eventDeadlineToAdds[indexPath.row]
            
            // Remaining timeが120未満の場合
            if let remainingTimeMinutes = Int(eventDeadlineToAdd), remainingTimeMinutes < 120 {
                cell.remainingTimeZeroLabel.text = "0"
                cell.remainingTimeMaxLabel.text = "\(remainingTimeMinutes)分"
                let halfTimeMinutes = remainingTimeMinutes / 2
                let halfTimeString = "\(halfTimeMinutes)"
                cell.remainingTimeMiddleLabel.text = "\(halfTimeString)"
            }
            // Remaining timeが120以上、1440未満の場合
            else if let remainingTimeMinutes = Int(eventDeadlineToAdd), remainingTimeMinutes >= 120, remainingTimeMinutes < 1440 {
                cell.remainingTimeZeroLabel.text = "0"
                let remainingTimeHours = remainingTimeMinutes / 60
                cell.remainingTimeMaxLabel.text = "\(remainingTimeHours)時間"
                let halfTimeHours = remainingTimeHours / 2
                var halfTimeString = "\(halfTimeHours)"
                if remainingTimeHours % 2 != 0 {
                    halfTimeString += "時間30分"
                }
                cell.remainingTimeMiddleLabel.text = "\(halfTimeString)"
            }
            // Remaining timeが1440の場合
            else if let remainingTimeMinutes = Int(eventDeadlineToAdd), remainingTimeMinutes == 1440 {
                cell.remainingTimeZeroLabel.text = "0"
                let remainingTimeDays = remainingTimeMinutes / 1440
                cell.remainingTimeMaxLabel.text = "\(remainingTimeDays)日"
                cell.remainingTimeMiddleLabel.text = "12時間"
            }
        } else {
            cell.remainingTimeZeroLabel.text = "読み込みエラー"
            cell.remainingTimeMiddleLabel.text = "読み込みエラー"
            cell.remainingTimeMaxLabel.text = "読み込みエラー"
        }
        
        if indexPath.row < self.eventDeadlineTimes.count {
            let eventDeadlineTime = self.eventDeadlineTimes[indexPath.row]
            let eventDeadlineToAdd = self.eventDeadlineToAdds[indexPath.row]
            
            let currentDate = Date()                // 現在の日時を取得
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo") // タイムゾーンを設定
            
            if let deadlineDate = dateFormatter.date(from: eventDeadlineTime) {
                if deadlineDate < currentDate {
                    //締め切りを過ぎている時
                    print("over deadline")
                    cell.remainingTimeProgressBar.progress = 0
                } else {
                    let calendar = Calendar.current
                    if let difference = calendar.dateComponents([.minute], from: currentDate, to: deadlineDate).minute {
                        print("締切までの残り時間: \(difference) 分")
                        let progressValue = (Float(difference) / Float(eventDeadlineToAdd)!)
                        cell.remainingTimeProgressBar.progress = progressValue
                    } else {
                        print("Failed to calculate time difference.")
                    }
                }
            }
        } else {
            print("プログレスバー:読み込みエラー")
        }
        
        if indexPath.row < self.eventConnectMembersCounts.count {
            let eventConnectMembersCount = self.eventConnectMembersCounts[indexPath.row]
        } else {
            print("connect of 読み込みエラー")
        }
        
        if indexPath.row < self.isUserEqualCreators.count, indexPath.row < self.isJoinedFlags.count{
            let isUserEqualCreator = self.isUserEqualCreators[indexPath.row]
            cell.isUserEqualCreator = isUserEqualCreator
            let isJoinedFlag = self.isJoinedFlags[indexPath.row]
            cell.isJoinedFlag = isJoinedFlag
            
//            print(eventIDs[indexPath.row])
//            print(isUserEqualCreator)
//            print(isJoinedFlag)
            
            if isUserEqualCreator {
                print("cell:userIdとcreatorが一致しました: \(self.displayEventsViewControllerValue)")
                // userIdとcreatorが一致する場合
                cell.eventNotJoinButton.isHidden = true
                cell.eventJoinButton.isHidden = true
                // 一致する場合は、progressbarとラベルを非表示にする
                cell.remainingTimeProgressBar.isHidden = true
                cell.remainingTimeZeroLabel.isHidden = true
                cell.remainingTimeMiddleLabel.isHidden = true
                cell.remainingTimeMaxLabel.isHidden = true
            } else {
                print("cell:userIdとcreatorが一致しません")
                if isJoinedFlag {
                    print("cell:userIdKey: で一致が見つかりました")
                    // 一致する場合は、eventJoinButtonのスタイルを変更し、isjoinedFlagをtrueに設定
                    cell.eventJoinButton.backgroundColor = UIColor.gray
                    cell.eventJoinButton.setTitleColor(UIColor.white, for: .normal)
                    cell.eventJoinButton.isEnabled = false
                    cell.eventNotJoinButton.setTitle("退会する", for: .normal)
                } else {
                    print("cell:一致するユーザーが見つかりませんでした")
                }
            }
        }
        
//        print(indexPath.row)
//        print(eventIDs)
//        print(isUserEqualCreators)
//        print(isJoinedFlags)/

        if indexPath.row < self.eventMembers.count {
            let eventMembersEachOther = self.eventMembers[indexPath.row]
            let eventJoinedMembersEachOther = self.eventJoinedMembers[indexPath.row]
            let eventId = self.eventIDs[indexPath.row]
            
            if let labelFrame = cell.initialEventMemberLabelFrame {
                
                // ラベルにメンバーの人数を表示する & 締切後かを確認
                if eventDeadlineIsCome.contains(eventId) {
                    cell.eventMemberCountLabel.text = " メンバー(\(eventMembersEachOther.count)) [〆切]"
                } else {
                    cell.eventMemberCountLabel.text = " メンバー(\(eventMembersEachOther.count))"
                }
                
                print("メンバー （\(eventMembersEachOther.count)）")
                
                // スクロールビュー内での最大のラベルの幅と高さを計算
                var maxWidth: CGFloat = 0.0
                var totalHeight: CGFloat = 0.0
                
                // 全てのメンバーのデータ取得が完了したかどうかを確認するためのカウンタ
                var completionCount = 0
                let totalMembers = eventMembersEachOther.count
                
                // メンバーをスクロールビュー内で表示
                for member in  eventMembersEachOther {
                    user.child(member).child("name").observeSingleEvent(of: .value) { snapshot in
                        if let memberName = snapshot.value as? String {
                            // 新しい UILabel を作成
                            let memberLabel = UILabel(frame: labelFrame)
                            memberLabel.text = memberName
                            memberLabel.font = UIFont.systemFont(ofSize: 17)

                            if eventJoinedMembersEachOther.contains(member) {
                                //joined参加している場合
                                memberLabel.textColor = .black
                            } else {
                                //invited誘われているだけでjoinedにない、参加していない場合
                                memberLabel.textColor = .gray
                            }
                            if member == self.creatorId {
                                // 作成者の場合
                                let attributedString = NSMutableAttributedString(string: memberName)
                                let range = NSRange(location: 0, length: attributedString.length)
                                attributedString.addAttribute(.strokeColor, value: UIColor.white, range: range)
                                attributedString.addAttribute(.strokeWidth, value: -2, range: range)
                                // UILabel に NSAttributedString をセット
                                memberLabel.attributedText = attributedString
                                memberLabel.textColor = .blue
                            }
                            let nameSize = (memberName as NSString).size(withAttributes: [.font: memberLabel.font as Any])
                            // 新しい UILabel の幅をメンバー名に合わせて設定
                            memberLabel.frame.size.width = nameSize.width
                            // 新しい UILabel のy座標を設定
                            memberLabel.frame.origin.y = totalHeight
                            // 最大の幅を更新
                            maxWidth = max(maxWidth, memberLabel.frame.width)
                            // 高さを追加
                            totalHeight += memberLabel.frame.size.height
                            // 新しい UILabel をスクロールビューに追加
                            cell.eventMemberScrollView.addSubview(memberLabel)
                        } else {
                            cell.eventMemberLabel.text = "No Name"
                        }
                        completionCount += 1
                        if completionCount == totalMembers {
                            // ScrollView の contentSize を設定
                            cell.eventMemberScrollView.contentSize = CGSize(width: maxWidth, height: totalHeight)
                        }
                    }
                }
            } else {
                print("initialEventMemberLabelFrame is nil")
            }
        } else {
            print("index:\(indexPath.row)")
            print("count:\(self.eventMembers.count)")
            cell.eventMemberLabel.text = "読み込みエラー"
        }
        
        cell.selectionStyle = .none
            
        return cell
    }
    
    //テーブルビューを左に引っ張って削除
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let index = indexPath.row
            // セルを削除する処理を実行
            let eventIdToDelete = eventIDs[index]
            
            print("deleat処理開始")
            
            // イベントメンバーカウントの値を取得
            allEvents.child(eventIdToDelete).child("connectMembersCount").observeSingleEvent(of: .value) { snapshot in
                if let eventMembersCount = snapshot.value as? String, let eventMembersCountInt = Int(eventMembersCount) {
                    print("イベント接続人数:",eventMembersCount)
                    //イベントに接続している人（自分）が最後の一人である時
                    if eventMembersCountInt == 1 {
                        // yourIdとallEventsからイベントを削除
                        self.userId.child("events").child("ID").observeSingleEvent(of: .value) { eventSnapshot in
                            if let eventDict = eventSnapshot.value as? [String: Any] {
                                for (key, value) in eventDict {
                                    if let eventID = value as? String, eventID == eventIdToDelete {
                                        print(eventID)
                                        self.userId.child("events").child("ID").child(key).removeValue { error, _ in
                                            if let error = error {
                                                print("Error removing value from your events node: \(error)")
                                            } else {
                                                print("(last)yourIdのeventsからイベント削除成功")
                                                self.userId.child("events").child("count").observeSingleEvent(of: .value) { snapshot in
                                                    if var countString = snapshot.value as? String, let count = Int(countString) {
                                                        countString = String(count - 1)
                                                        self.userId.child("events").child("count").setValue(countString)
                                                        print("(last)userIdのeventsのcountノードを減らすのに成功")
                                                        //alleventsからeventIdを削除
                                                        self.allEvents.child(eventIdToDelete).removeValue { error, _ in
                                                            if let error = error {
                                                                print("Failed to delete event: \(error.localizedDescription)")
                                                            } else {
                                                                print("allEventsからイベント削除成功")
                                                                self.tableViewRefresh()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    //イベントに接続している人がまだいる時
                    } else {
                        print("suc")
                        // yourIdからイベントを削除
                        self.userId.child("events").child("ID").observeSingleEvent(of: .value) { eventSnapshot in
                            if let eventDict = eventSnapshot.value as? [String: Any] {
                                for (key, value) in eventDict {
                                    if let eventID = value as? String, eventID == eventIdToDelete {
                                        print(eventID)
                                        self.userId.child("events").child("ID").child(key).removeValue { error, _ in
                                            if let error = error {
                                                print("Error removing value from your events node: \(error)")
                                            } else {
                                                print("(yet)yourIdのeventsからイベント削除成功")
                                                //接続人数を減らす
                                                self.allEvents.child(eventIdToDelete).child("connectMembersCount").observeSingleEvent(of: .value) { snapshot in
                                                    if var countString = snapshot.value as? String, let count = Int(countString) {
                                                        countString = String(count - 1)
                                                        self.allEvents.child(eventIdToDelete).child("connectMembersCount").setValue(countString)
                                                        print("接続人数を減らすのに成功")
                                                        //eventのcountを減らす
                                                        self.userId.child("events").child("count").observeSingleEvent(of: .value) { snapshot in
                                                            if var countString = snapshot.value as? String, let count = Int(countString) {
                                                                countString = String(count - 1)
                                                                self.userId.child("events").child("count").setValue(countString)
                                                                print("userIdのeventsのcountノードを減らすのに成功")
                                                                self.tableViewRefresh()
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if creatorId == displayEventsViewControllerValue {
            let lowRedColorWithAlpha = UIColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.03)
            cell.backgroundColor =  lowRedColorWithAlpha
            tableView.rowHeight = 235
        } else {
            let aquaColorWithAlpha = UIColor(red: 0.0, green: 1.0, blue: 1.0, alpha: 0.05)
            cell.backgroundColor = aquaColorWithAlpha
            //tableView.rowHeight = 270
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
