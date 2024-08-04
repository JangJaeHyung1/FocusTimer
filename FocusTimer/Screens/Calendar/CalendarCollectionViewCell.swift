//
//  CalendarCollectionViewCell.swift
//  LookIntoMind
//
//  Created by jh on 2023/11/15.
//

import FSCalendar
import UIKit
import RxSwift
import RxCocoa
import SnapKit

class CalendarCollectionViewCell: FSCalendarCell {
    var disposeBag = DisposeBag()
    static let cellId = "CalendarCollectionViewCell"
    
    private let backImageView: UIImageView = {
        let img = UIImageView()
        img.translatesAutoresizingMaskIntoConstraints = false
        img.isUserInteractionEnabled = true
        img.contentMode = .scaleAspectFit
        return img
    }()
    private let dateLbl: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 1
        lbl.textColor = BaseColor.gray4
        lbl.lineBreakMode = .byWordWrapping
        lbl.font = BaseFont.body2_num
        lbl.isUserInteractionEnabled = true
        return lbl
    }()
    
    private let timeLblBGView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    private let timeLbl: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 1
        lbl.textColor = .black
        lbl.textAlignment = .center
        lbl.font = .systemFont(ofSize: 14)
        lbl.lineBreakMode = .byWordWrapping
        lbl.text = ""
        lbl.isUserInteractionEnabled = true
        return lbl
    }()
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.backImageView.image = nil
        disposeBag = DisposeBag()
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        //        cellView.setShadow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //        cellView.setShadow()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    private func setupView() {
//        contentView.insertSubview(backImageView, at: 0)
        addSubview(backImageView)
        addSubview(dateLbl)
        addSubview(timeLblBGView)
        addSubview(timeLbl)
        
        setConstraints()
    }
    
    private func setConstraints() {
        timeLblBGView.snp.makeConstraints { make in
            make.width.equalTo(timeLbl).offset(10)
            make.height.equalTo(timeLbl).offset(4)
            make.center.equalTo(timeLbl)
        }
        timeLbl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(dateLbl.snp.bottom).offset(8)
        }
        backImageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        dateLbl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-14)
        }
    }
    func configure(with presentables: [DataModel], date: Date) {
        dateLbl.text = date.toString(date.day)
        dateLbl.font = BaseFont.body2_num
        let isToday = Date().summary == date.summary
        let record = presentables.filter({$0.date.summary == date.summary}).first
        if let presentable = record {
            // 데이터가 있을때
            timeLbl.isHidden = false
            timeLblBGView.isHidden = false
//            setTimeLblBGView(second: presentable.seconds)
            timeLbl.text = TimeConvertion.shared.convertMinute(seconds: presentable.seconds)
            if isToday {
                dateLbl.textColor = BaseColor.black
                dateLbl.font = BaseFont.title2_num
            } else {
                dateLbl.textColor = BaseColor.black
            }
        } else {
            timeLbl.isHidden = true
            timeLblBGView.isHidden = true
            if isToday {
                dateLbl.textColor = BaseColor.black
                dateLbl.font = BaseFont.title2_num
            } else {
                dateLbl.textColor = BaseColor.gray4
            }
        }
    }
    // 0~3 1시
    // 3~5 4시
    // 5~8 6 시
    // 8~12 9
    // 12+ 13시간
//    private func setTimeLblBGView(second: Int) {
//        if second < 3600 * 3 {
//            timeLbl.textColor = BaseColor.black
//            timeLblBGView.backgroundColor = .systemGray6
//        } else if second <  3600 * 5 {
//            timeLbl.textColor = BaseColor.black
//            timeLblBGView.backgroundColor = .systemGray4
//        } else if second <  3600 * 8 {
//            timeLbl.textColor = BaseColor.black
//            timeLblBGView.backgroundColor = .systemGray2
//        } else if second <  3600 * 12 {
//            timeLbl.textColor = BaseColor.black
//            timeLblBGView.backgroundColor = .systemGray
//        } else {
//            timeLbl.textColor = .white
//            timeLblBGView.backgroundColor = .darkGray
//        }
//    }
}
