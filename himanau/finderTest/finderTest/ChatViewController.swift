//
//  ChatViewController.swift
//  finderTest
//
//  Created by ヒロ N on 2023/12/15.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage

class ChatViewController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    
    @IBOutlet weak var ChatTableView: UITableView!
    @IBOutlet weak var nameInputView: UITextField!
    @IBOutlet weak var messageInputView: UITextField!
    @IBOutlet weak var inputViewBottomMargin: NSLayoutConstraint!
    
    var ChatViewControllerValue = "002"
    var databaseRef: DatabaseReference!
    var nameRef : DatabaseReference!
    var user: DatabaseReference!
    var allEvents: DatabaseReference!
    var chatOutputValue :String = "pppp"
    var chatEventOutputValue = "112"
    var messages: [String] = []
    var messageText = ""
    var sender = "koko"
    var chatuser = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        self.ChatTableView.dataSource = self
                // Initialize Firebase references
        self.user = Database.database().reference().child("user")
        
        
        
                self.nameRef = self.user.child(ChatViewControllerValue)
        
        nameRef.child("name").observeSingleEvent(of: .value) { snapshot  in
            if let name = snapshot.value as? String {
                self.nameInputView.text = name
                self.chatuser = name
                //self.eventsTableView.reloadData()
            } else {
                // タイトルが取得できなかった場合の処理
                print("Failed to retrieve title for name")
            }
        }
        
                self.databaseRef = Database.database().reference().child("allEvents").child(chatEventOutputValue).child("chat")
                
                // Fetch messages from Firebase Database
                self.databaseRef.observe(.childAdded, with: { snapshot in
                    if let obj = snapshot.value as? [String : AnyObject], let name = obj["name"] as? String, let message = obj["message"] as? String {
                        /*let*/ self.messageText = "\(name): \(message)"
                        self.messages.append(self.messageText)
                        self.ChatTableView.reloadData()
            }
        })
        
        //NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        //NotificationCenter.default.addObserver(self, selector: #selector(ChatViewController.keyboardWillHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell", for: indexPath)
        cell.textLabel?.numberOfLines=0
        
        let messageData = messages[indexPath.row]
        let components = messageData.components(separatedBy: ": ")
        
        if components.count == 2 {
            let sender = components[0] // 送信者情報を取得
            let message = components[1] // メッセージを取得
            
            cell.textLabel?.text = messageData
            
            if messageData.contains(chatuser) {
                cell.textLabel?.textColor = UIColor.blue // chatOutputValueを含む送信者のメッセージのテキスト色を赤に設定
                //chatbutton.backgroundColor = UIColor.green
            } else {
                cell.textLabel?.textColor = UIColor.black // その他の場合のデフォルトのテキスト色を設定
            }
        } else {
            cell.textLabel?.text = messageData // メッセージの形式が正しくない場合は、そのまま表示
            cell.textLabel?.textColor = UIColor.black // デフォルトのテキスト色を設定
        }
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        cell.addGestureRecognizer(longPressGesture)
        
        return cell
    }
    
    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        guard gestureRecognizer.state == .began else { return }

        let touchPoint = gestureRecognizer.location(in: ChatTableView)
        if let indexPath = ChatTableView.indexPathForRow(at: touchPoint) {
            let messageData = messages[indexPath.row]
            let components = messageData.components(separatedBy: ": ")
            
            // メッセージの形式が正しいかチェック
            if components.count == 2 {
                let sender = components[0]
                
                // ロングプレスされたメッセージがユーザー自身によるものかチェック
                if messageData.contains(chatuser) {
                    // メッセージを削除
                    messages.remove(at: indexPath.row)
                    ChatTableView.deleteRows(at: [indexPath], with: .automatic)
                    // Firebaseからも削除するコードを追加する場合はここで削除処理を実装してください
                }
            }
        }
    }
    

    @IBAction func tappedSendButton(_ sender: Any) {
        view.endEditing(true)
                
                if let name = nameInputView.text, let message = messageInputView.text {
                    
                    
                    let messageData = ["name": name, "message": message]
                    databaseRef.childByAutoId().setValue(messageData)
                    
                    messageInputView.text = ""
                }
        
        //print(name)
        print(sender)
            }
    
    
    
    @IBAction func backButton(_ sender: Any) {
        self.dismiss(animated: false, completion: nil)
    }
    
    
    @objc func keyboardWillShow(_ notification: NSNotification){
        if let userInfo = notification.userInfo, let keyboardFrameInfo = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            inputViewBottomMargin.constant = keyboardFrameInfo.cgRectValue.height
        }
        
    }
    
    @objc func keyboardWillHide(_ notification: NSNotification){
        inputViewBottomMargin.constant = 0
    }
    
}

extension ChatViewController {
    func setupUI() {
        /*self.view.backgroundColor = UIColor(red: 113/255, green: 148/255, blue: 194/255, alpha: 1)
        tableView.backgroundColor = UIColor(red: 113/255, green: 148/255, blue: 194/255, alpha: 1)*/

        ChatTableView.separatorColor = UIColor.clear // セルを区切る線を見えなくする
        ChatTableView.estimatedRowHeight = 10000 // セルが高さ以上になった場合バインバインという動きをするが、それを防ぐために大きな値を設定
        ChatTableView.rowHeight = UITableView.automaticDimension // Contentに合わせたセルの高さに設定
        ChatTableView.allowsSelection = false // 選択を不可にする
        ChatTableView.keyboardDismissMode = .interactive // テーブルビューをキーボードをまたぐように下にスワイプした時にキーボードを閉じる

        ChatTableView.register(UINib(nibName: "YourChatViewCell", bundle: nil), forCellReuseIdentifier: "YourChat")
        ChatTableView.register(UINib(nibName: "MyChatViewCell", bundle: nil), forCellReuseIdentifier: "MyChat")

        /*self.bottomView = ChatRoomInputView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 70)) // 下部に表示するテキストフィールドを設定
        let chat1 = ChatEntity(text: "text1", time: "10:01", userType: .I)
        let chat2 = ChatEntity(text: "text2", time: "10:02", userType: .You)
        let chat3 = ChatEntity(text: "text3", time: "10:03", userType: .I)
        chats = [chat1, chat2, chat3]*/

    }
}
