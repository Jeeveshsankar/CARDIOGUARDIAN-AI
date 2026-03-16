import 'dart:math';

class LocalPredictor {
  /// Local risk estimation when server is offline
  /// Ported/Simplified from standard heart disease risk factors
  static Map<String, dynamic> predictHeartRisk(Map<String, dynamic> signals) {
    double riskScore = 0.0;
    
    // 1. Age Factor (Linear increase)
    int age = signals['age'] ?? 50;
    riskScore += (age - 20) * 0.5;

    // 2. Gender Factor (Males often higher historical risk in UCI dataset)
    int sex = signals['sex'] ?? 1;
    if (sex == 1) riskScore += 5;

    // 3. Chest Pain (CP) - High impact
    int cp = signals['cp'] ?? 0;
    if (cp > 0) riskScore += (cp * 10);

    // 4. Blood Pressure (trestbps)
    int bp = signals['trestbps'] ?? 120;
    if (bp > 140) riskScore += (bp - 140) * 0.4;
    if (bp > 160) riskScore += 10;

    // 5. Cholesterol (chol)
    int chol = signals['chol'] ?? 200;
    if (chol > 240) riskScore += (chol - 240) * 0.1;
    if (chol > 300) riskScore += 5;

    // 6. Max Heart Rate (thalach) - Lower is generally higher risk if age-adjusted
    int hr = signals['thalach'] ?? 150;
    int expectedMax = 220 - age;
    if (hr < expectedMax * 0.7) riskScore += 15;

    // 7. Exercise Angina (exang)
    int exang = signals['exang'] ?? 0;
    if (exang == 1) riskScore += 15;

    // 8. ST Depression (oldpeak)
    double oldpeak = double.tryParse(signals['oldpeak'].toString()) ?? 0.0;
    riskScore += oldpeak * 12;

    // 9. Vessels (ca)
    int ca = signals['ca'] ?? 0;
    riskScore += (ca * 12);

    // Normalize to 0-100%
    // Base score for a "healthy" person is around 10-20
    // Max score can reach ~150 with all factors, we'll clamp and scale
    riskScore = (riskScore / 1.5).clamp(5.0, 98.0);
    
    // Add small random jitter to make it feel "dynamic"
    riskScore += Random().nextDouble() * 2.0 - 1.0;
    riskScore = double.parse(riskScore.toStringAsFixed(2));

    String status = "Low Risk";
    if (riskScore > 70) {
      status = "High Risk";
    } else if (riskScore > 30) {
      status = "Moderate Risk";
    }

    return {
      "risk_score": riskScore,
      "status": status,
      "mode": "Offline Local Diagnostic"
    };
  }
}
