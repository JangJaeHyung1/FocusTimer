import StoreKit
import RxSwift
import RxRelay

class InAppPurchaseManager: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {

    static let shared = InAppPurchaseManager()
    private var product: SKProduct?
    let disposeBag = DisposeBag()

    // Rx Subjects
    let purchaseResult = PublishSubject<Result<Void, Error>>()
    let restoreResult = PublishSubject<Result<Void, Error>>()

    // UserDefaults 키 정의
    private let adRemovalKey = "isAdRemoved"

    private override init() {
        super.init()
        SKPaymentQueue.default().add(self)
    }

    // 광고 제거 여부 확인
    var isAdRemoved: Bool {
        return UserDefaults.standard.bool(forKey: adRemovalKey)
    }

    // 1. 상품 정보 요청
    func fetchProduct(with identifier: String) -> Observable<SKProduct?> {
        return Observable.create { observer in
            let request = SKProductsRequest(productIdentifiers: [identifier])
            request.delegate = self
            request.start()

            let disposable = Disposables.create {
                request.cancel()
            }
            return disposable
        }
    }

    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if let fetchedProduct = response.products.first {
            product = fetchedProduct
            print("상품 로드 완료: \(fetchedProduct.localizedTitle) - \(fetchedProduct.priceLocale.currencySymbol ?? "")\(fetchedProduct.price)")
        } else {
            print("상품을 찾을 수 없음")
        }
    }

    // 2. 결제 요청
    // 2. 결제 요청
    func purchaseProduct() {
        if isAdRemoved {
            print("이미 광고 제거가 활성화되어 있습니다.")
            showToastMessage("ad_already_removed")
            return
        }
        guard let product = product else {
            print("상품이 준비되지 않았습니다.")
            purchaseResult.onNext(.failure(NSError(domain: "InAppPurchase", code: -1, userInfo: [NSLocalizedDescriptionKey: "상품이 준비되지 않았습니다."])))
            return
        }
        if SKPaymentQueue.canMakePayments() {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            print("인앱 결제를 사용할 수 없습니다.")
            purchaseResult.onNext(.failure(NSError(domain: "InAppPurchase", code: -1, userInfo: [NSLocalizedDescriptionKey: "인앱 결제를 사용할 수 없습니다."])))
        }
    }

    // 사용자에게 메시지를 보여주는 헬퍼 메서드
    private func showToastMessage(_ message: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = windowScene.windows.first else { return }
            
            let alert = UIAlertController(title: nil, message: message.localized, preferredStyle: .alert)
            window.rootViewController?.present(alert, animated: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                alert.dismiss(animated: true)
            }
        }
    }

    // 3. 결제 트랜잭션 처리
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                print("✅ 결제 성공")
                setAdRemovalStatus(true)
                finishTransaction(transaction)
                purchaseResult.onNext(.success(()))
                showToastMessage("purchase_success")

            case .failed:
                if transaction.payment.productIdentifier == "com.yourapp.adremoval" {
                    print("⚠️ 구매 복원 실패: \(transaction.error?.localizedDescription ?? "알 수 없는 오류")")
                    restoreResult.onNext(.failure(transaction.error ?? NSError(domain: "InAppPurchase", code: -1, userInfo: [NSLocalizedDescriptionKey: "알 수 없는 오류"])))
                    showToastMessage("restore_failed")
                } else {
                    print("❌ 결제 실패: \(transaction.error?.localizedDescription ?? "알 수 없는 오류")")
                    purchaseResult.onNext(.failure(transaction.error ?? NSError(domain: "InAppPurchase", code: -1, userInfo: [NSLocalizedDescriptionKey: "알 수 없는 오류"])))
                    showToastMessage("purchase_failed")
                }
                queue.finishTransaction(transaction)

            case .restored:
                print("🔄 구매 복원 완료")
                setAdRemovalStatus(true)
                restoreResult.onNext(.success(()))
                showToastMessage("restore_success")
                queue.finishTransaction(transaction)

            case .deferred:
                print("⏳ 결제 보류")
                showToastMessage("deferred")

            case .purchasing:
                print("💳 결제 진행 중")

            @unknown default:
                print("⚠️ 알 수 없는 결제 상태")
                showToastMessage("unknown")
            }
        }
    }

    private func finishTransaction(_ transaction: SKPaymentTransaction) {
        print("구매 완료 - 상품 ID: \(transaction.payment.productIdentifier)")
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    // 광고 제거 상태 변경
    private func setAdRemovalStatus(_ isRemoved: Bool) {
        UserDefaults.standard.set(isRemoved, forKey: adRemovalKey)
        print("광고 제거 상태 변경: \(isRemoved)")
    }
    
    // 광고 상태 조회
    func getAdRemovalStatus() -> Bool {
        let status = UserDefaults.standard.bool(forKey: adRemovalKey)
        print("광고 제거 상태 조회: \(status)")
        return status
    }
    // 4. 구매 복원
    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

