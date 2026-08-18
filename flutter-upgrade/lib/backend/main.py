
import os
import requests
from fastapi import FastAPI, HTTPException, Body
from pydantic import BaseModel
from dotenv import load_dotenv
from typing import List, Dict, Any, Optional

# تحميل متغيرات البيئة من ملف .env
load_dotenv()

# تهيئة تطبيق FastAPI
app = FastAPI(
    title="Medical History Analysis API",
    description="An API to analyze medical history using Hugging Face models.",
    version="1.0.0"
)

# جلب مفتاح API من متغيرات البيئة
API_KEY = os.getenv("HUGGING_FACE_API_KEY")
if not API_KEY:
    raise ValueError("HUGGING_FACE_API_KEY is not set in the environment variables.")

# عناوين URL لنماذج Hugging Face Inference API
# نموذج NER لاستخراج الكيانات الطبية (مثل التشخيصات)
NER_API_URL = "https://api-inference.huggingface.co/models/d4data/biomedical-ner-all"

# نموذج تلخيص تم تدريبه على بيانات طبية
SUMMARIZATION_API_URL = "https://api-inference.huggingface.co/models/ankur3107/bart-base-medical-summarization"

# نموذج استخراج النوايا/الأغراض الطبية
INTENT_DETECTION_API_URL = "https://api-inference.huggingface.co/models/Shobhank-iiitdwd/NLP-Medical-Intent-Detector"

# إعداد Headers للمصادقة
HEADERS = {"Authorization": f"Bearer {API_KEY}"}

# Pydantic models لتعريف بنية الطلب والاستجابة
class MedicalHistoryInput(BaseModel):
    text: str

class Diagnosis(BaseModel):
    entity: str
    score: float
    word: str

class AnalysisResult(BaseModel):
    summary: str
    diagnoses: List[Diagnosis]
    purposes: List[str] # حقل جديد للأغراض/النوايا
    recommendations: Optional[Dict[str, str]] = None

# دالة لإرسال الطلبات إلى Hugging Face API
def query_huggingface_api(api_url: str, payload: Dict[str, Any]) -> Any:
    """
    Sends a request to a specified Hugging Face Inference API endpoint.
    """
    response = requests.post(api_url, headers=HEADERS, json=payload)
    if response.status_code != 200:
        # رمي استثناء مع تفاصيل الخطأ من API
        raise HTTPException(
            status_code=response.status_code,
            detail=f"Error from Hugging Face API ({api_url}): {response.text}"
        )
    return response.json()

@app.post("/analyze", response_model=AnalysisResult)
async def analyze_medical_history(history_input: MedicalHistoryInput = Body(...)):
    """
    Analyzes medical history text to generate a summary, extract potential diagnoses, and identify medical purposes/intents.
    
    - **text**: The patient's medical history as a string.
    """
    medical_text = history_input.text
    
    # --- الخطوة 1: استخراج الكيانات الطبية (NER) للحصول على التشخيصات ---
    formatted_diagnoses = []
    try:
        ner_payload = {"inputs": medical_text}
        ner_results = query_huggingface_api(NER_API_URL, ner_payload)
        
        possible_diagnoses = [
            item for item in ner_results 
            if item['entity_group'] in ['Disease_disorder', 'Sign_symptom']
        ]
        
        top_diagnoses = sorted(possible_diagnoses, key=lambda x: x['score'], reverse=True)[:5]

        formatted_diagnoses = [
            Diagnosis(entity=d['entity_group'], score=d['score'], word=d['word'])
            for d in top_diagnoses
        ]

    except HTTPException as e:
        print(f"Failed to get diagnoses: {e.detail}")
    except Exception as e:
        print(f"Unexpected error during diagnosis extraction: {e}")

    # --- الخطوة 2: إنشاء ملخص للنص ---
    summary_text = "Could not generate summary."
    try:
        summarization_payload = {
            "inputs": medical_text,
            "parameters": {
                "min_length": 30,
                "max_length": 150,
                "do_sample": False
            }
        }
        summary_result = query_huggingface_api(SUMMARIZATION_API_URL, summarization_payload)
        summary_text = summary_result[0]['summary_text'] if summary_result else "Could not generate summary."

    except HTTPException as e:
        summary_text = "Summary generation failed."
        print(f"Summarization error: {e.detail}")
    except Exception as e:
        summary_text = "Could not generate summary due to an unexpected error."
        print(f"Unexpected error during summarization: {e}")

    # --- الخطوة 3: استخراج الأغراض/النوايا الطبية ---
    extracted_purposes = []
    try:
        intent_payload = {"inputs": medical_text}
        intent_results = query_huggingface_api(INTENT_DETECTION_API_URL, intent_payload)
        
        # نموذج Shobhank-iiitdwd/NLP-Medical-Intent-Detector يعيد قائمة من القواميس
        # كل قاموس يحتوي على 'label' و 'score'. نختار أعلى 3 نوايا.
        if intent_results and isinstance(intent_results, list) and len(intent_results) > 0:
            # النتائج تكون عادةً قائمة بقوائم، لذا نأخذ القائمة الأولى
            top_intents = sorted(intent_results[0], key=lambda x: x['score'], reverse=True)[:3]
            extracted_purposes = [intent['label'] for intent in top_intents]

    except HTTPException as e:
        print(f"Failed to get medical purposes: {e.detail}")
    except Exception as e:
        print(f"Unexpected error during purpose extraction: {e}")

    # --- الخطوة 4: تجميع النتائج ---
    recommendations = {
        "General Note": "This is an AI-generated analysis. Always consult with a qualified medical professional for diagnosis and treatment."
    }

    return AnalysisResult(
        summary=summary_text,
        diagnoses=formatted_diagnoses,
        purposes=extracted_purposes, # إضافة الأغراض المستخرجة
        recommendations=recommendations
    )

# نقطة نهاية بسيطة للتحقق من أن الـ API يعمل
@app.get("/")
def read_root():
    return {"status": "Medical History Analysis API is running."}

# لتشغيل الخادم محليًا:
# uvicorn main:app --reload
