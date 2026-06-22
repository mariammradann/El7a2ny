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
    15: "dangerous-animal",
    16: "fight"
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
    8: "person-unconscious",
    9: "fight"
}

class EmergencyDetector:
    def __init__(self, custom_model_path: str = "best.pt"):
        base_dir = os.path.dirname(os.path.dirname(__file__))
        
        # Load the standard COCO model
        logger.info("Initializing base YOLOv8 model from: yolov8n.pt")
        self.base_model = YOLO("yolov8n.pt")
        
        # Load the custom trained model if it exists
        custom_path = os.path.join(base_dir, custom_model_path)
        self.has_custom = os.path.exists(custom_path)
        if self.has_custom:
            logger.info(f"Initializing custom YOLOv8 model from: {custom_path}")
            self.custom_model = YOLO(custom_path)
        else:
            logger.warning(f"Custom model not found at {custom_path}. Make sure you moved best.pt to ai_service folder.")
            self.custom_model = None

    def detect(self, image_source) -> tuple[list[dict], dict]:
        raw_detections = []
        detected_counts = {}
        
        # Initialize counts for known fallback classes
        for name in CLASS_NAMES.values():
            detected_counts[name] = 0
            
        detected_counts["fire_detected"] = False
        detected_counts["people_injured_count"] = 0
        detected_counts["unconscious_detected"] = False

        # 1. Run base model (COCO)
        base_results = self.base_model(image_source, verbose=False)
        if base_results:
            for box in base_results[0].boxes:
                cls_id = int(box.cls[0].item())
                conf = float(box.conf[0].item())
                xyxy = box.xyxy[0].tolist()
                
                class_name = "other"
                if cls_id == 0:  
                    class_name = "person-lying"
                elif cls_id in [2, 3, 5, 7]:  
                    class_name = "damaged-vehicle"
                elif cls_id == 9:  
                    class_name = "road-block"
                elif cls_id == 10:  
                    class_name = "fire"
                elif cls_id in [15, 16]:  
                    class_name = "animal-injured"
                
                raw_detections.append({"class": class_name, "confidence": conf, "box": xyxy})
                detected_counts[class_name] = detected_counts.get(class_name, 0) + 1

        # 2. Run custom model (New Training)
        if self.has_custom:
            custom_results = self.custom_model(image_source, verbose=False)
            if custom_results:
                names_dict = self.custom_model.names
                for box in custom_results[0].boxes:
                    cls_id = int(box.cls[0].item())
                    conf = float(box.conf[0].item())
                    xyxy = box.xyxy[0].tolist()
                    
                    # Get actual class name from the trained model mapped to normalized name
                    class_name = CUSTOM_CLASS_NAMES.get(cls_id, names_dict.get(cls_id, "unknown"))
                    
                    raw_detections.append({"class": class_name, "confidence": conf, "box": xyxy})
                    detected_counts[class_name] = detected_counts.get(class_name, 0) + 1

        # Fill convenience fields
        if detected_counts.get("fire", 0) > 0 or detected_counts.get("smoke", 0) > 0:
            detected_counts["fire_detected"] = True
            
        detected_counts["people_injured_count"] = (
            detected_counts.get("person-injured", 0) + 
            detected_counts.get("person-unconscious", 0) + 
            detected_counts.get("person-trapped", 0) +
            detected_counts.get("person-lying", 0)
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
