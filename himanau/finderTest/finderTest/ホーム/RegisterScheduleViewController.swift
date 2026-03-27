//
//  RegisterScheduleViewController.swift
//  finderTest
//
//  Created by 宮脇拓真 on 2023/12/01.
//

import UIKit
import Firebase
import CryptoKit
import Foundation  //日付や時間に関する機能を使用するため
import AudioToolbox  //音を鳴らすため
import EventKit



class RegisterScheduleViewController: UIViewController{
    
    @IBOutlet weak var startTimePicker: UIDatePicker!//初期値の設定のため
    @IBOutlet weak var endTimePicker: UIDatePicker!//初期値の設定のため
    
    var registerScheduleViewControllerValue = ""  //ログインしているuserIDを表す
    
    var timeSlots: [Date] = []// 時刻データを保持する配列
    var startTime: Date?
    var endTime: Date?
    
    // 時刻の文字列を保持するプロパティ
    var startTimeString: String?
    var endTimeString: String?
    
    var user: DatabaseReference!
    var userId: DatabaseReference!
    var himaTime: DatabaseReference!
    
    //var currentCount = 0
    
    var ganttChartViewController: GanttChartViewController?
    @IBOutlet weak var yourContainerView: UIView!
    
    
    //開始pickerの呼び出しメソッド
    @IBAction func startTimePicker(_ sender: UIDatePicker) {
        let startFormatter = DateFormatter()
       startFormatter.dateFormat = "yyyyMMddHHmm"
       startTimeString = startFormatter.string(from: sender.date)
       print("startTime:", startTimeString ?? "nil")
        endTimePicker.minimumDate = sender.date.addingTimeInterval(0)// 最小時刻を開始時刻に設定
        // 開始時刻が現在の終了時刻より遅い場合、終了時刻を1時間後に設定
        if sender.date > endTimePicker.date {
            endTimePicker.date = sender.date.addingTimeInterval(3600)
            endTimeString = startFormatter.string(from: endTimePicker.date)
            playSoundAndVibrate()// 音と振動を発生

        }
    }
    // 音と振動を発生させるメソッド
    func playSoundAndVibrate() {
        // 振動を発生させる
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)

        // システムサウンドを再生する
        AudioServicesPlaySystemSound(1016)
    }
    
    
    //終了pickerの呼び出しメソッド
    @IBAction func endTimePicker(_ sender: UIDatePicker) {
        if sender.date <= startTimePicker.date {
            // 終了時間が開始時間より早い場合は、再設定する
            sender.date = startTimePicker.date.addingTimeInterval(3600)
        }

        let endFormatter = DateFormatter()
        endFormatter.dateFormat = "yyyyMMddHHmm"
        endTimeString = endFormatter.string(from: sender.date)
        print("endTime:  ", endTimeString ?? "nil")
    }
    
    //暇時間の開始時刻と終了時刻をdatabeseに送信するメソッド
    @IBAction func sendHimaTime(_ sender: UIButton) {
        guard let startTime = startTimeString, let endTime = endTimeString else {
               print("開始時刻または終了時刻が設定されていません")//初期値の設定によってこのコードは不要になった
               return
           }

           let himaTimeRef = Database.database().reference().child("user").child(registerScheduleViewControllerValue).child("himaTime")

           // カウントノードの値を取得し、更新する
           himaTimeRef.child("count").observeSingleEvent(of: .value, with: { snapshot in
               var currentCount = 0
               if let count = snapshot.value as? Int {
                   currentCount = count
               }

               // カウントを増やす
               let newCount = currentCount + 1
               himaTimeRef.child("count").setValue(newCount)

               // 時刻のセットを保存する新しいノードを作成
               let timeSet = "\(startTime)-\(endTime)"//デバッグ用
               print("himaTime :", timeSet )//デバッグ用
               
               let countString = String(format: "%04d", newCount)
               
               himaTimeRef.child(countString).child("startTime").setValue(startTime) { (error, _) in
                   if let error = error {
                       print("Error setting startTime: \(error.localizedDescription)")
                   } else {
                       print("StartTime set successfully")
                       // startTime の設定が成功したら、endTime を設定する
                       himaTimeRef.child(countString).child("endTime").setValue(endTime) { (error, _) in
                           if let error = error {
                               print("Error setting endTime: \(error.localizedDescription)")
                           } else {
                               print("EndTime set successfully")
                               self.reloadDislay()
                           }
                       }
                   }
               }

               
           }) { error in
               print("himaTimeの読み込みエラー: \(error.localizedDescription)")
           }
    }
    
    @IBAction func readCalendarTapped(_ sender: UIButton) {
        let eventStore = EKEventStore()

            eventStore.requestAccess(to: .event) { [self] (granted, error) in
                guard granted, error == nil else {
                    print("カレンダーアクセスが拒否されました")
                    return
                }

                let calendars = eventStore.calendars(for: .event)
                let today = Calendar.current.startOfDay(for: Date())

                var busyTimeIntervals: [ClosedRange<Date>] = []

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm"

                for calendar in calendars {
                    let predicate = eventStore.predicateForEvents(withStart: today, end: today.addingTimeInterval(24*60*60), calendars: [calendar])
                    let events = eventStore.events(matching: predicate)

                    for event in events {
                        guard let title = event.title, let startDate = event.startDate, let endDate = event.endDate else {
                            continue
                        }

                        let startFormatter = DateFormatter()
                        startFormatter.dateFormat = "yyyyMMddHHmm"
                        self.startTimeString = startFormatter.string(from: today)

                        let endFormatter = DateFormatter()
                        endFormatter.dateFormat = "yyyyMMddHHmm"
                        self.endTimeString = endFormatter.string(from: today)

                        print("イベントタイトル: \(title), 開始日時: \(startTimeString), 終了日時: \(endTimeString)")
                        busyTimeIntervals.append(startDate...endDate)
                    }
                }

                let dayEnd = today.addingTimeInterval(24*60*60)
                var freeTimeIntervals: [ClosedRange<Date>] = []
                let dispatchGroup = DispatchGroup()

                var newCount = 0 // newCount をここで初期化

                self.calculateFreeTimeIntervals(busyTimeIntervals: busyTimeIntervals, today: today, dayEnd: dayEnd) { freeTimeIntervals in
                    // 結果を表示
                    if freeTimeIntervals.isEmpty {
                        print("\(today)には予定がありません")
                    } else {
                            let himaTimeRef = Database.database().reference().child("user").child(registerScheduleViewControllerValue).child("himaTime")
                            
                            himaTimeRef.child("count").observeSingleEvent(of: .value) { snapshot in
                                var currentCount = 0
                                if let count = snapshot.value as? Int {
                                    currentCount = count
                                    print("currentCount：",currentCount)
                                }
                                
                                
                                for freeInterval in freeTimeIntervals {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.dateFormat = "yyyyMMddHHmm"
                                    let startString = dateFormatter.string(from: freeInterval.lowerBound)
                                    let endString = dateFormatter.string(from: freeInterval.upperBound)

                                    print("利用可能な時間帯: \(startString) 〜 \(endString)")
                                print("テスト：",currentCount)
                                currentCount =  currentCount + 1
                                
                                dispatchGroup.enter()
                                self.writeToDatabase(startTime: startString, endTime: endString, count: currentCount) { success in
                                    if success {
                                        self.reloadDislay()
                                    } else {
                                        // 書き込みが失敗した場合の処理
                                    }
                                    dispatchGroup.leave()
                                
                            }
                            

                            
                            
                            }
                        }
                    }
                }
            }
        }
            


    func writeToDatabase(startTime: String, endTime: String, count: Int, completion: @escaping (Bool) -> Void) {
        let sanitizedValue = sanitizeFirebaseKey(registerScheduleViewControllerValue)
        let himaTimeRef = Database.database().reference().child("user").child(sanitizedValue).child("himaTime")

        himaTimeRef.child("count").observeSingleEvent(of: .value) { snapshot in
            var currentCount = 0
            currentCount = count
            let newCount = currentCount
            print("newCount:", newCount) // デバッグ用に newCount の値を確認

            himaTimeRef.child("count").setValue(newCount)

            let timeSet = "\(startTime)-\(endTime)"
            print("himaTime :", timeSet)

            let countString = String(format: "%04d", newCount)
            himaTimeRef.child(countString).child("startTime").setValue(startTime)
            himaTimeRef.child(countString).child("endTime").setValue(endTime)

            DispatchQueue.main.async {
                completion(true)
            }
        }
    }
    
    func reloadDislay() {
        print("reloadButtonTapped")
        
        // DispatchGroupを作成
        let dispatchGroup = DispatchGroup()
        
        // 新しい GanttChartViewController を作成
        if let ganttChartViewController = storyboard?.instantiateViewController(withIdentifier: "GanttChartViewController") as? GanttChartViewController {
            print("registerScheduleViewControllerValue", registerScheduleViewControllerValue)
            
            
            ganttChartViewController.ganttChartViewControllerValue = registerScheduleViewControllerValue
            GanttChartViewController.reloadButtonTappedIs = true
            
            ganttChartViewController.loadViewIfNeeded()
            
            // DispatchGroupに入る
            dispatchGroup.enter()
            
            // setupData()の非同期処理が完了したらDispatchGroupから出る
            ganttChartViewController.setupData {
                dispatchGroup.leave()
            }
            
            // DispatchGroupから出た後の処理
            dispatchGroup.notify(queue: .main) {
                print("(reload) set up data finish adn addview")
                // もし既存の ganttChartViewController があれば削除する
                self.ganttChartViewController?.removeFromParent()
                self.ganttChartViewController?.view.removeFromSuperview()
                
                // 新しいインスタンスを画面に追加
                self.addChild(ganttChartViewController)
                ganttChartViewController.view.frame = self.yourContainerView.bounds
                self.yourContainerView.addSubview(ganttChartViewController.view)
                ganttChartViewController.didMove(toParent: self)
                
                GanttChartViewController.reloadButtonTappedIs = false
            }
        }
    }
    
    @IBAction func ganttChartReloadButtonTapped(_ sender: UIButton) {
        reloadDislay()
    }
    
            func calculateFreeTimeIntervals(busyTimeIntervals: [ClosedRange<Date>], today: Date, dayEnd: Date, completion: @escaping ([ClosedRange<Date>]) -> Void) {
                var freeTimeIntervals: [ClosedRange<Date>] = []
                var currentStart = today
                
                for busyInterval in busyTimeIntervals {
                    if currentStart < busyInterval.lowerBound {
                        freeTimeIntervals.append(currentStart...busyInterval.lowerBound)
                    }
                    currentStart = max(currentStart, busyInterval.upperBound)
                }

                if currentStart < dayEnd {
                    freeTimeIntervals.append(currentStart...dayEnd)
                }
                
                completion(freeTimeIntervals)
            }
    
    func sanitizeFirebaseKey(_ key: String) -> String {
        return key.replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: "#", with: "")
                .replacingOccurrences(of: "$", with: "")
                .replacingOccurrences(of: "[", with: "")
                .replacingOccurrences(of: "]", with: "")
    }

    
    
    
    
    //ViewControllerがメモリにロードされた後に自動的に呼び出さるメソッド
    override func viewDidLoad() {
        super.viewDidLoad()
        self.user = Database.database().reference().child("user")

        //日本のタイムゾーンを設定
        let dateFormatter = DateFormatter() // DateFormatterクラスのインスタンスを生成。これを使用して日付のフォーマットを指定。
        dateFormatter.dateFormat = "yyyyMMddHHmm" // 日付のフォーマットを設定
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Tokyo") // タイムゾーンを日本標準時に設定

        let currentDateTime = Date() // 現在の日付と時刻を取得
        let calendar = Calendar.current // 現在使用しているカレンダーを取得

        // 15分単位に丸める
        var roundedDateTime: Date! = nil
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: currentDateTime)
        if let roundedMinute = components.minute {
            let roundedDownMinute = roundedMinute - (roundedMinute % 15)
            roundedDateTime = calendar.date(bySettingHour: components.hour!, minute: roundedDownMinute, second: 0, of: currentDateTime)
        }
        
        // 丸められた時刻をpicker初期値として設定
        startTimePicker.date = roundedDateTime
        endTimePicker.date = roundedDateTime.addingTimeInterval(3600) // 丸められた時刻から1時間後
        endTimePicker.minimumDate = roundedDateTime.addingTimeInterval(3600) // 最小時刻を丸められた時刻から1時間後に設定
        
        //現在の時刻を基準にstartTimeStringとendTimeStringの初期値を設定
        startTimeString = dateFormatter.string(from: roundedDateTime)
        endTimeString = dateFormatter.string(from: roundedDateTime.addingTimeInterval(3600))
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let customTabBarController = self.tabBarController as? CustomTabBarController {
            let sharedValueFromTabBar = customTabBarController.sharedValue
            registerScheduleViewControllerValue = sharedValueFromTabBar
        }
        
        if segue.identifier == "GanttChartViewController" {
            if let destinationVC = segue.destination as? GanttChartViewController {
                destinationVC.ganttChartViewControllerValue = registerScheduleViewControllerValue
            }
        }
        
        if segue.identifier == "AdvancedSettingTableViewController" {
            if let destinationVC = segue.destination as? AdvancedSettingTableViewController {
                destinationVC.advancedSettingTableViewControllerValue = registerScheduleViewControllerValue
            }
        }
    }
}
