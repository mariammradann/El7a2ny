"""
Health Risk Engine — Personalized Health Monitoring Analytics
═══════════════════════════════════════════════════════════════

This module implements:
1. BaselineComputer  — Adaptive per-user baselines using EWMA
2. RiskScoreCalculator — Z-score + trend-based composite risk scoring (0-100)
3. AnomalyDetector — Threshold + trend escalation anomaly detection

SAFETY: Never claims medical diagnosis. Uses safe language only.
"""

import math
import logging
from datetime import timedelta
from django.utils import timezone
from django.db.models import Avg, StdDev, Min, Max, Count, F

from .models import (
    User, HealthMetric, HealthBaseline, HealthRiskScore,
    HealthAnomaly, HealthEmergencyReport,
)

logger = logging.getLogger(__name__)

# ═══════════════════════════════════════════════════════════════════════════════
# POPULATION DEFAULTS (cold-start fallbacks for first 14 days)
# ═══════════════════════════════════════════════════════════════════════════════

POPULATION_DEFAULTS = {
    "heart_rate": {"mean": 72.0, "std": 12.0, "min": 50, "max": 100, "unit": "bpm"},
    "spo2": {"mean": 97.0, "std": 1.5, "min": 94, "max": 100, "unit": "%"},
    "steps": {"mean": 7000.0, "std": 3000.0, "min": 0, "max": 25000, "unit": "steps"},
    "calories": {"mean": 2000.0, "std": 500.0, "min": 500, "max": 5000, "unit": "kcal"},
    "sleep_duration": {"mean": 450.0, "std": 60.0, "min": 240, "max": 600, "unit": "minutes"},
    "exercise": {"mean": 30.0, "std": 20.0, "min": 0, "max": 180, "unit": "minutes"},
}

# Minimum days of data before baseline is considered "mature"
BASELINE_MATURITY_DAYS = 14
# EWMA smoothing factor (higher = more weight on recent data)
EWMA_ALPHA = 0.15
# Default anomaly trigger threshold
DEFAULT_ANOMALY_THRESHOLD = 75
# Number of recent scores to check for trend escalation
TREND_WINDOW = 3

# Risk score weights for each metric type
RISK_WEIGHTS = {
    "heart_rate": 0.30,
    "spo2": 0.25,
    "steps": 0.20,  # inactivity detection
    "sleep_duration": 0.15,
    "exercise": 0.10,
}


# ═══════════════════════════════════════════════════════════════════════════════
# BASELINE COMPUTER
# ═══════════════════════════════════════════════════════════════════════════════

class BaselineComputer:
    """
    Computes and adaptively updates per-user health baselines.
    Uses EWMA (Exponential Weighted Moving Average) for smooth adaptation.
    Falls back to population defaults during cold-start period.
    """

    @staticmethod
    def compute_baseline(user, metric_type):
        """
        Compute or update baseline for a specific metric type.
        Returns the HealthBaseline object.
        """
        # Get all historical data for this metric
        metrics = HealthMetric.objects.filter(
            user=user, metric_type=metric_type
        ).order_by("recorded_at")

        if not metrics.exists():
            # No data at all — use population defaults
            defaults = POPULATION_DEFAULTS.get(metric_type, {})
            baseline, created = HealthBaseline.objects.update_or_create(
                user=user, metric_type=metric_type,
                defaults={
                    "mean_value": defaults.get("mean", 0),
                    "std_value": defaults.get("std", 0),
                    "min_value": defaults.get("min"),
                    "max_value": defaults.get("max"),
                    "sample_count": 0,
                    "is_mature": False,
                }
            )
            return baseline

        # Compute aggregate statistics
        stats = metrics.aggregate(
            mean=Avg("value"),
            std=StdDev("value"),
            min_val=Min("value"),
            max_val=Max("value"),
            count=Count("value"),
        )

        # Count unique days of data
        unique_days = metrics.dates("recorded_at", "day").count()

        new_mean = stats["mean"] or 0
        new_std = stats["std"] or 0
        is_mature = unique_days >= BASELINE_MATURITY_DAYS

        # If existing baseline exists, apply EWMA for smooth adaptation
        try:
            existing = HealthBaseline.objects.get(user=user, metric_type=metric_type)
            if existing.sample_count > 0:
                # EWMA: new = α * current + (1-α) * previous
                new_mean = EWMA_ALPHA * new_mean + (1 - EWMA_ALPHA) * existing.mean_value
                new_std = EWMA_ALPHA * new_std + (1 - EWMA_ALPHA) * existing.std_value
        except HealthBaseline.DoesNotExist:
            pass

        baseline, created = HealthBaseline.objects.update_or_create(
            user=user, metric_type=metric_type,
            defaults={
                "mean_value": new_mean,
                "std_value": max(new_std, 0.01),  # avoid zero std
                "min_value": stats["min_val"],
                "max_value": stats["max_val"],
                "sample_count": stats["count"],
                "is_mature": is_mature,
            }
        )
        return baseline

    @staticmethod
    def compute_all_baselines(user):
        """Compute baselines for all metric types for a user."""
        baselines = {}
        for metric_type, _ in HealthMetric.METRIC_TYPES:
            baselines[metric_type] = BaselineComputer.compute_baseline(user, metric_type)
        return baselines

    @staticmethod
    def get_baseline_or_default(user, metric_type):
        """Get existing baseline or population default."""
        try:
            return HealthBaseline.objects.get(user=user, metric_type=metric_type)
        except HealthBaseline.DoesNotExist:
            # Return a pseudo-baseline from population defaults
            defaults = POPULATION_DEFAULTS.get(metric_type, {"mean": 0, "std": 1})
            baseline = HealthBaseline(
                user=user,
                metric_type=metric_type,
                mean_value=defaults["mean"],
                std_value=defaults["std"],
                min_value=defaults.get("min"),
                max_value=defaults.get("max"),
                sample_count=0,
                is_mature=False,
            )
            return baseline

    @staticmethod
    def get_profile_maturity(user):
        """Check how mature the user's health profile is."""
        baselines = HealthBaseline.objects.filter(user=user)
        if not baselines.exists():
            return {"days_collected": 0, "is_mature": False, "progress_pct": 0}

        # Count unique days across all metrics
        unique_days = HealthMetric.objects.filter(
            user=user
        ).dates("recorded_at", "day").count()

        is_mature = unique_days >= BASELINE_MATURITY_DAYS
        progress_pct = min(100, int((unique_days / BASELINE_MATURITY_DAYS) * 100))

        return {
            "days_collected": unique_days,
            "is_mature": is_mature,
            "progress_pct": progress_pct,
        }


# ═══════════════════════════════════════════════════════════════════════════════
# RISK SCORE CALCULATOR
# ═══════════════════════════════════════════════════════════════════════════════

class RiskScoreCalculator:
    """
    Computes a composite health risk score (0-100) from multiple metrics.

    Techniques used:
    - Z-score deviation from personal baseline
    - Moving average smoothing (window of last 6 readings)
    - Time-window comparison (last hour vs last 24h)
    - Exponential weighted trend detection
    """

    @staticmethod
    def compute_z_score(value, mean, std):
        """Compute Z-score: how many standard deviations from mean."""
        if std == 0 or std is None:
            std = 0.01
        return abs(value - mean) / std

    @staticmethod
    def get_recent_moving_average(user, metric_type, window=6):
        """Get moving average of last N readings."""
        recent = HealthMetric.objects.filter(
            user=user, metric_type=metric_type
        ).order_by("-recorded_at")[:window]

        values = [m.value for m in recent]
        if not values:
            return None
        return sum(values) / len(values)

    @staticmethod
    def get_time_window_comparison(user, metric_type):
        """
        Compare last hour average vs last 24 hours average.
        Returns the ratio of deviation (> 1.0 means recent is higher).
        """
        now = timezone.now()
        last_hour = now - timedelta(hours=1)
        last_24h = now - timedelta(hours=24)

        recent_avg = HealthMetric.objects.filter(
            user=user, metric_type=metric_type,
            recorded_at__gte=last_hour
        ).aggregate(avg=Avg("value"))["avg"]

        daily_avg = HealthMetric.objects.filter(
            user=user, metric_type=metric_type,
            recorded_at__gte=last_24h
        ).aggregate(avg=Avg("value"))["avg"]

        if recent_avg is None or daily_avg is None or daily_avg == 0:
            return 1.0

        return recent_avg / daily_avg

    @staticmethod
    def compute_metric_risk(user, metric_type, baseline):
        """
        Compute risk contribution for a single metric.
        Returns: (risk_score_0_100, factor_dict)
        """
        # Get latest value
        latest = HealthMetric.objects.filter(
            user=user, metric_type=metric_type
        ).order_by("-recorded_at").first()

        if latest is None:
            return 0, None

        value = latest.value
        mean = baseline.mean_value
        std = baseline.std_value

        # 1. Z-score deviation
        z_score = RiskScoreCalculator.compute_z_score(value, mean, std)

        # 2. Moving average (smooth out noise)
        ma = RiskScoreCalculator.get_recent_moving_average(user, metric_type)
        ma_z_score = RiskScoreCalculator.compute_z_score(ma, mean, std) if ma else z_score

        # 3. Time-window comparison (trend detection)
        time_ratio = RiskScoreCalculator.get_time_window_comparison(user, metric_type)

        # Combine signals
        # Use the worse of single-reading and moving-average z-scores
        effective_z = max(z_score, ma_z_score)

        # Amplify if there's a rapid change trend
        trend_multiplier = 1.0
        if time_ratio > 1.3 or time_ratio < 0.7:
            trend_multiplier = 1.3  # 30% amplification for rapid changes

        # Special handling per metric type
        if metric_type == "spo2":
            # SpO2 dropping below baseline is more dangerous
            if value < mean:
                effective_z *= 1.5  # Amplify low SpO2

        elif metric_type == "steps":
            # Sudden inactivity is concerning (low steps when usually active)
            if value < mean * 0.3 and baseline.sample_count > 7:
                effective_z *= 1.3

        # Map Z-score to 0-100 risk scale
        # Z=0 → 0, Z=1 → ~15, Z=2 → ~40, Z=3 → ~70, Z=4+ → ~90+
        raw_risk = min(100, int(effective_z * trend_multiplier * 25))

        factor = {
            "metric_type": metric_type,
            "current_value": value,
            "baseline_mean": round(mean, 1),
            "baseline_std": round(std, 1),
            "z_score": round(z_score, 2),
            "moving_avg": round(ma, 1) if ma else None,
            "time_ratio": round(time_ratio, 2),
            "risk_contribution": raw_risk,
        }

        return raw_risk, factor

    @staticmethod
    def compute_risk_score(user):
        """
        Compute composite risk score for a user.
        Returns: HealthRiskScore object (saved to DB)
        """
        total_weighted_risk = 0
        total_weight = 0
        factors = []
        explanations = []

        for metric_type, weight in RISK_WEIGHTS.items():
            baseline = BaselineComputer.get_baseline_or_default(user, metric_type)
            risk, factor = RiskScoreCalculator.compute_metric_risk(user, metric_type, baseline)

            if factor is not None:
                total_weighted_risk += risk * weight
                total_weight += weight
                factors.append(factor)

                # Generate explanation for significant deviations
                if risk > 40:
                    explanations.append(
                        RiskScoreCalculator._generate_explanation(metric_type, factor)
                    )

        # Normalize
        if total_weight > 0:
            composite_score = int(total_weighted_risk / total_weight)
        else:
            composite_score = 0

        composite_score = max(0, min(100, composite_score))

        # Determine risk level
        if composite_score <= 20:
            risk_level = "normal"
        elif composite_score <= 50:
            risk_level = "low"
        elif composite_score <= 75:
            risk_level = "medium"
        else:
            risk_level = "high"

        explanation = " ".join(explanations) if explanations else "All health patterns appear within your normal range."

        # Save to DB
        risk_score = HealthRiskScore.objects.create(
            user=user,
            score=composite_score,
            risk_level=risk_level,
            factors=factors,
            explanation=explanation,
        )

        return risk_score

    @staticmethod
    def _generate_explanation(metric_type, factor):
        """Generate safe-language explanation for a metric deviation."""
        # SAFETY: Never claim medical diagnosis
        templates = {
            "heart_rate": "Elevated heart rate trend detected compared to your baseline.",
            "spo2": "Blood oxygen readings show an unusual pattern compared to your normal range.",
            "steps": "Significant change in activity level detected compared to your usual pattern.",
            "sleep_duration": "Sleep pattern disruption noted compared to your typical schedule.",
            "exercise": "Exercise pattern shows notable deviation from your baseline.",
            "calories": "Caloric activity shows an unusual trend.",
        }

        z = factor.get("z_score", 0)
        if z > 3:
            prefix = "Significant: "
        elif z > 2:
            prefix = ""
        else:
            prefix = "Mild: "

        base = templates.get(metric_type, f"Unusual {metric_type} pattern detected.")
        return prefix + base


# ═══════════════════════════════════════════════════════════════════════════════
# ANOMALY DETECTOR
# ═══════════════════════════════════════════════════════════════════════════════

class AnomalyDetector:
    """
    Detects health anomalies using:
    1. Threshold crossing (risk score > configurable threshold)
    2. Trend-based escalation (sustained increase over multiple readings)
    """

    @staticmethod
    def check_for_anomaly(user, risk_score, threshold=DEFAULT_ANOMALY_THRESHOLD):
        """
        Check if an anomaly should be triggered.
        Returns: HealthAnomaly object if triggered, None otherwise.
        """
        should_trigger = False
        trigger_reason = "none"

        # Check 1: Direct threshold crossing
        if risk_score.score > threshold:
            should_trigger = True
            trigger_reason = "threshold_crossed"

        # Check 2: Trend-based escalation
        # Look at last N risk scores — if consistently increasing, trigger even below threshold
        if not should_trigger:
            recent_scores = HealthRiskScore.objects.filter(
                user=user
            ).order_by("-computed_at")[:TREND_WINDOW + 1]

            scores = [s.score for s in recent_scores]
            if len(scores) >= TREND_WINDOW:
                # Check if scores are monotonically increasing
                is_escalating = all(scores[i] > scores[i + 1] for i in range(len(scores) - 1))
                # Also check if the latest score is in the "concerning" range
                if is_escalating and risk_score.score > 50:
                    should_trigger = True
                    trigger_reason = "trend_escalation"

        if not should_trigger:
            return None

        # Check if there's already an active anomaly for this user
        active_anomaly = HealthAnomaly.objects.filter(
            user=user, status="active"
        ).first()

        if active_anomaly:
            # Don't create duplicate — just update the existing one
            logger.info(f"Active anomaly already exists for user {user.user_id}")
            return active_anomaly

        # Build anomaly context
        current_metrics = AnomalyDetector._snapshot_current_metrics(user)
        baseline_comparison = AnomalyDetector._build_baseline_comparison(user)

        anomaly = HealthAnomaly.objects.create(
            user=user,
            risk_score=risk_score.score,
            current_metrics=current_metrics,
            baseline_comparison=baseline_comparison,
            factors=risk_score.factors,
            explanation=risk_score.explanation,
            status="active",
        )

        logger.warning(
            f"Health anomaly detected for user {user.user_id}: "
            f"score={risk_score.score}, reason={trigger_reason}"
        )

        return anomaly

    @staticmethod
    def _snapshot_current_metrics(user):
        """Take a snapshot of all latest metric values."""
        snapshot = {}
        for metric_type, label in HealthMetric.METRIC_TYPES:
            latest = HealthMetric.objects.filter(
                user=user, metric_type=metric_type
            ).order_by("-recorded_at").first()
            if latest:
                snapshot[metric_type] = {
                    "value": latest.value,
                    "unit": latest.unit,
                    "recorded_at": latest.recorded_at.isoformat(),
                }
        return snapshot

    @staticmethod
    def _build_baseline_comparison(user):
        """Build comparison of current values vs baselines."""
        comparison = {}
        for metric_type, label in HealthMetric.METRIC_TYPES:
            baseline = BaselineComputer.get_baseline_or_default(user, metric_type)
            latest = HealthMetric.objects.filter(
                user=user, metric_type=metric_type
            ).order_by("-recorded_at").first()

            if latest:
                comparison[metric_type] = {
                    "current": latest.value,
                    "baseline_mean": round(baseline.mean_value, 1),
                    "baseline_std": round(baseline.std_value, 1),
                    "deviation": round(abs(latest.value - baseline.mean_value), 1),
                    "z_score": round(
                        RiskScoreCalculator.compute_z_score(
                            latest.value, baseline.mean_value, baseline.std_value
                        ), 2
                    ),
                }
        return comparison

    @staticmethod
    def handle_user_response(anomaly_id, response):
        """
        Handle user response to an anomaly alert.
        response: 'ok' | 'help'
        """
        try:
            anomaly = HealthAnomaly.objects.get(anomaly_id=anomaly_id)
        except HealthAnomaly.DoesNotExist:
            return None

        anomaly.user_response = response
        anomaly.responded_at = timezone.now()

        if response == "ok":
            anomaly.status = "resolved"
        elif response == "help":
            anomaly.status = "acknowledged"
            # Create emergency report
            AnomalyDetector.create_emergency_report(anomaly)

        anomaly.save()
        return anomaly

    @staticmethod
    def handle_no_response(anomaly):
        """
        Called when user doesn't respond within timeout.
        Creates emergency report and notifies contacts.
        """
        anomaly.user_response = "no_response"
        anomaly.status = "acknowledged"
        anomaly.save()

        return AnomalyDetector.create_emergency_report(anomaly)

    @staticmethod
    def create_emergency_report(anomaly):
        """Create an emergency report from an anomaly."""
        user = anomaly.user

        # Get emergency contacts from user profile
        contacts = user.emergency_contacts or []

        report = HealthEmergencyReport.objects.create(
            user=user,
            anomaly=anomaly,
            risk_score=anomaly.risk_score,
            metrics_snapshot=anomaly.current_metrics,
            emergency_contacts_notified=contacts,
            status="pending",
        )

        logger.critical(
            f"Health emergency report created for user {user.user_id}: "
            f"report_id={report.report_id}, score={anomaly.risk_score}"
        )

        return report


# ═══════════════════════════════════════════════════════════════════════════════
# ORCHESTRATOR — Runs the full pipeline after each data sync
# ═══════════════════════════════════════════════════════════════════════════════

def process_health_sync(user, metrics_data):
    """
    Main entry point: called after new health data is synced from the app.

    1. Store new metrics
    2. Update baselines
    3. Compute risk score
    4. Check for anomalies

    Returns: dict with risk_score, anomaly (if any)
    """
    # 1. Store metrics
    stored_metrics = []
    for m in metrics_data:
        metric = HealthMetric.objects.create(
            user=user,
            metric_type=m["metric_type"],
            value=m["value"],
            unit=m["unit"],
            source=m.get("source", "health_connect"),
            recorded_at=m["recorded_at"],
            metadata=m.get("metadata", {}),
        )
        stored_metrics.append(metric)

    logger.info(f"Stored {len(stored_metrics)} health metrics for user {user.user_id}")

    # 2. Update baselines for affected metric types
    affected_types = set(m["metric_type"] for m in metrics_data)
    for metric_type in affected_types:
        BaselineComputer.compute_baseline(user, metric_type)

    # 3. Compute risk score
    risk_score = RiskScoreCalculator.compute_risk_score(user)

    # 4. Check for anomalies
    anomaly = AnomalyDetector.check_for_anomaly(user, risk_score)

    result = {
        "metrics_stored": len(stored_metrics),
        "risk_score": {
            "score": risk_score.score,
            "risk_level": risk_score.risk_level,
            "explanation": risk_score.explanation,
            "factors": risk_score.factors,
        },
        "anomaly": None,
    }

    if anomaly:
        result["anomaly"] = {
            "anomaly_id": str(anomaly.anomaly_id),
            "risk_score": anomaly.risk_score,
            "explanation": anomaly.explanation,
            "status": anomaly.status,
        }

    return result
