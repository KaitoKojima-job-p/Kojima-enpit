
import UIKit
import Firebase
import CryptoKit

class CreateEventViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    @IBOutlet weak var eventTitleTextField: UITextField!
    @IBOutlet weak var eventMemoTextField: UITextField!
    @IBOutlet weak var eventPlaceTextField: UITextField!
    
    @IBOutlet weak var eventStartDate: UIDatePicker!
    @IBOutlet weak var eventStartTime: UIDatePicker!
    @IBOutlet weak var eventEndDate: UIDatePicker!
    @IBOutlet weak var eventEndTime: UIDatePicker!
    @IBOutlet weak var timePicker: UIPickerView!
    
    @IBOutlet weak var createEventMemberTitleLabel: UILabel!
    @IBOutlet weak var createEventScrollView: UIScrollView!
    @IBOutlet weak var createEventMemberLabel: UILabel!
    
    var user: DatabaseReference!
    var userId: DatabaseReference!
    var allEvents: DatabaseReference!
    
    let timeIntervals: [Int] = [10, 20, 30, 60, 120, 180, 360, 720, 1440] // 分単位での時間間隔
    var createEventViewControllerValue = "" // ユーザーID用の変数l
    var selectedFriends: [String] = []
    var retryCount = 0  // createEvent用のリトライ回数
    var eventId = ""    //allEventsに登録したeventのID用の変数
    var selectedMinutes: Int = 30   // 変数で選択された時間を管理// デフォルトで30分を選択
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = Database.database().reference().child("user")
        self.userId = user.child(createEventViewControllerValue)
        self.allEvents = Database.database().reference().child("allEvents")
        
        dateSettings()  //datepickerの設定
        
        //timePickerの設定
        timePicker.dataSource = self
        timePicker.delegate = self
        // デフォルトで30分を選択
        let defaultRowIndex = timeIntervals.firstIndex(of: 30) ?? 0
        timePicker.selectRow(defaultRowIndex, inComponent: 0, animated: false)
        
        // 初期選択時間を設定
        selectedMinutes = timeIntervals[defaultRowIndex]
        
        displayEventMembers()
    }
    
    func dateSettings(){
        // 表示する時間の場所を設定
        eventStartDate.timeZone = TimeZone(identifier: "Asia/Tokyo")
        eventStartTime.timeZone = TimeZone(identifier: "Asia/Tokyo")
        eventEndDate.timeZone = TimeZone(identifier: "Asia/Tokyo")
        eventEndTime.timeZone = TimeZone(identifier: "Asia/Tokyo")
        // 日本のロケールを設定
        eventStartDate.locale = Locale(identifier: "ja_JP")
        eventStartTime.locale = Locale(identifier: "ja_JP")
        eventEndDate.locale = Locale(identifier: "ja_JP")
        eventEndTime.locale = Locale(identifier: "ja_JP")
    }
    
    func displayEventMembers() {
        var displayMembers: [String] = selectedFriends
        displayMembers.insert(createEventViewControllerValue, at: 0)
        print(displayMembers)
        let initialEventMemberLabelFrame: CGRect?  = createEventMemberLabel.frame
        if let labelFrame = initialEventMemberLabelFrame {
            createEventMemberTitleLabel.text = "メンバー(\(displayMembers.count))"
            createEventMemberLabel.text = ""
            var maxWidth: CGFloat = 0.0
            var totalHeight: CGFloat = 0.0
            var completionCount = 0
            let totalMembers = displayMembers.count
            
            for member in displayMembers{
                user.child(member).child("name").observeSingleEvent(of: .value) { snapshot in
                    if let memberName = snapshot.value as? String {
                        // 新しい UILabel を作成
                        let memberLabel = UILabel(frame: labelFrame)
                        memberLabel.text = memberName
                        memberLabel.font = UIFont.systemFont(ofSize: 17)
                        memberLabel.textColor = .black
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
                        self.createEventScrollView.addSubview(memberLabel)
                    } else {
                        self.createEventMemberLabel.text = "No Name"
                    }
                    completionCount += 1
                    if completionCount == totalMembers {
                        // ScrollView の contentSize を設定
                        self.createEventScrollView.contentSize = CGSize(width: maxWidth, height: totalHeight)
                    }
                }
            }
        } else {
            print("initialEventMemberLabelFrame is nil")
        }
    }
    
    // 作成ボタンがタップされた時
    @IBAction func createEventButtonTapped(_ sender: UIBarButtonItem) {
        // ポップアップを表示
        let alertController = UIAlertController(title: "確認", message: "イベントを作成しますか？", preferredStyle: .alert)
        
        // 「はい」アクション
        let yesAction = UIAlertAction(title: "はい", style: .default) { _ in
            // 「はい」が選択されたときの処理
            self.CreateEventInAllEvents()   //イベントをallEventsに作成
            self.CreateEventInYourEvents()   //イベントをuserIdのeventsに作成
            self.CreateEventInfriendsEvents()    //イベントをfriendのユーザーIDのeventsに作成
        }
        
        // 「いいえ」アクション
        let noAction = UIAlertAction(title: "いいえ", style: .cancel, handler: nil)
        
        // アクションをアラートに追加
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        // アラートを表示
        present(alertController, animated: true, completion: nil)
    }
    
    //イベントをallEventsの子ノードに作る関数
    func CreateEventInAllEvents() {
        
        // 開始時間が終了時間よりも後になっているかチェック
        if isStartTimeAfterEndTime() {
            showAlert(message: "開始時間は終了時間よりも前に設定してください。")
            return
        }
        
        // ランダムな値生成
        let randomValue = generateRandomValue(length: 8)
        
        allEvents.child(randomValue).observeSingleEvent(of: .value) { snapshot in
            if !snapshot.exists() {
                // データが存在しない場合、保存処理を行う
                let newEventRef = self.allEvents.child(randomValue)
                newEventRef.child("creator").setValue(self.createEventViewControllerValue)
                newEventRef.child("title").setValue(self.eventTitleTextField.text ?? "")
                newEventRef.child("memo").setValue(self.eventMemoTextField.text ?? "")
                newEventRef.child("place").setValue(self.eventPlaceTextField.text ?? "")
                newEventRef.child("connectMembersCount").setValue("\(self.selectedFriends.count+1)")
                newEventRef.child("message").setValue("追加されたイベントです")
                
                // timeノードの作成
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                // 日本のタイムゾーンを設定
                dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
                // 開始日時のDatePickerから日付と時間を取得
                let startDate = self.eventStartDate.date
                let startTime = self.eventStartTime.date
                // 終了日時のDatePickerから日付と時間を取得
                let endDate = self.eventEndDate.date
                let endTime = self.eventEndTime.date
                // Calendarを使用して時刻を合わせる
                let calendar = Calendar.current
                let startTimeWithTimeZone = calendar.date(bySettingHour: calendar.component(.hour, from: startTime),
                                                          minute: calendar.component(.minute, from: startTime),
                                                          second: 0,
                                                          of: startDate)
                
                let endTimeWithTimeZone = calendar.date(bySettingHour: calendar.component(.hour, from: endTime),
                                                        minute: calendar.component(.minute, from: endTime),
                                                        second: 0,
                                                        of: endDate)
                
                // 日付と時間を合わせて文字列に変換
                if let startTimeString = startTimeWithTimeZone.flatMap({ dateFormatter.string(from: $0) }),
                   let endTimeString = endTimeWithTimeZone.flatMap({ dateFormatter.string(from: $0) }) {
                    
                    //  データベースに登録
                    newEventRef.child("time").child("start").setValue(startTimeString)
                    newEventRef.child("time").child("end").setValue(endTimeString)
                    
                    if let deadlineTime = Calendar.current.date(byAdding: .minute, value: self.selectedMinutes, to: Date()) {
                        let deadlineTimeString = dateFormatter.string(from: deadlineTime)
                        newEventRef.child("deadline").child("time").setValue(deadlineTimeString)
                        newEventRef.child("deadline").child("toAdd").setValue(String(self.selectedMinutes))
                    }
                    
                    self.eventId = randomValue  //イベントのIDを登録
                    print("イベントが作成されました！")
                } else {
                    print("日付の変換に失敗しました")
                }
                
                //selectedFriends[]の文字列をnewEventRef.child("invited")に追加する処理
                for friendID in self.selectedFriends {
                    newEventRef.child("invited").childByAutoId().setValue(friendID)
                }

            } else {
                // データが存在する場合、リトライ
                self.retryCount += 1
                if self.retryCount < 10 {
                    print("重複するイベントが存在します。新しいランダムな値を生成して再試行します。")
                    self.CreateEventInAllEvents()
                } else {
                    // 10回以上リトライしてもデータが存在する場合、アラートを表示
                    self.showAlert(message: "イベントが作成できませんでした。")
                    self.retryCount = 0
                }
            }
        }
    }
    
    // アラートを表示するメソッド
    func showAlert(message: String) {
        let alertController = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // 開始時間が終了時間よりも後になっているかチェック
    func isStartTimeAfterEndTime() -> Bool {
        let startDateTime = eventStartDate.date.addingTimeInterval(eventStartTime.date.timeIntervalSinceReferenceDate)
        let endDateTime = eventEndDate.date.addingTimeInterval(eventEndTime.date.timeIntervalSinceReferenceDate)
        
        return startDateTime.timeIntervalSinceReferenceDate > endDateTime.timeIntervalSinceReferenceDate
    }
    
    // 安全なランダムなバイト列を生成
    func generateRandomBytes(count: Int) -> Data {
        var randomBytes = Data(count: count)
        _ = randomBytes.withUnsafeMutableBytes { mutableBytes in
            SecRandomCopyBytes(kSecRandomDefault, count, mutableBytes.baseAddress!)
        }
        return randomBytes
    }
    
    // 指定された長さのランダムな16進数の文字列を生成
    func generateRandomValue(length: Int) -> String {
        let randomData = generateRandomBytes(count: length)
        return randomData.map { String(format: "%02hhx", $0) }.joined()
    }
    
    // イベントをユーザーの子ノードのeventsの子ノードに作る関数
    func CreateEventInYourEvents(){
        let userEventsRef = self.user.child(self.createEventViewControllerValue).child("events")
        var userEventsIdRef: DatabaseReference!
        
        // 開始時間が終了時間よりも後になっているかチェック
        if isStartTimeAfterEndTime() {
            showAlert(message: "開始時間は終了時間よりも前に設定してください。")
            return
        }
        
        userEventsRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            if let count = snapshot.childSnapshot(forPath: "count").value as? String {
                let numericCount = Int(count)! + 1
                // userEventsRefの子ノードのIDの子ノードにeventIdを追加
                userEventsIdRef = userEventsRef.child("ID")
                userEventsIdRef.childByAutoId().setValue(self?.eventId)
                // countの値を更新
                userEventsRef.child("count").setValue(String(numericCount))
            } else {
                // countがない場合は初期値をセット
                userEventsIdRef = userEventsRef.child("ID")
                userEventsIdRef.childByAutoId().setValue(self?.eventId)
                userEventsRef.child("count").setValue("1")
            }
        }
    }

    
    //イベントをユーザーのフレンドの子ノードのeventsの子ノードに作る関数
    func CreateEventInfriendsEvents() {
        
        // 開始時間が終了時間よりも後になっているかチェック
        if isStartTimeAfterEndTime() {
            showAlert(message: "開始時間は終了時間よりも前に設定してください。")
            return
        }
        
        // selectedFriendsに登録されている各フレンドのIDに対して処理を行う
        for friendID in selectedFriends {
            let friendEventsRef = self.user.child(friendID).child("events")
            var friendEventsIdRef: DatabaseReference!
            
            friendEventsRef.observeSingleEvent(of: .value) { [weak self] snapshot in
                if let count = snapshot.childSnapshot(forPath: "count").value as? String {
                    let numericCount = Int(count)! + 1
                    // userEventsRefの子ノードのIDの子ノードにeventIdを追加
                    friendEventsIdRef = friendEventsRef.child("ID")
                    friendEventsIdRef.childByAutoId().setValue(self?.eventId)
                    // countの値を更新
                    friendEventsRef.child("count").setValue(String(numericCount))
                } else {
                    // countがない場合は初期値をセット
                    friendEventsIdRef = friendEventsRef.child("ID")
                    friendEventsIdRef.childByAutoId().setValue(self?.eventId)
                    friendEventsRef.child("count").setValue("1")
                }
            }
            
        }
    }
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1 // 1列だけ使用
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return timeIntervals.count
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let minutes = timeIntervals[row]
        if minutes >= 60 && minutes < 1440 {
            let hours = minutes / 60
            return "\(hours) 時間"
        } else if minutes == 1440 {
            return "1 日"
        } else {
            return "\(minutes) 分"
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // 選択された時間を変数に代入
        selectedMinutes = timeIntervals[row]
    }

    
}
