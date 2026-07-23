

import UIKit
import SnapKit
import RxSwift
import StoreKit

class MainViewController: UIViewController {
    private var circularSlider = CircularSlider()
    private var soundModule = SoundModule()
    var seconds: Int = 0
    var recordData: Int = 0
    var timer: Timer?
    var goBackgroundTime: Date = Date()
    var goForegroundTime: Date = Date()
    var gapTime: Int = 0
    private var isCompletingSession = false
    private let disposeBag = DisposeBag()
    private let centerCircle: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    private let btn: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "start".localized
        config.baseBackgroundColor = .black
        config.background.cornerRadius = 11
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 14, weight: .bold)
                return outgoing
            }
        let btn = UIButton(configuration: config)
        btn.isEnabled = false
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let resumeBtn: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "resume".localized
        config.baseBackgroundColor = .white
        config.baseForegroundColor = .black
        config.background.cornerRadius = 11
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 14, weight: .bold)
                return outgoing
            }
        let btn = UIButton(configuration: config)
        btn.layer.borderWidth = 2
        btn.layer.cornerRadius = 11
        btn.setTitleColor(.black, for: .normal)
        btn.isHidden = true
        btn.layer.borderColor = UIColor.black.cgColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let resetBtn: UIButton = {
        var config = UIButton.Configuration.filled()
        config.title = "reset".localized
        config.baseBackgroundColor = .black
        config.background.cornerRadius = 11
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 14, weight: .bold)
                return outgoing
            }
        let btn = UIButton(configuration: config)
        btn.isHidden = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let timeLbl: UILabel = {
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.numberOfLines = 1
        lbl.textAlignment = .center
        lbl.font = .monospacedDigitSystemFont(ofSize: 48, weight: .ultraLight)
        lbl.textColor = .darkGray
        lbl.lineBreakMode = .byWordWrapping
        lbl.isHidden = true
        lbl.text = ""
        lbl.isUserInteractionEnabled = true
        return lbl
    }()
    
    private let timeView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateCircleColor(_:)),
                                         name: Notification.Name("selectedIndex"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateTimeLbl(_:)),
                                         name: Notification.Name("sw1"), object: nil)
        setCircleColor()
        bind()
        if let records = fetch() {
            syncCurrentFocusSummaries(records: records)
        }
        view.backgroundColor = .white
        circularSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circularSlider)
        view.addSubview(btn)
        view.addSubview(resumeBtn)
        view.addSubview(resetBtn)
        view.addSubview(timeView)
        timeView.addSubview(timeLbl)
        view.addSubview(centerCircle)
        circularSlider.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(42)
            make.trailing.equalToSuperview().offset(-42)
            make.height.equalTo(circularSlider.snp.width)
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(42)
        }
        timeView.snp.makeConstraints { make in
            make.top.equalTo(circularSlider.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(btn.snp.top)
        }
        timeLbl.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        let hasNotch = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 > 0
        
        let btnBottomPadding = ( 138 / 812 ) * UIScreen.main.bounds.height
        btn.snp.makeConstraints { make in
            make.width.equalTo(108)
            make.height.equalTo(64)
            make.centerX.equalToSuperview()
            if hasNotch {
                make.bottom.equalToSuperview().offset(-btnBottomPadding)
            } else {
                make.bottom.equalToSuperview().offset(-10)
            }
        }
        resumeBtn.snp.makeConstraints { make in
            make.trailing.equalTo(view.snp.centerX).offset(-20)
            make.width.height.equalTo(btn)
            make.centerY.equalTo(btn)
        }
        
        resetBtn.snp.makeConstraints { make in
            make.leading.equalTo(view.snp.centerX).offset(20)
            make.width.height.equalTo(btn)
            make.centerY.equalTo(btn)
        }
        
        centerCircle.snp.makeConstraints { make in
            make.center.equalTo(circularSlider)
            make.width.height.equalTo(16)
        }
        
        circularSlider.addTarget(self, action: #selector(sliderValueChanged(_:)), for: .valueChanged)
        circularSlider.addTarget(self, action: #selector(sliderEditingDidEnd(_:)), for: .editingDidEnd)
        btn.addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
        circularSlider.setValue(0.026)
        restorePersistedTimerIfNeeded()
    }
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if UIDevice.current.orientation.rawValue != 2 {
            updateLayout()
        }
    }
    private func updateLayout() {
        timeView.snp.removeConstraints()
        circularSlider.snp.removeConstraints()
        let hasNotch = UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0 > 0
        let isLandscape = UIScreen.main.bounds.width > UIScreen.main.bounds.height
        NotificationCenter.default.post(name: Notification.Name("ToggleTabBar"), object: isLandscape)
        timeView.snp.remakeConstraints { make in
            if isLandscape {
                make.centerY.equalToSuperview().offset(-60)
                make.leading.equalTo(circularSlider.snp.trailing).offset(40) // 여백 추가
                make.trailing.equalToSuperview().offset(-40) // 우측 여백
            } else {
                make.top.equalTo(circularSlider.snp.bottom).offset(10)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(btn.snp.top)
            }
        }
        
        let padding: CGFloat = isLandscape ? 40 : 42
        
        circularSlider.snp.remakeConstraints { make in
            if isLandscape {
                
                if hasNotch {
                    make.leading.equalToSuperview().offset(padding + 60)
                } else {
                    make.leading.equalToSuperview().offset(padding + 16)
                }
                make.centerY.equalToSuperview()
                make.width.equalTo(view.snp.height).multipliedBy(0.7)
                make.height.equalTo(view.snp.height).multipliedBy(0.7)
                
//                make.bottom.equalToSuperview().offset(-60)
            } else {
                make.leading.equalToSuperview().offset(42)
                make.trailing.equalToSuperview().offset(-42)
                make.centerX.equalToSuperview()
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(42)
                make.height.equalTo(circularSlider.snp.width).multipliedBy(1.0)
            }
        }
        
        

        btn.snp.remakeConstraints { make in
            if isLandscape {
                make.centerX.equalTo(timeView) // 오른쪽 영역에서 중앙 정렬
                make.top.equalTo(timeView.snp.bottom).offset(80)
            } else {
                let btnBottomPadding = 138 / 812 * UIScreen.main.bounds.height
                make.centerX.equalToSuperview()
                if hasNotch {
                    make.bottom.equalToSuperview().offset(-btnBottomPadding)
                } else {
                    make.bottom.equalToSuperview().offset(-80)
                }
                
            }
            make.width.equalTo(108)
            make.height.equalTo(64)
        }
        
        resumeBtn.snp.remakeConstraints { make in
            if isLandscape {
                make.trailing.equalTo(btn.snp.leading).offset(5)
                make.centerY.equalTo(btn)
            } else {
                make.trailing.equalTo(view.snp.centerX).offset(-20)
                make.centerY.equalTo(btn)
            }
            make.width.height.equalTo(btn)
        }
        
        resetBtn.snp.remakeConstraints { make in
            if isLandscape {
                make.leading.equalTo(btn.snp.trailing).offset(-5)
                make.centerY.equalTo(btn)
            } else {
                make.leading.equalTo(view.snp.centerX).offset(20)
                make.centerY.equalTo(btn)
            }
            make.width.height.equalTo(btn)
        }

        centerCircle.snp.remakeConstraints { make in
            make.center.equalTo(circularSlider)
            make.width.height.equalTo(16)
        }
    
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    @objc func updateCircleColor(_ notification: Notification) {
        guard let index = notification.object as? Int else { return }
        circularSlider.setColor(color: SetColors(rawValue: index) ?? .red)
    }
    
    @objc func updateTimeLbl(_ notification: Notification) {
        guard let visible = notification.object as? Bool else { return }
        guard let timer = timer else { return }
        if timer.isValid {
            timeLbl.isHidden = !visible
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerCircle.setShadow()
    }
    
    private func setCircleColor() {
        let selectedIdx: Int = UserDefaults.standard.object(forKey: "selectedIndex") as? Int ?? 0
        circularSlider.setColor(color: SetColors(rawValue: selectedIdx) ?? .red)
    }
    
    private func bind() {
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(
            self,
            selector: #selector(focusTimerNotificationOpened),
            name: .focusTimerNotificationOpened,
            object: nil
        )
        
        resumeBtn.rx.tap
            .subscribe(onNext:{ [weak self] res in
                guard let self else { return }
                self.showPause()
            })
            .disposed(by: disposeBag)
        
        resetBtn.rx.tap
            .subscribe(onNext:{ [weak self] res in
                guard let self else { return }
                self.tappedReset()
                self.removePush()
            })
            .disposed(by: disposeBag)
    }
    
    @objc private func appMovedToBackground() {
        goBackgroundTime = Date()
        gapTime = seconds
        guard let timer = timer else { return }
        if timer.isValid {
            removePush()
            let session = FocusTimerSessionStore.load()
            let notificationInterval = session?.status == .running
                ? max(session?.endDate.timeIntervalSinceNow ?? Double(seconds), 1)
                : max(Double(seconds), 1)
            pushNotification(
                seconds: notificationInterval,
                sessionID: session?.id
            )
        }
    }
    
    @objc private func appMovedToForeground() {
        goForegroundTime = Date()
        restorePersistedTimerIfNeeded()
    }

    @objc private func focusTimerNotificationOpened() {
        restorePersistedTimerIfNeeded()
    }
    
    @discardableResult
    private func fetch() -> [DataModel]? {
//        dummyData()
        do {
            let data = try RealmAPI.shared.load()
            LoadData.items = data
            return data
        } catch {
            print("❌ mainVM fetchData() load error: \(error.localizedDescription)")
            return nil
        }
    }

    private func syncCurrentFocusSummaries(records: [DataModel]) {
        let summaries = FocusSummaryCalculator.currentPeriods(records: records)
        Task {
            do {
                _ = try await FocusRankingService.shared.sync(summaries)
            } catch SupabaseClientError.notConfigured {
                return
            } catch {
                debugPrint("❌ Focus ranking sync error: \(error.localizedDescription)")
            }
        }
    }
    
    private func dummyData() {
        for item in Dummy.data {
            do{
                _ = try RealmAPI.shared.save(item: item)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    @objc private func sliderValueChanged(_ sender: CircularSlider) {
        btn.isEnabled = true
        seconds = Int(sender.getValue() * 3600)
        timeLbl.text = TimeConvertion.shared.convertSeconds(seconds: seconds)
    }

    @objc private func sliderEditingDidEnd(_ sender: CircularSlider) {
        let roundedMinutes = Int((sender.getValue() * 60).rounded())
        seconds = roundedMinutes * 60
        sender.setValue(CGFloat(seconds) / 3600)
        timeLbl.text = TimeConvertion.shared.convertSeconds(seconds: seconds)
        btn.isEnabled = seconds > 0
    }

    @objc private func btnTapped() {
        if btn.titleLabel?.text == "pause".localized {
            removePush()
            btn.isHidden = true
            resetBtn.isHidden = false
            resumeBtn.isHidden = false
            timer?.invalidate()
            FocusTimerSessionStore.pause(remainingSeconds: seconds)
            FocusTimerLiveActivityManager.shared.pause(
                seconds: seconds,
                totalSeconds: recordData
            )
        } else {
            recordData = seconds
            showPause()
        }
    }
    // 시작전
    // 일시정지 상태
    // 다시 시작된 상태
    // 리셋된 상태
    // 종료된 상태
    private func showPause() {
        let session = FocusTimerSessionStore.startOrResume(
            durationSeconds: recordData,
            remainingSeconds: seconds
        )
        pushNotification(seconds: Double(seconds), sessionID: session.id)
        FocusTimerLiveActivityManager.shared.startOrResume(
            seconds: seconds,
            totalSeconds: recordData
        )
        showRunningState()
        startTimerIfNeeded()
    }

    private func showRunningState() {
        btn.isHidden = false
        btn.isEnabled = true
        resetBtn.isHidden = true
        resumeBtn.isHidden = true
        btn.setTitle("pause".localized, for: .normal)
        if UserDefaults.standard.object(forKey: "sw1") as? Bool ?? true {
            timeLbl.isHidden = false
        } else {
            timeLbl.isHidden = true
        }
        
        circularSlider.isEnabled = false
        btn.configuration?.baseBackgroundColor = UIColor(red: 236/255, green: 236/255, blue: 236/255, alpha: 1)
        btn.setTitleColor(UIColor.black, for: .normal)
    }

    private func startTimerIfNeeded() {
        guard timer?.isValid != true else { return }
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
    private func showStart() {
        circularSlider.isEnabled = true
        btn.isHidden = false
        btn.setTitle("start".localized, for: .normal)
        btn.configuration?.baseBackgroundColor = UIColor.black
        btn.setTitleColor(UIColor.white, for: .normal)
        btn.isEnabled = false
        timeLbl.isHidden = true
    }
    private func tappedReset() {
        FocusTimerLiveActivityManager.shared.end()
        FocusTimerSessionStore.clear()
        seconds = 0
        circularSlider.setValue(0.026)
        resetBtn.isHidden = true
        resumeBtn.isHidden = true
        showStart()
    }
    
    @objc func fireTimer() {
        if let session = FocusTimerSessionStore.load(), session.status == .running {
            seconds = max(Int(ceil(session.endDate.timeIntervalSinceNow)), 0)
        } else {
            seconds -= 1
        }

        if seconds <= 0 {
            stopTimer()
        } else {
            timeLbl.text = TimeConvertion.shared.convertSeconds(seconds: seconds)
            circularSlider.setValue(CGFloat(seconds) / CGFloat(3600))
        }
    }
    private func stopTimer(isBackgroundToForeground: Bool = false) {
        guard !isCompletingSession else { return }
        isCompletingSession = true

        timer?.invalidate()
        removePush()
        FocusTimerLiveActivityManager.shared.end()

        let session = FocusTimerSessionStore.load()
        let sessionID = session?.id ?? UUID().uuidString
        let completedAt = session?.endDate ?? Date()
        let durationSeconds = session?.durationSeconds ?? recordData

        do {
            let wasSaved = try RealmAPI.shared.saveCompletedSession(
                item: DataModel(date: completedAt, seconds: durationSeconds),
                sessionID: sessionID
            )
            FocusTimerSessionStore.clear(matching: sessionID)
            if let records = fetch() {
                syncCurrentFocusSummaries(records: records)
            }
            let sw2: Bool = UserDefaults.standard.object(forKey: "sw2") as? Bool ?? true
            if !isBackgroundToForeground {
                soundModule.soundOutput(sw2: sw2)
            }
            showStart()
            if wasSaved {
                ReviewRequestManager.registerCompletedSession()
            }
        } catch {
            debugPrint("❌ Completed timer save error: \(error.localizedDescription)")
            showStart()
        }

        isCompletingSession = false
    }

    private func restorePersistedTimerIfNeeded(now: Date = Date()) {
        guard !isCompletingSession, let session = FocusTimerSessionStore.load() else { return }

        recordData = session.durationSeconds

        switch session.status {
        case .running:
            let remainingSeconds = max(Int(ceil(session.endDate.timeIntervalSince(now))), 0)
            seconds = remainingSeconds

            if remainingSeconds == 0 {
                stopTimer(isBackgroundToForeground: true)
                return
            }

            timeLbl.text = TimeConvertion.shared.convertSeconds(seconds: remainingSeconds)
            circularSlider.setValue(CGFloat(remainingSeconds) / CGFloat(3600))
            showRunningState()
            startTimerIfNeeded()
            FocusTimerLiveActivityManager.shared.startOrResume(
                seconds: remainingSeconds,
                totalSeconds: session.durationSeconds
            )

            removePush()
            pushNotification(
                seconds: max(session.endDate.timeIntervalSince(now), 1),
                sessionID: session.id
            )

        case .paused:
            timer?.invalidate()
            seconds = max(session.remainingSeconds, 0)
            timeLbl.text = TimeConvertion.shared.convertSeconds(seconds: seconds)
            circularSlider.setValue(CGFloat(seconds) / CGFloat(3600))
            circularSlider.isEnabled = false
            btn.isHidden = true
            resetBtn.isHidden = false
            resumeBtn.isHidden = false

            let showsTime = UserDefaults.standard.object(forKey: "sw1") as? Bool ?? true
            timeLbl.isHidden = !showsTime
        }
    }
}

// MARK: - local push
extension MainViewController {
    
    func removePush() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["local_push"])
    }
    
    func pushNotification(seconds: Double, sessionID: String? = nil) {
        
        let focusTime = TimeConvertion.shared.convertSeconds(seconds: recordData)

        // 1️⃣ 알림 내용, 설정
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "end".localized
        notificationContent.body = focusTime + " " + "focus_on".localized
        notificationContent.sound = .default
        if let sessionID {
            notificationContent.userInfo = ["timer_session_id": sessionID]
        }
        // 2️⃣ 조건(시간, 반복)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)

        // 3️⃣ 요청
        let request = UNNotificationRequest(identifier: "local_push",
                                            content: notificationContent,
                                            trigger: trigger)

        // 4️⃣ 알림 등록
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
    }
}

private struct FocusTimerSession: Codable {
    enum Status: String, Codable {
        case running
        case paused
    }

    let id: String
    let startedAt: Date
    var endDate: Date
    let durationSeconds: Int
    var remainingSeconds: Int
    var status: Status
}

private enum FocusTimerSessionStore {
    private static let key = "focusTimer.activeSession.v1"

    static func load() -> FocusTimerSession? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(FocusTimerSession.self, from: data)
        } catch {
            debugPrint("❌ Timer session decode error: \(error.localizedDescription)")
            UserDefaults.standard.removeObject(forKey: key)
            return nil
        }
    }

    @discardableResult
    static func startOrResume(
        durationSeconds: Int,
        remainingSeconds: Int,
        now: Date = Date()
    ) -> FocusTimerSession {
        let existingSession = load()
        let pausedSession = existingSession?.status == .paused ? existingSession : nil
        let session = FocusTimerSession(
            id: pausedSession?.id ?? UUID().uuidString,
            startedAt: pausedSession?.startedAt ?? now,
            endDate: now.addingTimeInterval(TimeInterval(remainingSeconds)),
            durationSeconds: pausedSession?.durationSeconds ?? durationSeconds,
            remainingSeconds: remainingSeconds,
            status: .running
        )
        save(session)
        return session
    }

    static func pause(remainingSeconds: Int) {
        guard var session = load() else { return }
        session.remainingSeconds = remainingSeconds
        session.status = .paused
        save(session)
    }

    static func clear(matching sessionID: String? = nil) {
        if let sessionID, load()?.id != sessionID {
            return
        }
        UserDefaults.standard.removeObject(forKey: key)
    }

    private static func save(_ session: FocusTimerSession) {
        do {
            let data = try JSONEncoder().encode(session)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            debugPrint("❌ Timer session encode error: \(error.localizedDescription)")
        }
    }
}

private enum ReviewRequestManager {
    private static let completedSessionCountKey = "review.completedSessionCount"
    private static let lastRequestedVersionKey = "review.lastRequestedVersion"
    private static let minimumCompletedSessions = 5

    @MainActor
    static func registerCompletedSession() {
        let defaults = UserDefaults.standard
        let completedSessionCount = defaults.integer(forKey: completedSessionCountKey) + 1
        defaults.set(completedSessionCount, forKey: completedSessionCountKey)

        guard completedSessionCount >= minimumCompletedSessions else { return }

        let currentVersion = Bundle.main.object(
            forInfoDictionaryKey: "CFBundleShortVersionString"
        ) as? String ?? "unknown"
        guard defaults.string(forKey: lastRequestedVersionKey) != currentVersion else { return }

        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return }

        if #available(iOS 16.0, *) {
            AppStore.requestReview(in: windowScene)
        } else {
            SKStoreReviewController.requestReview(in: windowScene)
        }

        defaults.set(currentVersion, forKey: lastRequestedVersionKey)
        defaults.set(0, forKey: completedSessionCountKey)
    }
}
