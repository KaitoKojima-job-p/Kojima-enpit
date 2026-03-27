
import UIKit
import Firebase

struct FriendData {
    var name: String
    var isContained: Bool
    
    init(name: String, isContained: Bool) {
        self.name = name
        self.isContained = isContained
    }
}

class AddFriendsIDContainerView: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var addFriendSearchBar: UISearchBar!
    @IBOutlet weak var friendNameLabel: UILabel!
    
    @IBOutlet weak var groupsSearchBar: UISearchBar!
    @IBOutlet weak var groupsTableView: UITableView!
    @IBOutlet weak var groupsStackView: UIStackView!
    
    var addFriendsIDViewControllerValue = ""
    var administrator: DatabaseReference!
    var user: DatabaseReference!
    var yourId: DatabaseReference!
    var friendId: DatabaseReference!
    
    var originalData: [FriendData] = [] // 初期のリストのデータを保持する配列
    var displayedData: [FriendData] = []    // 表示するリストのデータを保持する配列
    var selectedItems: Set<Int> = []  // 選択されたアイテムのインデックスを保持するセット
    
    var addedFriendId: String?
    var addedFriendName: String?
    var friendIsContain = 3 //含まれている場合は0、含まれていない場合は1、自身のユーザーidの場合は2、存在しない場合は3
    var friendUserIDforLabelTapped: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        groupsStackHideAll()
        friendNameLabel.text = ""
        self.user = Database.database().reference().child("user")
        self.yourId = Database.database().reference().child("user").child(addFriendsIDViewControllerValue)
        addFriendSearchBar.delegate = self
        addFriendSearchBar.enablesReturnKeyAutomatically = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(nameLabelTapped))
        friendNameLabel.isUserInteractionEnabled = true
        friendNameLabel.addGestureRecognizer(tapGesture)
        
        // 検索バーの設定
        self.groupsSearchBar.delegate = self
        // テーブルビューの設定
        self.groupsTableView.dataSource = self
        self.groupsTableView.delegate = self
    
        // キーボード以外の場所をタップしたときの処理を追加
        let tapGestureKey = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGestureKey.cancelsTouchesInView = false
        self.view.addGestureRecognizer(tapGestureKey)
    }
    
    @objc func handleTap() {
        self.view.endEditing(true) // キーボードを閉じる
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder() // キーボードを閉じる
        
        if searchBar == addFriendSearchBar {
            if let friendUserID = searchBar.text {
                user.child(friendUserID).observeSingleEvent(of: .value, with: { (snapshot) in
                    if let friendUserDict = snapshot.value as? [String: Any], let friendUserName = friendUserDict["name"] as? String {
                        // count ノードの値を取得
                        self.yourId.child("count").observeSingleEvent(of: .value, with: { (countSnapshot) in
                            if let friendsCountString = countSnapshot.value as? String, let friendsCount = Int(friendsCountString) {
                                // friends ノード以下に friendNumber が value として格納されている場合
                                self.yourId.child("friends").observeSingleEvent(of: .value, with: { (friendsSnapshot) in
                                    if friendsCount >= 0 {
                                        // 友達に追加されていない場合 //はじめは登録されないものとする
                                        print("not contain")
                                        self.friendIsContain = 1
                                        self.friendUserIDforLabelTapped = friendUserID //ラベルがタップされた時用の変数
                                        self.addedFriendId = friendUserID
                                        self.friendNameLabel.text = friendUserName
                                        self.addedFriendName = friendUserName
                                        self.groupsStackHideAll()
                                        
                                        if friendUserID == self.addFriendsIDViewControllerValue {
                                            self.friendIsContain = 2
                                            self.friendNameLabel.text = "あなたのユーザーIDです"
                                        }
                                        
                                        if friendsCount == 0 {
                                            print("you have no friend")
                                            return
                                        }
                                        
                                        for i in 1...friendsCount {
                                            let friendNumber = String(format: "%03d", i)
                                            // friendNumber が存在し、その value が friendUserID である場合
                                            if friendsSnapshot.hasChild(friendNumber), let storedFriendID = friendsSnapshot.childSnapshot(forPath: friendNumber).value as? String, storedFriendID == friendUserID {
                                                // ユーザーが自分の friends に存在する場合
                                                print("contain")
                                                self.friendIsContain = 0
                                                self.friendNameLabel.text = friendUserName + "(友達に追加済み)"
                                                self.addedFriendId = friendUserID
                                                self.addedFriendName = friendUserName
                                                
                                                self.createOriginalData()
                                            }
                                        }
                                    }
                                })
                            } else {
                                // count ノードが存在しない場合など
                                print("Error: Count node not found or invalid value")
                                self.friendIsContain = 3
                                self.friendNameLabel.text = "友達が見つかりません"
                                self.addedFriendId = nil
                                self.addedFriendName = nil
                                self.groupsStackHideAll()
                            }
                        })
                    } else {
                        // ユーザーが database に存在しない場合
                        self.friendIsContain = 3
                        self.friendNameLabel.text = "友達が見つかりません"
                        self.addedFriendId = nil
                        self.addedFriendName = nil
                        self.groupsStackHideAll()
                    }
                })
            }
        } else if searchBar == groupsSearchBar {
            // groupsSearchBarの処理
            // 他のコード...
        }
    }
    
    func initArray() {
        originalData = [FriendData]()
        displayedData =  [FriendData]()
        selectedItems =  Set<Int>()
    }
    
    // friendsに自分の友達を追加する処理
    func addFriendToYourFriends(userID friendUserID: String) {
        
        let countRef = yourId.child("count")
        countRef.observeSingleEvent(of: .value) { (countSnapshot) in
            if let currentCount = countSnapshot.value as? String {
                
                // "count" カウンタをインクリメント
                countRef.setValue(String(Int(currentCount)! + 1))
                
                // "friends" ノードに友達のユーザーIDを連番に追加
                let friendNumber = String(format: "%03d", Int(currentCount)! + 1)
                let friendsRef = self.yourId.child("friends").child(friendNumber)
                friendsRef.setValue(friendUserID) { (error, reference) in
                    if let error = error {
                        print("友達を追加できませんでした: \(error.localizedDescription)")
                    } else {
                        print("友達を追加しました")
                    }
                }
            } else {
                print("error")
            }
        }
    }
    
    // 友達のfriendsにあなたを追加する処理
    func addYouToFriendsOfFriend(userID friendUserID: String) {
        
        friendId = Database.database().reference().child("user").child(friendUserID)
        let countRef = friendId.child("count")
        countRef.observeSingleEvent(of: .value) { (countSnapshot) in
            if let currentCount = countSnapshot.value as? String {
                
                // "count" カウンタをインクリメント
                countRef.setValue(String(Int(currentCount)! + 1))
                
                // "friends" ノードに友達のユーザーIDを連番に追加
                let friendNumber = String(format: "%03d", Int(currentCount)! + 1)
                let friendsRef = self.friendId.child("friends").child(friendNumber)
                friendsRef.setValue(self.addFriendsIDViewControllerValue) { (error, reference) in
                    if let error = error {
                        print("友達を追加できませんでした: \(error.localizedDescription)")
                    } else {
                        print("友達を追加しました")
                    }
                }
            } else {
                print("error")
            }
        }
    }
    
    func createOriginalData() {
        // originalDataを作る処理
        let groupsRef = self.yourId.child("groups")
        
        //データを受け取る箱を初期化
        self.originalData = [FriendData]()
        
        groupsRef.observeSingleEvent(of: .value) { snapshot in
            
            guard snapshot.exists() else {
                print("Groupなし")
                self.groupsStackShowAll()
                return
            }
            
            if let children = snapshot.children.allObjects as? [DataSnapshot] {
                var processedGroupCount = 0  // グループの処理が完了した数をカウント
                for child in children {
                    let groupRef = groupsRef.child(child.key)
                    groupRef.observeSingleEvent(of: .value) { groupOfSnapshot in
                        if let groupOfChildren = groupOfSnapshot.children.allObjects as? [DataSnapshot] {
                            // グループ内の各子ノードのvalueを確認
                            let friendIDs = groupOfChildren.map { $0.value as? String }
                            if friendIDs.contains(self.addedFriendId!) {
                                // グループにfriendIdが含まれている場合→グループに参加済み
                                self.originalData.append(FriendData(name: child.key, isContained: true))
                            } else {
                                // グループにfriendIdが含まれていない場合
                                self.originalData.append(FriendData(name: child.key, isContained: false))
                            }
                            // 1つのグループの処理が完了
                            processedGroupCount += 1
                            
                            if processedGroupCount == children.count {
                                // すべてのグループの処理が完了したら表示
                                self.displayedData = self.originalData
                                self.groupsTableView.reloadData()
                                self.groupsStackShowAll()
                                print("displayedData: \(self.displayedData)")
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar == addFriendSearchBar {
            if searchText.isEmpty {
                self.groupsStackHideAll()
                initArray()
                friendNameLabel.text = ""
                self.friendIsContain = 3
                addedFriendId = nil
                addedFriendName = nil
            }
        } else if searchBar == groupsSearchBar {
            // 検索バーの文字列でリストをフィルタリングして表示する処理
            displayedData = searchText.isEmpty ? originalData : originalData.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
            // フィルタリングした結果をテーブルビューに反映
            groupsTableView.reloadData()
        }
    }
    
    // 検索バーのクリアボタンが押されたときの処理
    func searchBarShouldClear(_ searchBar: UISearchBar) -> Bool {
        displayedData = originalData
        groupsTableView.reloadData()
        return true
    }
    
    //ラベルをタップした時
    @IBAction func nameLabelTapped(_ sender: UITapGestureRecognizer) {
        if friendIsContain == 1, let friendName = addedFriendName {
            let alertController = UIAlertController(title: "「\(friendName)」を友達に追加しますか", message: nil, preferredStyle: .alert)
            
            let addAction = UIAlertAction(title: "はい", style: .default) { (action) in
                // 友達に追加する処理をここに追加
                self.addFriendToYourFriends(userID: self.friendUserIDforLabelTapped!)
                self.addYouToFriendsOfFriend(userID: self.friendUserIDforLabelTapped!)
                self.friendNameLabel.text = friendName + "(友達に追加済み)"
                print("\(friendName)を友達に追加しました")
                //グループ画面の表示
                self.friendIsContain = 0
                self.createOriginalData()
            }
            
            let cancelAction = UIAlertAction(title: "いいえ", style: .cancel, handler: nil)
            
            alertController.addAction(addAction)
            alertController.addAction(cancelAction)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        let friendData = displayedData[indexPath.row]
        if friendData.isContained {
            cell.textLabel?.text = friendData.name + " [グループに追加済み]"
        } else {
            cell.textLabel?.text = friendData.name
        }
        
        // 選択されたセルにチェックマークを表示する
        cell.accessoryType = selectedItems.contains(indexPath.row) ? .checkmark : .none
        
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // セルが選択された際の処理
        // 選択されたセルのインデックスをセットに追加または削除
        if selectedItems.contains(indexPath.row) {
            selectedItems.remove(indexPath.row)
        } else {
            selectedItems.insert(indexPath.row)
        }
        // チェックマークを更新
        tableView.reloadRows(at: [indexPath], with: .automatic)
        // 選択状態の強調表示をなくす
        tableView.deselectRow(at: indexPath, animated: false)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // 左にスワイプして削除する処理
        if editingStyle == .delete {
            let deletedItem = displayedData[indexPath.row]
            let groupsRef = self.yourId.child("groups")
            
            groupsRef.child(deletedItem.name).removeValue { error, _ in
                if let error = error {
                    print("Error deleting group: \(error.localizedDescription)")
                    return
                }
                // 削除が成功した場合の処理
                self.originalData.remove(at: indexPath.row)
                self.displayedData = self.originalData
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            
        }
    }
    
    // 作成ボタンが押された時の処理
    @IBAction func createButtonTapped(_ sender: UIButton) {
        if let newItem = groupsSearchBar.text, !newItem.isEmpty {
            let groupsRef = self.yourId.child("groups")
            let newChildRef = groupsRef.child(newItem)
            
            // newItemがoriginalDataに含まれているか確認
            if originalData.contains(where: { $0.name == newItem }) {
                // アラートを表示して処理を中断
                showAlert(message: "「\(newItem)」はすでに作成しています")
                return
            }
            
            newChildRef.setValue("") { error, _ in
                if let error = error {
                    print("Error adding group: \(error.localizedDescription)")
                    return
                }
                // 新しいリストを追加
                self.originalData.append(FriendData(name: newItem, isContained: false))
                self.displayedData = self.originalData
                self.selectedItems.removeAll()
                self.groupsTableView.reloadData()
                // ポップアップを表示する
                self.showPopup(message: "グループ 「\(newItem)」を追加しました")
                // 検索バーをクリア
                self.groupsSearchBar.text = ""
            }
        }
    }
    
    // addButtonが押された時の処理
    @IBAction func addButtonTapped(_ sender: UIButton) {
        var loopcCount = 0
        // 選択されたセルがない場合は処理を中断
        guard !selectedItems.isEmpty else { return }
        // アラートメッセージの構築
        var message = ""
        for index in self.selectedItems {
            message += "\(self.displayedData[index].name)\n"
        }
        message += "に「\(self.addedFriendName!)」を追加しますか？"
        // アラートを表示
        let alertController = UIAlertController(title: "友達をグループに追加", message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
            let groupsRef = self.yourId.child("groups")
            
            for index in self.selectedItems {
                let groupName = self.displayedData[index].name
                let groupRef = groupsRef.child(groupName)
                
                let savedCount = self.selectedItems.count
                
                groupRef.observeSingleEvent(of: .value) { snapshot in
                    if let children = snapshot.children.allObjects as? [DataSnapshot] {
                        // グループ内の各子ノードのvalueを確認
                        let friendIDs = children.map { $0.value as? String }
                        if !friendIDs.contains(self.addedFriendId) {
                            // friendIDが含まれていない場合
                            let newChildRef = groupRef.childByAutoId()
                            // (friendID)をvalueに追加
                            newChildRef.setValue(self.addedFriendId) { error, _ in
                                if let error = error {
                                    // setValueが失敗した場合の処理
                                    print("Error adding friend to group: \(error.localizedDescription)")
                                } else {
                                    loopcCount += 1
                                    if loopcCount == savedCount{
                                        self.initArray()
                                        self.createOriginalData()
                                    }
                                }
                            }
                        } else {
                            loopcCount += 1
                            // friendIDが含まれている場合
                            if loopcCount == savedCount{
                                self.initArray()
                                self.createOriginalData()
                            }
                        }
                    }
                }
            }
            // チェックボックスの選択状態を解除
            self.selectedItems.removeAll()
            self.groupsTableView.reloadData()
        }))
        alertController.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func outButtonTapped(_ sender: UIButton) {
        // 選択されたセルがない場合は処理を中断
        guard !selectedItems.isEmpty else { return }
        var loopCount = 0
        // アラートメッセージの構築
        var message = ""
        for index in self.selectedItems {
            message += "\(self.displayedData[index].name)\n"
        }
        message += "から「\(self.addedFriendName!)」を外しますか？"
        // アラートを表示
        let alertController = UIAlertController(title: "友達をグループから外す", message: message, preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "はい", style: .default, handler: { _ in
            let groupsRef = self.yourId.child("groups")
            
            for index in self.selectedItems {
                let groupName = self.displayedData[index].name
                let groupRef = groupsRef.child(groupName)
                let savedCount = self.selectedItems.count
                
                groupRef.observeSingleEvent(of: .value) { snapshot in
                    if let children = snapshot.children.allObjects as? [DataSnapshot] {
                        for child in children {
                            if let friendID = child.value as? String, friendID == self.addedFriendId {
                                // friendIDが含まれている場合
                                if children.count == 1 {
                                    groupRef.child(child.key).removeValue { error, _ in
                                        if let error = error {
                                            print("Error deleating value \(error.localizedDescription)")
                                        } else {
                                            print("外すのに成功child")
                                            let newChildRef = groupsRef.child(groupName)
                                            
                                            newChildRef.setValue("") { error, _ in
                                                if let error = error {
                                                    print("Error adding group: \(error.localizedDescription)")
                                                    return
                                                }
                                                print("再び作り直すのに成功")
                                                loopCount += 1
                                                print(loopCount)
                                                print(savedCount)
                                                if loopCount == savedCount {
                                                    self.initArray()
                                                    self.createOriginalData()
                                                }
                                            }
                                        }
                                    }
                                } else {
                                    groupRef.child(child.key).removeValue { error, _ in
                                        if let error = error {
                                            print("Error deleating value \(error.localizedDescription)")
                                        } else {
                                            print("外すのに成功childs")
                                            loopCount += 1
                                            if loopCount == savedCount {
                                                self.initArray()
                                                self.createOriginalData()
                                            }
                                        }
                                    }
                                }
                                break
                            }
                        }
                        let friendIDs = children.map { $0.value as? String }
                        if !friendIDs.contains(self.addedFriendId) {
                            //idが含まれない場合
                            print("idはグループ内に含まれない")
                            loopCount += 1
                            if loopCount == savedCount {
                                self.initArray()
                                self.createOriginalData()
                            }
                        }
                    } else {
                        // グループ内に子ノードが存在しない場合の処理
                        print("No child nodes in the group.")
                    }
                }
            }
            // チェックボックスの選択状態を解除
            self.selectedItems.removeAll()
            self.groupsTableView.reloadData()
        }))
        alertController.addAction(UIAlertAction(title: "いいえ", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // StackViewに配置されているアイテム全てを表示する関数
    func groupsStackShowAll() {
        for view in groupsStackView.arrangedSubviews {
            view.isHidden = false
        }
    }
    
    // StackViewに配置されているアイテム全てを非表示にする関数
    func groupsStackHideAll() {
        for view in groupsStackView.arrangedSubviews {
            view.isHidden = true
        }
    }
    
    // アラートを表示するメソッド
    func showAlert(message: String) {
        let alert = UIAlertController(title: "エラー", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // ポップアップを表示する関数
    private func showPopup(message: String) {
        let popupWidth: CGFloat = 250
        let popupHeight: CGFloat = 100
        
        let popupView = UIView(frame: CGRect(x: (view.bounds.width - popupWidth) / 2, y: (view.bounds.height - popupHeight) / 2, width: popupWidth, height: popupHeight))
        popupView.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        popupView.layer.cornerRadius = 10
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: popupWidth, height: popupHeight))
        label.text = message
        label.textColor = UIColor.white
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 14)
        
        popupView.addSubview(label)
        view.addSubview(popupView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            popupView.removeFromSuperview()
        }
    }

    
}




