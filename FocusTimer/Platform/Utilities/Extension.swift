//
//  Extension.swift
//  FocusTimer
//
//  Created by jh on 2023/11/06.
//

import UIKit

extension UIView {
    func setShadow(radius: CGFloat = 2, opacity: Float = 0.1, x: Int = 2, y: Int = 2) {
       
       layer.shadowColor = UIColor.gray.cgColor
       layer.masksToBounds = false
       layer.shadowOffset = CGSize(width: x, height: y)
       
       layer.shadowPath = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius).cgPath
       layer.shadowRadius = radius
       layer.shadowOpacity = Float(opacity)
  }
}

extension UIImage
{
  func resizedImage(Size sizeImage: CGSize) -> UIImage?
  {
      let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: sizeImage.width, height: sizeImage.height))
      UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
      self.draw(in: frame)
      let resizedImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      self.withRenderingMode(.alwaysOriginal)
      return resizedImage
  }
}

extension CALayer {
    func addBorder(_ arr_edge: [UIRectEdge], color: UIColor, width: CGFloat) {
        for edge in arr_edge {
            let border = CALayer()
            switch edge {
            case UIRectEdge.top:
                border.frame = CGRect.init(x: 0, y: 0, width: frame.width, height: width)
                break
            case UIRectEdge.bottom:
                border.frame = CGRect.init(x: 0, y: frame.height - width, width: frame.width, height: width)
                break
            case UIRectEdge.left:
                border.frame = CGRect.init(x: 0, y: 0, width: width, height: frame.height)
                break
            case UIRectEdge.right:
                border.frame = CGRect.init(x: frame.width - width, y: 0, width: width, height: frame.height)
                break
            default:
                break
            }
            border.backgroundColor = color.cgColor;
            self.addSublayer(border)
        }
    }
}

extension CALayer {
    // Sketch 스타일의 그림자를 생성하는 유틸리티 함수
    func applyShadow(
        color: UIColor = .black,
        alpha: Float = 0.5,
        x: CGFloat = 0,
        y: CGFloat = 2,
        blur: CGFloat = 4
    ) {
        shadowColor = color.cgColor
        shadowOpacity = alpha
        shadowOffset = CGSize(width: x, height: y)
        shadowRadius = blur / 2.0
    }
}

extension UITabBar {
    // 기본 그림자 스타일을 초기화해야 커스텀 스타일을 적용할 수 있다.
    static func clearShadow() {
        UITabBar.appearance().shadowImage = UIImage()
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().backgroundColor = .white
    }
}

extension UILabel {
    // 행간
    static func lblSpacing(lbl: UILabel, spacing: CGFloat) -> UILabel{
        let attrString = NSMutableAttributedString(string: lbl.text!)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lbl.bounds.width * 0.3 * -1
        attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, attrString.length))
        lbl.attributedText = attrString
        return lbl
    }
    
    // 자간
    func addCharacterSpacing(_ value: Double = -0.03) {
        let kernValue = self.font.pointSize * CGFloat(value)
        guard let text = text, !text.isEmpty else { return }
        let string = NSMutableAttributedString(string: text)
        string.addAttribute(NSAttributedString.Key.kern, value: kernValue, range: NSRange(location: 0, length: string.length - 1))
        attributedText = string
    }
    
//    func addCharacterSpacing(kernValue:Double = 0.5) {
//        guard let text = text, !text.isEmpty else { return }
//        let string = NSMutableAttributedString(string: text)
//        string.addAttribute(NSAttributedString.Key.kern, value: kernValue, range: NSRange(location: 0, length: string.length - 1))
//        attributedText = string
//    }
}

extension UITextView {
    func addCharacterSpacing(_ value: Double = -0.03) {
        let kernValue = self.font!.pointSize * CGFloat(value)
        guard let text = text, !text.isEmpty else { return }
        let string = NSMutableAttributedString(string: text)
        string.addAttribute(NSAttributedString.Key.kern, value: kernValue, range: NSRange(location: 0, length: string.length - 1))
        attributedText = string
    }
}

extension UITextField {
    func addCharacterSpacing(_ value: Double = -0.03) {
        let kernValue = self.font!.pointSize * CGFloat(value)
        guard let text = text, !text.isEmpty else { return }
        let string = NSMutableAttributedString(string: text)
        string.addAttribute(NSAttributedString.Key.kern, value: kernValue, range: NSRange(location: 0, length: string.length - 1))
        attributedText = string
    }
}

extension UIViewController {
    func back(page: Int) {
        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
        self.navigationController!.popToViewController(viewControllers[viewControllers.count - page], animated: true)
    }
    
    func hideTextFieldKeyboardWhenTappedBackground() {
        let tapEvent = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapEvent.cancelsTouchesInView = false
        view.addGestureRecognizer(tapEvent)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func createSpinnerView() -> UIView {
        let spinnerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 100))
        
        let spinner = UIActivityIndicatorView()
        spinner.center = spinnerView.center
        spinnerView.addSubview(spinner)
        spinner.startAnimating()
        
        return spinnerView
    }
}


open class CustomLabel : UILabel {
    @IBInspectable open var characterSpacing:CGFloat = 1 {
        didSet {
            let attributedString = NSMutableAttributedString(string: self.text!)
            attributedString.addAttribute(NSAttributedString.Key.kern, value: self.characterSpacing, range: NSRange(location: 0, length: attributedString.length))
            self.attributedText = attributedString
        }

    }
}

extension UIColor {
    static var rgba: (Int, Int, Int, CGFloat) -> UIColor {
        return { red, green, blue, alpha in
            let clampedRed = CGFloat(max(0, min(255, red))) / 255.0
            let clampedGreen = CGFloat(max(0, min(255, green))) / 255.0
            let clampedBlue = CGFloat(max(0, min(255, blue))) / 255.0
            return UIColor(red: clampedRed, green: clampedGreen, blue: clampedBlue, alpha: alpha)
        }
    }
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xFF,
            green: (rgb >> 8) & 0xFF,
            blue: rgb & 0xFF
        )
    }
}


// 행간
extension UILabel {
    func setLineSpacing(spacing: CGFloat) {
        guard let text = text else { return }

        let attributeString = NSMutableAttributedString(string: text)
        let style = NSMutableParagraphStyle()
        style.lineSpacing = spacing
        attributeString.addAttribute(.paragraphStyle,
                                     value: style,
                                     range: NSRange(location: 0, length: attributeString.length))
        attributedText = attributeString
    }
}

// 행간
extension UILabel {
    func setLineSpacing(ratio: Double) {
        let style = NSMutableParagraphStyle()
        let lineheight = self.font.pointSize * ratio  //font size * multiple
        style.minimumLineHeight = lineheight
        style.maximumLineHeight = lineheight

        self.attributedText = NSAttributedString(
            string: self.text ?? "", attributes: [
            .paragraphStyle: style
          ])
    }
}

extension UITextView {
    func setLineSpacing(lineSpacing: CGFloat) {
        // Get the existing attributed text from the UITextView
        guard let existingAttributedString = self.attributedText else {
            return
        }
        // Create a mutable copy of the existing attributed text
        let mutableAttributedString = NSMutableAttributedString(attributedString: existingAttributedString)
        // Create a paragraph style with the desired line spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        // Set the paragraph style for the entire text
        mutableAttributedString.addAttribute(NSAttributedString.Key.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, mutableAttributedString.length))
        // Set the updated attributed text to the UITextView
        self.attributedText = mutableAttributedString
    }
}


extension UIFont {
    static func customFont(ofSize fontSize: CGFloat, weight: UIFont.Weight, lineHeight: CGFloat) -> UIFont {
        let font = UIFont.systemFont(ofSize: fontSize, weight: weight)
        let lineHeightMultiple = lineHeight / font.lineHeight

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle
        ]

        return UIFont(descriptor: font.fontDescriptor, size: fontSize).withTraits(traits: .traitBold)
    }
}

extension UIFont {
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(traits)
        return UIFont(descriptor: descriptor!, size: 0)
    }
}

extension UITableView {
    func lastIndexpath() -> IndexPath {
        let section = max(numberOfSections - 1, 0)
        let row = max(numberOfRows(inSection: section) - 1, 0)

        return IndexPath(row: row, section: section)
    }
}

extension Date {
  // MARK: - 기본 & 짧은 날짜 표시
  public var main: String {
    return toString("MM.dd EEEE")
  }
    
  // Realm Data key
  public var summary: String {
    return toString("yyyy.MM.dd")
  }
    public var day: String {
        return toString("d")
    }
    
    public var month: String {
        return toString("yyyy.MM")
    }
  
  // MARK: - 요일 포함 날짜 표시
  public var basicWithDay: String {
    return toString("yyyy년 M월 d일 (EEEEE)")
  }
  
  // MARK: - 시간 표시
  public var timeWithoutSecond: String {
    return toString("a h시 m분")
  }
  public var timeWithSecond: String {
    return toString("a h시 m분 s초")
  }
  public var shortTimeWithoutSecond: String {
    return toString("HH:mm")
  }
  public var shortTimeWithSecond: String {
    return toString("HH:mm:ss")
  }
  
  // MARK: - 시간 포함 짧은 날짜 표시
  public var summaryWithTimeWithoutSecond: String {
    return toString("yyyy-MM-dd HH:mm")
  }
  public var summaryWithTimeWithSecond: String {
    return toString("yyyy-MM-dd HH:mm:ss")
  }
  
  // MARK: - 요일 & 시간 포함 기본 날짜 표시
  public var basicWithDayAndTimeWithoutSecond: String {
    return toString("yyyy년 M월 d일 (EEEEE) a h시 m분")
  }
  public var basicWithDayAndTimeWithSecond: String {
    return toString("yyyy년 M월 d일 (EEEEE) a h시 m분 s초")
  }
  
  // MARK: - Date -> String
  public func toString(_ dateFormat: String) -> String {
    return DateFormatter
      .convertToKoKR(dateFormat: dateFormat)
      .string(from: self)
  }
}

extension DateFormatter {
    public static func convertToKoKR(dateFormat: String) -> DateFormatter {
        let dateFormatter = createKoKRFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter
    }
}

private func createKoKRFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.timeZone = TimeZone(abbreviation: "KST")
    return dateFormatter
}

extension String {
    
    var localized: String {
        return NSLocalizedString(self, tableName: "Localizable", value: self, comment: "")
    }
    
    func localizedFormat(_ arguments: CVarArg...) -> String {
        let localizedValue = self.localized
        return String(format: localizedValue, arguments: arguments)
    }
}

