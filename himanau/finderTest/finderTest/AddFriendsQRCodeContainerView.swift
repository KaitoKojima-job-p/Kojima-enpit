import UIKit
import CoreImage

class AddFriendsQRCodeContainerView: UIViewController {
    
    @IBOutlet weak var qrCodeImageView: UIImageView!
    
    var addFriendsQRCodeViewControllerValue = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        generateAndDisplayQRCode()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "QRCodeScannerViewController" {
            let next = segue.destination as? QRCodeScannerViewController
            next?.QRCodeScannerViewControllerValue = addFriendsQRCodeViewControllerValue
        }
    }
    
    func generateAndDisplayQRCode() {
        // CIQRCodeGeneratorを使用してQRコードのCIImageを生成
        if let qrCodeFilter = CIFilter(name: "CIQRCodeGenerator") {
            if let data = addFriendsQRCodeViewControllerValue.data(using: String.Encoding.ascii) {
                qrCodeFilter.setValue(data, forKey: "inputMessage")
                
                // Correction levelの設定（L、M、Q、H）
                qrCodeFilter.setValue("Q", forKey: "inputCorrectionLevel")
                
                if let qrCodeCIImage = qrCodeFilter.outputImage {
                    let qrCodeImageViewSize = qrCodeImageView.frame.size
                    let qrCodeSize = qrCodeImageViewSize
                    let scaledQRCodeCIImage = qrCodeCIImage.transformed(by: CGAffineTransform(scaleX: qrCodeSize.width / qrCodeCIImage.extent.width, y: qrCodeSize.height / qrCodeCIImage.extent.height))
                    
                    // CIImageからUIImageに変換
                    let context = CIContext()
                    if let cgImage = context.createCGImage(scaledQRCodeCIImage, from: scaledQRCodeCIImage.extent) {
                        let qrCodeImage = UIImage(cgImage: cgImage)
                        
                        // 生成したQRコードの画像をUIImageViewにセット
                        qrCodeImageView.image = qrCodeImage
                    }
                }
            }
        }
    }
}
