import logging
from PIL import Image
from PIL.ExifTags import TAGS
from io import BytesIO

logger = logging.getLogger(__name__)

def analyze_metadata(image_bytes: bytes) -> dict:
    """
    Analyzes EXIF metadata from image bytes.
    Returns validation verdict and probability score of being a real mobile camera capture.
    """
    try:
        img = Image.open(BytesIO(image_bytes))
        exif_data = img._getexif()
        
        # If no exif data, this is suspicious (usually screenshot or edited/generated)
        if not exif_data:
            return {
                "valid": False,
                "score": 0.35, # Moderate chance of being fake
                "reason": "Missing EXIF metadata. Image is likely a screenshot, web-download, or AI-generated."
            }
            
        metadata = {}
        for tag, value in exif_data.items():
            decoded = TAGS.get(tag, tag)
            metadata[decoded] = value
            
        software = str(metadata.get("Software", "")).lower()
        
        # Check for image editors or generation packages
        ai_editors = ["midjourney", "stable diffusion", "dall-e", "photoshop", "gimp", "canva", "generative"]
        for tool in ai_editors:
            if tool in software:
                return {
                    "valid": False,
                    "score": 0.05, # High certainty of manipulation/generation
                    "reason": f"AI generation/editing software signature found: {metadata.get('Software')}"
                }
                
        # Real mobile photos typically contain camera manufacturer, model, and original capture time
        has_camera = "Make" in metadata or "Model" in metadata
        has_datetime = "DateTimeOriginal" in metadata or "DateTime" in metadata
        
        if has_camera and has_datetime:
            return {
                "valid": True,
                "score": 0.95,
                "reason": f"Valid camera metadata found: {metadata.get('Make')} {metadata.get('Model')}"
            }
            
        return {
            "valid": True,
            "score": 0.70,
            "reason": "EXIF metadata is present but incomplete (missing device descriptors)."
        }
        
    except Exception as e:
        logger.error(f"Error reading image metadata: {e}")
        return {
            "valid": False,
            "score": 0.40,
            "reason": f"Failed to parse EXIF metadata: {str(e)}"
        }

def check_image_consistency(yolo_detections: list[dict], user_description: str) -> float:
    """
    Checks semantic consistency between YOLO detections and the user's text description.
    Returns a score between 0.0 and 1.0 (1.0 = perfectly consistent or not contradictory).
    """
    if not user_description:
        return 1.0
        
    desc = user_description.lower()
    detected_classes = {d["class"] for d in yolo_detections}
    
    conflict_score = 1.0
    checks = 0
    failures = 0
    
    # Check 1: User claims fire/smoke
    if any(w in desc for w in ["fire", "smoke", "burn", "burning", "حريق", "نار", "دخان"]):
        checks += 1
        if "fire" not in detected_classes and "smoke" not in detected_classes:
            failures += 1
            
    # Check 2: User claims car crash/accident
    if any(w in desc for w in ["accident", "crash", "collision", "حادث", "تصادم"]):
        checks += 1
        if "vehicle-accident" not in detected_classes and "damaged-vehicle" not in detected_classes:
            failures += 1
            
    # Check 3: User claims blood or bleeding
    if any(w in desc for w in ["blood", "bleeding", "wound", "دم", "ينزف"]):
        checks += 1
        if "blood" not in detected_classes and "person-injured" not in detected_classes:
            failures += 1
            
    # Check 4: User claims collapse
    if any(w in desc for w in ["collapse", "collapsed", "ruins", "انهيار", "منهار"]):
        checks += 1
        if "collapsed-building" not in detected_classes:
            failures += 1

    if checks > 0:
        conflict_score = 1.0 - (failures / checks)
        
    return conflict_score

def calculate_authenticity_verdict(metadata_score: float, consistency_score: float, user_trust_score: float = 1.0) -> tuple[bool, float]:
    """
    Combines EXIF metadata analysis, YOLO consistency, and user historical trust score to return:
    - is_real (boolean verdict)
    - probability_of_real (float 0.0 to 1.0)
    """
    # Weights for final calculation
    w_meta = 0.50
    w_cons = 0.30
    w_trust = 0.20
    
    real_probability = (metadata_score * w_meta) + (consistency_score * w_cons) + (user_trust_score * w_trust)
    
    # A score below 0.50 indicates the report is likely fake
    is_real = real_probability >= 0.50
    
    return is_real, real_probability
