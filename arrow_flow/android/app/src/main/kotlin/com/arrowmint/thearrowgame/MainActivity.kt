package com.arrowmint.thearrowgame

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.ads.AdError
import com.google.android.gms.ads.AdRequest
import com.google.android.gms.ads.FullScreenContentCallback
import com.google.android.gms.ads.LoadAdError
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import com.google.android.gms.ads.rewarded.RewardedAd
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.arrowmint.thearrowgame/ads"
    private var rewardedAd: RewardedAd? = null
    private var isLoadingAd = false
    private val GOOGLE_SAMPLE_REWARDED_ID = "ca-app-pub-3940256099942544/5224354917"
    private var activeAdUnitId = "ca-app-pub-8008085801755273/1610312711"
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initAds" -> {
                    try {
                        val requestConfig = RequestConfiguration.Builder()
                            .setTestDeviceIds(listOf(AdRequest.DEVICE_ID_EMULATOR))
                            .build()
                        MobileAds.setRequestConfiguration(requestConfig)
                        MobileAds.initialize(this) {
                            preloadRewardedAd(activeAdUnitId)
                            result.success(true)
                        }
                    } catch (e: Throwable) {
                        result.success(false)
                    }
                }
                "showRewardedAd" -> {
                    val adUnitId = call.argument<String>("adUnitId") ?: activeAdUnitId
                    activeAdUnitId = adUnitId
                    showOrLoadRewardedAd(adUnitId, result)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun preloadRewardedAd(adUnitId: String) {
        if (rewardedAd != null || isLoadingAd) return
        isLoadingAd = true
        mainHandler.post {
            try {
                val adRequest = AdRequest.Builder().build()
                RewardedAd.load(
                    this,
                    adUnitId,
                    adRequest,
                    object : RewardedAdLoadCallback() {
                        override fun onAdLoaded(ad: RewardedAd) {
                            rewardedAd = ad
                            isLoadingAd = false
                        }

                        override fun onAdFailedToLoad(loadAdError: LoadAdError) {
                            isLoadingAd = false
                            rewardedAd = null
                            // If live unit has no inventory yet during testing, preload Google sample unit
                            if (adUnitId != GOOGLE_SAMPLE_REWARDED_ID) {
                                preloadRewardedAd(GOOGLE_SAMPLE_REWARDED_ID)
                            }
                        }
                    }
                )
            } catch (e: Throwable) {
                isLoadingAd = false
            }
        }
    }

    private fun showOrLoadRewardedAd(adUnitId: String, result: MethodChannel.Result) {
        mainHandler.post {
            val ad = rewardedAd
            if (ad != null) {
                presentRewardedAd(ad, result)
                rewardedAd = null
                preloadRewardedAd(adUnitId)
            } else {
                // Load on-demand with automatic Google test fallback if no fill
                try {
                    val adRequest = AdRequest.Builder().build()
                    RewardedAd.load(
                        this,
                        adUnitId,
                        adRequest,
                        object : RewardedAdLoadCallback() {
                            override fun onAdLoaded(loadedAd: RewardedAd) {
                                presentRewardedAd(loadedAd, result)
                                preloadRewardedAd(adUnitId)
                            }

                            override fun onAdFailedToLoad(loadAdError: LoadAdError) {
                                if (adUnitId != GOOGLE_SAMPLE_REWARDED_ID) {
                                    try {
                                        val fallbackRequest = AdRequest.Builder().build()
                                        RewardedAd.load(
                                            this@MainActivity,
                                            GOOGLE_SAMPLE_REWARDED_ID,
                                            fallbackRequest,
                                            object : RewardedAdLoadCallback() {
                                                override fun onAdLoaded(fallbackAd: RewardedAd) {
                                                    presentRewardedAd(fallbackAd, result)
                                                    preloadRewardedAd(adUnitId)
                                                }

                                                override fun onAdFailedToLoad(error: LoadAdError) {
                                                    result.error("AD_LOAD_FAILED", error.message, null)
                                                }
                                            }
                                        )
                                    } catch (e: Throwable) {
                                        result.error("AD_EXCEPTION", e.message, null)
                                    }
                                } else {
                                    result.error("AD_LOAD_FAILED", loadAdError.message, null)
                                }
                            }
                        }
                    )
                } catch (e: Throwable) {
                    result.error("AD_EXCEPTION", e.message, null)
                }
            }
        }
    }

    private fun presentRewardedAd(ad: RewardedAd, result: MethodChannel.Result) {
        var userRewarded = false
        ad.fullScreenContentCallback = object : FullScreenContentCallback() {
            override fun onAdDismissedFullScreenContent() {
                result.success(userRewarded)
            }

            override fun onAdFailedToShowFullScreenContent(adError: AdError) {
                result.success(false)
            }
        }
        ad.show(this@MainActivity) { _ ->
            userRewarded = true
        }
    }
}
