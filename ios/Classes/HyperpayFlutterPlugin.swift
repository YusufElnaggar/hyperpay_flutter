import Flutter
import UIKit
import SafariServices

public class HyperpayFlutterPlugin: NSObject, FlutterPlugin ,OPPThreeDSEventListener,OPPCheckoutProviderDelegate,SFSafariViewControllerDelegate,PKPaymentAuthorizationViewControllerDelegate  {
    
    
    var type:String = "";
    var mode:String = "";
    var checkoutid:String = "";
    var brand:String = "";
    var STCPAY:String = "";
    var number:String = "";
    // var phoneNumber:String = "";
    var holder:String = "";
    var year:String = "";
    var month:String = "";
    var cvv:String = "";
    var pMadaVExp:String = "";
    var prMadaMExp:String = "";
    var brands:String = "";
    // var storedPayment: String? = "";
    var tokenId: String = "";
    var shopperResultUrl: String = "";
    var applePayBundel:String = "";
    
    
    
    var amount:Double = 1;
    
    var safariVC: SFSafariViewController?

    var callDidAuthorizePayment = false
    
    var transaction: OPPTransaction?
    
    var provider = OPPPaymentProvider(mode: OPPProviderMode.live)
    
    var checkoutProvider: OPPCheckoutProvider?
    
    var Presult:FlutterResult?
    
    
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "hyperpay_flutter", binaryMessenger: registrar.messenger())
        let instance = HyperpayFlutterPlugin()
        registrar.addApplicationDelegate(instance)
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        self.Presult = result
        
        if call.method == "gethyperpayresponse"{
            
            print("paymentAuthorizationViewControllerDidFinish")
            NSLog("paymentAuthorizationViewControllerDidFinish")
            
            print("gethyperpayresponse")
            
            let args = call.arguments as? Dictionary<String,Any>
            print((args!["type"] as? String)!)
            self.type = (args!["type"] as? String)!
            // self.brand = (args!["brand"] as? String)!
            self.mode = (args!["mode"] as? String)!
            self.checkoutid = (args!["checkoutid"] as? String)!
            // self.storedPayment = (args!["storedPayment"] as? String)!
            self.shopperResultUrl = (args!["shopperResultUrl"] as? String)!
            self.applePayBundel = (args!["merchantId"] as? String)!
            
            
            if self.type == "ReadyUI" {
                
                DispatchQueue.main.async {
                    self.openCheckoutUI(checkoutId: self.checkoutid, result1: result)
                    
                }
                
            }
            else if self.type=="storedPayment" {
                self.tokenId = (args!["tokenId"] as? String)!
                self.cvv = (args!["cvv"] as? String)!
                self.brand = (args!["brand"] as? String)!
                self.openStotredCustomUI(checkoutId: self.checkoutid, tokenID: self.tokenId, brand: self.brand, cvv: self.cvv, result1:result)
            }
            
            else if self.type=="CustomUI" {
                // else {
                if let brand = (args!["brand"] as? String) {
                    self.brand = brand
                    self.number = (args!["card_number"] as? String)!
                    self.holder = (args!["holder_name"] as? String)!
                    self.year = (args!["year"] as? String)!
                    self.month = (args!["month"] as? String)!
                    self.cvv = (args!["cvv"] as? String)!
                    self.pMadaVExp = (args!["MadaRegexV"] as? String)!
                    self.prMadaMExp = (args!["MadaRegexM"] as? String)!
                }
                
                if let amount = (args!["Amount"] as? Double) {
                    self.amount = amount
                }
                
                self.openCustomUI(checkoutId: self.checkoutid, result1: result)
            }
            else if self.type=="APPLEPAY" {
                
                if let amount = (args!["Amount"] as? Double) {
                    self.amount = amount
                }
                
                self.payWithApplePay(checkoutId: self.checkoutid, result1: result)
                
            }
            // else if self.type=="STCPAY" {
            //     self.phoneNumber = (args!["phone_number"] as? String)!
            
            //     self.payWithSTCPay(checkoutId: self.checkoutid, result1: result)
            
            // }
            else {
                
                result(FlutterError(code: "1", message: "Method name is not found", details: ""))
                
            }
            
        } else {
            result(FlutterError(code: "1", message: "Method name is not found", details: ""))
        }
    }
    
    
    private func openCheckoutUI(checkoutId: String,result1: @escaping FlutterResult) {
        
        DispatchQueue.main.async{
            let checkoutSettings = OPPCheckoutSettings()
            if self.brand == "mada" {
                checkoutSettings.paymentBrands = ["MADA"]
            } else if self.brand == "credit" {
                checkoutSettings.paymentBrands = ["VISA", "MASTER","MADA","STC_PAY"]
            } else if self.brand == "APPLEPAY" {
                let paymentRequest = OPPPaymentProvider.paymentRequest(withMerchantIdentifier: self.applePayBundel, countryCode: "SA")
                if #available(iOS 12.1.1, *) {
                    paymentRequest.supportedNetworks = [ PKPaymentNetwork.mada,PKPaymentNetwork.visa,
                                                         PKPaymentNetwork.masterCard ]
                } else {
                    // Fallback on earlier versions
                    paymentRequest.supportedNetworks = [ PKPaymentNetwork.visa,
                                                         PKPaymentNetwork.masterCard ]
                }
                checkoutSettings.applePayPaymentRequest = paymentRequest
                checkoutSettings.paymentBrands = ["APPLEPAY"]
            }
            
            checkoutSettings.shopperResultURL = self.shopperResultUrl+".payments://result"
            
            if self.mode == "LIVE" {
                self.provider = OPPPaymentProvider(mode: OPPProviderMode.live)
            } else {
                self.provider = OPPPaymentProvider(mode: OPPProviderMode.test)
            }
            self.checkoutProvider = OPPCheckoutProvider(paymentProvider: self.provider, checkoutID: checkoutId, settings: checkoutSettings)!
            self.checkoutProvider?.delegate = self
            self.checkoutProvider?.presentCheckout(forSubmittingTransactionCompletionHandler: { (transaction, error) in
                guard let transaction = transaction else {
                    // Handle invalid transaction, check error
                    print(error.debugDescription)
                    return
                }
                self.transaction = transaction
                if transaction.type == .synchronous {
                    // If a transaction is synchronous, just request the payment status
                    // You can use transaction.resourcePath or just checkout ID to do it
                    DispatchQueue.main.async {
                        result1("SYNC")
                    }
                } else if transaction.type == .asynchronous {
                    NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveAsynchronousPaymentCallback), name: Notification.Name(rawValue: "AsyncPaymentCompletedNotificationKey"), object: nil)
                } else {
                    // Executed in case of failure of the transaction for any reason
                    print(self.transaction.debugDescription)
                }
            }, cancelHandler: {
                // Executed if the shopper closes the payment page prematurely
                print(self.transaction.debugDescription)
            })
        }
    }
    
    func onThreeDSChallengeRequired(completion: @escaping (UINavigationController?) -> Void) {
        completion(self.safariVC?.navigationController)
    }
    
    public func onThreeDSConfigRequired(completion: @escaping (OPPThreeDSConfig) -> Void) {
        let config = OPPThreeDSConfig()
        completion(config)
    }
    
    private func openStotredCustomUI(checkoutId: String,tokenID: String,brand: String,cvv: String,result1: @escaping FlutterResult){
        
        if self.mode == "LIVE" {
            self.provider = OPPPaymentProvider(mode: OPPProviderMode.live)
        } else {
            self.provider = OPPPaymentProvider(mode: OPPProviderMode.test)
        }
        
        do {
            let params = try OPPTokenPaymentParams(checkoutID: checkoutId, tokenID: tokenID, cardPaymentBrand:brand, cvv: cvv)
            
            params.shopperResultURL = self.shopperResultUrl+".payments://result"
            
            self.transaction  = OPPTransaction(paymentParams: params)
            self.provider.threeDSEventListener = self
            self.provider.submitTransaction(self.transaction!) { (transaction, error) in
                guard let transaction = self.transaction else {
                    // Handle invalid transaction, check error
                    self.createalart(titletext: error as! String, msgtext: "")
                    return
                }
                if transaction.type == .asynchronous {
                    self.safariVC = SFSafariViewController(url: self.transaction!.redirectURL!)
                    self.safariVC?.delegate = self;
                    //    self.present(self.safariVC!, animated: true, completion: nil)
                    UIApplication.shared.delegate?.window??.rootViewController?.present(self.safariVC!, animated: true, completion: nil)
                } else if transaction.type == .synchronous {
                    // Send request to your server to obtain transaction status
                    result1("success")
                } else {
                    // Handle the error
                    self.createalart(titletext: error as! String, msgtext: "")
                }
            }
        } catch let error as NSError {
            //See error.code (OPPErrorCode) and error.localizedDescription to identify the reason of failure.
            print(error.code)
            print(error.localizedDescription)
            self.createalart(titletext: error.localizedDescription, msgtext: "")
        }
    }
    
    
    private func openCustomUI(checkoutId: String,result1: @escaping FlutterResult) {
        
        if self.mode == "LIVE" {
            self.provider = OPPPaymentProvider(mode: OPPProviderMode.live)
            
        } else {
            self.provider = OPPPaymentProvider(mode: OPPProviderMode.test)
        }
        
        if !OPPCardPaymentParams.isNumberValid(self.number, luhnCheck: true) {
            
            self.createalart(titletext: "Card Number is Invalid", msgtext: "")
            
        }
        
        else  if !OPPCardPaymentParams.isHolderValid(self.holder) {
            
            self.createalart(titletext: "Card Holder is Invalid", msgtext: "")
            
        } else   if !OPPCardPaymentParams.isCvvValid(self.cvv) {
            
            self.createalart(titletext: "CVV is Invalid", msgtext: "")
            
        } else  if !OPPCardPaymentParams.isExpiryYearValid(self.year) {
            
            self.createalart(titletext: "Expiry Year is Invalid", msgtext: "")
            
        } else  if !OPPCardPaymentParams.isExpiryMonthValid(self.month) {
            
            self.createalart(titletext: "Expiry Month is Invalid", msgtext: "")
            
        } else
        {
            
            do {
                
                if self.brand == "mada" {
                    
                    let bin = self.number.prefix(6)
                    
                    let range = NSRange(location: 0, length: String(bin).utf16.count)
                    
                    let regex = try! NSRegularExpression(pattern: self.pMadaVExp)
                    let regex2 = try! NSRegularExpression(pattern: self.prMadaMExp)
                    
                    if regex.firstMatch(in: String(bin), options: [], range: range) != nil
                        || regex2.firstMatch(in: String(bin), options: [], range: range) != nil {
                        
                        self.brands = "MADA"
                        
                    } else {
                        
                        self.createalart(titletext:  "This card is not Mada card", msgtext: "")
                        
                    }
                    
                    
                }
                
                else if self.number.prefix(1) == "4" {
                    
                    self.brands = "VISA"
                    
                } else if self.number.prefix(1) == "5" {
                    
                    self.brands = "MASTER";
                    
                    
                }
                
                let params = try OPPCardPaymentParams(checkoutID: checkoutId, paymentBrand: self.brands, holder: self.holder, number: self.number, expiryMonth: self.month, expiryYear: self.year, cvv: self.cvv)
                
                params.shopperResultURL = self.shopperResultUrl+".payments://result"
                
                
                self.transaction  = OPPTransaction(paymentParams: params)
                self.provider.threeDSEventListener = self
                self.provider.register(self.transaction!) { (transaction, error) in
                    guard let transaction = self.transaction else {
                        // Handle invalid transaction, check error
                        self.createalart(titletext: error as! String, msgtext: "")
                        return
                    }
                    if transaction.type == .asynchronous {
                        self.safariVC = SFSafariViewController(url: self.transaction!.redirectURL!)
                        self.safariVC?.delegate = self;
                        //    self.present(self.safariVC!, animated: true, completion: nil)
                        UIApplication.shared.delegate?.window??.rootViewController?.present(self.safariVC!, animated: true, completion: nil)
                    } else if transaction.type == .synchronous {
                        // Send request to your server to obtain transaction status
                        result1("success")
                    } else {
                        // Handle the error
                        self.createalart(titletext: error as! String, msgtext: "")
                    }
                }
            } catch let error as NSError {
                // See error.code (OPPErrorCode) and error.localizedDescription to identify the reason of failure
                print(error.code)
                print(error.localizedDescription)
                self.createalart(titletext: error.localizedDescription, msgtext: "")
            }
        }
    }
    
    private func payWithApplePay(checkoutId: String,result1: @escaping FlutterResult) {
        do {
            
            if self.mode == "LIVE" {
                self.provider = OPPPaymentProvider(mode: OPPProviderMode.live)
                
            } else {
                self.provider = OPPPaymentProvider(mode: OPPProviderMode.test)
            }
            
            let request = OPPPaymentProvider.paymentRequest(withMerchantIdentifier: self.applePayBundel, countryCode: "SA")
            request.currencyCode = "SAR"
            
            self.amount = Double(String(format: "%.2f", self.amount))!
            
            // Create total item. Label should represent your company.
            // It will be prepended with the word "Pay" (i.e. "Pay Sportswear $100.00")
            // let amount = NSDecimalNumber(mantissa: 10000, exponent: 0 ,isNegative: false)
            
            request.paymentSummaryItems = [PKPaymentSummaryItem(label: "Kaart", amount: NSDecimalNumber(value: self.amount))]
            //  let request1 = PKPaymentRequest() // See above
            if OPPPaymentProvider.canSubmitPaymentRequest(request) {
                
                if let vc = PKPaymentAuthorizationViewController(paymentRequest: request) as PKPaymentAuthorizationViewController? {
                    vc.delegate = self
                    UIApplication.shared.delegate?.window??.rootViewController?.present(vc, animated: true, completion: nil)
                } else {
                    self.createalart(titletext: "Apple Pay not supported", msgtext: "")
                    NSLog("Apple Pay not supported.")
                }
            }
            else{
                self.createalart(titletext: "Apple Pay not supported", msgtext: "")
                print("not suported")
            }
        } catch let error as NSError {
            // See error.code (OPPErrorCode) and error.localizedDescription to identify the reason of failure
            print(error.code)
            print(error.localizedDescription)
            self.createalart(titletext: error.localizedDescription, msgtext: "")
        }
        
    }
    
    
    
    // private func payWithSTCPay(checkoutId: String,result1: @escaping FlutterResult) {
    
    //     if self.mode == "LIVE" {
    //         self.provider = OPPPaymentProvider(mode: OPPProviderMode.live)
    
    //     } else {
    //         self.provider = OPPPaymentProvider(mode: OPPProviderMode.test)
    //     }
    //     do {
    //         let params = try OPPSTCPayPaymentParams(checkoutID: checkoutId,verificationOption: STCPayVerificationOption.mobilePhone)
    //         params.setMobilePhoneNumber(self.phoneNumber)
    //         params.shopperResultURL = self.shopperResultUrl+".payments://result"
    
    //         self.transaction  = OPPTransaction(paymentParams: params)
    //         self.provider.threeDSEventListener = self
    //         self.provider.submitTransaction(self.transaction!) { (transaction, error) in
    //             guard let transaction = self.transaction else {
    //                 // Handle invalid transaction, check error
    //                 self.createalart(titletext: error as! String, msgtext: "")
    //                 return
    //             }
    
    //             if transaction.type == .asynchronous {
    //                 NotificationCenter.default.addObserver(self, selector: #selector(self.didReceiveAsynchronousPaymentCallback), name: Notification.Name(rawValue: "AsyncPaymentCompletedNotificationKey"), object: nil)
    
    //                 self.safariVC = SFSafariViewController(url: self.transaction!.redirectURL!)
    //                 self.safariVC?.delegate = self;
    //                 //  self.present(self.safariVC!, animated: true, completion: nil)
    //             } else if transaction.type == .synchronous {
    //                 // Send request to your server to obtain transaction status
    //                 result1("success")
    //             } else {
    //                 // Handle the error
    //             }
    //         }
    //         // Set shopper result URL
    //         //    params.shopperResultURL = "com.companyname.appname.payments://result"
    //     } catch let error as NSError {
    //         // See error.code (OPPErrorCode) and error.localizedDescription to identify the reason of failure
    //         self.createalart(titletext: error.localizedDescription, msgtext: "")
    //     }
    
    // }
    
    
    @objc func didReceiveAsynchronousPaymentCallback(result: @escaping FlutterResult) {
        NotificationCenter.default.removeObserver(self, name: Notification.Name(rawValue: "AsyncPaymentCompletedNotificationKey"), object: nil)
        if self.type == "ReadyUI" {
            self.checkoutProvider?.dismissCheckout(animated: true) {
                DispatchQueue.main.async {
                    result("success")
                }
            }
        } else {
            self.safariVC?.dismiss(animated: true) {
                DispatchQueue.main.async {
                    result("success")
                }
            }
        }
    }
    
    
    
    
    public func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        var handler:Bool = false
        if url.scheme?.caseInsensitiveCompare(self.shopperResultUrl+".payments") == .orderedSame {
            // if url.scheme?.caseInsensitiveCompare((self.shopperResultUrl ?? "com.kaart.client")+".payments") == .orderedSame {
            didReceiveAsynchronousPaymentCallback(result: self.Presult!)
            handler = true
        }
        return handler
    }
    
    func createalart(titletext:String,msgtext:String){
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: titletext, message:
                                                        msgtext, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: NSLocalizedString("ok", comment: ""), style: .default,handler: { (action) in alertController.dismiss(animated: true, completion: nil)}))
            UIApplication.shared.delegate?.window??.rootViewController?.present(alertController, animated: true, completion: nil)
        }}

    // public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
    //     self.paymentResult!("canceled")
    // }
    
    // public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    //     self.paymentResult!("canceled")
    // }
    
    
    
    public func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        print("paymentAuthorizationViewControllerDidFinish")
        NSLog("paymentAuthorizationViewControllerDidFinish")

        // controller.dismiss(animated: true, completion: nil)
        controller.dismiss(animated: true){
            DispatchQueue.main.async {

                if !self.callDidAuthorizePayment {
                    
                    self.Presult!("canceled")
                }
            }

        }

    }
    
    
    public func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, completion: @escaping (PKPaymentAuthorizationStatus) -> Void) {
        print("paymentAuthorizationViewController")
        NSLog("paymentAuthorizationViewController")
        callDidAuthorizePayment = true
        if let params = try? OPPApplePayPaymentParams(checkoutID: self.checkoutid, tokenData: payment.token.paymentData) as OPPApplePayPaymentParams? {
            self.transaction  = OPPTransaction(paymentParams: params)
            self.provider.submitTransaction(OPPTransaction(paymentParams: params), completionHandler: { (transaction, error) in
                if (error != nil) {
                    // See code attribute (OPPErrorCode) and NSLocalizedDescription to identify the reason of failure.
                    print(error?.localizedDescription as Any)
                    self.createalart(titletext: "APPLEPAY Error", msgtext: "")
                } else {
                    // Send request to your server to obtain transaction status.
                    completion(.success)
                    self.Presult!("success")
                }
            })
        }
    }
    
    
    func decimal(with string: String) -> NSDecimalNumber {
        //  let formatter = NumberFormatter()
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        return formatter.number(from: string) as? NSDecimalNumber ?? 0
    }
    
}
