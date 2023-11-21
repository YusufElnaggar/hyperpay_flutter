package com.kaart.hyperpay_flutter

import androidx.annotation.NonNull

import android.app.Activity
import android.content.Intent
import android.content.Context
import android.content.ComponentName
import android.content.ServiceConnection
import android.net.Uri
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.widget.Toast

import com.oppwa.mobile.connect.provider.*
import com.oppwa.mobile.connect.payment.BrandsValidation
import com.oppwa.mobile.connect.payment.CheckoutInfo
import com.oppwa.mobile.connect.payment.ImagesRequest
import com.oppwa.mobile.connect.payment.PaymentParams
import com.oppwa.mobile.connect.payment.card.CardPaymentParams
import com.oppwa.mobile.connect.payment.token.TokenPaymentParams
import com.oppwa.mobile.connect.threeds.OppThreeDSConfig
import com.oppwa.mobile.connect.checkout.dialog.CheckoutActivity
import com.oppwa.mobile.connect.checkout.meta.CheckoutSettings
import com.oppwa.mobile.connect.exception.PaymentError
import com.oppwa.mobile.connect.exception.PaymentException

import java.util.LinkedHashSet

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.NewIntentListener
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener


/** HyperpayFlutterPlugin */
class HyperpayFlutterPlugin : FlutterPlugin, ActivityAware, ActivityResultListener, NewIntentListener, ITransactionListener, MethodCallHandler{

    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity

    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var activity: Activity

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding ) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "hyperpay_flutter")
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }
    
    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private var result: MethodChannel.Result? = null

    
    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        if (context != null) {
            this.result = result
            
            if (call.method == "gethyperpayresponse") {
                
                type = call.argument("type")
                mode = call.argument("mode")
                checkoutid = call.argument("checkoutid")
                storedPayment = call.argument("storedPayment")
                shopperResultUrl = call.argument("shopperResultUrl")
                
                if (type == "ReadyUI") {

                    openCheckoutUI(checkoutid)

                } else if (type == "storedPayment") {

                    tokenId = call.argument("tokenId")
                    cvv = call.argument("cvv")
                    brand = call.argument("brand")

                    openStotredCustomUI(checkoutid, tokenId, brand, cvv)

                }
                //  else if (type == "STCPAY") {

                //     phoneNumber = call.argument("phone_number")
                    
                //     payWithSTCPay(checkoutid)
                    
                // }
                 else if (type == "CustomUI") {
                    brands = call.argument("brand")
                    number = call.argument("card_number")
                    holder = call.argument("holder_name")
                    year = call.argument("year")
                    month = call.argument("month")
                    cvv = call.argument("cvv")
                    ptMadaVExp = call.argument("MadaRegexV")
                    ptMadaMExp = call.argument("MadaRegexM")

                    openCustomUI(checkoutid)

                 } else {
                     result.notImplemented()
                 }
            } else {
                result.notImplemented()
            }
        } else {
            // Handle the case where context is null
        }
    }
    
    
    
    
    private var checkoutid: String? = ""
    private var type: String? = ""
    private var shopperResultUrl : String? = ""
    private var number: String? = null
    // private var phoneNumber: String? = null
    private var holder: String? = null
    private var cvv: String? = null
    private var year: String? = null
    private var month: String? = null
    private var brand: String? = null
    private var mode: String? = ""
    private var storedPayment: String? = ""
    private var tokenId: String? = ""

    var transaction: Transaction? = null
    var ptMadaVExp: String? = ""
    var ptMadaMExp: String? = ""
    var brands: String? = ""
    

   
            
    private fun openCheckoutUI(checkoutId: String?) {
        val paymentBrands: MutableSet<String> = LinkedHashSet()
        if (brands == "mada") {
            paymentBrands.add("MADA")
        } else {
            paymentBrands.add("VISA")
            paymentBrands.add("MASTER")
        }
        var checkoutSettings = CheckoutSettings(
            checkoutId!!, paymentBrands,
            Connect.ProviderMode.LIVE
            ).setShopperResultUrl(shopperResultUrl+".payment://result")
        if (mode == "LIVE") {
            checkoutSettings = CheckoutSettings(
                checkoutId, paymentBrands,
                Connect.ProviderMode.LIVE
            ).setShopperResultUrl(shopperResultUrl+".payment://result")
        }
        val componentName = ComponentName(
            context.packageName, CheckoutBroadcastReceiver::class.java.getName()
        )
                        
            /* Set up the Intent and start the checkout activity. */
            val intent = checkoutSettings.createCheckoutActivityIntent(context, componentName)
            activity.startActivityForResult(intent, CheckoutActivity.REQUEST_CODE_CHECKOUT)
        }
        
        
    private fun openStotredCustomUI(
        checkoutid: String?,
        tokenID: String?,
        brand: String?,
        cvv: String?
        ) {
        try {
            var paymentProvider = OppPaymentProvider(context, Connect.ProviderMode.LIVE)
            if (mode == "TEST") {
                paymentProvider = OppPaymentProvider(context, Connect.ProviderMode.TEST)
            }
            val paymentParams = TokenPaymentParams(checkoutid!!, tokenID!!, brand!!, cvv)
            paymentParams.shopperResultUrl = shopperResultUrl+".payment://result"
            val transaction = Transaction(paymentParams)
            paymentProvider.setThreeDSWorkflowListener(threeDSWorkflowListener)
            paymentProvider.submitTransaction(transaction, this)

        } catch (e: PaymentException) {
            Toast.makeText(context, "fail", Toast.LENGTH_LONG).show()
        }
    }


    val threeDSWorkflowListener: ThreeDSWorkflowListener = object : ThreeDSWorkflowListener {
        override fun onThreeDSChallengeRequired(): Activity {
            // provide your Activity
            return activity
        }

        override fun onThreeDSConfigRequired(): OppThreeDSConfig {
            // provide your OppThreeDSConfig
            return onThreeDSConfigRequired()
        }
    }


    // private fun payWithSTCPay(checkoutid: String?) {
    //     try {

    //         val paymentParams = STCPayPaymentParams(checkoutid!!, STCPayVerificationOption.MOBILE_PHONE)
    //         paymentParams.setMobilePhoneNumber(phoneNumber)
    //         val paymentProvider = OppPaymentProvider(context, Connect.ProviderMode.LIVE)
    //         paymentParams.shopperResultUrl = shopperResultUrl+".payment://result"
    //         val transaction = Transaction(paymentParams)
    //         paymentProvider.setThreeDSWorkflowListener(threeDSWorkflowListener)
    //         paymentProvider.registerTransaction(transaction, this)
    //     } catch (e: PaymentException) {
    //     }
    // }

    private fun openCustomUI(checkoutid: String?) {

        val checkResult = check(number)
        if (!checkResult) {
            Toast.makeText(context, "Card Number is Invalid . ", Toast.LENGTH_LONG).show()
            return
        } else if (!CardPaymentParams.isNumberValid(number)) {
            Toast.makeText(context, "Card Number is Invalid", Toast.LENGTH_LONG).show()
            return
        } else if (!CardPaymentParams.isHolderValid(holder)) {
            Toast.makeText(context, "Card Holder is Invalid", Toast.LENGTH_LONG).show()
        } else if (!CardPaymentParams.isExpiryYearValid(year)) {
            Toast.makeText(context, "Expiry Year is Invalid", Toast.LENGTH_LONG).show()
        } else if (!CardPaymentParams.isExpiryMonthValid(month)) {
            Toast.makeText(context, "Expiry Month is Invalid", Toast.LENGTH_LONG).show()
        } else if (!CardPaymentParams.isCvvValid(cvv)) {
            Toast.makeText(context, "CVV is Invalid", Toast.LENGTH_LONG).show()
        } else {
            val firstnumber = number!![0].toString()
            // To add MADA
            if (brands == "mada") {
                val bin = number!!.substring(0, 6)
                if (bin.matches(ptMadaVExp!!.toRegex()) || bin.matches(ptMadaMExp!!.toRegex())) {
                    brand = "MADA"
                } else {
                    Toast.makeText(
                        context,
                        "This card is not Mada card",
                        Toast.LENGTH_LONG
                    ).show()
                }
            } else {
                if (firstnumber == "4") {
                    brand = "VISA"
                } else if (firstnumber == "5") {
                    brand = "MASTER"
                }
            }
            try {
                Toast.makeText(context, brand, Toast.LENGTH_LONG).show()
                val paymentParams: PaymentParams = CardPaymentParams(
                    checkoutid!!,
                    brand!!,
                    number!!,
                    holder,
                    month,
                    year,
                    cvv
                )
                paymentParams.shopperResultUrl = shopperResultUrl+".payment://result"
                val transaction = Transaction(paymentParams)
                var paymentProvider = OppPaymentProvider(context, Connect.ProviderMode.LIVE)
                if (mode == "TEST") {
                    paymentProvider = OppPaymentProvider(context, Connect.ProviderMode.TEST)
                }
                paymentProvider.setThreeDSWorkflowListener(threeDSWorkflowListener)
                paymentProvider.registerTransaction(transaction, this)
            } catch (e: PaymentException) {
            }
        }
        
    }

    fun check(ccNumber: String?): Boolean {
        var sum = 0
        var alternate = false
        for (i in ccNumber!!.length - 1 downTo 0) {
            var n = ccNumber.substring(i, i + 1).toInt()
            if (alternate) {
                n *= 2
                if (n > 9) {
                    n = n % 10 + 1
                }
            }
            sum += n
            alternate = !alternate
        }
        return sum % 10 == 0
    }

    private val handler = Handler(Looper.getMainLooper())
    
    private fun success(result: Any?) {
        handler.post { this.result!!.success(result) }
    }
    
    private fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
        handler.post { this.result!!.error(errorCode, errorMessage, errorDetails) }
    }
    
    private fun notImplemented() {
        handler.post { this.result!!.notImplemented() }
    }

    override fun brandsValidationRequestSucceeded(brandsValidation: BrandsValidation) {

        Log.d("hyperpay_flutter","payment :  brandsValidationRequestSucceeded" )
    }

    override fun brandsValidationRequestFailed(paymentError: PaymentError) {

        Log.d("hyperpay_flutter","payment :  brandsValidationRequestFailed" )
    }

    override fun imagesRequestSucceeded(imagesRequest: ImagesRequest) {

        Log.d("hyperpay_flutter","payment :  imagesRequestSucceeded" )
    }

    override fun imagesRequestFailed() {
        Log.d("hyperpay_flutter","payment :  imagesRequestFailed" )

    }
    
    override fun paymentConfigRequestSucceeded(checkoutInfo: CheckoutInfo) {
        Log.d("hyperpay_flutter","payment :  paymentConfigRequestSucceeded" )

    }

    override fun paymentConfigRequestFailed(paymentError: PaymentError) {

        Log.d("hyperpay_flutter","payment :  paymentConfigRequestFailed" )
    }


    override fun transactionCompleted(transaction: Transaction) {
        Log.d("hyperpay_flutter","payment :  transactionCompleted" )
        if (transaction == null) {
            return
        }
        if (transaction.transactionType == TransactionType.SYNC) {
            Log.d("hyperpay_flutter","transaction.transactionType : " + transaction.transactionType)
            success("SYNC")
        } else {
            Log.d("hyperpay_flutter","transaction.transactionType : " + transaction.transactionType)
            /* wait for the callback in the s */
            val uri = Uri.parse(transaction.redirectUrl)
            val intent = Intent(Intent.ACTION_VIEW, uri)
            Log.d("hyperpay_flutter","intent : " + intent!!.toString())
            activity.startActivity(intent)
        }
    }
    
    override fun transactionFailed(transaction: Transaction, paymentError: PaymentError) {
        Log.d("hyperpay_flutter","payment :  transactionFailed" )
        error("transactionFailed", paymentError.errorMessage, "transactionFailed")
    }
    
    
    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d("hyperpay_flutter","payment :  onAttachedToActivity" )
        activity = binding.activity
        binding.addActivityResultListener(this)
        binding.addOnNewIntentListener(this)
    }
    override fun onDetachedFromActivityForConfigChanges() {
        Log.d("hyperpay_flutter","payment :  onDetachedFromActivityForConfigChanges" )
        
    }
    
    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d("hyperpay_flutter","payment :  onReattachedToActivityForConfigChanges" )
        
    }
    
    override fun onDetachedFromActivity() {
        Log.d("hyperpay_flutter","payment :  onDetachedFromActivity" )
        
    }
    
    
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d("hyperpay_flutter","payment :  onActivityResult" )
        Log.d("hyperpay_flutter","resultCode : " + resultCode!!.toString())
        when (resultCode) {
            CheckoutActivity.RESULT_OK -> {
                val transaction = data?.getParcelableExtra<Transaction>(CheckoutActivity.CHECKOUT_RESULT_TRANSACTION)
                if (transaction?.transactionType == TransactionType.SYNC) {
                    success("SYNC")
                }
            }
            CheckoutActivity.RESULT_CANCELED -> error("2", "Canceled", "")
            CheckoutActivity.RESULT_ERROR -> error("3", "Checkout Result Error", "")
        }
        return true
    }
    
    override fun onNewIntent(intent: Intent): Boolean {
        Log.d("hyperpay_flutter","payment :  onNewIntent" )
        if (intent?.scheme != null && intent.scheme == shopperResultUrl+".payment") {
            success("success")
        }
        return true
    }
}
