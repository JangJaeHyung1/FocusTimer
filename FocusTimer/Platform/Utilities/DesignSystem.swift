
import UIKit

struct BaseColor {
    static let black = UIColor.rgba(0, 0, 0, 1)
    static let white = UIColor.rgba(255, 255, 255, 1)
    
    static let gray1 = UIColor.rgba(34, 34, 34, 1)
    static let gray2 = UIColor.rgba(68, 68, 68, 1)
    static let gray3 = UIColor.rgba(136, 136, 136, 1)
    static let gray4 = UIColor.rgba(189, 189, 189, 1)
    static let gray5 = UIColor.rgba(221, 221, 221, 1)
    static let gray6 = UIColor.rgba(233, 233, 233, 1)
    static let gray7 = UIColor.rgba(243, 243, 243, 1)
    
}

struct BaseFont {
    static let title1 = UIFont.customFont(ofSize: 24, weight: .bold, lineHeight: 0)
    static let title1_sub = UIFont.customFont(ofSize: 21, weight: .bold, lineHeight: 30)
    static let title2 = UIFont.customFont(ofSize: 16, weight: .bold, lineHeight: 24)
    static let title2_num = UIFont.customFont(ofSize: 16, weight: .bold, lineHeight: 24)
    
    static let body1 = UIFont.customFont(ofSize: 18, weight: .bold, lineHeight: 24)
    
    static let body2 = UIFont.customFont(ofSize: 16, weight: .medium, lineHeight: 24)
    static let body2_long = UIFont.customFont(ofSize: 16, weight: .medium, lineHeight: 28)
    static let body2_num = UIFont.customFont(ofSize: 16, weight: .light, lineHeight: 24)
    
    static let body3 = UIFont.customFont(ofSize: 14, weight: .bold, lineHeight: 20)
    static let body4 = UIFont.customFont(ofSize: 14, weight: .medium, lineHeight: 20)
    static let body4_num = UIFont.customFont(ofSize: 14, weight: .medium, lineHeight: 20)
    
}
