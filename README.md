https://apps.apple.com/kr/app/id6605927206

# 집중 타이머 - 집중을 돕는 직관적인 UI/UX 타이머

---

## 프로젝트 개요

**집중 타이머**는 집중 시간을 측정하고 일별 통계로 보여주는 iOS 앱입니다.  
UIKit 기반 MVVM 아키텍처로 구성했으며,  
Realm을 이용한 데이터 저장, 캘린더로 데이터 기록 시각화,  
타이머 종료 시 FCM 알림, 광고 제거 인앱 결제, 다국어 지원 등  
서비스 운영에 필요한 주요 기능을 포함하고 있습니다.

---

## 주요 기능

- 원형 슬라이더로 직관적인 타이머 표시
- 집중 시간 기록을 달력에 시각화
- 타이머 종료 시 FCM 알림 발송
- 광고 제거 인앱 결제 기능 (StoreKit)
- 한국어, 영어, 일본어, 중국어, 러시아어, 베트남어 등 다국어 지원

---

## 기술 스택

| 항목 | 내용 |
|------|------|
| Language | Swift |
| UI | UIKit, SnapKit |
| Architecture | MVVM |
| Local DB | Realm |
| Notification | Firebase Cloud Messaging |
| In-App Purchase | StoreKit |
| Localization | Localizable.strings 기반 |

---

## 화면 구성

- **Main**: 타이머 설정 및 시작. 종료 시 알림 발송
- **Calendar**: 집중 시간 누적 데이터를 달력에 표시
- **Setting**: 언어, 사운드, 광고 설정 등 환경 구성
- **Tabbar**: 화면 간 탭 전환

---

## 작업 내용 및 경험

- UIKit과 SnapKit을 활용하여 UI 구현
- MVVM 구조로 로직과 UI 역할을 분리해 유지보수 용이성 확보
- Realm을 이용해 집중 기록을 저장하고 빠르게 조회
- Firebase 연동으로 타이머 종료 시 푸시 알림 트리거 구현
- StoreKit 기반 인앱 결제를 도입해 광고 제거 기능 제공
- 다국어 지원을 적용해 7개 국가 배포 (한국어, 영어, 일본어, 중국어 간체, 중국어 번체, 러시아어, 베트남어)

## 디렉토리 구조

```bash
FocusTimer/
├── Application/
│   ├── AppDelegate.swift
│   └── SceneDelegate.swift
│
├── Supporting/
│   ├── Image/
│   ├── Main/
│   ├── LaunchScreen/
│   ├── Info.plist
│   └── Assets.xcassets
│
├── Screens/
│   ├── Tabbar/
│   │   └── TabbarViewController.swift
│   ├── Common/
│   │   ├── CircularSlider.swift
│   │   └── NativeAdView.swift
│   ├── Calendar/
│   │   ├── CalendarViewController.swift
│   │   └── CalendarCollectionViewCell.swift
│   ├── Setting/
│   │   └── SettingViewController.swift
│   └── Main/
│       └── MainViewController.swift
│
├── Domain/
│   ├── Model/
│   │   ├── DataModel.swift
│   │   └── RealmDataModel.swift
│   └── Repository/
│       ├── LoadData.swift
│       └── RealmAPI.swift
│
└─ Platform
   └─ Utilities
      ├─ InAppProduct/
      │  ├─ InAppProduct.swift
      │  └─ InAppPurchaseManager.swift
      ├─ Localized/
      │  ├─ Localizable.strings
      │  └─ InfoPlist.strings
      ├─ Extension/
      ├─ DesignSystem/
      ├─ TimeConvertion/
      └─ SoundModule/
```

---
