

import UIKit
import SnapKit
import RxSwift
import GoogleMobileAds

class MainViewController: UIViewController, GADBannerViewDelegate {
    var getAdRemovalStatus: Bool = false
    private var bannerView: GADBannerView!
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
        let viewWidth = view.frame.inset(by: view.safeAreaInsets).width

        let adaptiveSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(viewWidth)
        bannerView = GADBannerView(adSize: adaptiveSize)

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bannerView)
        
        bannerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top) // SafeArea의 상단과 맞춤
            make.trailing.equalToSuperview()
            make.width.equalTo(UIScreen.main.bounds.width) // 전체 너비의 90% 크기로 설정 (조절 가능)
            make.height.equalTo(adaptiveSize.size.height) // AdMob에서 제공하는 배너 높이 적용
        }
        loadNativeAd()
        circularSlider.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(42)
            make.trailing.equalToSuperview().offset(-42)
            make.height.equalTo(circularSlider.snp.width)
            make.centerX.equalToSuperview()
            make.top.equalTo(bannerView.snp.bottom).offset(50)
//            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(42)
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
        btn.addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
        circularSlider.setValue(0.026)
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
        let isLandscape = UIDevice.current.orientation.isLandscape
        NotificationCenter.default.post(name: Notification.Name("ToggleTabBar"), object: isLandscape)
        if !getAdRemovalStatus {
            if isLandscape {
                bannerView.snp.updateConstraints { make in
                    make.width.equalTo(UIScreen.main.bounds.width * 0.5)
                }
            } else {
                bannerView.snp.updateConstraints { make in
                    make.width.equalTo(UIScreen.main.bounds.width)
                }
            }
        }
        
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
                // 광고 제거 여부에 따라 크기 변경
                make.width.equalTo(view.snp.height).multipliedBy(0.7)
                make.height.equalTo(view.snp.height).multipliedBy(0.7)
                
//                make.bottom.equalToSuperview().offset(-60)
            } else {
                make.leading.equalToSuperview().offset(42)
                make.trailing.equalToSuperview().offset(-42)
                make.centerX.equalToSuperview()
                if getAdRemovalStatus {
                    make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(42)
                } else {
                    make.top.equalTo(bannerView.snp.bottom).offset(50)
                }
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
    
    func loadNativeAd() {
//        bannerView.adUnitID = "ca-app-pub-3940256099942544/2435281174" // test
        bannerView.adUnitID = "ca-app-pub-1128227668000865/1572761106"
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }
    
    func addBannerViewToView(_ bannerView: GADBannerView) {
        
        // This example doesn't give width or height constraints, as the provided
        // ad size gives the banner an intrinsic content size to size the view.
        view.addConstraints(
          [NSLayoutConstraint(item: bannerView,
                              attribute: .top,
                              relatedBy: .equal,
                              toItem: view.safeAreaLayoutGuide,
                              attribute: .top,
                              multiplier: 1,
                              constant: 0),
          NSLayoutConstraint(item: bannerView,
                              attribute: .centerX,
                              relatedBy: .equal,
                              toItem: view,
                              attribute: .centerX,
                              multiplier: 1,
                              constant: 0)
          ])
      }
    
    override func viewWillAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
        getAdRemovalStatus = InAppPurchaseManager.shared.getAdRemovalStatus()
        if getAdRemovalStatus {
            handleAdRemoval()
        }
    }
    
    func handleAdRemoval() {
        bannerView?.removeFromSuperview()
        bannerView = nil
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

