//homeviewcontrollerを変更したのち
//カメラロールの使用にはinfoにPrivacy - Photo Library Usage Description:を追加する必要がある
//https://qiita.com/kanae_/items/8afaa7925401bcfdaf27
//
//crop view controlerの導入
//File > Add package... > 検索フォームにhttps://github.com/TimOliver/TOCropViewController.gitを入れて検索するとライブラリが出てくるので選択してAdd packageをクリックします。
//TOCropViewControllerをadd
//新規登録でプロフィール画像をデフォルトで作る


import UIKit
import Firebase
import FirebaseStorage
import Photos
import CropViewController

class AdvancedSettingTableViewController: UITableViewController,  UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CropViewControllerDelegate {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var changeIconImageButton: UIButton!
    
    @IBOutlet weak var settingNameTextField: UITextField!
    
    @IBOutlet weak var settingUserIdLabel: UILabel!
    @IBOutlet weak var copyUserIdButton: UIButton!
    
    var advancedSettingTableViewControllerValue = "" //userID
    var administrator: DatabaseReference!
    var yourId: DatabaseReference!
    
    var yourNewName = ""    //名前編集用の新しい名前
    var selectedPhotoIdentifiers: Set<String> = []  // Create a property to store selected photo identifiers
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.yourId = Database.database().reference().child("user").child(advancedSettingTableViewControllerValue)
        
        //プロフィール画像を表示する
        displayUserImage()
        
        //名前を表示する
        displayUserName()
        //ユーザーIDをラベルに表示
        settingUserIdLabel.text = advancedSettingTableViewControllerValue
        // UITextFieldDelegateを設定
        settingNameTextField.delegate = self
        // キーボード以外の場所をタップしたときにキーボードを閉じるための UITapGestureRecognizer を追加
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        // 「Copy UserID」ボタンが押されたときのアクションを追加
        copyUserIdButton.addTarget(self, action: #selector(copyUserIdToClipboard), for: .touchUpInside)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // セクションの数を返します
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // それぞれのセクション毎に何行のセルがあるかを返します
        switch section {
        case 0: // 「プロフィール」のセクション
            return 3
        case 1: // 「アカウント」のセクション
            return 2
        default:
            return 0
        }
    }
    
    // ユーザー名を表示する関数
    func displayUserName() {
        yourId.observeSingleEvent(of: .value) { [weak self] (snapshot) in
            if let data = snapshot.value as? [String: Any], let name = data["name"] as? String {
                self?.settingNameTextField.text = name
            }
        }
    }
    
    // UITextFieldDelegateのメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        self.yourNewName = self.settingNameTextField.text!
        // キーボードを閉じる
        settingNameTextField.resignFirstResponder()
        // ポップアップを表示
        showNameChangeConfirmationAlert()
        
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // 画面遷移時にキーボードを閉じる
        view.endEditing(true)
    }
    
    // タップイベントのハンドラ
    @objc func handleTap() {
        view.endEditing(true) // キーボードを閉じる
    }
    
    
    // 名前編集用のポップアップを表示するメソッド
    func showNameChangeConfirmationAlert() {
        let alertController = UIAlertController(title: "確認", message: "名前を「\(yourNewName)」に変更しますか？", preferredStyle: .alert)
        
        // 「はい」ボタンが押されたときの処理
        let yesAction = UIAlertAction(title: "はい", style: .default) { [weak self] _ in
            // データベースの名前を更新
            if let newName = self?.settingNameTextField.text {
                self?.updateUserName(newName)
            }
        }
        
        // 「いいえ」ボタンが押されたときの処理
        let noAction = UIAlertAction(title: "いいえ", style: .cancel) { [weak self] _ in
            // テキストフィールドに変更前の名前を表示
            self?.displayUserName()
        }
        
        alertController.addAction(yesAction)
        alertController.addAction(noAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    // ユーザー名を更新する関数
    func updateUserName(_ newName: String) {
        yourId.child("name").setValue(newName) { [weak self] (error, ref) in
            if let error = error {
                print("Error updating name: \(error.localizedDescription)")
            } else {
                print("Name updated successfully")
                // 更新後のユーザー名を表示
                self?.settingNameTextField.text = newName
            }
        }
    }
    
    // ユーザーIDをクリップボードにコピーするメソッド
    @objc func copyUserIdToClipboard() {
        let userIdToCopy = settingUserIdLabel.text
        // クリップボードにユーザーIDをコピー
        UIPasteboard.general.string = userIdToCopy
        //アラート表示
        let alertController = UIAlertController(title: "コピー完了", message: "ユーザーIDがクリップボードにコピーされました", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // 写真選択ボタンがタップされたときの処理
    @IBAction func changeIconImageButtonTapped(_ sender: Any) {
        checkPhotoLibraryPermission()
    }
    
    // プロフィール画像を表示するための関数
    func displayUserImage() {
        let iconURLRef = self.yourId.child("iconURL")
        
        iconURLRef.observeSingleEvent(of: .value) { (snapshot) in
            if let iconURLString = snapshot.value as? String, let iconURL = URL(string: iconURLString) {
                // ダウンロードURLを元に画像を表示
                URLSession.shared.dataTask(with: iconURL) { (data, response, error) in
                    if let error = error {
                        print("Error downloading image data: \(error.localizedDescription)")
                        return
                    }
                    
                    if let data = data, let image = UIImage(data: data) {
                        DispatchQueue.main.async {
                            self.iconImageView.contentMode = .scaleAspectFill
                            self.iconImageView.layer.cornerRadius = self.iconImageView.frame.width / 2
                            self.iconImageView.layer.masksToBounds = true
                            self.iconImageView.image = image
                        }
                    } else {
                        print("Error creating UIImage from downloaded data")
                    }
                }.resume()
            } else {
                print("Error retrieving icon URL from snapshot")
            }
        }
    }

    
    // 写真ライブラリへのアクセス許可の確認
    func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized:
            openPhotoLibrary()
        case .limited:
            //self?.openLimitedPhotoLibrary()   (本来は.limited用の処理を行う)
            openPhotoLibrary()
        case .denied, .restricted:
            showPermissionAlert()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] (newStatus) in
                if newStatus == .authorized {
                    self?.openPhotoLibrary()
                } else if newStatus == .limited{
                    self?.openPhotoLibrary()
                    //self?.openLimitedPhotoLibrary()   (本来は.limited用の処理を行う)
                }
            }
        default:
            break
        }
    }
    
    // すべてのアクセスが許可されている場合
    func openPhotoLibrary() {
        DispatchQueue.main.async{
            print("opend access")
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    // 限定されたアクセスが許可されている場合の処理
    func openLimitedPhotoLibrary() {
        DispatchQueue.main.async{
            print("limited access")
        }
    }
    
    // ユーザーにアクセスを許可するよう促すダイアログを表示
    func showPermissionAlert() {
        let alertController = UIAlertController(title: "写真アクセスの許可", message: "このアプリは写真にアクセスする必要があります。設定でアクセスを許可してください。", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "設定へ", style: .default) { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
        alertController.addAction(settingsAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // 写真が選択されたときの処理
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            // トリミング画面に遷移する
            showCropViewController(with: pickedImage)
        } else {
            print("Error: Unable to retrieve the selected image.")
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    // 写真選択がキャンセルされたときの処理
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // トリミング画面に遷移するメソッド
    func showCropViewController(with image: UIImage) {
        let cropViewController = CropViewController(croppingStyle: .circular, image: image)
        cropViewController.delegate = self
        cropViewController.customAspectRatio = CGSize(width: 128, height: 128)
        cropViewController.aspectRatioPickerButtonHidden = true
        cropViewController.resetAspectRatioEnabled = false
        cropViewController.rotateButtonsHidden = false
        cropViewController.cropView.cropBoxResizeEnabled = false
        
        // トリミング画面を表示
        dismiss(animated: true) {
            self.present(cropViewController, animated: true, completion: nil)
        }
    }
    
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        print(image.size.height)
        
        // 画像の高さが512より大きい場合は縮小
        if image.size.height > 512 {
            let newSize = CGSize(width: 512, height: 512)
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
            image.draw(in: CGRect(origin: CGPoint.zero, size: newSize))
            let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            iconImageView.contentMode = .scaleAspectFill
            iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
            iconImageView.layer.masksToBounds = true
            self.iconImageView.image = scaledImage
            
            addIconImageBottunTapped(addImage: scaledImage!)
            
        } else {
            iconImageView.contentMode = .scaleAspectFill
            iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
            iconImageView.layer.masksToBounds = true
            self.iconImageView.image = image
            
            addIconImageBottunTapped(addImage: image)
            
        }
        
        // トリミング画面を閉じる
        dismiss(animated: true, completion: nil)
    }
    
    func addIconImageBottunTapped(addImage yourIconImage: UIImage) {
        // Firebase Storageへの参照を作成
        let storage = Storage.storage()
        let storageReference = storage.reference()
        
        // アップロードする画像のデータ
        if let imageData = yourIconImage.jpegData(compressionQuality: 1.0) {
            // 画像ファイルの名前を指定（例: "userIconImage/userID/iconImage.jpg"）
            let imageRef = storageReference.child("userIconImage").child(advancedSettingTableViewControllerValue).child("iconImage.jpg")
            
            // 画像のアップロード
            imageRef.putData(imageData, metadata: nil) { (metadata, error) in
                if let error = error {
                    // アップロードエラーが発生した場合の処理
                    print("Error uploading image: \(error.localizedDescription)")
                } else {
                    // アップロードが成功した場合の処理
                    imageRef.downloadURL { (url, error) in
                        if let downloadURL = url {
                            // アップロード後の画像のダウンロードURLを取得
                            print("Download URL: \(downloadURL)")
                            
                            // userIDの子ノードiconURLにダウンロードURLを追加
                            self.yourId.child("iconURL").setValue(downloadURL.absoluteString) { (error, ref) in
                                if let error = error {
                                    print("Error updating iconURL: \(error.localizedDescription)")
                                } else {
                                    print("iconURL updated successfully")
                                }
                            }
                        } else {
                            // ダウンロードURLの取得に失敗した場合のエラーコード
                            print("Error getting download URL")
                        }
                    }
                }
            }
        } else {
            // 画像データの取得に失敗した場合のエラーコード
            print("Error getting image data")
        }
    }
    
    
}
