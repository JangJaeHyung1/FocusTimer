//
//  NativeAdView.swift
//  FocusTimer
//
//  Created by jh on 2/10/25.
//

import GoogleMobileAds
import UIKit
import SnapKit

class NativeAdView: GADNativeAdView {
    
    private let headlineLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.numberOfLines = 2
        return label
    }()
    
    private let bodyLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 3
        label.textColor = .black
        return label
    }()
    
    private let advertiserLabel: UILabel = {
        let label = UILabel()
        label.font = .italicSystemFont(ofSize: 12)
        label.textColor = .black
        return label
    }()
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        return imageView
    }()
    
//    private let media: GADMediaView = {
//        let view = GADMediaView()
//        view.contentMode = .scaleAspectFill
//        view.clipsToBounds = true
//        return view
//    }()
    
    private let callToActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .boldSystemFont(ofSize: 14)
        button.backgroundColor = .clear
        button.setTitle("", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.systemGray6
        layer.cornerRadius = 10
        setupViews()
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(iconImageView)
        addSubview(headlineLabel)
        addSubview(bodyLabel)
//        addSubview(media)
        addSubview(callToActionButton)
//        addSubview(advertiserLabel)
        
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
//        media.translatesAutoresizingMaskIntoConstraints = false
        callToActionButton.translatesAutoresizingMaskIntoConstraints = false
//        advertiserLabel.translatesAutoresizingMaskIntoConstraints = false
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalToSuperview().offset(10)
            make.width.height.equalTo(40)
        }
        
        headlineLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.equalTo(iconImageView.snp.trailing).offset(10)
            make.trailing.equalToSuperview().offset(-10)
        }
        
        bodyLabel.snp.makeConstraints { make in
            make.top.equalTo(headlineLabel.snp.bottom).offset(5)
            make.leading.trailing.equalTo(headlineLabel)
        }

//            media.snp.makeConstraints { make in
//                make.top.equalTo(bodyLabel.snp.bottom).offset(10)
//                make.leading.equalToSuperview().offset(10)
//                make.trailing.equalToSuperview().offset(-10)
//                make.height.equalTo(150)
//            }

//            advertiserLabel.snp.makeConstraints { make in
//                make.top.equalTo(media.snp.bottom).offset(5)
//                make.leading.equalToSuperview().offset(10)
//            }

            callToActionButton.snp.makeConstraints { make in
                make.top.equalToSuperview()
                make.leading.equalToSuperview()
                make.trailing.equalToSuperview()
                make.height.equalTo(40)
                make.bottom.equalToSuperview()
            }
        
        // 광고 요소 등록
        self.headlineView = headlineLabel
        self.bodyView = bodyLabel
        self.advertiserView = advertiserLabel
        self.iconView = iconImageView
//        self.mediaView = mediaView
        self.callToActionView = callToActionButton
    }
    
    func configure(with nativeAd: GADNativeAd) {
        headlineLabel.text = nativeAd.headline
        bodyLabel.text = nativeAd.body
//        advertiserLabel.text = nativeAd.advertiser

        if let icon = nativeAd.icon {
            iconImageView.image = icon.image
        } else {
            iconImageView.isHidden = true
        }

        mediaView?.mediaContent = nativeAd.mediaContent
        callToActionButton.isHidden = nativeAd.callToAction == nil
    }
}
