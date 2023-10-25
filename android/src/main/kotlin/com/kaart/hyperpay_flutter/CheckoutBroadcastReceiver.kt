package com.kaart.hyperpay_flutter

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.oppwa.mobile.connect.checkout.dialog.CheckoutActivity

/**
 * Broadcast receiver to listen the intents from CheckoutActivity.
 */
class CheckoutBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        var intent = intent
        val action = intent.action
        if (CheckoutActivity.ACTION_ON_BEFORE_SUBMIT == action) {
            val paymentBrand = intent.getStringExtra(CheckoutActivity.EXTRA_PAYMENT_BRAND)
            val checkoutId = intent.getStringExtra(CheckoutActivity.EXTRA_CHECKOUT_ID)

            /* This callback can be used to request a new checkout ID if selected payment brand requires
               some specific parameters or just send back the same checkout id to continue checkout process */intent =
                Intent(
                    context,
                    CheckoutActivity::class.java
                )
            intent.action = CheckoutActivity.ACTION_ON_BEFORE_SUBMIT
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            intent.putExtra(CheckoutActivity.EXTRA_CHECKOUT_ID, checkoutId)

            /* Also it can be used to cancel the checkout process by sending
               the CheckoutActivity.EXTRA_CANCEL_CHECKOUT */intent.putExtra(
                CheckoutActivity.EXTRA_TRANSACTION_ABORTED,
                false
            )
            context.startActivity(intent)
        }
    }


}