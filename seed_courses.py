import os
import django

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "El7a2ny_backend.settings")
django.setup()

from El7a2ny_backend.models import TrainingCourse, TrainingLesson, CourseQuizQuestion
import uuid

def seed():
    # Clear existing training data to allow clean re-runs
    CourseQuizQuestion.objects.all().delete()
    TrainingLesson.objects.all().delete()
    TrainingCourse.objects.all().delete()

    print("[SEED] Seeding Training Academy Courses...")

    # --- Course 1: First Aid & CPR ---
    c1 = TrainingCourse.objects.create(
        title_en="CPR & Cardiopulmonary Resuscitation",
        title_ar="الإنعاش القلبي الرئوي والإسعافات الأولية",
        description_en="Learn how to perform Chest Compressions, rescue breathing, and handle choking in emergency situations.",
        description_ar="تعلم كيفية إجراء الضغطات الصدرية، والتنفس الاصطناعي، والتعامل مع حالات الاختناق في الحالات الطارئة.",
        category_en="First Aid",
        category_ar="إسعافات أولية",
        difficulty="beginner",
        duration_minutes=25,
        badge_name_en="First Aid Hero",
        badge_name_ar="بطل الإسعافات الأولية",
        price=150.00,
        is_irl=True,
        location_info_en="Cairo First Aid Academy, Downtown",
        location_info_ar="أكاديمية الإسعافات الأولية بالقاهرة، وسط البلد",
        schedule_info_en="Saturdays at 10:00 AM",
        schedule_info_ar="السبت الساعة ١٠:٠٠ صباحاً"
    )
    
    # Lessons for Course 1
    TrainingLesson.objects.create(
        course=c1,
        order_index=1,
        title_en="Introduction to CPR",
        title_ar="مقدمة في الإنعاش القلبي الرئوي",
        content_en="### What is CPR?\nCardiopulmonary Resuscitation (CPR) is an emergency procedure that can help save a person's life if their breathing or heart has stopped.\n\n### The Chain of Survival:\n1. **Early Recognition**: Recognize the cardiac arrest and call emergency services immediately.\n2. **Early CPR**: Start chest compressions to keep blood flowing to vital organs.\n3. **Rapid Defibrillation**: Use an AED as soon as one becomes available.\n\n### Critical Compressions:\n- Place both hands on the center of the chest.\n- Push hard and fast: at a rate of 100 to 120 compressions per minute.\n- Allow the chest to fully recoil between compressions.",
        content_ar="### ما هو الإنعاش القلبي الرئوي؟\nالإنعاش القلبي الرئوي (CPR) هو إجراء طارئ يمكن أن يساعد في إنقاذ حياة شخص ما إذا توقف تنفسه أو نبض قلبه.\n\n### سلسلة البقاء على قيد الحياة:\n1. **التعرف المبكر**: التعرف على السكتة القلبية والاتصال بخدمات الطوارئ فوراً.\n2. **الإنعاش القلبي الرئوي المبكر**: ابدأ الضغطات الصدرية للحفاظ على تدفق الدم إلى الأعضاء الحيوية.\n3. **إزالة الرجفان السريعة**: استخدم جهاز إزالة الرجفان الخارجي الآلي (AED) بمجرد توفره.\n\n### الضغطات الصدرية الحاسمة:\n- ضع كلتا يديك في منتصف الصدر.\n- اضغط بقوة وسرعة: بمعدل 100 إلى 120 ضغطة في الدقيقة.\n- اسمح للصدر بالارتداد بالكامل بين الضغطات.",
        reading_time_minutes=8
    )

    TrainingLesson.objects.create(
        course=c1,
        order_index=2,
        title_en="Rescue Breaths & Choking Rescue",
        title_ar="التنفس الاصطناعي وإسعاف الاختناق",
        content_en="### How to Give Rescue Breaths:\n- Tilt the victim's head back and lift the chin to open the airway.\n- Pinch the nose shut and make a complete seal over their mouth.\n- Blow into the mouth for 1 second, watching for the chest to rise.\n- Give 2 rescue breaths for every 30 chest compressions (30:2 ratio).\n\n### Choking Protocol (Heimlich Maneuver):\n- Stand behind the person, wrap your arms around their waist.\n- Make a fist with one hand and place it just above the navel.\n- Grasp the fist with your other hand and press into the abdomen with quick, upward thrusts.\n- Repeat until the blockage is dislodged or the victim becomes unconscious.",
        content_ar="### كيفية إعطاء التنفس الاصطناعي:\n- أمل رأس المصاب للخلف وارفع الذقن لفتح مجرى الهواء.\n- أغلق فتحتي الأنف بيدك وضع فمك بالكامل فوق فم المصاب.\n- انفخ في الفم لمدة ثانية واحدة، مع مراقبة ارتفاع الصدر.\n- أعطِ نفستين إنقاذيتين مقابل كل 30 ضغطة صدرية (نسبة 30:2).\n\n### بروتوكول الاختناق (مناورة هيمليخ):\n- قف خلف الشخص المصاب، ولف ذراعيك حول خصره.\n- اصنع قبضة بإحدى يديك وضعها فوق السرة مباشرة.\n- امسك القبضة بيدك الأخرى واضغط على البطن بدفعات سريعة وصاعدة.\n- كرر العملية حتى تخرج المادة المسببة للاختناق أو يفقد المصاب وعيه.",
        reading_time_minutes=10
    )

    # Quiz for Course 1
    CourseQuizQuestion.objects.create(
        course=c1,
        question_text_en="What is the recommended ratio of chest compressions to rescue breaths for adult CPR?",
        question_text_ar="ما هي النسبة الموصى بها للضغطات الصدرية إلى نفثات الإنقاذ في الإنعاش القلبي الرئوي للبالغين؟",
        options_en=["15 compressions to 2 breaths", "30 compressions to 2 breaths", "50 compressions to 5 breaths", "100 compressions to 10 breaths"],
        options_ar=["15 ضغطة إلى نفستين", "30 ضغطة إلى نفستين", "50 ضغطة إلى 5 نفثات", "100 ضغطة إلى 10 نفثات"],
        correct_option_index=1
    )
    
    CourseQuizQuestion.objects.create(
        course=c1,
        question_text_en="Where should you place your hands when performing chest compressions?",
        question_text_ar="أين يجب أن تضع يديك عند إجراء الضغطات الصدرية؟",
        options_en=["On the upper throat", "On the left side of the rib cage", "On the center of the chest (sternum)", "On the upper abdomen"],
        options_ar=["على الحلق العلوي", "على الجانب الأيسر من القفص الصدري", "في منتصف الصدر (عظمة القص)", "على الجزء العلوي من البطن"],
        correct_option_index=2
    )

    CourseQuizQuestion.objects.create(
        course=c1,
        question_text_en="What is the first step in the Heimlich Maneuver for a choking conscious adult?",
        question_text_ar="ما هي الخطوة الأولى في مناورة هيمليخ لشخص بالغ واعٍ يعاني من الاختناق؟",
        options_en=["Lay them on the floor", "Stand behind them and wrap your arms around their waist", "Perform blind finger sweeps in the mouth", "Start rescue breathing"],
        options_ar=["استلقائهم على الأرض", "الوقوف خلفهم ولف ذراعيك حول خصرهم", "إجراء مسح بالإصبع داخل الفم بشكل عشوائي", "البدء بالتنفس الاصطناعي"],
        correct_option_index=1
    )


    # --- Course 2: Fire Safety ---
    c2 = TrainingCourse.objects.create(
        title_en="Fire Safety & Extinguisher Mastery",
        title_ar="السلامة من الحرائق واستخدام مطافئ الحريق",
        description_en="Master the types of fires and learn how to use a fire extinguisher safely using the PASS method.",
        description_ar="تعرف على أنواع الحرائق المختلفة وكيفية استخدام طفاية الحريق بأمان باستخدام طريقة PASS.",
        category_en="Firefighting",
        category_ar="مكافحة الحرائق",
        difficulty="intermediate",
        duration_minutes=20,
        badge_name_en="Fire Marshal",
        badge_name_ar="مشرف سلامة الحرائق",
        price=250.00,
        is_irl=True,
        location_info_en="Giza Fire Station Training Yard",
        location_info_ar="ساحة تدريب مطافئ الجيزة",
        schedule_info_en="Tuesdays at 4:00 PM",
        schedule_info_ar="الثلاثاء الساعة ٤:٠٠ عصراً"
    )

    TrainingLesson.objects.create(
        course=c2,
        order_index=1,
        title_en="Understanding Fire Classes & Hazards",
        title_ar="فهم فئات الحرائق ومخاطرها",
        content_en="### Classes of Fire:\nNot all fires are the same. Using the wrong extinguisher can spread the fire or cause fatal electrocution!\n\n1. **Class A**: Ordinary combustibles (wood, paper, fabrics).\n2. **Class B**: Flammable liquids (gasoline, oils, paints).\n3. **Class C**: Electrical fires (short circuits, appliances).\n4. **Class D**: Combustible metals (magnesium, sodium).\n5. **Class K**: Cooking oils and kitchen fats.\n\n### Fire Hazards:\n- Smoke inhalation is the leading cause of death in fires, not burns.\n- Toxic gases can cause confusion or instant unconsciousness.",
        content_ar="### فئات الحرائق:\nليست كل الحرائق متشابهة. قد يؤدي استخدام طفاية حريق خاطئة إلى انتشار الحريق أو التسبب في صعق كهربائي قاتل!\n\n1. **الفئة أ (Class A)**: المواد الصلبة القابلة للاشتعال (الخشب، الورق، الأقمشة).\n2. **الفئة ب (Class B)**: السوائل القابلة للاشتعال (البنزين، الزيوت، الدهانات).\n3. **الفئة ج (Class C)**: حرائق الكهرباء (الماس الكهربائي، الأجهزة المنزلية).\n4. **الفئة د (Class D)**: المعادن القابلة للاحتراق (الماغنسيوم، الصوديوم).\n5. **الفئة ك (Class K)**: زيوت الطهي ودهون المطبخ.\n\n### مخاطر الحريق:\n- استنشاق الدخان هو السبب الرئيسي للوفاة في الحرائق، وليس الحروق.\n- يمكن أن تسبب الغازات السامة الارتباك أو فقدان الوعي الفوري.",
        reading_time_minutes=6
    )

    TrainingLesson.objects.create(
        course=c2,
        order_index=2,
        title_en="Using the PASS Method",
        title_ar="طريقة استخدام طفاية الحريق (PASS)",
        content_en="### The PASS Technique:\nWhen operating a fire extinguisher, remember the acronym **P-A-S-S**:\n\n1. **P - Pull**: Pull the safety pin at the top of the extinguisher to break the seal.\n2. **A - Aim**: Aim the nozzle or hose low at the base of the fire, not at the flames.\n3. **S - Squeeze**: Squeeze the handle lever slowly to discharge the extinguishing agent.\n4. **S - Sweep**: Sweep the hose side-to-side across the base of the fire until it goes out.\n\n### Safe Evacuation Rule:\nIf the fire spreads quickly, fills the room with thick smoke, or your exit path is threatened, **EVACUATE IMMEDIATELY** and call emergency services.",
        content_ar="### تقنية PASS:\nعند تشغيل طفاية حريق، تذكر الاختصار **P-A-S-S**:\n\n1. **P - Pull (اسحب)**: اسحب دبوس الأمان الموجود في الجزء العلوي من الطفاية لكسر الختم.\n2. **A - Aim (وجّه)**: وجه فوهة الخرطوم إلى قاعدة الحريق المنخفضة، وليس إلى اللهب.\n3. **S - Squeeze (اضغط)**: اضغط على المقبض ببطء لتفريغ مادة الإطفاء.\n4. **S - Sweep (حرّك)**: حرك الخرطوم من جانب إلى آخر عبر قاعدة الحريق حتى ينطفئ.\n\n### قاعدة الإخلاء الآمن:\nإذا انتشر الحريق بسرعة، أو امتلأت الغرفة بدخان كثيف، أو تعرض مسار خروجك للتهديد، **فاخلِ المكان فوراً** واتصل بخدمات الطوارئ.",
        reading_time_minutes=8
    )

    # Quiz for Course 2
    CourseQuizQuestion.objects.create(
        course=c2,
        question_text_en="What does the 'A' in the PASS fire safety acronym stand for?",
        question_text_ar="ماذا يرمز الحرف 'A' في اختصار السلامة من الحرائق PASS؟",
        options_en=["Activate the alarm", "Aim low at the base of the fire", "Alert the neighbors", "Always run away"],
        options_ar=["تفعيل الإنذار", "التوجيه لأسفل عند قاعدة الحريق", "تنبيه الجيران", "الهروب دائماً"],
        correct_option_index=1
    )

    CourseQuizQuestion.objects.create(
        course=c2,
        question_text_en="Which type of fire extinguisher should NEVER be used on an electrical fire?",
        question_text_ar="أي نوع من مطافئ الحريق لا يجب استخدامه أبداً في حريق كهربائي؟",
        options_en=["CO2 Extinguisher", "Water-based Extinguisher", "Dry Powder Extinguisher", "Clean Agent Extinguisher"],
        options_ar=["طفاية غاز ثاني أكسيد الكربون", "طفاية مائية", "طفاية البودرة الجافة", "طفاية المواد النظيفة"],
        correct_option_index=1
    )

    CourseQuizQuestion.objects.create(
        course=c2,
        question_text_en="What is the leading cause of death during a building fire?",
        question_text_ar="ما هو السبب الرئيسي للوفاة أثناء حريق المبنى؟",
        options_en=["Direct thermal burns", "Smoke inhalation and toxic gases", "Structural collapse of walls", "Panic and stampede"],
        options_ar=["الحروق الحرارية المباشرة", "استنشاق الدخان والغازات السامة", "الانهيار الهيكلي للجدران", "الذعر والتدافع"],
        correct_option_index=1
    )


    # --- Course 3: Disaster Preparedness ---
    c3 = TrainingCourse.objects.create(
        title_en="Disaster Preparedness & Evacuation",
        title_ar="الاستعداد للكوارث وإجراءات الإخلاء",
        description_en="Learn how to build survival kits, plan evacuation paths, and stay calm during earthquakes, floods, or structural crises.",
        description_ar="تعلم كيفية حقائب البقاء على قيد الحياة، وتخطيط مسارات الإخلاء، والحفاظ على الهدوء أثناء الزلازل أو الفيضانات.",
        category_en="Disaster Response",
        category_ar="مواجهة الكوارث",
        difficulty="advanced",
        duration_minutes=30,
        badge_name_en="Crisis Ready Responder",
        badge_name_ar="مستجيب مستعد للأزمات",
        price=350.00,
        is_irl=True,
        location_info_en="Civil Defense HQ, Nasr City",
        location_info_ar="مقر الحماية المدنية، مدينة نصر",
        schedule_info_en="Fridays at 1:00 PM",
        schedule_info_ar="الجمعة الساعة ١:٠٠ ظهراً"
    )

    TrainingLesson.objects.create(
        course=c3,
        order_index=1,
        title_en="Emergency Kits & Communication Plans",
        title_ar="حقائب الطوارئ وخطط الاتصال",
        content_en="### The 72-Hour Survival Kit:\nIn a major disaster, emergency services may not reach you immediately. You must prepare to survive independently for at least 72 hours. Your kit should include:\n\n- **Water**: 1 gallon per person per day.\n- **Food**: Non-perishable, easy-to-prepare items.\n- **First Aid Kit**: Bandages, antiseptics, and essential medications.\n- **Tools**: Flashlight, battery-powered radio, extra batteries, and a whistle to signal for help.\n\n### Family Communication Plan:\nEstablish an out-of-town contact person. If local lines are busy, calling long-distance or sending text messages is often easier and more reliable.",
        content_ar="### حقيبة البقاء لمدة 72 ساعة:\nفي الكوارث الكبرى، قد لا تصلك خدمات الطوارئ على الفور. يجب أن تكون مستعداً للبقاء بمفردك لمدة 72 ساعة على الأقل. يجب أن تحتوي حقيبتك على:\n\n- **الماء**: جالون واحد للشخص الواحد في اليوم.\n- **الغذاء**: أطعمة غير قابلة للتلف وسهلة التحضير.\n- **حقيبة إسعافات أولية**: ضمادات، مطهرات، وأدوية أساسية.\n- **أدوات**: كشاف ضوئي، راديو يعمل بالبطارية، بطاريات إضافية، وصفارة لإرسال إشارات الاستغاثة.\n\n### خطة اتصالات العائلة:\nحدد شخصاً كجهة اتصال خارج المدينة. إذا كانت الخطوط المحلية مشغولة، فإن الاتصال بمسافات طويلة أو إرسال الرسائل النصية يكون عادةً أسهل وأكثر موثوقية.",
        reading_time_minutes=10
    )

    TrainingLesson.objects.create(
        course=c3,
        order_index=2,
        title_en="Drop, Cover, and Hold On (Earthquake Safety)",
        title_ar="الانحناء والتغطية والثبات (سلامة الزلازل)",
        content_en="### During an Earthquake:\nIf you feel the ground shake, immediately practice **Drop, Cover, and Hold On**:\n\n1. **Drop**: Drop down onto your hands and knees. This prevents you from being knocked over.\n2. **Cover**: Cover your head and neck under a sturdy table or desk. If no shelter is nearby, crawl next to an interior wall.\n3. **Hold On**: Hold onto your shelter until the shaking stops. Be prepared for aftershocks.\n\n### What NOT to do:\n- Do NOT run outside while shaking is happening (falling debris is extremely dangerous).\n- Do NOT use elevators under any circumstances during or after the tremor.",
        content_ar="### أثناء الزلزال:\nإذا شعرت بهز الأرض، تدرب فوراً على **الانحناء والتغطية والثبات**:\n\n1. **انحنِ (Drop)**: انحنِ على يديك وركبتيك لحماية نفسك من السقوط.\n2. **تغطَّ (Cover)**: غطِ رأسك ورقبتك تحت طاولة أو مكتب قوي. إذا لم يكن هناك مأوى قريب، تزحف بجانب جدار داخلي.\n3. **اثبت (Hold On)**: تمسك بالمأوى الخاص بك حتى يتوقف الاهتزاز. كن مستعداً للهزات الارتدادية.\n\n### أشياء لا تفعلها:\n- لا تركض إلى الخارج أثناء حدوث الاهتزاز (الحطام المتساقط خطير للغاية).\n- لا تستخدم المصاعد تحت أي ظرف من الظروف أثناء أو بعد الهزة الأرضية.",
        reading_time_minutes=8
    )

    # Quiz for Course 3
    CourseQuizQuestion.objects.create(
        course=c3,
        question_text_en="What are the three actions recommended during an earthquake?",
        question_text_ar="ما هي الإجراءات الثلاثة الموصى بها أثناء حدوث زلزال؟",
        options_en=["Run, Shout, Evacuate", "Drop, Cover, and Hold On", "Stand in a doorway, Look up, Wait", "Call 122, Take photos, Hide"],
        options_ar=["الركض، الصراخ، الإخلاء", "الانحناء، التغطية، والثبات", "الوقوف عند الباب، النظر لأعلى، الانتظار", "الاتصال بـ 122، التقاط الصور، الاختباء"],
        correct_option_index=1
    )

    CourseQuizQuestion.objects.create(
        course=c3,
        question_text_en="How much water should be stored per person per day in an emergency kit?",
        question_text_ar="كمية المياه التي يجب تخزينها للشخص الواحد يومياً في حقيبة الطوارئ؟",
        options_en=["1 cup", "1 liter", "1 gallon (approx 3.8 liters)", "5 gallons"],
        options_ar=["كوب واحد", "لتر واحد", "جالون واحد (حوالي 3.8 لتر)", "5 جالونات"],
        correct_option_index=2
    )

    CourseQuizQuestion.objects.create(
        course=c3,
        question_text_en="Why is it advised not to run outside during earthquake shaking?",
        question_text_ar="لماذا يُنصح بعدم الركض إلى الخارج أثناء اهتزازات الزلزال؟",
        options_en=["To avoid getting lost", "To prevent traffic jams", "Falling debris and building parts pose extreme injury risk", "The air outside is toxic during tremors"],
        options_ar=["لتجنب الضياع", "لمنع الاختناقات المرورية", "الحطام المتساقط وأجزاء المباني تشكل خطراً كبيراً للإصابة", "الهواء الخارجي يكون ساماً أثناء الهزات"],
        correct_option_index=2
    )

    print("[SUCCESS] Seeding Completed successfully! 3 courses, 6 lessons, and 9 quiz questions created.")

if __name__ == "__main__":
    seed()
