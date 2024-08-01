

import UIKit
import SnapKit
import RxSwift


class MainViewController: UIViewController {
    private var circularSlider = CircularSlider()
    var seconds: Int = 0
    var recordData: Int = 0
    var timer: Timer?
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
        config.title = "Start"
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
        config.title = "Resume"
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
        config.title = "Reset"
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
            make.width.height.equalTo(300)
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        centerCircle.setShadow()
    }
    
    private func bind() {
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
            })
            .disposed(by: disposeBag)
    }
    
    
    private func fetch() {
        do {
            let data = try RealmAPI.shared.load()
            LoadData.items = data
        } catch {
            print("❌ mainVM fetchData() load error: \(error.localizedDescription)")
        }
    }
    @objc private func sliderValueChanged(_ sender: CircularSlider) {
//        print("Slider value changed: \(sender.getValue())")
        btn.isEnabled = true
        seconds = Int(sender.getValue() * 3600)
        timeLbl.text = TimeConvertion.shared.convertSeconds(seconds: seconds)
    }
    @objc private func btnTapped(_ sender: CircularSlider) {
        if btn.titleLabel?.text == "Pause" {
            btn.isHidden = true
            resetBtn.isHidden = false
            resumeBtn.isHidden = false
            timer?.invalidate()
        } else {
            recordData = seconds
            showPause()
        }

    }
    
    private func showPause() {
        btn.isHidden = false
        resetBtn.isHidden = true
        resumeBtn.isHidden = true
        btn.setTitle("Pause", for: .normal)
        timeLbl.isHidden = false
        circularSlider.isEnabled = false
        btn.configuration?.baseBackgroundColor = UIColor(red: 236/255, green: 236/255, blue: 236/255, alpha: 1)
        btn.setTitleColor(UIColor.black, for: .normal)
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(fireTimer), userInfo: nil, repeats: true)
    }
    
    private func showStart() {
        circularSlider.isEnabled = true
        btn.isHidden = false
        btn.setTitle("Start", for: .normal)
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
        timeLbl.text = TimeConvertion.shared.convertSeconds(seconds: seconds)
        circularSlider.setValue(CGFloat(seconds) / CGFloat(3600))
        if seconds == 0 {
            Task {
                timer?.invalidate()
                _ = try RealmAPI.shared.save(item: DataModel(date: Date(), seconds: recordData))
                fetch()
                print("타이머 끝")
                showStart()
            }
        }
    }
    
}
