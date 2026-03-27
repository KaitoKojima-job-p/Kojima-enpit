import UIKit
import Firebase

class AddFriendsViewController: UIViewController {
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBOutlet weak var addFriendIDContainerView: UIView!
    @IBOutlet weak var addFriendQRCodeContainerView: UIView!
    
    
    var addFriendsViewControllerValue = ""
    var administrator: DatabaseReference!
    var user: DatabaseReference!
    var userId: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // セグメントコントロールの初期選択を設定
        segmentedControl.selectedSegmentIndex = 0
        
        // 初期状態ではaddFriendIDContainerViewを表示し、addFriendQRCodeContainerViewを非表示にする
        addFriendIDContainerView.isHidden = false
        addFriendQRCodeContainerView.isHidden = true
        
        // セグメントコントロールの値が変更されたときに呼び出されるアクションを追加
        segmentedControl.addTarget(self, action: #selector(segmentControlValueChanged(_:)), for: .valueChanged)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddFriendsIDContainerView" {
            if let destinationVC = segue.destination as? AddFriendsIDContainerView {
                // AddFriendsIDContainerViewに値を渡す
                destinationVC.addFriendsIDViewControllerValue = addFriendsViewControllerValue
            }
        } else if segue.identifier == "AddFriendsQRCodeContainerView" {
            if let destinationVC = segue.destination as? AddFriendsQRCodeContainerView {
                // AddFriendsQRCodeContainerViewに値を渡す
                destinationVC.addFriendsQRCodeViewControllerValue = addFriendsViewControllerValue
            }
        }
    }
    
    // メソッドでコンテナビューの切り替え
    func switchContainerView(forSegmentIndex index: Int) {
        switch index {
        case 0:
            addFriendIDContainerView.isHidden = false
            addFriendQRCodeContainerView.isHidden = true
        case 1:
            addFriendIDContainerView.isHidden = true
            addFriendQRCodeContainerView.isHidden = false
        default:
            break
        }
    }
    
    @objc func segmentControlValueChanged(_ sender: UISegmentedControl) {
        switchContainerView(forSegmentIndex: sender.selectedSegmentIndex)
    }
    
}
