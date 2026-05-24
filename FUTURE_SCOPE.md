# Zzen — Product Roadmap & Future Scope

This document outlines the planned future features, scaling strategies, and technical roadmap for **Zzen**.

---

## 🚀 1. Cross-Platform App Store Publishing
*   **Android**: Build and sign production-grade Android App Bundles (`.aab`) to publish on the Google Play Store. Set up automated deployment pipelines via Fastlane.
*   **iOS**: Configure Apple Developer credentials, handle provisioning profiles, and build the iOS client using Xcode/CocoaPods. Publish on the Apple App Store.
*   **Tablet/iPad Support**: Optimize layouts for larger screens using responsive grids and master-detail UI patterns.

## 📱 2. Scale App Features (Target: 50+ Features)
To make Zzen a comprehensive sleep wellness platform, we plan to implement 50+ holistic wellness and sleep improvement features:
*   **Sleep Sounds Expansion**: Integrate ambient mixes (custom sound mixers for wind, rain, campfire), guided meditations, binaural beats, and ASMR.
*   **Guided Wind-Down Activities**: Interactive breathing exercises, progressive muscle relaxation (PMR), and journaling/worry-dumping prompts before bed.
*   **Sleep Trivia & Gamification**: Weekly sleep quizzes, daily trivia cards, sleep pets (virtual pets that sleep when you sleep), and badges for maintaining consistency.
*   **Chronotype Diagnostics**: Implement morningness-eveningness questionnaires (MEQ) to identify if the user is a "lion", "bear", "wolf", or "dolphin" chronotype, custom-tailoring sleep score calculation.
*   **Sleep Hygiene Quests**: Structured 7-day, 14-day, and 30-day sleep challenges with progressive difficulty levels.

## ⌚ 3. Extrinsic Smart Watch Connectivity
Currently, sleep tracking relies on user inputs and screen time logs. We will integrate physical trackers to fetch high-fidelity data:
*   **WearOS & Apple Watch Companion Apps**: Custom lightweight watch apps that run in the background to monitor heart rate, blood oxygen levels, and accelerometer movement.
*   **Health Connect (Android) & HealthKit (iOS)**: Read consolidated health data from Google Fit, Samsung Health, Apple Health, Fitbit, Garmin, and Oura Ring.
*   **Continuous Accelerometer Sleep Stage Monitoring**: Parse raw triaxial accelerometer data to estimate REM, Deep, and Light sleep stages without manual logging.

## 📊 4. Sleep Graph Averaging & High-Fidelity Data Merging
To deliver the most accurate metrics to the user, we will build a data-merging engine:
*   **Dual-Source Correlation**: Collect data from both the smart watch (physiological sleep stages) and the smartphone (phone usage sleep-interval boundaries).
*   **Averaging & Outlier Detection Algorithms**: Apply weighted moving averages and Kalman filters to reconcile differences between watch metrics and manual logs (e.g. if the watch logs sleep but the phone has screen time activity, adjust sleep time to reflect the true cognitive wind-down time).
*   **Advanced fl_chart Visualizations**: Multi-layered graphs showing heart rate variability (HRV) overlayed onto sleep stages, screen time bars, and caffeine intake dots.

## 💎 5. Premium Subscriptions & Limits Handling
*   **Premium Tier**: Introduce a paid subscription via RevenueCat (Google Play Billing + Apple In-App Purchases) to unlock unlimited Gemini AI Sleep Coach messages.
*   **Tiered AI Quotas**:
    *   *Free Tier*: 10 messages/day with a polite quota-exceeded warning offering users to upgrade or retry tomorrow.
    *   *Premium Tier*: Unlimited tokens with access to advanced Gemini models (e.g. Gemini 1.5 Pro) for deeper analytical reports.
