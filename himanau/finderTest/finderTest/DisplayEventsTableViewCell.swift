
import UIKit
import Firebase

class DisplayEventsTableViewCell: UITableViewCell {
    
    @IBOutlet weak var eventDetailButton: UIButton!
    @IBOutlet weak var eventNotJoinButton: UIButton!
    @IBOutlet weak var eventJoinButton: UIButton!
    
    @IBOutlet weak var eventTitleLabel: UILabel!
    @IBOutlet weak var eventPlaceLabel: UILabel!
    @IBOutlet weak var eventDateStartLabel: UILabel!
    @IBOutlet weak var eventTimeStartLabel: UILabel!
    @IBOutlet weak var eventDateEndLabel: UILabel!
    @IBOutlet weak var eventTimeEndLabel: UILabel!
    @IBOutlet weak var eventMemberCountLabel: UILabel!
    @IBOutlet weak var eventMemberLabel: UILabel!
    
    @IBOutlet weak var eventMemberScrollView: UIScrollView!
    @IBOutlet weak var eventMemberScrollViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var eventMemberScrollViewWidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var remainingTimeProgressBar: UIProgressView!
    
    @IBOutlet weak var remainingTimeZeroLabel: UILabel!
    @IBOutlet weak var remainingTimeMiddleLabel: UILabel!
    @IBOutlet weak var remainingTimeMaxLabel: UILabel!
    
    var user: DatabaseReference!
    var userId: DatabaseReference!
    var allEvents: DatabaseReference!
    var displayEventTableViewCellValue: String = ""
    var eventId: String = ""
    var isUserEqualCreator: Bool = false
    var isJoinedFlag: Bool = false
    
    var initialEventMemberLabelFrame: CGRect?    // eventMemberLabelの初期フレームを保存するプロパティ
    var refreshCellDataCallback: (() -> Void)?
    
    // セルが初めて利用される時に呼ばれるメソッド
    override func awakeFromNib() {
        super.awakeFromNib()
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        initialLabelAndButton()
        initialEventMemberLabelFrame = eventMemberLabel.frame   //eventMemberLabel初期フレームを保存する
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    // セルが再利用される前に呼ばれるメソッド
    override func prepareForReuse() {
        super.prepareForReuse()
        initialLabelAndButton()
        // セルが再利用される前に eventMemberScrollView のサブビューをクリア
        for subview in eventMemberScrollView.subviews {
            subview.removeFromSuperview()
        }
        //eventMemberLabel初期フレームを再利用の際にセット
        if let initialFrame = initialEventMemberLabelFrame {
            if let label = eventMemberLabel {
                label.frame = initialFrame
                label.text = "nil"
            } else {
                print("eventMemberLabel is nil.")
            }
        } else {
            print("InitialEventMemberLabelFrame is nil.")
        }
    }
    
    // ラベル/ボタンの初期化をする関数
    func initialLabelAndButton() {
        eventTitleLabel?.text = ""
        eventPlaceLabel?.text = ""
        eventDateStartLabel?.text = ""
        eventTimeStartLabel?.text = ""
        eventDateEndLabel?.text = ""
        eventTimeEndLabel?.text = ""
        eventMemberCountLabel?.text = ""
        eventMemberLabel?.text = " "
        
        eventJoinButton.setTitle("参加する", for: .normal)
        eventJoinButton.backgroundColor = UIColor.systemCyan.withAlphaComponent(0.2)
        eventJoinButton.setTitleColor(UIColor.systemBlue, for: .normal)
        eventJoinButton.isEnabled = true
        
        eventNotJoinButton.setTitle("参加しない", for: .normal)
        eventNotJoinButton.backgroundColor = UIColor.systemRed
        eventNotJoinButton.setTitleColor(UIColor.white, for: .normal)
        eventNotJoinButton.isEnabled = true
        
        eventDetailButton.setTitle("詳細", for:  .normal)
        eventDetailButton.backgroundColor = UIColor.systemGray5
        eventDetailButton.setTitleColor(UIColor.systemBlue, for: .normal)
        eventDetailButton.isEnabled = true
    }

    // セル内で関数を実行するためのメソッド
    func executeCellFunction() {
        // 例: DisplayEventsViewControllerのcellPrintメソッドを呼び出す
        if let viewController = findViewController() as? DisplayEventsViewController {
            viewController.tableViewRefresh()
        }
    }
    
    // セル内で関数を実行するためのメソッド
    func executeCellFunctionOfReloadData() {
        // 例: DisplayEventsViewControllerのcellPrintメソッドを呼び出す
        if let viewController = findViewController() as? DisplayEventsViewController {
            viewController.eventsTableView.reloadData()
        }
    }
    
    func findViewController() -> UIViewController? {
        var responder: UIResponder? = self
        while let currentResponder = responder {
            if let viewController = currentResponder as? UIViewController {
                return viewController
            }
            responder = currentResponder.next
        }
        return nil
    }
    
    @IBAction func eventDetailButtonTapped(_ sender: UIButton) {
        print("kookok")
        executeCellFunction()
        if let tableView = self.superview as? UITableView, let indexPath = tableView.indexPath(for: self) {
                               if let viewController = findViewController() as? DisplayEventsViewController {
                                   let eventId = viewController.eventIDs[indexPath.row] // eventIDsはYourViewController内で保持しているデータの配列などです
                                   
                                   // 画面遷移先のビューコントローラを取得
                                   if let destinationVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController {
                                       // eventIdを次の画面に渡す
                                       destinationVC.chatEventOutputValue = eventId
                                       destinationVC.ChatViewControllerValue = displayEventTableViewCellValue
                                       
                                       // ナビゲーションコントローラを使って画面遷移
                                       viewController.navigationController?.pushViewController(destinationVC, animated: true)
                                   }
                               }
                           }
                       
    }
    
    @IBAction func eventNotJoinButtonTapped(_ sender: UIButton) {
        self.user = Database.database().reference().child("user")
        self.userId = self.user.child(displayEventTableViewCellValue)
        let eventRef = self.allEvents.child(self.eventId)
        
        guard let tableView = self.superview as? UITableView else {
            print("Error: Unable to find UITableView in superview.")
            return
        }
        
        guard let indexPath = tableView.indexPath(for: self) else {
            print("Error: Unable to get indexPath for cell.")
            return
        }
        
        guard let controller = tableView.delegate as? DisplayEventsViewController else {
            print("Error: Unable to find DisplayEventsViewController.")
            return
        }
        
        eventRef.observeSingleEvent(of: .value) { [weak self] snapshot in
            guard let self = self else { return }
            
            if snapshot.exists() {
                // イベントが存在する場合
                eventRef.child("title").observeSingleEvent(of: .value) { titleSnapshot in
                    var eventTitle = "タイトルなし"
                    if let title = titleSnapshot.value as? String, !title.isEmpty {
                        eventTitle = title
                    }
                    
                    var notJoinAlertTitle: String
                    var notJoinAlertMessage: String
                    
                    if self.isJoinedFlag == false{
                        notJoinAlertTitle = "参加拒否確認"
                        notJoinAlertMessage = "\(eventTitle)を断りますか？"
                    } else {
                        notJoinAlertTitle = "退会確認"
                        notJoinAlertMessage = "\(eventTitle)から退会しますか？"
                    }
                    
                    let confirmationAlert = UIAlertController(title: notJoinAlertTitle, message: notJoinAlertMessage, preferredStyle: .alert)
                    
                    let yesAction = UIAlertAction(title: "はい", style: .default) { _ in
                        if self.isJoinedFlag == false{
                            // イベントの参加を断る処理をここに追加
                            self.userId.child("events").child("ID").observeSingleEvent(of: .value) { eventsSnapshot in
                                if let eventsDict = eventsSnapshot.value as? [String: Any] {
                                    for (key, value) in eventsDict {
                                        if let eventID = value as? String, eventID == self.eventId {
                                            // eventIdと同じキーが存在する場合、参加を断る処理を実行
                                            self.userId.child("events").child("ID").child(key).removeValue()
                                            self.userId.child("events").child("count").observeSingleEvent(of: .value) { snapshot in
                                                if var countString = snapshot.value as? String, let count = Int(countString) {
                                                    countString = String(count - 1)
                                                    self.userId.child("events").child("count").setValue(countString)
                                                    self.executeCellFunction()
                                                }
                                                return
                                            }
                                        }
                                    }
                                    return
                                } else {
                                    // eventidと同じキーが見つからなかった場合の処理
                                    print("Error: Key not found in joined node.")
                                    return
                                }
                            }
                        } else {
                            // イベントの退会をする処理をここに追加
                            eventRef.child("joined").observeSingleEvent(of: .value) { joinedSnapshot in
                                if let joinedDict = joinedSnapshot.value as? [String: Any] {
                                    for (key, value) in joinedDict {
                                        if let joinedID = value as? String, joinedID == self.displayEventTableViewCellValue {
                                            // displayEventTableViewCellValueと同じキーが存在する場合、退会する処理を実行
                                            eventRef.child("joined").child(key).removeValue { error, _ in
                                                if let error = error {
                                                    print("Error removing value from joined node: \(error)")
                                                } else {
                                                    self.userId.child("events").child("ID").observeSingleEvent(of: .value) { eventsSnapshot in
                                                        if let eventsDict = eventsSnapshot.value as? [String: Any] {
                                                            for (key, value) in eventsDict {
                                                                if let eventID = value as? String, eventID == self.eventId {
                                                                    // eventIdと同じキーが存在する場合、参加を断る処理を実行
                                                                    self.userId.child("events").child("ID").child(key).removeValue()
                                                                    self.userId.child("events").child("count").observeSingleEvent(of: .value) { snapshot in
                                                                        if var countString = snapshot.value as? String, let count = Int(countString) {
                                                                            countString = String(count - 1)
                                                                            self.userId.child("events").child("count").setValue(countString)
                                                                            self.executeCellFunction()
                                                                        }
                                                                        return
                                                                    }
                                                                }
                                                            }
                                                        } else {
                                                            // eventidと同じキーが見つからなかった場合の処理
                                                            print("Error: Key not found in joined node.")
                                                            return
                                                        }
                                                    }
                                                }
                                            }
                                            return
                                        }
                                    }
                                }
                                // displayEventTableViewCellValueと同じキーが見つからなかった場合の処理
                                print("Error: Key not found in joined node.")
                                return
                            }
                        }
                    }
                    let noAction = UIAlertAction(title: "いいえ", style: .cancel, handler: nil)
                    confirmationAlert.addAction(yesAction)
                    confirmationAlert.addAction(noAction)
                    
                    controller.present(confirmationAlert, animated: true, completion: nil)
                }
            } else {
                // イベントが存在しない場合の処理
                let notExistAlert = UIAlertController(title: "エラー", message: "イベントは存在しません。", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                notExistAlert.addAction(okAction)
                controller.present(notExistAlert, animated: true, completion: nil)
            }
        }
    }
    
    
    @IBAction func eventJoinButtonTapped(_ sender: UIButton) {
        let eventRef = self.allEvents.child(self.eventId)
        
        guard let tableView = self.superview as? UITableView else {
            print("Error: Unable to find UITableView in superview.")
            return
        }
        
        guard let indexPath = tableView.indexPath(for: self) else {
            print("Error: Unable to get indexPath for cell.")
            return
        }
        
        guard let controller = tableView.delegate as? DisplayEventsViewController else {
            print("Error: Unable to find DisplayEventsViewController.")
            return
        }
        
        eventRef.observeSingleEvent(of: .value) { snapshot in
            if snapshot.exists() {
                // イベントが存在する場合
                eventRef.child("title").observeSingleEvent(of: .value) { titleSnapshot in
                    var eventTitle = "タイトルなし"
                    if let title = titleSnapshot.value as? String, !title.isEmpty {
                        eventTitle = title
                    }
                    
                    let confirmationAlert = UIAlertController(title: "参加確認", message: "\(eventTitle)に参加しますか？", preferredStyle: .alert)
                    
                    let yesAction = UIAlertAction(title: "はい", style: .default) { _ in
                        // イベントに参加する処理
                        let joinedRef = eventRef.child("joined")
                        joinedRef.childByAutoId().setValue(self.displayEventTableViewCellValue)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.executeCellFunction()
                        }
                    }
                    let noAction = UIAlertAction(title: "いいえ", style: .cancel, handler: nil)
                    confirmationAlert.addAction(yesAction)
                    confirmationAlert.addAction(noAction)
                    
                    controller.present(confirmationAlert, animated: true, completion: nil)
                }
            } else {
                // イベントが存在しない場合の処理
                let notExistAlert = UIAlertController(title: "エラー", message: "イベントは存在しません。", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                notExistAlert.addAction(okAction)
                controller.present(notExistAlert, animated: true, completion: nil)
            }
        }
        
    }


    
}
