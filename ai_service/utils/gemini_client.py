import os
import json
import logging
from google import genai
from google.genai import types

logger = logging.getLogger(__name__)

# Prompt instructing the Gemini model to parse detections and return structured data
SYSTEM_INSTRUCTION = """
You are the central emergency dispatch intelligence for El7a2ny (إلحقني), an Egyptian emergency response system.
Given the image of the incident (if provided), a list of YOLO detections, GPS context, and user description, you must synthesize:
1. A concise, professional summary of the incident in English and Egyptian Arabic. In this summary, you MUST explicitly state the key emergency objects or status visible in the photo (e.g. active fire, smoke, crashed vehicle, injured/unconscious person).
2. Step-by-step instructions for the reporting user on how to stay safe and how they can safely assist other people or animals injured/impacted in the accident until the ambulance/emergency services arrive. These instructions must be in English and Egyptian Arabic.
3. Step-by-step instructions for responders/volunteers (volunteer_instructions) in English and Egyptian Arabic.
   - IMPORTANT: Since volunteers are everyday citizens (not certified professionals) who will likely arrive BEFORE official emergency services, these instructions MUST:
     a. Be simple, numbered steps that ANY ordinary citizen can perform safely (no specialized gear or advanced medical certification required).
     b. Be focused on what the volunteer can do directly to assist the impacted people or animals at the scene UNTIL official emergency services arrive.
     c. NOT depend on official emergency services (like police or fire fighters) already being present. Do not instruct them to coordinate with or wait for emergency services before helping, as they are the first to arrive.
     d. Prioritize immediate actions: checking breathing, keeping victims warm/calm, securing a safe perimeter, warning traffic, preventing further harm.
4. Recommendations for volunteer dispatch: Specify the total count and split among functional roles:
   - "first_aid": Medical support/first aid.
   - "fire_response": Fire containment/crowd safety.
   - "transportation": Logistical support/evacuation assistance.
   - "rescue": Structural/vehicle extraction.
5. Severity assessment based on ACTUAL DANGER to people and animals in or near the scene:
   - "Critical" (Triage Red):  Immediate life threat — active fire/explosion near people or animals, unconscious/trapped victims, structural collapse with casualties, mass flooding with people present.
   - "High"     (Triage Orange): Serious but stable — injured conscious person, dangerous animal in public, significant vehicle accident with injured occupants, active fire without confirmed trapped victims.
   - "Medium"   (Triage Yellow): Moderate — vehicle accident with no visible injuries, minor injuries, road hazard, injured animal with no threat to people.
   - "Low"      (Triage Green):  Non-urgent — someone needs minor assistance (e.g. fuel, flat tire, minor fall), small crowd gathering, general non-emergency request.

Respond ONLY with a valid JSON document (no markdown, no code blocks) matching this exact schema:
{
  "severity": "Critical|High|Medium|Low",
  "triage_level": "Red|Orange|Yellow|Green",
  "summary": {
    "en": "concise English summary",
    "ar": "ملخص عربي مصري موجز وواضح"
  },
  "user_instructions": {
    "en": ["step 1", "step 2"],
    "ar": ["إجراء 1", "إجراء 2"]
  },
  "volunteer_instructions": {
    "en": ["step 1", "step 2"],
    "ar": ["خطوة 1", "خطوة 2"]
  },
  "volunteers_recommended": {
    "first_aid": int,
    "fire_response": int,
    "transportation": int,
    "rescue": int
  }
}

Use natural, clear, and reassuring Egyptian Arabic for the 'ar' translation values.
"""

class GeminiReasoner:
    def __init__(self):
        api_key = os.getenv("GEMINI_API_KEY")
        if not api_key:
            logger.error("GEMINI_API_KEY environment variable is not set!")
            self.client = None
        else:
            self.client = genai.Client(api_key=api_key)

    def reason_incident(self, yolo_counts: dict, user_description: str, baseline_severity: str, image_data: bytes = None, mime_type: str = None) -> dict:
        """
        Queries Gemini API to generate structured summary, guidelines, and staffing recommendations.
        Optionally accepts image_data and mime_type for multimodal analysis.
        """
        # Determine defaults based on both YOLO counts and text description keywords
        desc_lower = (user_description or "").lower()
        
        first_aid = 1 if yolo_counts.get("people_injured_count", 0) > 0 else 0
        fire_response = 1 if yolo_counts.get("fire_detected", False) else 0
        rescue = 1 if yolo_counts.get("person-trapped", 0) > 0 or yolo_counts.get("collapsed-building", 0) > 0 else 0
        
        if any(w in desc_lower for w in ["fire", "smoke", "burn", "حريق", "دخان", "نار"]):
            fire_response = max(fire_response, 1)
        if any(w in desc_lower for w in ["injured", "unconscious", "blood", "bleed", "مصاب", "مغمى", "دم"]):
            first_aid = max(first_aid, 1)
        if any(w in desc_lower for w in ["trapped", "collapse", "ruin", "محتجز", "انهيار"]):
            rescue = max(rescue, 1)

        # Construct dynamic summary based on YOLO detections & description
        detected_items = []
        ar_detected_items = []
        
        if yolo_counts.get("fire", 0) > 0 or yolo_counts.get("fire_detected", False):
            detected_items.append("active fire/smoke")
            ar_detected_items.append("حريق أو دخان نشط")
        if yolo_counts.get("vehicle-accident", 0) > 0 or yolo_counts.get("damaged-vehicle", 0) > 0:
            detected_items.append("damaged vehicles/collision")
            ar_detected_items.append("مركبات متضررة أو تصادم")
        if yolo_counts.get("people_injured_count", 0) > 0:
            count = yolo_counts.get("people_injured_count", 1)
            detected_items.append(f"{count} injured/trapped persons")
            ar_detected_items.append(f"مصابين أو أشخاص محاصرين (عدد {count})")
        if yolo_counts.get("collapsed-building", 0) > 0:
            detected_items.append("collapsed building structure")
            ar_detected_items.append("انهيار مبنى أو حطام")
        if yolo_counts.get("flood", 0) > 0:
            detected_items.append("flooding")
            ar_detected_items.append("فيضان وتراكم مياه")
        if yolo_counts.get("road-block", 0) > 0:
            detected_items.append("road blocks")
            ar_detected_items.append("عائق في الطريق أو انسداد مروري")

        if detected_items:
            summary_en = f"Emergency detected with: {', '.join(detected_items)}."
            summary_ar = f"تم رصد حالة طوارئ تحتوي على: {', '.join(ar_detected_items)}."
        else:
            summary_en = f"Incident reported. Description: {user_description or 'No description provided.'}"
            summary_ar = f"تم الإبلاغ عن حالة طوارئ. التفاصيل: {user_description or 'لا توجد تفاصيل.'}"

        # Dynamic instructions based on detections
        inst_en = ["Stay calm and move to a safe distance immediately if there is active danger."]
        inst_ar = ["حافظ على هدوئك وتحرك لمسافة آمنة فوراً إذا كان هناك خطر مباشر."]
        
        vol_inst_en = ["Assess the scene from a safe distance before stepping in."]
        vol_inst_ar = ["قيم الموقع من مسافة آمنة قبل التدخل."]

        # Fire instructions
        if yolo_counts.get("fire", 0) > 0 or yolo_counts.get("fire_detected", False) or "fire" in desc_lower or "حريق" in desc_lower:
            inst_en.append("Avoid inhaling smoke, stay low if there is smoke cover.")
            inst_ar.append("تجنب استنشاق الدخان، وابقى منخفضاً إذا كان الدخان كثيفاً.")
            vol_inst_en.append("Alert everyone nearby to evacuate the area immediately.")
            vol_inst_ar.append("نبّه كل الناس في الجوار عشان يخلوا المكان فوراً.")
            vol_inst_en.append("Help guide people to a safe assembly point away from smoke and heat.")
            vol_inst_ar.append("ساعد في توجيه الناس لمكان آمن بعيد عن الدخان والحرارة.")
            vol_inst_en.append("Keep bystanders at a safe distance and warning incoming traffic.")
            vol_inst_ar.append("ابعد الناس المتفرجين وحذّر العربيات اللي جاية.")
            
        # Vehicle accident instructions
        if yolo_counts.get("vehicle-accident", 0) > 0 or yolo_counts.get("damaged-vehicle", 0) > 0 or "accident" in desc_lower or "حادث" in desc_lower:
            inst_en.append("Watch out for fuel leaks and oncoming traffic.")
            inst_ar.append("انتبه لأي تسريب وقود وحركة المرور القادمة.")
            vol_inst_en.append("Check the scene for hazards like leaking fuel or traffic.")
            vol_inst_ar.append("اتأكد من أمان الموقع الأول (مفيش تسريب بنزين أو خطر طريق).")
            vol_inst_en.append("Direct traffic or set up warnings to protect the crash site.")
            vol_inst_ar.append("وجه المرور أو حط علامات تحذيرية عشان تحمي مكان الحادثة.")
            vol_inst_en.append("Reassure the occupants and tell them help is coming.")
            vol_inst_ar.append("طمن الناس اللي جوة العربية وقولهم المساعدة جاية.")

        # Injured people instructions
        if yolo_counts.get("people_injured_count", 0) > 0 or "injured" in desc_lower or "مصاب" in desc_lower:
            inst_en.append("Do not move injured people unless there is an immediate threat to life.")
            inst_ar.append("لا تحرك المصابين إلا إذا كان هناك خطر مباشر على حياتهم.")
            inst_en.append("Keep the injured person calm, check if they are breathing, and reassure them until the ambulance arrives.")
            inst_ar.append("حاول طمأنة المصاب ومساعدته على الاسترخاء، وتأكد من أنه يتنفس بشكل طبيعي حتى وصول الإسعاف.")
            vol_inst_en.append("Check if the person is responsive and breathing.")
            vol_inst_ar.append("اتأكد لو الشخص واعي وبيتنفس.")
            vol_inst_en.append("If they are unconscious but breathing, place them gently in the recovery position (on their side).")
            vol_inst_ar.append("لو فاقد الوعي بس بيتنفس، حطه براحة على جنبه (وضع الإفاقة).")
            vol_inst_en.append("Keep the person warm, quiet, and reassured.")
            vol_inst_ar.append("طمن المصاب وهدّيه ودفّيه.")
            vol_inst_en.append("Apply direct pressure with a clean cloth to any severe bleeding.")
            vol_inst_ar.append("اضغط بقطعة قماش نظيفة مباشرة على أي نزيف شديد.")

        # Animal injured instructions
        if yolo_counts.get("animal-injured", 0) > 0 or "animal" in desc_lower or "حيوان" in desc_lower or "كلب" in desc_lower or "قط" in desc_lower:
            inst_en.append("Approach injured animals slowly from a safe distance; keep them calm and warm until veterinary or emergency support arrives.")
            inst_ar.append("اقترب من الحيوانات المصابة ببطء ومن مسافة آمنة؛ حاول طمأنتها وتدفئتها حتى وصول المساعدة أو الطبيب البيطري.")
            vol_inst_en.append("Approach injured animals slowly from a safe distance to prevent bites/scratches.")
            vol_inst_ar.append("اقترب من الحيوانات المصابة ببطء ومن مسافة آمنة عشان ماتعضكش أو تخربشك.")
            vol_inst_en.append("Keep the animal warm and quiet from a safe distance.")
            vol_inst_ar.append("حافظ على تدفئة وهدوء الحيوان من مسافة آمنة.")

        # Building collapse instructions
        if yolo_counts.get("collapsed-building", 0) > 0 or "collapse" in desc_lower or "انهيار" in desc_lower:
            inst_en.append("Stay away from unstable structures and watch for falling debris.")
            inst_ar.append("ابعد عن الهياكل غير المستقرة وانتبه لتساقط الحطام.")
            vol_inst_en.append("Stay away from unstable structures and guide people away from falling debris.")
            vol_inst_ar.append("ابعد عن الهياكل غير المستقرة ووجه الناس يبعدوا عن تساقط الحطام.")

        inst_en.append("Share your live location with responders.")
        inst_ar.append("شارك موقعك الجغرافي المباشر لمساعدة المسعفين في الوصول إليك.")
        
        vol_inst_en.append("Keep the path clear for incoming emergency vehicles.")
        vol_inst_ar.append("اتأكد إن ممرات الدخول فاضية وسهلة لعربيات الطوارئ والإسعاف.")

        default_response = {
            "summary": {
                "en": summary_en,
                "ar": summary_ar
            },
            "user_instructions": {
                "en": inst_en,
                "ar": inst_ar
            },
            "volunteer_instructions": {
                "en": vol_inst_en,
                "ar": vol_inst_ar
            },
            "volunteers_recommended": {
                "first_aid": first_aid,
                "fire_response": fire_response,
                "transportation": 1 if first_aid > 0 else 0,
                "rescue": rescue
            }
        }

        if not self.client:
            logger.warning("Gemini Client not initialized. Returning default reasoning response.")
            return default_response

        # Format input text
        input_data = {
            "yolo_detections_counts": {k: v for k, v in yolo_counts.items() if v},
            "user_description": user_description or "No description provided",
            "baseline_severity": baseline_severity
        }

        prompt = (
            f"Perform emergency analysis for this incident payload: {json.dumps(input_data)}\n\n"
            "Analyze the attached image (if provided) along with the YOLO counts and description.\n"
            "In your summary (both English and Egyptian Arabic), you MUST explicitly describe what is visible "
            "in the image itself (such as an active fire, smoke columns, crashed cars, or a person who appears "
            "injured or unconscious).\n"
            "IMPORTANT — Assess severity based on ACTUAL DANGER TO PEOPLE AND ANIMALS near the scene:\n"
            "  - Critical: fire/explosion directly threatening people or animals, unconscious/trapped victims.\n"
            "  - High: injured person (conscious), dangerous animal, significant accident with injured occupants.\n"
            "  - Medium: vehicle accident no visible injuries, minor injuries, road hazard, injured animal (no threat to people).\n"
            "  - Low: non-urgent assistance (fuel, flat tyre, minor fall), small crowd, no injuries visible.\n"
            "In your user_instructions (both English and Egyptian Arabic), provide clear, actionable steps guiding the "
            "reporting user on how they can safely assist other people or animals injured/impacted in the accident "
            "(e.g., reassurance, checking breathing, comforting animals, etc.) until the ambulance/emergency services arrive."
        )

        contents = [prompt]
        if image_data and mime_type:
            contents.append(
                types.Part.from_bytes(
                    data=image_data,
                    mime_type=mime_type
                )
            )

        try:
            logger.info("Sending emergency details to Gemini...")
            response = self.client.models.generate_content(
                model="gemini-2.5-flash",
                contents=contents,
                config=types.GenerateContentConfig(
                    system_instruction=SYSTEM_INSTRUCTION,
                    response_mime_type="application/json"
                )
            )
            
            # Clean and parse response text
            text = response.text.strip()
            if text.startswith("```json"):
                text = text[7:]
            if text.startswith("```"):
                text = text[3:]
            if text.endswith("```"):
                text = text[:-3]
            text = text.strip()
            
            parsed_result = json.loads(text)
            
            # Basic schema validation
            required_keys = ["summary", "user_instructions", "volunteer_instructions", "volunteers_recommended"]
            if all(k in parsed_result for k in required_keys):
                # Normalise severity casing just in case Gemini returns lowercase
                raw_sev = parsed_result.get("severity", "")
                valid_severities = {"critical": "Critical", "high": "High", "medium": "Medium", "low": "Low"}
                parsed_result["severity"] = valid_severities.get(raw_sev.lower(), None)
                raw_tri = parsed_result.get("triage_level", "")
                valid_triages = {"red": "Red", "orange": "Orange", "yellow": "Yellow", "green": "Green"}
                parsed_result["triage_level"] = valid_triages.get(raw_tri.lower(), None)
                logger.info(f"Gemini severity assessment: {parsed_result.get('severity')} / {parsed_result.get('triage_level')}")
                return parsed_result
            else:
                logger.warning("Gemini JSON response is missing required keys. Using fallback.")
                return default_response
                
        except Exception as e:
            logger.error(f"Gemini API reasoning failed: {e}", exc_info=True)
            return default_response

