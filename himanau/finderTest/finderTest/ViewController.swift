import UIKit
import Firebase
import Photos
import FirebaseStorage
import CropViewController
import Dispatch

class HimaClass {
    var key: String
    var datas: [HimaClassChild]
    
    init(key: String, datas: [HimaClassChild] = []) {
        self.key = key
        self.datas = datas
    }
}

class HimaClassParent {
    var key: String
    var datas: [HimaClass]
    
    init(key: String, datas: [HimaClass] = []) {
        self.key = key
        self.datas = datas
    }
}

class HimaClassChild {
    var key: String
    var start: String
    var end: String
    
    init(key: String, start: String, end: String) {
        self.key = key
        self.start = start
        self.end = end
    }
}

class blockData{
    var num: Int
    var start: [String]
    var end: [String]
    var data: String
    
    init(num: Int, start: [String]=[], end: [String]=[], data: String) {
        self.num = num
        self.start = start
        self.end = end
        self.data = data
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate, UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet weak var squareFieldView: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var varticalStackView: UIStackView!
    @IBOutlet weak var addFriendsBottun: UIButton!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var eventBotun: UIButton!
    @IBOutlet weak var reloadButton: UIButton!
    var viewControllerValue = ""
    var administrator: DatabaseReference!
    var user: DatabaseReference!
    var userId: DatabaseReference!
    var checkpoint = 0
    var numberOfCells = 0
    var friendNameText = ""
    var selectedIndexPath: IndexPath?
    var HimaTimeArray = [String]()
    var cellCount = 0
    var friendValue = [String]()
    var processChecker = 0
    var processChecker2 = 0
    var progressOfuserId = 0
    var progressOfHimaCount = 0
    var numberOfUsers = 0
    var progress = 0
    var HimaTimeDatasStart = [String]()
    var HimaTimeDatasEnd = [String]()
    var startDatas: [[String]] = []
    var endDatas: [[String]] = []
    var friendArray = [String]()
    var numberOfHimaDatas = 0
    var numberOfFriends = 0
    var startDataFrag = 0
    var endDataFrag = 0
    var cellRow = 0
    var cellTapped = 0
    var observeHimaDataChecker = 0
    var errorTag = 0
    var nameInTappedCell: String = ""
    
    var friendNameLabels = [String]()
    var HimaDataStart1 = [String]()
    var HimaDataStart2 = [String]()
    var HimaDataEnd1 = [String]()
    var HimaDataEnd2 = [String]()
    var dataObserved = 0
    var friedNum = 0
    var checkmarkArray = [Int]()
    var selectedIndexPaths: [IndexPath] = []
    var selectedFriendID = [String]()
    var friendIDs = [String]()
    var iconURLs = [String]()
    
    var HIMAdatas = [HimaClass]()


    override func viewDidLoad() {
        super.viewDidLoad()
        transformAddFriendBottun()
        transformeventBottun()
        transformReloadButton()
        //observeHimaDataTest()
        
        self.administrator = Database.database().reference().child("administrator")
        loadNumberOfUsers()
        
        tableView.register(UINib(nibName:  "HimaTimeTableViewCell", bundle: nil), forCellReuseIdentifier: "customCell")
        tableView.backgroundColor = UIColor.clear
        tableView.delegate = self
        if let customTabBarController = self.tabBarController as? CustomTabBarController {
            let sharedValueFromTabBar = customTabBarController.sharedValue
            viewControllerValue = sharedValueFromTabBar
        }
        
        observeHimaDataTest()
        // 複数のセル選択を有効にする
        tableView.allowsMultipleSelection = true
        tableView.delegate = self
        
        //self.administrator = Database.database().reference().child("administrator")
        self.user = Database.database().reference().child("user")
        self.userId = self.user.child(viewControllerValue)
        
        //observeHimaDataTest()
        let group = DispatchGroup()
        self.user = Database.database().reference().child("user") // DB -> user
        //let userReference = self.user.child(viewControllerValue) // user -> 002
        
        group.enter()
        getFriendArray{
            group.leave()
        }
        
        group.notify(queue: .main){
            let group2 = DispatchGroup()
            
            guard self.friendArray.count != 0 else{
                print("cannot get friendArray")
                return
            }
            while 0 < 1{
                if self.friendArray.count != 0{
                    print("got friendArray")
                    break
                }
            }
            /*
            print("line 109")
            group2.enter()
            self.observeCount{
                group2.leave()
            }
            group2.notify(queue: .main){
                print("line 114")
                print("numberOfFriends: \(self.numberOfFriends)")
                guard self.HimaTimeDatasStart.count != 0 else{
                    print("cannot get HimaTimeDatasStart")
                    return
                }
                guard self.HimaTimeDatasEnd.count != 0 else{
                    print("cannot get HimaTimeDatasEnd")
                    return
                }
                self.tableView.reloadData()
            }*/
        }
        
        let Group01 = DispatchGroup()
        Group01.enter()
        //getHimaData {
            self.loadFriends()
            self.loadDataFromFirebase()
            //let name = self.userId.child("name")
            //displayUserImage()
            //addBackground()

            Group01.leave()
        
    }
    
    
    //AddFriendsViewControllerへの値渡し
    //AdvancedSettingViewControllerへの値渡し
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddFriendsViewController" {
            let next = segue.destination as? AddFriendsViewController
            next?.addFriendsViewControllerValue = viewControllerValue
        }
        
        if segue.identifier == "CreateEventViewController" {
            let next = segue.destination as? CreateEventViewController
            next?.createEventViewControllerValue = viewControllerValue
            next?.selectedFriends = selectedFriendID
        }
        
        if segue.identifier == "CustomTabBarController" {
            if let destinationVC = segue.destination as? CustomTabBarController {
                destinationVC.sharedValue = viewControllerValue
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
            return 80
        }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Int(self.cellCount)
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! HimaTimeTableViewCell
        
        if self.dataObserved != 0{
            //let cell = tableView.dequeueReusableCell(withIdentifier: "customCell") as! HimaTimeTableViewCell
            print("friendNameLabels \(self.friendNameLabels)")
            if friendNameLabels.count > indexPath.row{
                cell.nameLabel.text = self.friendNameLabels[indexPath.row]
            }else{
                cell.nameLabel.text = "unknown"
            }
            
            var viewFrame = cell.squareField.frame
            var oneHourWidth = viewFrame.size.width / 12
            self.administrator = Database.database().reference().child("administrator")
            self.user = Database.database().reference().child("user")
            let yourUserRef = self.user.child(viewControllerValue)
            
            //let friendRef = yourUserRef.child("friends")
            cell.squareField.contentSize = CGSize(width: oneHourWidth * 24,height: viewFrame.height)
            cell.horizontalScrollHandler = {offsetX in
                // 他のセルのhorizontalScrollViewのcontentOffsetを更新
                for visibleCell in tableView.visibleCells {
                    if let himaCell = visibleCell as? HimaTimeTableViewCell, himaCell != cell {
                        himaCell.squareField.contentOffset.x = offsetX
                    }
                }
            }
            
            cell.squareField.delegate = self
            viewFrame = cell.squareField.frame
            oneHourWidth = viewFrame.size.width / 24
            
            // セルのcontentViewの背景色を透明に設定
            cell.backgroundColor = UIColor.clear
            //cell.img.image = UIImage(systemName: "lasso")
            //cell.nameLabel.text = friendNameText//"Swift"
            
            //cellのチェックマーク処理
            //print("self.checkmarkArray \(self.checkmarkArray)")
            //print("indexPath.row \(indexPath.row)")
            if self.checkmarkArray.contains(indexPath.row){
                cell.accessoryType = .checkmark
                print("checkmark on")
            }else{
                cell.accessoryType = .none
            }
            
            self.user = Database.database().reference().child("user")
            //let viewFrame = cell.squareField.frame
            let FriendID = String(format: "%03d", self.friendArray[indexPath.row])
            let backgroundImage = UIImageView()
            backgroundImage.frame = CGRect(x: 0.0, y: 10.0, width: viewFrame.width, height: viewFrame.height / 4)
            // 画像を設定
            if let originalImage = UIImage(named: "background_column2.jpg") {
                //let newSize = CGSize(width: backgroundImage.frame.width, height: backgroundImage.frame.height)
                backgroundImage.image = originalImage
                cell.squareField.addSubview(backgroundImage)
            }
            // Auto Layout制約を設定
            backgroundImage.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                backgroundImage.topAnchor.constraint(equalTo: cell.squareField.topAnchor),
                backgroundImage.bottomAnchor.constraint(equalTo: cell.squareField.bottomAnchor),
                backgroundImage.leadingAnchor.constraint(equalTo: cell.squareField.leadingAnchor),
                backgroundImage.trailingAnchor.constraint(equalTo: cell.squareField.trailingAnchor),
                backgroundImage.centerYAnchor.constraint(equalTo: cell.squareField.centerYAnchor),
                backgroundImage.centerXAnchor.constraint(equalTo: cell.squareField.centerXAnchor),
                backgroundImage.widthAnchor.constraint(equalTo: cell.squareField.widthAnchor),
                backgroundImage.heightAnchor.constraint(equalTo: cell.squareField.heightAnchor)
            ])

            // 画像を引き伸ばしてViewに合わせる
            backgroundImage.contentMode = .scaleToFill
            backgroundImage.clipsToBounds = true
            cell.squareField.addSubview(backgroundImage)
            //if self.observeHimaDataChecker == 1{
                print("test datas")
                //print("start data: \(self.HIMAdatas[0].datas[0].start)")
                print("self.HimaDataStart1: \(self.HimaDataStart1)")
                self.observeHimaDataChecker = 0
                
                let squareNum = numberOfHimaBlocks(_HimaParentsKey: self.friendArray[indexPath.row])
                
                if squareNum.num != 0{
                    var squareViews: [UIView] = []
                    for i in 1...squareNum.num{ //その日何回目の暇時間か
                        let squareY = 0.0
                        for j in 1...2{ //startとendの2回
                            var startTime1: String = ""
                            var endTime1: String = ""
                            var startTime2: String = ""
                            var endTime2: String = ""
                            if j == 1{
                                let squareView1 = UIView()
                                //startTime1 = self.HimaDataStart1[((indexPath.row+1)*4)-1]
                                //endTime1 = self.HimaDataEnd1[((indexPath.row+1)*2)-1]
                                startTime1 = squareNum.start[i-1]
                                endTime1 = squareNum.end[i-1]
                                let numericCharacterSet = CharacterSet.decimalDigits
                                let IntCheckerStart = startTime1.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
                                let IntCheckerEnd = endTime1.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
                                if IntCheckerStart && IntCheckerEnd{
                                    let start = Int(startTime1)
                                    let end = Int(endTime1)
                                    //print(start)
                                    //print(end)
                                    // squareFieldの幅を取得
                                    let squareFieldWidth = cell.squareField.bounds.width
                                    //let squareY = 0.0
                                    let squareX = min(oneHourWidth * CGFloat(start!), squareFieldWidth)// + viewFrame.origin.x
                                    //print("original x left: \(viewFrame.origin.x)")
                                    //print("original x right: \(viewFrame.origin.x + viewFrame.width)")
                                    //print("original width: \(viewFrame.width)")
                                    //print("squareX left: \(squareX)")
                                    let squareWidth = min(oneHourWidth * CGFloat(end! - start!),squareFieldWidth - squareX)
                                    //print("squareX right: \(squareX + squareWidth)")
                                    //print("width: \(squareWidth)")
                                    //print("")
                                    
                                    let squareHeight = 10
                                    // 2. UIViewのプロパティを設定
                                    squareView1.frame = CGRect(x: squareX, y: squareY, width: squareWidth, height: CGFloat(squareHeight))
                                    //位置とサイズ
                                    squareView1.backgroundColor = UIColor.blue
                                    
                                    squareViews.append(squareView1)
                                }
                            }
                            if j == 2{
                                let squareView2 = UIView()
                                //startTime2 = self.HimaDataStart2[((indexPath.row+1)*2)-1]
                                //endTime2 = self.HimaDataEnd2[((indexPath.row+1)*2)-1]
                                startTime1 = squareNum.start[i-1]
                                endTime1 = squareNum.end[i-1]
                                let numericCharacterSet = CharacterSet.decimalDigits
                                let IntCheckerStart = startTime1.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
                                let IntCheckerEnd = endTime1.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
                                if IntCheckerStart && IntCheckerEnd{
                                    let start = Int(startTime1)
                                    let end = Int(endTime1)
                                    //print(start)
                                    //print(end)
                                    // squareFieldの幅を取得
                                    let squareFieldWidth = cell.squareField.bounds.width
                                    //let squareY = 0.0
                                    let squareX = min(oneHourWidth * CGFloat(start!), squareFieldWidth)// + viewFrame.origin.x
                                    //print("original x left: \(viewFrame.origin.x)")
                                    //print("original x right: \(viewFrame.origin.x + viewFrame.width)")
                                    //print("original width: \(viewFrame.width)")
                                    //print("squareX left: \(squareX)")
                                    let squareWidth = min(oneHourWidth * CGFloat(end! - start!),squareFieldWidth - squareX)
                                    //print("squareX right: \(squareX + squareWidth)")
                                    //print("width: \(squareWidth)")
                                    //print("")
                                    let squareHeight = 10
                                    // 2. UIViewのプロパティを設定
                                    squareView2.frame = CGRect(x: squareX, y: squareY, width: squareWidth, height: CGFloat(squareHeight))
                                    //位置とサイズ
                                    squareView2.backgroundColor = UIColor.blue
                                    
                                    squareViews.append(squareView2)
                                    // 3. UIViewControllerのviewにUIViewを追加
                                    //cell.squareField.addSubview(squareView)
                                }
                            }
                        }
                    }
                    let squareView1 = UIView()
                    let propos = self.getTimeNow()
                    let squareX = Float(oneHourWidth) * propos
                    squareView1.frame = CGRect(x: CGFloat(squareX), y: 0.0, width: 2, height: CGFloat(40))
                    squareView1.backgroundColor = UIColor.red
                    squareViews.append(squareView1)
                    
                    
                    for subview in cell.squareField.subviews {
                        if let existingSquareView = subview as? UIView, squareViews.contains(existingSquareView) {
                            // すでに存在する場合は追加しない
                        } else {
                            for squareView in squareViews {
                                cell.squareField.addSubview(squareView)
                                //print("squareView: \(squareView.frame)")
                            }
                        }
                    }
                }
            let squareView1 = UIView()
            let propos = self.getTimeNow()
            let squareX = Float(oneHourWidth) * propos
            squareView1.frame = CGRect(x: CGFloat(squareX), y: 0.0, width: 2, height: CGFloat(40))
            squareView1.backgroundColor = UIColor.red
            cell.squareField.addSubview(squareView1)
            //}
            //ここ
            
            //print("iconURLs \(iconURLs)")
            print("iconURLs.count: \(iconURLs.count)")
            print("self.friedNum: \(self.friedNum)")
            if iconURLs.count >= self.friedNum{
                let iconURL = URL(string: self.iconURLs[indexPath.row])
                URLSession.shared.dataTask(with: iconURL!) { (data, response, error) in
                    if let error = error {
                        print("Error downloading image data: \(error.localizedDescription)")
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            cell.img.contentMode = .scaleAspectFill
                            cell.img.layer.cornerRadius = cell.img.frame.width / 2
                            cell.img.layer.masksToBounds = true
                            cell.img.image = image
                        }
                        print("displaying icon")
                    } else {
                        print("Error creating UIImage from downloaded data")
                        self.errorTag = 1
                    }
                }.resume()
                if errorTag == 1{
                    cell.img.image = UIImage(systemName: "lasso")
                    self.errorTag = 0
                }
            }else{
                print("cannot get iconURLs from Array")
                cell.img.image = UIImage(systemName: "lasso")
                //print("iconURLs \(self.iconURLs)")
            }
            
            self.HimaTimeArray = []
        }else{
            let group = DispatchGroup()
            group.enter()
            //let cell = tableView.dequeueReusableCell(withIdentifier: "customCell", for: indexPath) as! HimaTimeTableViewCell
            numberOfCells += 1
            var viewFrame = cell.squareField.frame
            var oneHourWidth = viewFrame.size.width / 12
            cell.squareField.contentSize = CGSize(width: oneHourWidth * 24,height: viewFrame.height)
            cell.horizontalScrollHandler = {offsetX in
                // 他のセルのhorizontalScrollViewのcontentOffsetを更新
                for visibleCell in tableView.visibleCells {
                    if let himaCell = visibleCell as? HimaTimeTableViewCell, himaCell != cell {
                        himaCell.squareField.contentOffset.x = offsetX
                    }
                }
            }
            
            cell.squareField.delegate = self
            viewFrame = cell.squareField.frame
            oneHourWidth = viewFrame.size.width / 24
            self.administrator = Database.database().reference().child("administrator")
            self.user = Database.database().reference().child("user")
            let yourUserRef = self.user.child(viewControllerValue)
            
            let friendRef = yourUserRef.child("friends")
            var count = numberOfCells
            
            //ここからgetHimaDataを移植
            //let group = DispatchGroup()
            self.user = Database.database().reference().child("user") // DB -> user
            //let userReference = self.user.child(viewControllerValue) // user -> 002
            
            administrator.observe(.value){(snapshot: DataSnapshot) in
                if let userCount = snapshot.value as? String, let userCountInt = Int(userCount){
                    self.numberOfUsers = userCountInt
                }
            }
            while 1 > 0{
                if self.processChecker2 == 1{
                    break
                }
            }
            
            //let friendNumberString = String(format: "%03d", friendArray[indexPath.row])
            let friendNumberString = friendArray[indexPath.row]
            /*
            var friendNumberString = ""
            if friendArray.count >= indexPath.row+1{
                friendNumberString = friendArray[indexPath.row]
            }else{
                tableView.reloadData()
            }*/
            
            let friendIdRef = friendRef.child(friendNumberString)
            print("friendNumberString: \(friendNumberString)")
            
            let dispatchGroup = DispatchGroup()
            
            friendIdRef.observeSingleEvent(of: .value) { (snapshot:DataSnapshot) in
                if let friendId = snapshot.value as? String{
                    let yourFriendUserRef = self.user.child(friendId)
                    let iconURLRef = yourFriendUserRef.child("iconURL")
                    
                    if self.iconURLs.count <= self.friedNum{
                        
                        dispatchGroup.enter()
                        iconURLRef.observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
                            if let iconURLString = snapshot.value as? String, let iconURL = URL(string: iconURLString) {
                                self.iconURLs.append(iconURLString)
                                print("append \(self.iconURLs.count)th URL : \(iconURLString)")
                                // ダウンロードURLを元に画像を表示
                                URLSession.shared.dataTask(with: iconURL) { (data, response, error) in
                                    if let error = error {
                                        print("Error downloading image data: \(error.localizedDescription)")
                                        return
                                    }
                                    
                                    if let data = data, let image = UIImage(data: data) {
                                        DispatchQueue.main.async {
                                            cell.img.contentMode = .scaleAspectFill
                                            cell.img.layer.cornerRadius = cell.img.frame.width / 2
                                            cell.img.layer.masksToBounds = true
                                            cell.img.image = image
                                        }
                                        print("displaying icon")
                                    } else {
                                        print("Error creating UIImage from downloaded data")
                                        self.errorTag = 1
                                    }
                                }.resume()
                                if self.errorTag == 1{
                                    cell.img.image = UIImage(systemName: "lasso")
                                    self.errorTag = 0
                                }
                            } else {
                                print("Error retrieving icon URL from snapshot")
                                self.iconURLs.append("")
                                cell.img.image = UIImage(systemName: "lasso")
                            }
                            dispatchGroup.leave()
                            //print("iconURLs \(self.iconURLs)")
                        }
                        
                    }else{
                        print("error: do not match the number of icons and friends")
                    }
        
                }
            }
            dispatchGroup.notify(queue: .main){
                //print("numberOfUsers: \(numberOfUsers)")
                //print("friendValue: \(friendValue)")
                //let friendNumberString = String(format: "%03d", numberOfUsers)
                //let friendIdRef = friendRef.child(friendNumberString)
                friendRef.observe(.value){ (snapshot: DataSnapshot) in
                    // snapshot内に取得したデータが含まれています
                    if let data = snapshot.value as? [String: String] {
                        //for (key, value) in data {
                        //  print("Key: \(key), Value: \(value)")
                        //}
                        let valuesArray = Array(data.values)
                        self.friedNum = valuesArray.count
                        while self.progress < self.numberOfUsers{
                            self.progress += 1
                            //self.friendValue = Array(data.values)
                            var friendIDNum = String(format: "%03d", self.progress)
                            print("friendIDNum: \(friendIDNum)")
                            if valuesArray.contains(friendIDNum){//} && self.processChacker == 1{
                                print("配列内に \(friendIDNum) が含まれています。")
                                let friendIdRef = self.user.child(friendIDNum)
                                let friendNameRef = friendIdRef.child("name")
                                
                                friendNameRef.observe(.value){ (snapshot) in
                                    if let friendName = snapshot.value as? String{
                                        print("friend name: \(friendName)")
                                        self.friendIDs.append(friendIDNum)
                                        self.friendNameText = friendName
                                        cell.nameLabel.text = self.friendNameText
                                        self.friendNameLabels.append(self.friendNameText)
                                        DispatchQueue.main.async {
                                            // Firebaseからデータが取得された後にTableViewを更新
                                            self.tableView.reloadData()
                                        }
                                    } else {
                                        //self.addNewLabel(_newLabelText: "メンバーの名前が取得できません", _originalLabel: self.originalNameLabel, _index: i, _spacing: spacing)
                                    }
                                }
                                return
                            } else {
                                print("配列内に \(friendIDNum) は含まれていません。")
                            }
                        }
                    }
                }
                
                // セルのcontentViewの背景色を透明に設定
                cell.backgroundColor = UIColor.clear
                
                self.user = Database.database().reference().child("user")
                let backgroundImage = UIImageView()
                //backgroundImage.frame = CGRect(x: 0.0, y: 10.0, width: viewFrame.width, height: viewFrame.height / 4)
                backgroundImage.frame = CGRect(x: viewFrame.origin.x, y: viewFrame.origin.y, width: viewFrame.width, height: viewFrame.height / 4)
                //xとyをviewFrame.originにしてみる
                // 画像を設定
                if let originalImage = UIImage(named: "background_column2.jpg") {
                    let newSize = CGSize(width: backgroundImage.frame.width, height: backgroundImage.frame.height)
                    backgroundImage.image = originalImage
                    cell.squareField.addSubview(backgroundImage)
                }
                // Auto Layout制約を設定
                backgroundImage.translatesAutoresizingMaskIntoConstraints = false
                //cell.squareField.addSubview(backgroundImage)
                /*
                NSLayoutConstraint.activate([
                    // UIImageViewの上端を親ビューの上端に合わせる
                    backgroundImage.topAnchor.constraint(equalTo: self.view.topAnchor),
                    // UIImageViewの下端を親ビューの下端に合わせる
                    backgroundImage.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    // UIImageViewの左端を親ビューの左端に合わせる
                    backgroundImage.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    // UIImageViewの右端を親ビューの右端に合わせる
                    backgroundImage.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
                ])*/
                
                NSLayoutConstraint.activate([
                    backgroundImage.topAnchor.constraint(equalTo: cell.squareField.topAnchor),
                    backgroundImage.bottomAnchor.constraint(equalTo: cell.squareField.bottomAnchor),
                    backgroundImage.leadingAnchor.constraint(equalTo: cell.squareField.leadingAnchor),
                    backgroundImage.trailingAnchor.constraint(equalTo: cell.squareField.trailingAnchor),
                    backgroundImage.centerYAnchor.constraint(equalTo: cell.squareField.centerYAnchor),
                    backgroundImage.centerXAnchor.constraint(equalTo: cell.squareField.centerXAnchor),
                    backgroundImage.widthAnchor.constraint(equalTo: cell.squareField.widthAnchor),
                    backgroundImage.heightAnchor.constraint(equalTo: cell.squareField.heightAnchor)
                ])

                // 画像を引き伸ばしてViewに合わせる
                backgroundImage.contentMode = .scaleToFill
                backgroundImage.clipsToBounds = true
                cell.squareField.addSubview(backgroundImage)
                var HimaData: [String] = []// HimaDataの宣言。Databaseから取得するようになれば不要
                // ex: [2_3,15_20]
                
                //ここからgetHimaDataを移植
                let group1 = DispatchGroup()
                let group2 = DispatchGroup()
                self.user = Database.database().reference().child("user") // DB -> user
                //let userReference = self.user.child(viewControllerValue) // user -> 002
                let FriendID = String(format: "%03d", self.friendArray[indexPath.row])
                //print("indexPath.row: \(indexPath.row)")
                //print("FriendID : \(FriendID)")
                let HimaCountRef = self.user.child(self.friendArray[indexPath.row]).child("himaTime").child("count")
                //group2.notify(queue: .main){
                    //ここまでgetHimaData
                    
                    if 0 < 1{//self.startDataFrag == 1 && self.endDataFrag == 1{
                        //print("start data: \(self.HimaTimeDatasStart)")
                        //print("end data: \(self.HimaTimeDatasEnd)")
                        //let squareView = UIView()
                        
                        if count > 0 {
                            // countが0より大きい場合のみ処理を実行
                            for i in 1...2{//count {
                                
                                // 仮データ
                                var randomInt1 = Int.random(in: 1..<12)
                                var randomInt2 = Int.random(in: 1..<12)
                                var randomInt3 = Int.random(in: 13..<24)
                                var randomInt4 = Int.random(in: 13..<24)
                                
                                if randomInt1 < randomInt2{
                                    if randomInt3 < randomInt4{
                                        HimaData.append("\(randomInt1)_\(randomInt2),\(randomInt3)_\(randomInt4)")
                                    }else{
                                        HimaData.append("\(randomInt1)_\(randomInt2),\(randomInt4)_\(randomInt3)")
                                    }
                                }else{
                                    if randomInt3 < randomInt4{
                                        HimaData.append("\(randomInt2)_\(randomInt1),\(randomInt3)_\(randomInt4)")
                                    }else{
                                        HimaData.append("\(randomInt2)_\(randomInt1),\(randomInt4)_\(randomInt3)")
                                    }
                                }
                            }
                            HimaCountRef.observe(.value){(HimaCountSnapshot: DataSnapshot) in
                                if let HimaCount = HimaCountSnapshot.value as? Int{
                                    print("HimaCount in tableView func: \(HimaCount)")
                                    //print("key: \(self.HIMAdatas[0].key)")
                                    //print("start: \(self.HIMAdatas[0].start)")
                                    //print("end: \(self.HIMAdatas[0].end)")
                                }
                            }
                            
                            
                            //if self.observeHimaDataChecker == 1{
                                print("test datas")
                                //print("start data: \(self.HIMAdatas[0].datas[0].start)")
                                print("self.HimaDataStart1: \(self.HimaDataStart1)")
                                self.observeHimaDataChecker = 0
                                
                                let squareNum = self.numberOfHimaBlocks(_HimaParentsKey: self.friendArray[indexPath.row])
                                print("squareNum \(squareNum.data)")
                                
                                let squaresInfo = self.observeAndTransform(_friendID: self.friendArray[indexPath.row])
                                print("squaresInfo: \(squaresInfo)")
                                //let friendNumberString = String(format: "%03d", i)
                                //let friendIdRef = friendRef.child(friendNumberString)
                                if squareNum.num != 0{
                                    var squareViews: [UIView] = []
                                    for i in 1...squareNum.num{ //その日何回目の暇時間か
                                        //print("HimaData: \(HimaData[i-1])")
                                        self.interpretHimaData(_HimaData: HimaData[i-1], _spacing: CGFloat(40))
                                        //print("HimaData: \(HimaData)")
                                        //let squareView = UIView()
                                        //var squareViews: [UIView] = []
                                        let squareY = 0.0
                                        //for j in 1...2{ //startとendの2回
                                            //print("numberOfCells: \(self.numberOfCells)")
                                            self.HimaTimeArray = []
                                            //self.interpretHimaData(_HimaData: squaresInfo, _spacing: CGFloat(40))
                                            //self.interpretHimaData(_HimaData: self.randomDatas[j-1], _spacing: CGFloat(40))
                                            //print("HimaTimeArray: \(self.HimaTimeArray)")
                                            var startTime1: String = ""
                                            var endTime1: String = ""
                                            //var startTime2: String = ""
                                            //var endTime2: String = ""
                                            //print("HimaTimeArray: \(self.HimaTimeArray)")
                                            //if j == 1{
                                                let squareView1 = UIView()
                                                //startTime1 = self.HimaTimeArray[i-1]
                                                //endTime1 = self.HimaTimeArray[i]
                                                startTime1 = squareNum.start[i-1]
                                                endTime1 = squareNum.end[i-1]
                                                
                                                self.HimaDataStart1.append(startTime1)
                                                self.HimaDataEnd1.append(endTime1)
                                                let numericCharacterSet = CharacterSet.decimalDigits
                                                let IntCheckerStart = startTime1.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
                                                let IntCheckerEnd = endTime1.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
                                                if IntCheckerStart && IntCheckerEnd{
                                                    let start = Int(startTime1)
                                                    let end = Int(endTime1)
                                                    //print(start)
                                                    //print(end)
                                                    // squareFieldの幅を取得
                                                    let squareFieldWidth = cell.squareField.bounds.width
                                                    //let squareY = 0.0
                                                    let squareX = min(oneHourWidth * CGFloat(start!), squareFieldWidth)// + viewFrame.origin.x
                                                    //print("original x left: \(viewFrame.origin.x)")
                                                    //print("original x right: \(viewFrame.origin.x + viewFrame.width)")
                                                    //print("original width: \(viewFrame.width)")
                                                    //print("squareX left: \(squareX)")
                                                    let squareWidth = min(oneHourWidth * CGFloat(end! - start!),squareFieldWidth - squareX)
                                                    //print("squareX right: \(squareX + squareWidth)")
                                                    //print("width: \(squareWidth)")
                                                    //print("")
                                                    
                                                    let squareHeight = 10
                                                    // 2. UIViewのプロパティを設定
                                                    squareView1.frame = CGRect(x: squareX, y: squareY, width: squareWidth, height: CGFloat(squareHeight))
                                                    //位置とサイズ
                                                    squareView1.backgroundColor = UIColor.blue
                                                    
                                                    squareViews.append(squareView1)
                                                }
                                            //}
                                            /*
                                            if j == 2{
                                                let squareView2 = UIView()
                                                startTime2 = self.HimaTimeArray[2]
                                                endTime2 = self.HimaTimeArray[3]
                                                self.HimaDataStart2.append(startTime2)
                                                self.HimaDataEnd2.append(endTime2)
                                                let numericCharacterSet = CharacterSet.decimalDigits
                                                let IntCheckerStart = startTime2.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
                                                let IntCheckerEnd = endTime2.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
                                                if IntCheckerStart && IntCheckerEnd{
                                                    let start = Int(startTime2)
                                                    let end = Int(endTime2)
                                                    //print(start)
                                                    //print(end)
                                                    // squareFieldの幅を取得
                                                    let squareFieldWidth = cell.squareField.bounds.width
                                                    //let squareY = 0.0
                                                    let squareX = min(oneHourWidth * CGFloat(start!), squareFieldWidth)// + viewFrame.origin.x
                                                    //print("original x left: \(viewFrame.origin.x)")
                                                    //print("original x right: \(viewFrame.origin.x + viewFrame.width)")
                                                    //print("original width: \(viewFrame.width)")
                                                    //print("squareX left: \(squareX)")
                                                    let squareWidth = min(oneHourWidth * CGFloat(end! - start!),squareFieldWidth - squareX)
                                                    //print("squareX right: \(squareX + squareWidth)")
                                                    //print("width: \(squareWidth)")
                                                    //print("")
                                                    let squareHeight = 10
                                                    // 2. UIViewのプロパティを設定
                                                    squareView2.frame = CGRect(x: squareX, y: squareY, width: squareWidth, height: CGFloat(squareHeight))
                                                    //位置とサイズ
                                                    squareView2.backgroundColor = UIColor.blue
                                                    
                                                    squareViews.append(squareView2)
                                                    // 3. UIViewControllerのviewにUIViewを追加
                                                    //cell.squareField.addSubview(squareView)
                                                }
                                            }*/
                                    }
                                    let squareView1 = UIView()
                                    let propos = self.getTimeNow()
                                    let squareX = Float(oneHourWidth) * propos
                                    squareView1.frame = CGRect(x: CGFloat(squareX), y: 0.0, width: 2, height: CGFloat(40))
                                    squareView1.backgroundColor = UIColor.red
                                    squareViews.append(squareView1)
                                    
                                    for subview in cell.squareField.subviews {
                                        if let existingSquareView = subview as? UIView, squareViews.contains(existingSquareView) {
                                            // すでに存在する場合は追加しない
                                        } else {
                                            for squareView in squareViews {
                                                cell.squareField.addSubview(squareView)
                                                //print("squareView: \(squareView.frame)")
                                            }
                                        }
                                    }
                                    
                                    HimaData = []
                                    self.HimaTimeArray = []
                                    
                                    
                                }
                            let squareView1 = UIView()
                            let propos = self.getTimeNow()
                            let squareX = Float(oneHourWidth) * propos
                            squareView1.frame = CGRect(x: CGFloat(squareX), y: 0.0, width: 2, height: CGFloat(40))
                            squareView1.backgroundColor = UIColor.red
                            cell.squareField.addSubview(squareView1)
                            
                                print("squareInfo is empty")
                            /*}else{
                                print("observing Hima datas hasn't been finished")
                                tableView.reloadData()
                            }*/
                        }
                    }else{
                        tableView.reloadData()
                    }
                
                if indexPath.row == self.friedNum-1{
                    self.dataObserved = 1
                }
            }
        }
        //print("names: \(self.friendNameLabels)")
        //print("start1: \(self.HimaDataStart1)")
        //print("start2: \(self.HimaDataStart2)")
        //print("end1: \(self.HimaDataEnd1)")
        //print("end2: \(self.HimaDataEnd2)")
        //print("index \(indexPath.row)")
        /*
        if indexPath.row == self.friedNum-1{
            self.dataObserved = 1
        }*//*
        if indexPath == selectedIndexPath {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }*/
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.dequeueReusableCell(withIdentifier: "customCell") as! HimaTimeTableViewCell
        print("friendIDs: \(friendIDs)")
        if let index = selectedIndexPaths.firstIndex(of: indexPath){//indexPath == selectedIndexPath {
            // 同じセルが再度タップされた場合、チェックマークを解除する
            //selectedIndexPath = nil
            self.cellTapped = -1
            self.cellRow = indexPath.row
            print("tapped index: \(indexPath.row)")
            //print("checkmarkArray \(checkmarkArray)")
            for i in 1...self.checkmarkArray.count{
                if self.checkmarkArray[i-1] == indexPath.row{
                    print("checkmarkArray \(checkmarkArray)")
                    self.checkmarkArray.remove(at: i-1)
                    break
                }else{
                    print("error")
                }
                if self.selectedFriendID[i-1] == self.friendIDs[indexPath.row]{
                    self.selectedFriendID.remove(at: i-1)
                }
            }
            selectedIndexPaths.remove(at: index)
            self.nameInTappedCell = cell.nameLabel.text!
            //print("selectedFriendID \(self.selectedFriendID)")
            //print("checkmark: \(self.checkmarkArray)")
            tableView.reloadData()
        } else {
            // 別のセルがタップされた場合、そのセルにチェックマークを表示
            //selectedIndexPath = indexPath
            self.cellTapped = 1
            //self.cellRow = selectedIndexPath!.row
            self.cellRow = indexPath.row
            //self.checkmarkArray.append(selectedIndexPath!.row)
            self.checkmarkArray.append(indexPath.row)
            selectedIndexPaths.append(indexPath)
            self.selectedFriendID.append(friendIDs[indexPath.row])
            self.nameInTappedCell = cell.nameLabel.text!
            print("tapped index: \(indexPath.row)")
            //print("selectedFriendID \(self.selectedFriendID)")
            //print("checkmark: \(self.checkmarkArray)")
            tableView.reloadData()
            //print("selectedRow \(self.nameInTappedCell)")
        }
    }
    
    // tableViewのcellの数を取得する関数
    func loadDataFromFirebase() {
        self.user = Database.database().reference().child("user")
        self.userId = self.user.child(viewControllerValue)

        userId.child("count").observe(.value) { (snapshot: DataSnapshot) in
            if let countValue = snapshot.value as? String, let countInt = Int(countValue) {
                self.cellCount = countInt
                DispatchQueue.main.async {
                    // Firebaseからデータが取得された後にTableViewを更新
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // friendのIDを取得する関数
    func loadFriends(){
        self.user = Database.database().reference().child("user")
        let yourUserRef = self.user.child(viewControllerValue)
        let friendRef = yourUserRef.child("friends")
               
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        
        friendRef.observe(.value){[weak self](snapshot: DataSnapshot) in
            guard let self = self else { return }
            // snapshot内に取得したデータが含まれています
            if let data = snapshot.value as? [String: String] {
                //print("data.value: \(data.values)")
                self.friendValue = Array(data.values)
                self.tableView.reloadData()
                /*
                DispatchQueue.main.async {
                    // Firebaseからデータが取得された後にTableViewを更新
                    self.tableView.reloadData()
                    print("friendValue: \(self.friendValue)")
                }*/
                for friendId in self.friendValue {
                        let friendIdRef = self.user.child(friendId)
                        let friendNameRef = friendIdRef.child("name")
                    
                        dispatchGroup.enter()

                        friendNameRef.observe(.value) { (snapshot) in
                            if let friendName = snapshot.value as? String {
                                // friendNameを利用した処理を行う（必要に応じてHimaTimeArrayの処理も行う）
                                // ...
                                // すべての非同期処理が完了したらTableViewを再描画
                                DispatchQueue.main.async {
                                    // Firebaseからデータが取得された後にTableViewを更新
                                    self.tableView.reloadData()
                                }
                                dispatchGroup.leave()
                            }
                        }
                    }
                //self.processChacker = 1
            }
        }
        dispatchGroup.notify(queue: .main) {
                // すべての非同期処理が完了したらTableViewを再描画
                self.tableView.reloadData()
                //self.processChacker = 1
        }
    }
    
    func getHimaData(completion: @escaping () -> Void){
        let group1 = DispatchGroup()
        //let group2 = DispatchGroup()
        let group3 = DispatchGroup()
        self.user = Database.database().reference().child("user") // DB -> user
        let userReference = self.user.child(viewControllerValue) // user -> 002
        let friendRef = userReference.child("friends") // 002 -> friends
        group1.enter() // friendArrayの取得処理の開始
        friendRef.observe(.value){(snapshot: DataSnapshot) in // user -> 002 -> friends 直下のdataを取得
            if let data = snapshot.value as? [String: String] {
                self.friendArray = Array(data.values)
                print("friendArray: \(self.friendArray)")
            }
            group1.leave() // friendArrayの取得処理の終了
        }
        //group1.leave() // friendArrayの取得処理の終了
        group1.notify(queue: .main){ // group1の終了がnotifyされたら以下の処理
            //group2.enter() // HimaTime取得処理の開始
            let FriendNumCount = userReference.child("count")// 002 -> count
            FriendNumCount.observe(.value) {(snapshot: DataSnapshot) in
                if let countVal = snapshot.value as? String, let IntCount = Int(countVal) {
                    for i in 1...IntCount{
                        let userID = self.friendArray[i-1]
                        print("userID: \(userID)")
                        let fIDRef = self.user.child(userID) // friendのIDを参照
                        //let fIDRef = self!.user.child("003")
                        let HimaDataRef = fIDRef.child("himaTime")
                        let HimaDataCountRef = HimaDataRef.child("count")
                        var HimaCount = 0
                        HimaDataCountRef.observe(.value){(snapshot: DataSnapshot) in
                            if let HimaDataCount = snapshot.value as? Int{
                                print("HimaDataCount: \(HimaDataCount)")
                                HimaCount = HimaDataCount
                                print("HimaCount: \(HimaCount)")
                                //group2.leave()
                                //group2.notify(queue: .main){
                                    group3.enter()
                                    for j in 1...HimaCount{
                                        let HimaIDString = String(format: "%04d", j)
                                        print("HimaIDString: \(HimaIDString)")
                                        let DataRef = HimaDataRef.child(HimaIDString)
                                        //let DataRef = HimaDataRef.child("0001")
                                        let startTimeRef = DataRef.child("startTime")
                                        let endTimeRef = DataRef.child("endTime")
                                        startTimeRef.observe(.value){(snapshot: DataSnapshot) in
                                            if let startData = snapshot.value as? String{
                                                print("add startData \(startData)")
                                                self.HimaTimeDatasStart.append(startData)
                                                //print("HimaDataStart: \(self.HimaTimeDatasStart)")
                                            }
                                        }
                                        endTimeRef.observe(.value){(snapshot: DataSnapshot) in
                                            if let endData = snapshot.value as? String{
                                                print("add endData \(endData)")
                                                self.HimaTimeDatasEnd.append(endData)
                                                //print("HimaDataEnd: \(self.HimaTimeDatasEnd)")
                                            }
                                        }
                                        
                                    }
                                    group3.leave()
                                //}// group2.notify
                            }
                        }
                        //completion()//　ここより上のcompletionはエラーが出る
                    }
                    //completion()
                }
            }
        }// group1.notify
        group3.notify(queue: .main){
            //self.tableView.reloadData()
            self.processChecker = 1
            //self.tableView.reloadData()
            completion()
        }
    }
    
    func loadNumberOfUsers(){
        let dispatchGroup = DispatchGroup()
        self.administrator = Database.database().reference().child("administrator")
        let countRef = self.administrator.child("count")
        dispatchGroup.enter()
        countRef.observe(.value){(snapshot: DataSnapshot) in
            if let userCount = snapshot.value as? String, let userCountInt = Int(userCount){
                self.numberOfUsers = userCountInt
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) { [self] in
            self.processChecker2 = 1
        }
    }
    
    func getFriendArray(completion: @escaping () -> Void){
        self.user = Database.database().reference().child("user") // DB -> user
        let userReference = self.user.child(viewControllerValue) // user -> 002
        let friendRef = userReference.child("friends") // 002 -> friends
        friendRef.observe(.value){(snapshot: DataSnapshot) in // user -> 002 -> friends 直下のdataを取得
            if let data = snapshot.value as? [String: String] {
                self.friendArray = Array(data.values)
                print("friendArray: \(self.friendArray)")
            }
            completion()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // TableView内の各セルを取得
        if let visibleCells = tableView.visibleCells as? [HimaTimeTableViewCell] {
            // 各セルのScrollViewを同じ量だけスクロールさせる
            for cell in visibleCells {
                cell.squareField.contentOffset.y = scrollView.contentOffset.y
            }
        }
    }
    
    func observeHimaDataTest(){
        self.user = Database.database().reference().child("user")
        let userReference = self.user.child(self.viewControllerValue)
        let friendCountRef = userReference.child("count")
        
        var NumberOfFriends = 0
        let dispatchGroup = DispatchGroup()
        
        friendCountRef.observe(.value){(friendCountSnapshot: DataSnapshot) in
            if let friendCount = friendCountSnapshot.value as? String{
                NumberOfFriends = Int(friendCount) ?? 0
                //print("NumberOfFriends: \(NumberOfFriends)")
                
                if NumberOfFriends != 0{
                    for j in 1...NumberOfFriends{
                        var NumberOfHimaDatas = 0
                        
                        let friendNum = String(format: "%03d", j)
                        var HimaClassArray = HimaClass(key: friendNum, datas: [])
                    
                        let HimaOwner = self.user.child(friendNum)
                        let HimaRef = HimaOwner.child("himaTime")
                        let HimaCountRef = HimaRef.child("count")
                        
                        //print("friendNum: \(friendNum)")
                        //let dispatchGroup = DispatchGroup()

                        dispatchGroup.enter()
                        HimaCountRef.observe(.value){(HimaCountSnapshot: DataSnapshot) in
                            if let HimaCount = HimaCountSnapshot.value as? Int{
                                NumberOfHimaDatas = HimaCount
                                print("HimaCount: \(HimaCount)")
                                
                                //print("NumberOfHimaDatas: \(NumberOfHimaDatas)")
                                
                                if NumberOfHimaDatas != 0{
                                    for i in 1...NumberOfHimaDatas{
                                        let HimaNum = String(format: "%04d", i)
                                        let HimaTimeRef = HimaRef.child(HimaNum)
                                        var HimaArray = HimaClassChild(key: HimaNum, start: "", end: "")
                                        print("HimaNum: \(HimaNum)")
                                        dispatchGroup.enter()
                                        HimaTimeRef.observe(.value){(HimaDataSnapshot: DataSnapshot) in
                                            if let HIMAdata = HimaDataSnapshot.value as? [String: String] {
                                                //print("HIMAdata: \(HIMAdata)")
                                                HimaArray.start.append(HIMAdata["startTime"]!)
                                                HimaArray.end.append(HIMAdata["endTime"]!)
                                                if i == NumberOfHimaDatas {
                                                    //self.HIMAdatas.append(HimaArray)
                                                    HimaClassArray.datas.append(HimaArray)
                                                    print("HimaClass append")
                                                    dispatchGroup.leave()
                                                    //print("HIMAdatas key: \(self.HIMAdatas[0].key)")
                                                    if self.HIMAdatas.count == j{
                                                        self.HIMAdatas[j-1] = (HimaClassArray)
                                                        print("HIMAdatas \(self.HIMAdatas)")
                                                    }else{
                                                        self.HIMAdatas.append(HimaClassArray)
                                                        print("HIMAdatas append")
                                                        print("HIMAdatas \(self.HIMAdatas)")
                                                    }
                                                    self.tableView.reloadData()
                                                    //print("HIMAdatas start: \(self.HIMAdatas[0].start)")
                                                    //print("HIMAdatas end: \(self.HIMAdatas[0].end)")
                                                    //self.tableView.reloadData()
                                                    dispatchGroup.leave()
                                                }
                                            }
                                        }
                                    }
                                    //self.HIMAdatas.append(HimaClassArray)
                                    //print("append to HIMAdatas")
                                }
                                
                            }
                            dispatchGroup.leave()
                        }/*
                        dispatchGroup.notify(queue: .main) {
                            //self.HIMAdatas.append(HimaClassArray)
                            if j == NumberOfFriends{
                                //self.HIMAdatas.append(HimaClassArray)
                                //print("HIMAdatas key: \(self.HIMAdatas[0].key)")
                                print("observe test ended")
                                self.observeHimaDataChecker = 1
                                self.tableView.reloadData()
                                //print("HIMAdatas start: \(self.HIMAdatas[0].datas.start)")
                                //print("HIMAdatas end: \(self.HIMAdatas[0].datas.end)")
                            }
                        }*/
                    }
                    
                }
            }
        }
        dispatchGroup.notify(queue: .main) {
            //self.HIMAdatas.append(HimaClassArray)
            if NumberOfFriends > 0{
                //self.HIMAdatas.append(HimaClassArray)
                //print("HIMAdatas key: \(self.HIMAdatas[0].key)")
                print("observe test ended")
                self.observeHimaDataChecker = 1
                self.tableView.reloadData()
                //print("HIMAdatas start: \(self.HIMAdatas[0].datas.start)")
                //print("HIMAdatas end: \(self.HIMAdatas[0].datas.end)")
            }
        }
    }
    
    func observeAndTransform(_friendID friendID: String) -> String{
        var transformed = ""
        self.user = Database.database().reference().child("user")
        let userReference = self.user.child(self.viewControllerValue)
        let friendCountRef = userReference.child("count")
        
        var HimaClassArray = HimaClass(key: friendID, datas: [])
            
        let HimaOwner = self.user.child(friendID)
        let HimaRef = HimaOwner.child("himaTime")
        let HimaCountRef = HimaRef.child("count")
            
        HimaCountRef.observe(.value){(HimaCountSnapshot: DataSnapshot) in
            if let HimaCount = HimaCountSnapshot.value as? Int{
                print("HimaCount: \(HimaCount)")
                
                //print("NumberOfHimaDatas: \(NumberOfHimaDatas)")
                
                if HimaCount != 0{
                    for i in 1...HimaCount{
                        let HimaNum = String(format: "%04d", i)
                        let HimaTimeRef = HimaRef.child(HimaNum)
                        var HimaArray = HimaClassChild(key: HimaNum, start: "", end: "")
                        print("HimaNum: \(HimaNum)")
                        HimaTimeRef.observe(.value){(HimaDataSnapshot: DataSnapshot) in
                            if let HIMAdata = HimaDataSnapshot.value as? [String: String] {
                                //print("HIMAdata: \(HIMAdata)")
                                HimaArray.start.append(HIMAdata["startTime"]!)
                                HimaArray.end.append(HIMAdata["endTime"]!)
                                
                                let today = self.getCurrentDate()
                                if (Int(today)!*10000 <= Int(HIMAdata["startTime"]!)!) && (Int(HIMAdata["startTime"]!)! <= Int(today)!*10000+2359){
                                    let startTIME = self.transformDataStyle(_data: HIMAdata["startTime"]!)
                                    let endTIME = self.transformDataStyle(_data: HIMAdata["endTime"]!)
                                    
                                    if transformed == ""{
                                        transformed = "\(startTIME)_\(endTIME)"
                                    }else{
                                        transformed = "\(transformed)_\(startTIME)_\(endTIME)"
                                    }
                                }
                            }
                        }
                    }
                }
                
            }
        }
        print("transformed \(transformed)")
        return transformed
    }
    
    func getTodaysDateTime() -> String{
        let dt = Date()
        let dateFormatter = DateFormatter()

        // DateFormatter を使用して書式とロケールを指定する
        dateFormatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMddHHmm", options: 0, locale: Locale(identifier: "ja_JP"))

        return (dateFormatter.string(from: dt))
    }
    
    func getCurrentDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd" // フォーマットを適宜変更

        let currentDate = Date()
        let dateString = dateFormatter.string(from: currentDate)

        return dateString
    }
    
    func numberOfHimaBlocks(_HimaParentsKey HimaParentsKey: String) -> blockData{
        let blockInfo = blockData(num: 0 ,start: [],end: [], data: "")
        let today = getCurrentDate()
        var blockNum = 0
        
        if self.HIMAdatas.count != 0{
            for i in 1...self.HIMAdatas.count{
                let HimaBlockKey = self.HIMAdatas[i-1].key
                if HimaBlockKey == HimaParentsKey{
                    for j in 1...self.HIMAdatas[i-1].datas.count{
                        //let key = String(format: "%04d", j)
                        let blockStart = self.HIMAdatas[i-1].datas[j-1].start
                        let blockEnd = self.HIMAdatas[i-1].datas[j-1].end
                        if (Int(today)!*10000 <= Int(blockStart)!) && (Int(blockStart)! <= Int(today)!*10000+2359){
                            blockNum += 1
                            print("hima start: \(transformDataStyle(_data: blockStart))")
                            print("hima end: \(transformDataStyle(_data: blockEnd))")
                            blockInfo.start.append(transformDataStyle(_data: blockStart))
                            blockInfo.end.append(transformDataStyle(_data: blockEnd))
                            if blockInfo.data == ""{
                                blockInfo.data = "\(blockStart)_\(blockEnd)"
                            }else{
                                blockInfo.data = "\(blockInfo.data),\(blockStart)_\(blockEnd)"
                            }
                        }
                    }
                }
            }
            blockInfo.num = blockNum
            return blockInfo
        }else{
            blockInfo.num = 0
            return blockInfo
        }
        
    }
    
    func transformDataStyle(_data data: String) -> String{
        var returnedData = ""
        let dataSplit_hour = data.suffix(4).prefix(2)
        let dataSplit_minute = data.suffix(2)
        if Int(dataSplit_minute)! <= 30{
            returnedData = String(dataSplit_hour)
        }else{
            returnedData = String(Int(dataSplit_hour)! + 1)
        }
        return returnedData
    }
    
    func getTimeNow() -> Float{
        let Today = getTodaysDateTime()
        let nowHour = Today.suffix(5).prefix(2)
        let nowMinute = Today.suffix(2)
        let decimalMinute = Float(nowMinute)!/60
        return Float(nowHour)! + decimalMinute
    }
    
    func interpretHimaData1(_startTime startTime: String, _endTime endTime: String){
        let startYear = startTime.prefix(4)
        var restStart = startTime.suffix(startTime.count - 3)
        let endYear = endTime.prefix(4)
        var restEnd = endTime.suffix(endTime.count - 3)
        let startMonth = restStart.prefix(2)
        restStart = restStart.suffix(restStart.count - 1)
        let endMonth = restEnd.prefix(2)
        restEnd = restEnd.suffix(restEnd.count - 1)
        let startDate = restStart.prefix(2)
        restStart = restStart.suffix(restStart.count - 1)
        let endDate = restEnd.prefix(2)
        restEnd = restEnd.suffix(restEnd.count - 1)
        let startHour = restStart.prefix(2)
        restStart = restStart.suffix(restStart.count - 1)
        let endHour = restEnd.prefix(2)
        restEnd = restEnd.suffix(restEnd.count - 1)
        let startMinute = restStart.prefix(2)
        restStart = restStart.suffix(restStart.count - 1)
        let endMinute = restEnd.prefix(2)
        restEnd = restEnd.suffix(restEnd.count - 1)
        
        if (Int(endYear)! - Int(startYear)!) <= 1{
            if (Int(endMonth)! - Int(startMonth)!) <= 1{
                if (Int(endDate)! - Int(startDate)!) <= 1{
                    
                }else{
                    
                }
            }
        }
    }
    
    func interpretHimaData(_HimaData HimaData: String, _spacing spacing: CGFloat){
        let targetCharacter: Character = ","
        let targetCharacter2: Character = "_"
        
        if let ind = HimaData.firstIndex(of: targetCharacter) {
            let position = HimaData.distance(from: HimaData.startIndex, to: ind) + 1
            let himaTime = String(HimaData.prefix(position - 1))
            let himaTimeLatter = String(HimaData.suffix(HimaData.count -  position))
            
            interpretHimaData(_HimaData: himaTime, _spacing: spacing)
            interpretHimaData(_HimaData: himaTimeLatter, _spacing: spacing)
        } else {
            if let index2 = HimaData.firstIndex(of: targetCharacter2){
                let position2 = HimaData.distance(from: HimaData.startIndex, to: index2) + 1
                let startTime = String(HimaData.prefix(position2 - 1))
                let endTime = String(HimaData.suffix(HimaData.count -  position2))
                //print("calling addSquare from \(startTime) to \(endTime)")
                //addSquare(_startTime: startTime, _endTime: endTime, _originalLabel: originalLabel, _index: index, _spacing: spacing)
                self.HimaTimeArray.append(startTime)
                self.HimaTimeArray.append(endTime)
            }
        }
    }
    
    
    func addSquare(_startTime startTime: String, _endTime endTime: String, _originalLabel originalLabel: UILabel, _index index: Int, _spacing spacing: CGFloat){
        let squareView = UIView()
        let originalLabelFrame = originalLabel.frame
        let viewFrame = self.contentView.frame
        
        let numericCharacterSet = CharacterSet.decimalDigits
        let IntCheckerStart = startTime.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
        let IntCheckerEnd = endTime.rangeOfCharacter(from: numericCharacterSet.inverted) == nil
        if IntCheckerStart && IntCheckerEnd{
            let start = Int(startTime)
            let end = Int(endTime)
            let squareY = originalLabelFrame.origin.y + CGFloat(index - 1) * (originalLabelFrame.size.height + spacing) + 30
            //let oneHourWidth = originalLabelFrame.size.width / 8
            let oneHourWidth = viewFrame.size.width / 24
            let squareX = originalLabelFrame.origin.x + oneHourWidth * CGFloat(start!)
            let squareWidth = oneHourWidth * CGFloat(end! - start!)

            let squareHeight = 10
            // 2. UIViewのプロパティを設定
            squareView.frame = CGRect(x: squareX, y: squareY, width: squareWidth, height: CGFloat(squareHeight))
            //位置とサイズ
            squareView.backgroundColor = UIColor.blue
            // 3. UIViewControllerのviewにUIViewを追加
            contentView.addSubview(squareView)
            
        }
    }
    
    @IBAction func reloadButtonTapped(_ sender: UIButton) {
        print("reload tapped")
        
        checkpoint = 0
        numberOfCells = 0
        friendNameText = ""
        HimaTimeArray = []
        cellCount = 0
        friendValue = []
        processChecker = 0
        processChecker2 = 0
        progressOfuserId = 0
        progressOfHimaCount = 0
        numberOfUsers = 0
        progress = 0
        HimaTimeDatasStart = []
        HimaTimeDatasEnd = []
        startDatas = []
        endDatas = []
        friendArray = []
        numberOfHimaDatas = 0
        numberOfFriends = 0
        startDataFrag = 0
        endDataFrag = 0
        cellRow = 0
        cellTapped = 0
        observeHimaDataChecker = 0
        errorTag = 0
        nameInTappedCell = ""
        
        friendNameLabels = []
        HimaDataStart1 = []
        HimaDataStart2 = []
        HimaDataEnd1 = []
        HimaDataEnd2 = []
        dataObserved = 0
        friedNum = 0
        checkmarkArray = []
        selectedIndexPaths = []
        selectedFriendID = []
        friendIDs = []
        iconURLs = []
        
        HIMAdatas = []
        
        self.tableView.reloadData()
    }
    
    func imageWithColor(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image ?? UIImage()
    }
    
    func scrollContent(){
        let contentSize = CGSize(width: view.frame.width, height: 1000)

        // コンテナビューの設定
        contentView.frame = CGRect(origin: CGPoint.zero, size: contentSize)
        view.addSubview(contentView)
        // スクロールのジェスチャーを追加
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        contentView.addGestureRecognizer(panGesture)
    }
    
    func transformAddFriendBottun(){
        // ボタンの座標取得
            let currentX = self.addFriendsBottun.frame.origin.x
            let currentY = self.addFriendsBottun.frame.origin.y
            let currentWidth = self.addFriendsBottun.frame.width
            let currentHeight = self.addFriendsBottun.frame.height
            
            // 新しい座標に変更
            let newX = currentX + currentWidth / 2
            let newY = currentY + currentHeight / 2
            let newWidth = currentHeight
            self.addFriendsBottun.frame = CGRect(x: newX, y: newY, width: newWidth, height: currentHeight)
            
            // 角丸設定
            self.addFriendsBottun.layer.cornerRadius = self.addFriendsBottun.bounds.width / 2
            self.addFriendsBottun.clipsToBounds = true
    }
    func transformeventBottun(){
        // ボタンの座標取得
            let currentX = self.eventBotun.frame.origin.x
            let currentY = self.eventBotun.frame.origin.y
            let currentWidth = self.eventBotun.frame.width
            let currentHeight = self.eventBotun.frame.height
            
            // 新しい座標に変更
            let newX = self.addFriendsBottun.frame.origin.x + 10 + currentHeight / 2
            let newY = currentY + currentHeight / 2
            let newWidth = currentHeight
            self.eventBotun.frame = CGRect(x: newX, y: newY, width: newWidth, height: currentHeight)
            
            // 角丸設定
            self.eventBotun.layer.cornerRadius = self.eventBotun.bounds.width / 2
            self.eventBotun.clipsToBounds = true
    }
    func transformReloadButton(){
        // ボタンの座標取得
            let currentX = self.reloadButton.frame.origin.x
            let currentY = self.reloadButton.frame.origin.y
            let currentWidth = self.reloadButton.frame.width
            let currentHeight = self.reloadButton.frame.height
            
            // 新しい座標に変更
            let newX = currentX + currentWidth / 2
            let newY = currentY + currentHeight / 2
            let newWidth = currentHeight
            self.reloadButton.frame = CGRect(x: newX, y: newY, width: newWidth, height: currentHeight)
            
            // 角丸設定
            self.reloadButton.layer.cornerRadius = self.addFriendsBottun.bounds.width / 2
            self.reloadButton.clipsToBounds = true
    }
    
    @IBAction func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        //let translation = gesture.translation(in: contentView)
        let translation = gesture.translation(in: tableView)

        // スクロールのジェスチャーに合わせてTableViewをスクロール
        if let tableView = gesture.view as? UITableView {
            let velocity = gesture.velocity(in: tableView)

            // スクロールする方向が垂直方向かつ、TableViewが上端または下端にない場合にスクロール
            if abs(velocity.y) > abs(velocity.x), (tableView.contentOffset.y > 0 || translation.y > 0) {
                tableView.setContentOffset(CGPoint(x: 0, y: max(tableView.contentOffset.y - translation.y, 0)), animated: false)
                        
                // スクロールに合わせてscrollViewも同期
                let contentOffsetY = max(tableView.contentOffset.y - translation.y, 0)
                scrollView.setContentOffset(CGPoint(x: 0, y: contentOffsetY), animated: false)
                }
        }
        // 現在の位置に移動
        //let currentY = contentView.frame.origin.y
        //contentView.frame.origin.y = currentY + translation.y
        //let currentX = contentView.frame.origin.x
        //contentView.frame.origin.x = currentX + translation.x
        /*
        let currentY_tableView = tableView.frame.origin.y
        tableView.frame.origin.y = currentY_tableView + translation.y
    */
        // ジェスチャーの移動をリセット
        //gesture.setTranslation(CGPoint.zero, in: contentView)
        gesture.setTranslation(CGPoint.zero, in: tableView)
    }
    /*
    func scrollViewDidScroll(_ ScrollView: UIScrollView) {
        // yourTableViewのスクロールに合わせてyourScrollViewもスクロール
        if ScrollView == tableView {
            ScrollView.contentOffset = tableView.contentOffset
        }
    }*/
}
/*
extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = "Row \(indexPath.row)"
        return cell
    }
}*/
