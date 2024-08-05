

import UIKit
import SnapKit
import RxSwift


class MainViewController: UIViewController {
    private var circularSlider = CircularSlider()
    private var soundModule = SoundModule()
    var seconds: Int = 0
    var recordData: Int = 0
    var timer: Timer?
    var goBackgroundTime: Date = Date()
    var goForegroundTime: Date = Date()
    var gapTime: Int = 0
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
        lbl.font = .systemFont(ofSize: 48, weight: .ultraLight)
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
        fetch()
        view.backgroundColor = .white
        circularSlider.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(circularSlider)
        view.addSubview(btn)
        view.addSubview(resumeBtn)
        view.addSubview(resetBtn)
        view.addSubview(timeView)
        timeView.addSubview(timeLbl)
        view.addSubview(centerCircle)
//        
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
        let btnBottomPadding = 138 / 812 * UIScreen.main.bounds.height
        btn.snp.makeConstraints { make in
            make.width.equalTo(108)
            make.height.equalTo(64)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-btnBottomPadding)
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
        btn.addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
        circularSlider.setValue(0.026)
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
            pushNotification(seconds: Double(seconds))
        }
    }
    
    @objc private func appMovedToForeground() {
        goForegroundTime = Date()
        guard let timer = timer else { return }
        if timer.isValid {
            seconds = max (gapTime - Int(goForegroundTime.timeIntervalSince(goBackgroundTime)), 0)
            circularSlider.setValue(CGFloat(seconds) / CGFloat(3600))
            if seconds == 0 {
                stopTimer(isBackgroundToForeground: true)
            }
        }
    }
    
    private func fetch() {
//        dummyData()
        do {
            let data = try RealmAPI.shared.load()
            LoadData.items = data
        } catch {
            print("❌ mainVM fetchData() load error: \(error.localizedDescription)")
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
    @objc private func btnTapped() {
        if btn.titleLabel?.text == "pause".localized {
            removePush()
            btn.isHidden = true
            resetBtn.isHidden = false
            resumeBtn.isHidden = false
            timer?.invalidate()
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
        pushNotification(seconds: Double(seconds))
        btn.isHidden = false
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
        seconds = 0
        circularSlider.setValue(0.026)
        resetBtn.isHidden = true
        resumeBtn.isHidden = true
        showStart()
    }
    
    @objc func fireTimer() {
        seconds -= 1
        if seconds == -1 {
            stopTimer()
        } else {
            timeLbl.text = TimeConvertion.shared.convertSeconds(seconds: seconds)
            circularSlider.setValue(CGFloat(seconds) / CGFloat(3600))
        }
    }
    private func stopTimer(isBackgroundToForeground: Bool = false) {
        Task {
            timer?.invalidate()
            _ = try RealmAPI.shared.save(item: DataModel(date: Date(), seconds: recordData))
            fetch()
            let sw2: Bool = UserDefaults.standard.object(forKey: "sw2") as? Bool ?? true
            if !isBackgroundToForeground {
                soundModule.soundOutput(sw2: sw2)
            }
            showStart()
        }
    }
}

// MARK: - local push
extension MainViewController {
    
    func removePush() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["local_push"])
    }
    
    func pushNotification(seconds: Double) {
        
        let focusTime = TimeConvertion.shared.convertSeconds(seconds: recordData)

        // 1️⃣ 알림 내용, 설정
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = "end".localized
        notificationContent.body = focusTime + " " + "focus_on".localized
        notificationContent.sound = .default
        // 2️⃣ 조건(시간, 반복)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)

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
