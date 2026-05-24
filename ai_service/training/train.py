import os
import argparse
from ultralytics import YOLO

def main():
    parser = argparse.ArgumentParser(description="Train YOLOv8 on Emergency Incidents Dataset.")
    parser.add_argument("--data", type=str, required=True, help="Path to data.yaml file")
    parser.add_argument("--model", type=str, default="yolov8n.pt", help="Pretrained model weights (yolov8n.pt, yolov8s.pt, etc.)")
    parser.add_argument("--epochs", type=int, default=100, help="Number of training epochs")
    parser.add_argument("--batch", type=int, default=16, help="Batch size")
    parser.add_argument("--imgsz", type=int, default=640, help="Image size")
    parser.add_argument("--device", type=str, default="0", help="CUDA device index (e.g. 0) or 'cpu'")
    parser.add_argument("--project", type=str, default="el7a2ny_yolo", help="Project name")
    parser.add_argument("--name", type=str, default="emergency_detector", help="Run name")
    args = parser.parse_args()

    # Verify data.yaml exists
    if not os.path.exists(args.data):
        raise FileNotFoundError(f"data.yaml file not found at: {args.data}")

    print(f"Loading pretrained weights: {args.model}...")
    model = YOLO(args.model)

    print(f"Starting training on device={args.device} for {args.epochs} epochs...")
    results = model.train(
        data=args.data,
        epochs=args.epochs,
        batch=args.batch,
        imgsz=args.imgsz,
        device=args.device,
        project=args.project,
        name=args.name,
        workers=4,
        plots=True,
        save=True
    )

    print("\n✅ Training complete!")
    print("Evaluating model on validation set...")
    metrics = model.val()
    
    print(f"mAP50: {metrics.box.map50:.4f}")
    print(f"mAP50-95: {metrics.box.map:.4f}")

    # Export to ONNX for fast deployment/CPU inference
    print("Exporting model to ONNX format...")
    onnx_path = model.export(format="onnx")
    print(f"Exported ONNX model path: {onnx_path}")

if __name__ == "__main__":
    main()
