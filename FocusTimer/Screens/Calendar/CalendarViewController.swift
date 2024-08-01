//
//  CalenderViewController.swift
//  LookIntoMind
//
//  Created by jh on 2023/11/07.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import FSCalendar

class CalendarViewController: UIViewController {
    private let leftBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "arrow_left"), for: .normal)
        btn.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.imageView?.contentMode = .scaleAspectFit
        return btn
    }()
    
    private let rightBtn: UIButton = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "arrow_right"), for: .normal)
        btn.contentEdgeInsets = .init(top: 10, left: 10, bottom: 10, right: 10)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.imageView?.contentMode = .scaleAspectFit
        return btn
    }()
    
    private let calendarView: FSCalendar = {
        let view = FSCalendar()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    private let titleLbl: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.textColor = BaseColor.black
        lbl.font = BaseFont.title2_num
        lbl.text = Date().toString(Date().month)
        lbl.lineBreakMode = .byWordWrapping
        lbl.isUserInteractionEnabled = true
        return lbl
    }()
    
    var currentPage: Date?
    let calendarCurrent = Calendar.current
    let today: Date = Date()
    var dateComponents = DateComponents()
    var records: [DataModel] = []
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    override func viewWillAppear(_ animated: Bool) {
        if self.records.count != LoadData.items.count {
            self.records = LoadData.items
            calendarView.reloadData()
        }
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
extension CalendarViewController {
    private func setUp() {
        configure()
        setCalendar()
        addViews()
        setConstraints()
        bind()
        setCalendar()
    }
    
    private func configure() {
        view.backgroundColor = .white
        
        calendarView.delegate = self
        calendarView.dataSource = self
    }
    
    private func bind() {
        leftBtn.rx.tap
            .subscribe(onNext:{ [weak self] res in
                guard let self else { return }
                self.moveCurrentPage(moveUp: false)
            })
            .disposed(by: disposeBag)
        
        rightBtn.rx.tap
            .subscribe(onNext:{ [weak self] res in
                guard let self else { return }
                self.moveCurrentPage(moveUp: true)
            })
            .disposed(by: disposeBag)
    }
    
    private func addViews() {
        view.addSubview(calendarView)
        view.addSubview(rightBtn)
        view.addSubview(leftBtn)
        view.addSubview(titleLbl)
    }
    
    private func setConstraints() {
        calendarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(422 + 75)
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
            make.centerX.equalToSuperview()
        }
        leftBtn.snp.makeConstraints { make in
            make.width.height.equalTo(14 + 20)
            make.centerX.equalTo(calendarView.calendarHeaderView).offset(-52)
            make.centerY.equalTo(calendarView.calendarHeaderView).offset(4)
        }
        rightBtn.snp.makeConstraints { make in
            make.width.height.equalTo(leftBtn)
            make.centerX.equalTo(calendarView.calendarHeaderView).offset(52)
            make.centerY.equalTo(leftBtn)
        }
        titleLbl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(leftBtn)
        }
    }
}

extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource, UICollectionViewDelegateFlowLayout {
    
    private func moveCurrentPage(moveUp: Bool) {
        dateComponents.month = moveUp ? 1 : -1
        currentPage = calendarCurrent.date(byAdding: dateComponents, to: currentPage ?? today)
        self.calendarView.setCurrentPage(currentPage!, animated: true)
        
    }
    
    private func setCalendar() {
        calendarView.register(CalendarCollectionViewCell.self, forCellReuseIdentifier: CalendarCollectionViewCell.cellId)
        calendarView.locale = Locale.current
        calendarView.headerHeight = 44
        calendarView.adjustsBoundingRectWhenChangingMonths = true
        calendarView.appearance.headerMinimumDissolvedAlpha = 0.0
//        calendarView.appearance.headerDateFormat = "YYYY.MM"
        calendarView.appearance.headerDateFormat = ""
        calendarView.appearance.headerTitleColor = BaseColor.black
        calendarView.appearance.headerTitleFont = BaseFont.title2_num
        
        calendarView.appearance.titleSelectionColor = BaseColor.gray4
        calendarView.appearance.todayColor = UIColor.clear
        calendarView.appearance.selectionColor = UIColor.clear
        
        calendarView.appearance.weekdayFont = BaseFont.body2
        calendarView.appearance.weekdayTextColor = BaseColor.gray3
        
        calendarView.appearance.titleSelectionColor = UIColor.clear
        calendarView.appearance.titleDefaultColor = UIColor.clear
        calendarView.appearance.titleWeekendColor = UIColor.clear
        calendarView.appearance.titleTodayColor = UIColor.clear
        calendarView.appearance.titleFont = BaseFont.body2_num
        calendarView.placeholderType = .none
        calendarView.reloadData()
    }
    
    func calendar(_ calendar: FSCalendar, cellFor date: Date, at position: FSCalendarMonthPosition) -> FSCalendarCell {
        
        guard let cell = calendar.dequeueReusableCell(withIdentifier: CalendarCollectionViewCell.cellId, for: date, at: position) as? CalendarCollectionViewCell else { return FSCalendarCell() }
        cell.configure(with: self.records, date: date)
        return cell
    }
    
    func calendar(_ calendar: FSCalendar, boundingRectWillChange bounds: CGRect, animated: Bool) {
        calendar.snp.updateConstraints { (make) in
            make.height.equalTo(bounds.height)
            // Do other updates
        }
        self.view.layoutIfNeeded()
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        titleLbl.text = calendar.currentPage.month
    }
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
    
        guard let selectedData = records.filter({$0.date.summary == date.summary}).first else {
            return
        }
    }
}
