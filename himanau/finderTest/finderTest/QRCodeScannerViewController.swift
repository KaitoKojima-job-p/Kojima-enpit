import UIKit
import AVFoundation
import Firebase

class QRCodeScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    private var isAlertPresented = false // アラートが表示されているかどうかのフラグ
    private var originalNavigationBarAppearance: UINavigationBarAppearance?
    
    var user: DatabaseReference!
    var yourId: DatabaseReference!
    var friendId: DatabaseReference!
    
    var QRCodeScannerViewControllerValue = ""
    
    let qrCodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.user = Database.database().reference().child("user")
        self.yourId = Database.database().reference().child("user").child(QRCodeScannerViewControllerValue)
        
        setupCamera()
        setupUI()
    }
    
    func setupCamera() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            failed()
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            failed()
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func setupUI() {
        view.addSubview(qrCodeImageView)
        
        // QR Code Image View Constraints
        qrCodeImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        qrCodeImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10).isActive = true
        qrCodeImageView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5).isActive = true
        qrCodeImageView.heightAnchor.constraint(equalTo: qrCodeImageView.widthAnchor).isActive = true
        
        showQRCodeImage(false) // Initially hide QR code image
    }
    
    func failed() {
        let alert = UIAlertController(title: "Scanning not supported", message: "Your device does not support scanning a code from an item. Please use a device with a camera.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        captureSession = nil
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if (captureSession?.isRunning == false) {
            captureSession.startRunning()
        }
        
        if #available(iOS 13.0, *) {
            originalNavigationBarAppearance = navigationController?.navigationBar.standardAppearance.copy()
            navigationItem.title = "QRコード読み込み"
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black.withAlphaComponent(0.5)
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            navigationController?.navigationBar.standardAppearance = appearance
            navigationController?.navigationBar.scrollEdgeAppearance = appearance
        } else {
            originalNavigationBarAppearance = navigationController?.navigationBar.barTintColor?.copy() as? UINavigationBarAppearance
            navigationItem.title = "QRコード読み込み"
            navigationController?.navigationBar.tintColor = UIColor.white
            navigationController?.navigationBar.isTranslucent = false
            navigationController?.navigationBar.barTintColor = UIColor.red.withAlphaComponent(0.5)
            navigationController?.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if (captureSession?.isRunning == true) {
            captureSession.stopRunning()
        }
        
        if let originalAppearance = originalNavigationBarAppearance {
            if #available(iOS 13.0, *) {
                navigationController?.navigationBar.standardAppearance = originalAppearance
                navigationController?.navigationBar.scrollEdgeAppearance = nil
            } else {
                navigationController?.navigationBar.isTranslucent = originalAppearance.backgroundEffect != nil
                navigationController?.navigationBar.barTintColor = originalAppearance.backgroundColor
                navigationController?.navigationBar.titleTextAttributes = originalAppearance.titleTextAttributes
            }
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if isAlertPresented {
            // アラートが表示されている場合は QR コードの処理をスキップ
            return
        }
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            found(code: stringValue)
        }
        
        // Resume the camera session regardless of whether a QR code is found or not
        captureSession.startRunning()
    }
    
    func found(code: String) {
        // Update the QR Code image view
        if let qrCodeImage = createQRCodeImage(from: code) {
            qrCodeImageView.image = qrCodeImage
            showQRCodeImage(true)
        }
        
        showRegistrationAlert(for: code)
    }
    
    
    
    func showRegistrationAlert(for code: String) {
        // Stop the capture session temporarily
        captureSession.stopRunning()
        
        isAlertPresented = true // アラートが表示されていることをフラグで管理
        
        var forAlertMessageTofriendName = ""
        
        let userFriendNameRef =  self.user.child(code).child("name")
        userFriendNameRef.observeSingleEvent(of: .value, with: { (countSnapshot) in
            if let friendsnameString = countSnapshot.value as? String{
                forAlertMessageTofriendName = friendsnameString
                
                let alert = UIAlertController(title: "QRコードを検知", message: "\(forAlertMessageTofriendName)を友達に登録しますか?", preferredStyle: .alert)
                
                let yesAction = UIAlertAction(title: "はい", style: .default) { _ in
                    self.hideQRCodeImage()
                    if code == self.QRCodeScannerViewControllerValue{
                        self.showAutoDismissView(message: "これはあなたのユーザーIDです")
                    }else{
                        self.yourId.child("count").observeSingleEvent(of: .value, with: { (countSnapshot) in
                            if let friendsCountString = countSnapshot.value as? String, let friendsCount = Int(friendsCountString) {
                                
                                self.yourId.child("friends").observeSingleEvent(of: .value, with: { (friendsSnapshot) in
                                    let dispatchGroup = DispatchGroup()
                                    var isFriendContained = false
                                    // 友達の人数分だけ走査
                                    dispatchGroup.enter()
                                    if friendsCount > 0 {
                                        for i in 1...friendsCount {
                                            let friendNumber = String(format: "%03d", i)
                                            // friendNumber が存在し、その value が friendUserID である場合
                                            if friendsSnapshot.hasChild(friendNumber), let storedFriendID = friendsSnapshot.childSnapshot(forPath: friendNumber).value as? String, storedFriendID == code {
                                                // ユーザーが自分の friends に存在する場合
                                                print("contain")
                                                self.showAutoDismissView(message: "\(forAlertMessageTofriendName)\nは既に追加されている友達です")
                                                isFriendContained = true
                                            }
                                        }
                                    }
                                    dispatchGroup.leave()
                                    // すべての非同期処理が完了した後の処理
                                    dispatchGroup.notify(queue: .main) {
                                        if !isFriendContained {
                                            // 友達に追加されていない場合
                                            print("not contain")
                                            self.registerDatabaseID(code)
                                            self.showAutoDismissView(message: "\(forAlertMessageTofriendName)\nを友達に追加しました")
                                        }
                                    }
                                })

                            }
                        })
                    }
                }
                
                let noAction = UIAlertAction(title: "いいえ", style: .cancel) { _ in
                    self.isAlertPresented = false // アラートが閉じられたことをフラグで管理
                    self.captureSession.startRunning() // Resume the camera session
                    self.hideQRCodeImage()
                }
                
                alert.addAction(yesAction)
                alert.addAction(noAction)
                
                self.present(alert, animated: true)
            }
        })
    }
    
    func createSquareView() -> UIView {
        let squareView = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 100))
        squareView.center = view.center
        squareView.backgroundColor = .white
        squareView.layer.borderWidth = 1.0
        squareView.layer.cornerRadius = 5.0
        return squareView
    }
    
    func showAutoDismissView(message: String) {
        let squareView = createSquareView()
        
        // ラベルを作成して四角形のビューに追加
        let label = UILabel(frame: squareView.bounds.insetBy(dx: 5, dy: 5))
        label.text = message
        label.textAlignment = .center
        label.numberOfLines = 0
        squareView.addSubview(label)
        
        // 画面に表示
        view.addSubview(squareView)
        
        // 3秒後に自動でビューを非表示にする
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            squareView.removeFromSuperview()
            self.isAlertPresented = false // アラートが閉じられたことをフラグで管理
        }
    }
    
    func createQRCodeImage(from code: String) -> UIImage? {
        let data = code.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
    func showQRCodeImage(_ show: Bool) {
        qrCodeImageView.isHidden = !show
    }
    
    func hideQRCodeImage() {
        showQRCodeImage(false)
    }
    
    func registerDatabaseID(_ code: String){
        print("\(code)を発見しました。")
        
        let countRef = yourId.child("count")
        countRef.observeSingleEvent(of: .value) { (countSnapshot) in
            if let currentCount = countSnapshot.value as? String {
                // "friends" ノードに友達のユーザーIDを連番に追加
                let friendNumber = String(format: "%03d", Int(currentCount)! + 1)
                let friendsRef = self.yourId.child("friends").child(friendNumber)
                friendsRef.setValue(code) { (error, reference) in
                    if let error = error {
                        print("友達を追加できませんでした: \(error.localizedDescription)")
                    } else {
                        print("友達を追加しました")
                        // "count" カウンタをインクリメント
                        countRef.setValue(String(Int(currentCount)! + 1))
                    }
                }
            } else {
                // "count" の子ノードが存在しない場合、初期値として"001"で友達を追加
                let friendsRef = self.yourId.child("friends").child("001")
                friendsRef.setValue(code) { (error, reference) in
                    if let error = error {
                        print("友達を追加できませんでした: \(error.localizedDescription)")
                    } else {
                        print("友達を追加しました")
                        
                        // "count" カウンタを初期化
                        countRef.setValue("1")
                    }
                }
            }
        }
        
        //友達の方に追加する処理
        friendId = Database.database().reference().child("user").child(code)
        let friendCountRef = friendId.child("count")
        friendCountRef.observeSingleEvent(of: .value) { (countSnapshot) in
            if let currentCount = countSnapshot.value as? String {
                // "friends" ノードに友達のユーザーIDを連番に追加
                let friendNumber = String(format: "%03d", Int(currentCount)! + 1)
                let friendsRef = self.friendId.child("friends").child(friendNumber)
                friendsRef.setValue(self.QRCodeScannerViewControllerValue) { (error, reference) in
                    if let error = error {
                        print("友達を追加できませんでした: \(error.localizedDescription)")
                    } else {
                        print("友達を追加しました")
                        // "count" カウンタをインクリメント
                        friendCountRef.setValue(String(Int(currentCount)! + 1))
                    }
                }
            } else {
                // "count" の子ノードが存在しない場合、初期値として"001"で友達を追加
                let friendsOfFriendsRef = self.friendId.child("friends").child("001")
                friendsOfFriendsRef.setValue(self.QRCodeScannerViewControllerValue) { (error, reference) in
                    if let error = error {
                        print("友達を追加できませんでした: \(error.localizedDescription)")
                    } else {
                        print("友達を追加しました")
                        // "count" カウンタを初期化
                        friendCountRef.setValue("1")
                    }
                }
            }
        }
    }
    
}

extension UINavigationController {
    override open var childForStatusBarStyle: UIViewController? {
        return self.visibleViewController
    }
    
    override open var childForStatusBarHidden: UIViewController? {
        return self.visibleViewController
    }
}
