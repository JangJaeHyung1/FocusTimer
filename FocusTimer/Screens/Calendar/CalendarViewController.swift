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

    private let currentWeekFocusTimeLabel = CalendarViewController.makeSummaryLabel()
    private let monthFocusTimeLabel = CalendarViewController.makeSummaryLabel()

    private let summaryContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var summaryStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            currentWeekFocusTimeLabel,
            monthFocusTimeLabel
        ])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        stackView.spacing = 6
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let calendarCurrent = Calendar.current
    var records: [DataModel] = []
    private var calendarHeightConstraint: Constraint?
    private var recordsLoadedSuccessfully = false
    private var rankingResults: [FocusRankingResult] = []
    private var rankingTask: Task<Void, Never>?
    
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
        do {
            records = try RealmAPI.shared.load()
            LoadData.items = records
            recordsLoadedSuccessfully = true
        } catch {
            records = LoadData.items
            recordsLoadedSuccessfully = false
            debugPrint("❌ Calendar Realm load error: \(error.localizedDescription)")
        }
        rankingResults = []
        updateFocusTimeSummaries()
        DispatchQueue.main.async {
            self.calendarView.reloadData()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        rankingTask?.cancel()
    }
    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

}
extension CalendarViewController {
    private static func makeSummaryLabel() -> UILabel {
        let label = UILabel()
        label.textColor = BaseColor.black
        label.font = BaseFont.body4
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }

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
        view.addSubview(summaryContainerView)
        summaryContainerView.addSubview(summaryStackView)
    }
    
    private func setConstraints() {
        calendarView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            calendarHeightConstraint = make.height.equalTo(422 + 75).priority(.high).constraint
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(10)
            make.bottom.lessThanOrEqualTo(summaryContainerView.snp.top).offset(-12)
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
        summaryContainerView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-8)
        }
        summaryStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
        }
    }

    private func updateFocusTimeSummaries(
        now: Date = Date(),
        requestDelayNanoseconds: UInt64 = 0
    ) {
        let displayedMonth = calendarView.currentPage
        let isCurrentMonth = FocusSummaryCalculator.isSameMonth(displayedMonth, now)
        let monthSummary = FocusSummaryCalculator.month(
            containing: displayedMonth,
            records: records
        )
        let weekSummary = isCurrentMonth
            ? FocusSummaryCalculator.currentWeek(records: records, now: now)
            : nil

        currentWeekFocusTimeLabel.isHidden = !isCurrentMonth

        if let weekSummary {
            currentWeekFocusTimeLabel.text = summaryText(
                localizationKey: "current_week_total_focus_time",
                summary: weekSummary
            )
            monthFocusTimeLabel.text = summaryText(
                localizationKey: "current_month_total_focus_time",
                summary: monthSummary
            )
        } else {
            monthFocusTimeLabel.text = summaryText(
                localizationKey: "displayed_month_total_focus_time",
                summary: monthSummary
            )
        }

        rankingTask?.cancel()
        guard recordsLoadedSuccessfully else { return }

        let summaries: [FocusPeriodSummary]
        if let weekSummary {
            summaries = [weekSummary, monthSummary]
        } else if FocusSummaryCalculator.isWithinLatestTwelveMonths(displayedMonth, now: now) {
            summaries = [monthSummary]
        } else {
            return
        }

        let expectedMonthKey = monthSummary.periodKey
        rankingTask = Task { [weak self] in
            do {
                let cacheLookup = await FocusRankingService.shared.cachedLookup(
                    for: summaries,
                    now: now
                )
                try Task.checkCancellation()

                if let self {
                    let visibleMonthKey = FocusSummaryCalculator.month(
                        containing: self.calendarView.currentPage,
                        records: self.records
                    ).periodKey
                    guard visibleMonthKey == expectedMonthKey else { return }
                    self.rankingResults = cacheLookup.results
                    self.renderFocusTimeSummaries(now: now)
                }

                guard cacheLookup.requiresSync else { return }
                if requestDelayNanoseconds > 0 {
                    try await Task.sleep(nanoseconds: requestDelayNanoseconds)
                }
                try Task.checkCancellation()
                let results = try await FocusRankingService.shared.sync(summaries)
                try Task.checkCancellation()
                guard let self else { return }
                let visibleMonthKey = FocusSummaryCalculator.month(
                    containing: self.calendarView.currentPage,
                    records: self.records
                ).periodKey
                guard visibleMonthKey == expectedMonthKey else { return }
                self.rankingResults = results
                self.renderFocusTimeSummaries(now: now)
            } catch is CancellationError {
                return
            } catch SupabaseClientError.notConfigured {
                return
            } catch {
                debugPrint("❌ Focus ranking sync error: \(error.localizedDescription)")
            }
        }
    }

    private func renderFocusTimeSummaries(now: Date) {
        let displayedMonth = calendarView.currentPage
        let isCurrentMonth = FocusSummaryCalculator.isSameMonth(displayedMonth, now)
        let monthSummary = FocusSummaryCalculator.month(
            containing: displayedMonth,
            records: records
        )

        if isCurrentMonth {
            let weekSummary = FocusSummaryCalculator.currentWeek(records: records, now: now)
            currentWeekFocusTimeLabel.text = summaryText(
                localizationKey: "current_week_total_focus_time",
                summary: weekSummary
            )
            monthFocusTimeLabel.text = summaryText(
                localizationKey: "current_month_total_focus_time",
                summary: monthSummary
            )
        } else {
            monthFocusTimeLabel.text = summaryText(
                localizationKey: "displayed_month_total_focus_time",
                summary: monthSummary
            )
        }
    }

    private func summaryText(
        localizationKey: String,
        summary: FocusPeriodSummary
    ) -> String {
        let baseText = localizationKey.localizedFormat(formatFocusHours(summary.totalSeconds))
        guard
            let ranking = rankingResults.first(where: {
                $0.periodType == summary.periodType && $0.periodKey == summary.periodKey
            }),
            let rankingText = ranking.localizedText
        else { return baseText }

        return "\(baseText) · \(rankingText)"
    }

    private func formatFocusHours(_ seconds: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .halfUp

        let hours = Double(seconds) / 3600
        let formattedHours = formatter.string(from: NSNumber(value: hours)) ?? "0"
        return "focus_duration_format".localizedFormat(formattedHours)
    }
}

extension CalendarViewController: FSCalendarDelegate, FSCalendarDataSource, UICollectionViewDelegateFlowLayout {
    
    private func moveCurrentPage(moveUp: Bool) {
        var dateComponents = DateComponents()
        dateComponents.month = moveUp ? 1 : -1

        guard let targetPage = calendarCurrent.date(
            byAdding: dateComponents,
            to: calendarView.currentPage
        ) else { return }

        calendarView.setCurrentPage(targetPage, animated: true)
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
        calendarHeightConstraint?.update(offset: bounds.height)
        self.view.layoutIfNeeded()
    }
    
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        titleLbl.text = calendar.currentPage.month
        updateFocusTimeSummaries(requestDelayNanoseconds: 350_000_000)
    }
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
    
        guard let selectedData = records.filter({$0.date.summary == date.summary}).first else {
            return
        }
    }
}
