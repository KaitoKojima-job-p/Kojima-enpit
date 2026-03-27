//
//  HomeViewController.swift
//  finderTest
//
//  Created by ヒロ N on 2023/11/01.
//
//keyboardを遷移時に閉じるコードを追加

import UIKit
import Firebase

class HomeViewController: UIViewController,  UITextFieldDelegate {
    
    
    @IBOutlet weak var homeTargetIdText: UITextField!
    @IBOutlet weak var userPasswordText: UITextField!
    @IBOutlet weak var homeconnectButton: UIButton!
    let textFieldKey = "SavedText"
    let textFieldKey2 = "SavedTex2"
    
    
    var user: DatabaseReference!
    var userId: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.user = Database.database().reference().child("user")
        
        //homeTargetIdText.isEnabled = true
        homeTargetIdText.delegate = self
        
        userPasswordText.delegate = self
        
        if let savedText = UserDefaults.standard.string(forKey: textFieldKey) {
            homeTargetIdText.text = savedText
        }
        if let savedText2 = UserDefaults.standard.string(forKey: textFieldKey2) {
            userPasswordText.text = savedText2
        }
    }
    
    // UITextFieldDelegateのメソッド
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        if textField == self.homeTargetIdText {
            homeTargetIdText.resignFirstResponder()
        } else if textField == self.userPasswordText {
            userPasswordText.resignFirstResponder()
        }
        return true
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CustomTabBarController" {
            if let destinationVC = segue.destination as? CustomTabBarController {
                destinationVC.sharedValue = self.homeTargetIdText.text!
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // キーボードを閉じる
        view.endEditing(true)
        
        saveTextFieldValue()
    }
    
    /*
    override func  oryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }*/

    @IBAction func userConnect(_ sender: Any) {
        guard let enteredUserId = homeTargetIdText.text, !enteredUserId.isEmpty else {
            // ユーザーIDが入力されていない場合の処理
            print("ユーザーIDを入力してください")
            return
        }
        
        guard let enteredUserPassword = userPasswordText.text, !enteredUserPassword.isEmpty else {
            // ユーザーIDが入力されていない場合の処理
            print("パスワードを入力してください")
            return
        }
        
        self.user.observeSingleEvent(of: .value) { snapshot in
            // クエリ結果から子ノードのキーを取得
            let userKeys = snapshot.children.allObjects.compactMap { ($0 as? DataSnapshot)?.key }
            
            // self.homeTargetIdText.text! が userKeys 配列に含まれているかどうかを確認
            if userKeys.contains(enteredUserId) {
                // DBにidが登録されている場合の処理
                print("ユーザーIDが含まれています")
                self.user.child(enteredUserId).child("password").observeSingleEvent(of: .value) { passwordSnapshot in
                    let userPassword = passwordSnapshot.value as? String
                    
                    if let userPassword = userPassword, userPassword == enteredUserPassword {
                        print("アクセス成功")
                        self.performSegue(withIdentifier: "CustomTabBarController", sender: nil)
                    } else {
                        print("パスワードが異なります")
                        let alert = UIAlertController(title: "エラー", message: "パスワードが異なります", preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "了解", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                }
            } else {
                // DBにidが登録されていない場合の処理
                print("ユーザーIDが含まれていません")
                let alert = UIAlertController(title: "エラー", message: "そのログインIDは存在しません", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "了解", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func saveTextFieldValue() {
        if let text = homeTargetIdText.text {
            UserDefaults.standard.set(text, forKey: textFieldKey)
        }
    
        if let text = userPasswordText.text {
            UserDefaults.standard.set(text, forKey: textFieldKey2)
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
