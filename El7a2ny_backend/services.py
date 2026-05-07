import os
from ultralytics import YOLO

class YOLOManager:
    _instance = None
    _model = None

    def __new__(cls, *args, **kwargs):
        if not cls._instance:
            cls._instance = super(YOLOManager, cls).__new__(cls, *args, **kwargs)
        return cls._instance

    @property
    def model(self):
        if self._model is None:
            # Load the pre-trained YOLOv8 model once.
            # You can also use yolov8n.pt, yolov8s.pt, etc.
            # Using yolov8n.pt as a default lightweight model.
            self._model = YOLO('yolov8n.pt')
        return self._model

def detect_accident(image_path):
    """
    Analyzes an image using YOLOv8 to detect signs of common accidents.
    Looks for fire, cars, motorcycles, or crashes.
    """
    if not os.path.exists(image_path):
        return {
            "is_accident": False,
            "confidence": 0.0,
            "labels": []
        }

    # Use singleton to access the cached model
    manager = YOLOManager()
    model = manager.model

    # Run inference
    results = model(image_path)

    # Standard COCO labels or custom ones can be matched here
    # Standard YOLOv8 has: car, motorcycle, truck, bus, fire hydrant.
    # We will look for anything that indicates a potential accident.
    accident_keywords = {'car', 'motorcycle', 'truck', 'bus', 'fire hydrant', 'fire', 'crash'}
    
    is_accident = False
    max_confidence = 0.0
    detected_labels = []

    for result in results:
        # result.boxes contains bounding box info and labels
        if result.boxes is not None:
            for box in result.boxes:
                # Class name
                class_id = int(box.cls[0])
                label = model.names[class_id].lower()
                conf = float(box.conf[0])

                detected_labels.append(label)

                # Check if the detected label matches accident keywords
                if any(keyword in label for keyword in accident_keywords):
                    is_accident = True
                    if conf > max_confidence:
                        max_confidence = conf

    # To ensure it returns unique values
    detected_labels = list(set(detected_labels))

    return {
        "is_accident": is_accident,
        "confidence": round(max_confidence, 4),
        "labels": detected_labels
    }
