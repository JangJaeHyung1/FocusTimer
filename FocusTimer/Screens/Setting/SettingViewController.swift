//
//  SettingViewController.swift
//  FocusTimer
//
//  Created by jh on 7/31/24.
//

import UIKit
import SnapKit
import RxSwift

class SettingViewController: UIViewController {
    private let edgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        return view
    }()
    private let disposeBag = DisposeBag()
    var selectedIndexPath: Int
    var sw1IsOn: Bool
    var sw2IsOn: Bool
    
    var headerArray: [String] = [
        "clock_theme".localized,
        "setting".localized
        ]
    var textArray: [[String]] = [
        ["red_color".localized,
         "black_color".localized,],
        ["show_time_countdown".localized,
         "enabled_end_sound".localized,]
    ]
    var tableView: UITableView!
    init() {
        selectedIndexPath = UserDefaults.standard.object(forKey: "selectedIndex") as? Int ?? 0
        sw1IsOn = UserDefaults.standard.object(forKey: "sw1") as? Bool ?? true
        sw2IsOn = UserDefaults.standard.object(forKey: "sw2") as? Bool ?? true
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGray6
        setUp()
    }

}
extension SettingViewController {
    private func setUp() {
        configure()
        setNavi()
        addViews()
        setConstraints()
        bind()
        fetch()
    }
    private func configure() {
        view.backgroundColor = .white
        setTableView()
    }
    private func setTableView(){
        tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.contentInset = .init(top: 20, left: 0, bottom: 0, right: 0)
    }
    private func fetch() {
        
    }
    
    private func bind() {
        
    }
    
    private func setNavi() {
    }
    
    private func addViews() {
        
        view.addSubview(tableView)
        view.addSubview(edgeView)
//        view.bringSubviewToFront(edgeView)
        edgeView.layer.zPosition = 1
    }
    
    private func setConstraints() {
        edgeView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(edgeView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headerArray[section]
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textArray[section].count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none
        cell.textLabel?.text = textArray[indexPath.section][indexPath.row]
        if indexPath.section == 0 {
            cell.isSelected = indexPath.row == self.selectedIndexPath
            cell.accessoryView = .none
            cell.accessoryType = cell.isSelected ? .checkmark : .none
        } else {
            cell.accessoryType = .none
            let switchView = UISwitch()
            switchView.isOn = indexPath.row == 0 ? sw1IsOn : sw2IsOn
            switchView.rx.value
                .subscribe(onNext:{ [weak self] res in
                    guard let self else { return }
                    if indexPath.row == 0 {
                        self.sw1IsOn = res
                        UserDefaults.standard.set(res, forKey: "sw1")
                        NotificationCenter.default.post(name: Notification.Name("sw1"),
                                                                     object: self.sw1IsOn)
                    } else {
                        self.sw2IsOn = res
                        UserDefaults.standard.set(res, forKey: "sw2")
                    }
                })
                .disposed(by: disposeBag)
            cell.accessoryView = switchView
        }
        return cell
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        return headerArray.count
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            self.selectedIndexPath = indexPath.row
            UserDefaults.standard.set(indexPath.row, forKey: "selectedIndex")
            NotificationCenter.default.post(name: Notification.Name("selectedIndex"),
                                                         object: indexPath.row)
            self.tableView.reloadData()
        }
    }
}

