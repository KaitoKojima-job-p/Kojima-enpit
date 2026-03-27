
import UIKit
import Firebase

class CreateAccountViewController: UIViewController {
    
    
    @IBOutlet weak var userIdTextField: UITextField!
    @IBOutlet weak var userPasswordTextField: UITextField!
    @IBOutlet weak var userNameTextField: UITextField!
    
    var administrator: DatabaseReference!
    var user: DatabaseReference!
    var userId: DatabaseReference!
   
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.user = Database.database().reference().child("user")
        self.administrator = Database.database().reference().child("administrator")
    }
    
    @IBAction func createAccountButtonTapped(_ sender: UIButton) {
        if let enteredUserId = self.userIdTextField.text {
            let userRef = self.user.child(enteredUserId)
            
            // Check if the user ID already exists
            userRef.observeSingleEvent(of: .value) { (snapshot) in
                if snapshot.exists() {
                    // User ID already exists, show alert
                    self.showAlert(title: "エラー", message: "このユーザーIDはすでに登録されています。")
                } else {
                    // User ID doesn't exist, proceed with registration
                    self.administrator.child("count").observeSingleEvent(of: .value) { (countSnapshot) in
                        if let countValue = countSnapshot.value as? String, let countInt = Int(countValue) {
                            self.administrator.child("count").setValue(String(countInt + 1))
                            
                            // Set user information
                            let passwordRef: DatabaseReference = userRef.child("password")
                            let nameRef: DatabaseReference = userRef.child("name")
                            let statusRef: DatabaseReference = userRef.child("status")
                            let countRef: DatabaseReference = userRef.child("count")
                            
                            let eventsRef: DatabaseReference = userRef.child("events")
                            let eventsCountRef: DatabaseReference = eventsRef.child("count")
                            //let friendsRef: DatabaseReference = userRef.child("friends")
                            //let iconURLRef: DatabaseReference = userRef.child("iconURL")
                            
                            if let enteredUserPassword = self.userPasswordTextField.text {
                                passwordRef.setValue(enteredUserPassword)
                            }
                            
                            if let enteredUserName = self.userNameTextField.text {
                                nameRef.setValue(enteredUserName)
                            }
                            
                            statusRef.observeSingleEvent(of: .value) { (statusSnapshot: DataSnapshot) in
                                if !statusSnapshot.exists() {
                                    statusRef.setValue("not暇")
                                }
                            }
                            
                            countRef.observeSingleEvent(of: .value) { (countSnapshot: DataSnapshot) in
                                if !countSnapshot.exists() {
                                    countRef.setValue("0")
                                }
                            }
                            
                            eventsCountRef.observeSingleEvent(of: .value) { (countSnapshot: DataSnapshot) in
                                if !countSnapshot.exists() {
                                    eventsCountRef.setValue("0")
                                }
                            }
                            
                            // Show registration completed alert
                            self.showAlert(title: "成功", message: "登録が完了しました。")
                        }
                    }
                }
            }
        }
    }
    
    func showAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}
