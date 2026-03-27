
import UIKit

class CustomTabBarController: UITabBarController {
    
    public var sharedValue = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.selectedIndex = 1//初めに表示
    }



}
