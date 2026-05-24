import logging

logger = logging.getLogger(__name__)

def evaluate_baseline_triage(detected_counts: dict) -> tuple[str, str, int]:
    """
    Evaluates incident severity based on detected emergency features.
    Returns:
        severity: "Low", "Medium", "High", "Critical"
        triage_level: "Red" (Immediate), "Orange" (Urgent), "Yellow" (Delayed), "Green" (Minor)
        urgency_score: integer from 1 to 10
    """
    # Base indicators
    has_unconscious = detected_counts.get("person-unconscious", 0) > 0
    has_trapped = detected_counts.get("person-trapped", 0) > 0
    has_injured = detected_counts.get("person-injured", 0) > 0
    has_fire = detected_counts.get("fire", 0) > 0 or detected_counts.get("fire_detected", False)
    has_collapse = detected_counts.get("collapsed-building", 0) > 0
    has_accident = detected_counts.get("vehicle-accident", 0) > 0 or detected_counts.get("damaged-vehicle", 0) > 0
    has_road_block = detected_counts.get("road-block", 0) > 0
    has_dangerous_animal = detected_counts.get("dangerous-animal", 0) > 0
    has_flood = detected_counts.get("flood", 0) > 0
    
    # 1. CRITICAL LEVEL TRIGGERS (Triage Red / Urgency 9-10)
    # Severe life threats: unconscious/trapped people, structural collapses with active fire, massive floods.
    if has_unconscious or has_trapped:
        return "Critical", "Red", 10
        
    if has_fire and (has_collapse or detected_counts.get("crowd", 0) > 5):
        return "Critical", "Red", 9
        
    if has_flood and detected_counts.get("crowd", 0) > 0:
        return "Critical", "Red", 9

    # 2. HIGH LEVEL TRIGGERS (Triage Orange / Urgency 7-8)
    # Severe but stable: Active fire, injured (conscious) victims, dangerous animals in public.
    if has_fire or has_injured or has_dangerous_animal:
        return "High", "Orange", 8
        
    if has_collapse:
        return "High", "Orange", 7

    # 3. MEDIUM LEVEL TRIGGERS (Triage Yellow / Urgency 4-6)
    # Stable: Vehicle accidents, road blocks, injured animals.
    if has_accident or has_road_block:
        return "Medium", "Yellow", 6
        
    if detected_counts.get("animal-injured", 0) > 0:
        return "Medium", "Yellow", 4

    # 4. LOW LEVEL TRIGGERS (Triage Green / Urgency 1-3)
    # Non-urgent: General crowds, minor smoke, empty damaged vehicles.
    if detected_counts.get("smoke", 0) > 0 or detected_counts.get("crowd", 0) > 0:
        return "Low", "Green", 3

    return "Low", "Green", 2
