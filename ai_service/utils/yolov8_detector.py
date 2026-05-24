import os
import logging
from ultralytics import YOLO

logger = logging.getLogger(__name__)

# Predefined class names mapping for El7a2ny emergency model (COCO Fallback)
CLASS_NAMES = {
    0: "fire",
    1: "smoke",
    2: "vehicle-accident",
    3: "damaged-vehicle",
    4: "person-injured",
    5: "person-unconscious",
    6: "person-lying",
    7: "person-trapped",
    8: "blood",
    9: "crowd",
    10: "flood",
    11: "collapsed-building",
    12: "emergency-vehicle",
    13: "road-block",
    14: "animal-injured",
    15: "dangerous-animal"
}

# Mapping for the user's custom Roboflow version 2 dataset
CUSTOM_CLASS_NAMES = {
    0: "flood",
    1: "person-injured",
    2: "collapsed-building",
    3: "damaged-vehicle",
    4: "fire",
    5: "road-block",
    6: "smoke",
    7: "vehicle-accident",
    8: "person-unconscious"
}

class EmergencyDetector:
    def __init__(self, model_path: str = None):
        if not model_path:
            # Look for weights in ai_service/models/
            base_dir = os.path.dirname(os.path.dirname(__file__))
            model_path = os.path.join(base_dir, "models", "yolov8_emergency.pt")
            
        # Fallback to standard pretrained coco model if custom model is not yet trained/available
        self.is_custom = True
        if not os.path.exists(model_path):
            logger.warning(f"Custom model weights not found at: {model_path}. Falling back to 'yolov8n.pt'")
            model_path = "yolov8n.pt"
            self.is_custom = False
            
        logger.info(f"Initializing YOLOv8 model from: {model_path} (is_custom={self.is_custom})")
        self.model = YOLO(model_path)

    def detect(self, image_source) -> tuple[list[dict], dict]:
        """
        Run object detection on the image source.
        Returns:
            raw_detections: list of dicts with box, confidence, class name.
            detected_counts: summary dictionary with total occurrences.
        """
        # Run inference
        results = self.model(image_source, verbose=False)
        
        raw_detections = []
        detected_counts = {}
        
        # Initialize counts for custom classes (and fallback classes to be safe)
        active_names = CUSTOM_CLASS_NAMES if self.is_custom else CLASS_NAMES
        for name in CLASS_NAMES.values():
            detected_counts[name] = 0
        for name in CUSTOM_CLASS_NAMES.values():
            detected_counts[name] = 0
            
        # Add flags for simple checking
        detected_counts["fire_detected"] = False
        detected_counts["people_injured_count"] = 0
        detected_counts["unconscious_detected"] = False

        if not results:
            return raw_detections, detected_counts

        result = results[0]
        boxes = result.boxes
        
        for box in boxes:
            cls_id = int(box.cls[0].item())
            conf = float(box.conf[0].item())
            xyxy = box.xyxy[0].tolist() # [x1, y1, x2, y2]
            
            # Map classes based on custom weights vs coco fallback
            if not self.is_custom:
                # Fallback mapping for demo purposes using yolov8n.pt (COCO)
                class_name = "other"
                if cls_id == 0:  # person
                    class_name = "person-lying"  # Map to lying for demonstration if needed
                elif cls_id in [2, 3, 5, 7]:  # car, motorcycle, bus, truck
                    class_name = "damaged-vehicle"
                elif cls_id == 9:  # traffic light
                    class_name = "road-block"
                elif cls_id == 10:  # fire hydrant
                    class_name = "fire"
                elif cls_id in [15, 16]:  # cat, dog
                    class_name = "animal-injured"
            else:
                # Custom trained classes
                class_name = CUSTOM_CLASS_NAMES.get(cls_id, "other")

            raw_detections.append({
                "class": class_name,
                "confidence": conf,
                "box": xyxy
            })
            
            # Update summary counts
            if class_name in detected_counts:
                detected_counts[class_name] += 1
                
        # Fill convenience fields
        if detected_counts.get("fire", 0) > 0 or detected_counts.get("smoke", 0) > 0:
            detected_counts["fire_detected"] = True
            
        detected_counts["people_injured_count"] = (
            detected_counts.get("person-injured", 0) + 
            detected_counts.get("person-unconscious", 0) + 
            detected_counts.get("person-trapped", 0)
        )
        
        if detected_counts.get("person-unconscious", 0) > 0:
            detected_counts["unconscious_detected"] = True
            
        return raw_detections, detected_counts

    def detect_video(self, video_path: str) -> tuple[list[dict], dict]:
        """
        Sample 5 frames evenly from the video file and run YOLOv8 detection.
        Aggregates maximum object counts across sampled frames.
        """
        import cv2
        cap = cv2.VideoCapture(video_path)
        if not cap.isOpened():
            logger.error(f"Could not open video file: {video_path}")
            return [], {name: 0 for name in CUSTOM_CLASS_NAMES.values()}
        
        total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        if total_frames <= 0:
            return [], {name: 0 for name in CUSTOM_CLASS_NAMES.values()}
            
        # Sample 5 frames evenly
        sample_indices = [int(i * total_frames / 5) for i in range(5)]
        
        all_raw_detections = []
        aggregated_counts = {}
        for name in CLASS_NAMES.values():
            aggregated_counts[name] = 0
        for name in CUSTOM_CLASS_NAMES.values():
            aggregated_counts[name] = 0
            
        # Add flags
        aggregated_counts["fire_detected"] = False
        aggregated_counts["people_injured_count"] = 0
        aggregated_counts["unconscious_detected"] = False
        
        for idx in sample_indices:
            cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
            ret, frame = cap.read()
            if not ret:
                continue
            
            raw, counts = self.detect(frame)
            all_raw_detections.extend(raw)
            for k, v in counts.items():
                if isinstance(v, bool):
                    if v:
                        aggregated_counts[k] = True
                elif isinstance(v, (int, float)):
                    aggregated_counts[k] = max(aggregated_counts.get(k, 0), v)
                    
        cap.release()
        
        # Re-evaluate convenience flags
        if aggregated_counts.get("fire", 0) > 0 or aggregated_counts.get("smoke", 0) > 0:
            aggregated_counts["fire_detected"] = True
            
        aggregated_counts["people_injured_count"] = (
            aggregated_counts.get("person-injured", 0) + 
            aggregated_counts.get("person-unconscious", 0) + 
            aggregated_counts.get("person-trapped", 0)
        )
        
        if aggregated_counts.get("person-unconscious", 0) > 0:
            aggregated_counts["unconscious_detected"] = True
            
        return all_raw_detections, aggregated_counts
