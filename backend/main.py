import os
import ast
import datetime
import socket
import uvicorn
import joblib
import pandas as pd
from typing import Optional, Dict, Any, List
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="CardioGuardian AI")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=True,
)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_PATH = os.path.join(BASE_DIR, 'models', 'heart_disease_model.pkl')
FEATURES_PATH = os.path.join(BASE_DIR, 'models', 'feature_names.pkl')
EXCEL_PATH = os.path.join(BASE_DIR, 'health_database.xlsx')
CSV_BACKUP = os.path.join(BASE_DIR, 'health_database_backup.csv')

patients_db: List[Dict[str, Any]] = []
visits_db: List[Dict[str, Any]] = []
predictions_db: List[Dict[str, Any]] = []
vitals_db: List[Dict[str, Any]] = []


def get_local_ip():
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "127.0.0.1"


class ExcelDB:
    @staticmethod
    def _safe_read() -> pd.DataFrame:
        if os.path.exists(EXCEL_PATH):
            try:
                return pd.read_excel(EXCEL_PATH)
            except Exception as e:
                print(f"Excel read failed ({e}), recovering from CSV backup...")
                try:
                    os.rename(EXCEL_PATH, EXCEL_PATH + ".corrupted")
                except Exception:
                    pass
        if os.path.exists(CSV_BACKUP):
            try:
                return pd.read_csv(CSV_BACKUP)
            except Exception:
                pass
        return pd.DataFrame(columns=["Timestamp", "Action", "Details"])

    @staticmethod
    def _safe_write(df: pd.DataFrame):
        tmp_path = EXCEL_PATH.replace(".xlsx", "_tmp.xlsx")
        try:
            df.to_excel(tmp_path, index=False)
            if os.path.exists(EXCEL_PATH):
                os.replace(tmp_path, EXCEL_PATH)
            else:
                os.rename(tmp_path, EXCEL_PATH)
            df.to_csv(CSV_BACKUP, index=False)
        except Exception as e:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)
            raise e

    @staticmethod
    def initialize():
        global patients_db, visits_db, predictions_db, vitals_db
        df = ExcelDB._safe_read()
        if df.empty:
            ExcelDB._safe_write(df)
            print("Fresh Excel Database created.")
            return

        for _, row in df[df['Action'] == 'PATIENT_REGISTERED'].iterrows():
            try:
                data = ast.literal_eval(str(row['Details']))
                if isinstance(data, dict) and 'id' in data:
                    if not any(p['id'] == data['id'] for p in patients_db):
                        patients_db.append(data)
            except Exception:
                continue

        for _, row in df[df['Action'] == 'VISIT_SCHEDULED'].iterrows():
            try:
                data = ast.literal_eval(str(row['Details']))
                if isinstance(data, dict) and 'id' in data:
                    if not any(v['id'] == data['id'] for v in visits_db):
                        visits_db.append(data)
            except Exception:
                continue

        for _, row in df[df['Action'] == 'ML_REPORT_SAVED'].iterrows():
            try:
                data = ast.literal_eval(str(row['Details']))
                if isinstance(data, dict):
                    predictions_db.append(data)
            except Exception:
                continue

        for _, row in df[df['Action'] == 'VITAL_ENTRY'].iterrows():
            try:
                data = ast.literal_eval(str(row['Details']))
                if isinstance(data, dict):
                    vitals_db.append(data)
            except Exception:
                continue

        print(f"Restored {len(patients_db)} patients, {len(visits_db)} visits, {len(predictions_db)} predictions from Excel.")

    @staticmethod
    def write(action: str, data: Any):
        timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        entry = pd.DataFrame([{"Timestamp": timestamp, "Action": action, "Details": str(data)}])
        try:
            existing = ExcelDB._safe_read()
            updated = pd.concat([existing, entry], ignore_index=True)
            ExcelDB._safe_write(updated)
            print(f"  Excel [{action}] at {timestamp}")
        except Exception as e:
            print(f"  Excel FAIL [{action}]: {e}")


ExcelDB.initialize()

try:
    model = joblib.load(MODEL_PATH) if os.path.exists(MODEL_PATH) else None
    feature_names = joblib.load(FEATURES_PATH) if os.path.exists(FEATURES_PATH) else []
    if model:
        print("ML Model loaded successfully.")
    else:
        print("ML Model not found. Run train_model.py to generate it.")
except Exception as e:
    print(f"ML Model load error: {e}")
    model = None
    feature_names = []


class PatientEntry(BaseModel):
    id: Optional[str] = None
    name: str
    age: int
    gender: str
    contact: str

class PatientUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    contact: Optional[str] = None

class VisitEntry(BaseModel):
    id: Optional[str] = None
    patient_id: str
    patient_name: str
    purpose: str
    status: str = "Pending"

class HealthSignals(BaseModel):
    age: int
    sex: int
    cp: int
    trestbps: int
    chol: int
    fbs: int
    restecg: int
    thalach: int
    exang: int
    oldpeak: float
    slope: int
    ca: int
    thal: int

class ActionLog(BaseModel):
    action_name: str
    details: str

class ChatRequest(BaseModel):
    message: str

class VitalLog(BaseModel):
    patient_id: Optional[str] = None
    patient_name: Optional[str] = None
    type: str
    value: str
    unit: str

class MLReportSave(BaseModel):
    patient_id: str
    patient_name: str
    risk_score: float
    risk_status: str
    vitals: Dict[str, Any]


@app.get("/")
def status():
    server_ip = get_local_ip()
    return {
        "status": "Online",
        "server_ip": server_ip,
        "server_url": f"http://{server_ip}:8000",
        "patients": len(patients_db),
        "visits": len(visits_db),
        "predictions": len(predictions_db),
        "ml_model": "Loaded" if model else "Not Found"
    }

@app.get("/config")
def get_config():
    server_ip = get_local_ip()
    return {"server_ip": server_ip, "base_url": f"http://{server_ip}:8000"}


@app.get("/patients")
def get_patients():
    return patients_db

@app.post("/patients/add")
def add_patient(patient: PatientEntry):
    patient.id = str(len(patients_db) + 1)
    data = patient.model_dump()
    patients_db.append(data)
    ExcelDB.write("PATIENT_REGISTERED", data)
    return data

@app.put("/patients/{patient_id}")
def update_patient(patient_id: str, update: PatientUpdate):
    for p in patients_db:
        if p['id'] == patient_id:
            if update.name is not None: p['name'] = update.name
            if update.age is not None: p['age'] = update.age
            if update.gender is not None: p['gender'] = update.gender
            if update.contact is not None: p['contact'] = update.contact
            ExcelDB.write("PATIENT_UPDATED", p)
            return p
    return {"error": "Patient not found"}

@app.delete("/patients/{patient_id}")
def delete_patient(patient_id: str):
    global patients_db, visits_db
    patients_db = [p for p in patients_db if p['id'] != patient_id]
    visits_db = [v for v in visits_db if v['patient_id'] != patient_id]
    ExcelDB.write("PATIENT_DELETED", {"patient_id": patient_id})
    return {"status": "deleted", "remaining_patients": len(patients_db)}


@app.get("/visits")
def get_visits():
    return visits_db

@app.post("/visits/add")
def add_visit(visit: VisitEntry):
    visit.id = str(len(visits_db) + 1)
    data = visit.model_dump()
    visits_db.append(data)
    ExcelDB.write("VISIT_SCHEDULED", data)
    return data

@app.put("/visits/{visit_id}/status")
def update_visit_status(visit_id: str, status: str = "Completed"):
    for v in visits_db:
        if v['id'] == visit_id:
            v['status'] = status
            ExcelDB.write("VISIT_STATUS_UPDATED", v)
            return v
    return {"error": "Visit not found"}

@app.delete("/visits/{visit_id}")
def delete_visit(visit_id: str):
    global visits_db
    visits_db = [v for v in visits_db if v['id'] != visit_id]
    ExcelDB.write("VISIT_DELETED", {"visit_id": visit_id})
    return {"status": "deleted"}


@app.post("/predict")
def predict(signals: HealthSignals):
    data = signals.model_dump()
    ExcelDB.write("ML_PREDICTION_REQUEST", data)

    if model is None:
        result = {"risk_score": 14.5, "status": "Low Risk (Model not trained)"}
        ExcelDB.write("ML_RESULT", result)
        return result

    try:
        input_df = pd.DataFrame([data])[feature_names]
        prob = model.predict_proba(input_df)[0][1]
        risk = round(prob * 100, 2)
        status = "High Risk" if risk > 70 else "Moderate Risk" if risk > 30 else "Low Risk"
        result = {"risk_score": risk, "status": status}
        ExcelDB.write("ML_RESULT", result)
        return result
    except Exception as e:
        print(f"ML Error: {e}")
        fallback = {"risk_score": 0.0, "status": "Error"}
        ExcelDB.write("ML_ERROR", {"error": str(e)})
        return fallback


@app.post("/reports/save")
def save_report(report: MLReportSave):
    data = report.model_dump()
    data['timestamp'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    predictions_db.append(data)
    ExcelDB.write("ML_REPORT_SAVED", data)
    return {"status": "saved", "report": data}

@app.get("/reports")
def get_reports():
    return predictions_db

@app.get("/reports/patient/{patient_id}")
def get_patient_reports(patient_id: str):
    return [r for r in predictions_db if r.get('patient_id') == patient_id]


@app.post("/vitals/log")
def log_vital_entry(vital: VitalLog):
    data = vital.model_dump()
    data['timestamp'] = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    vitals_db.append(data)
    ExcelDB.write("VITAL_ENTRY", data)
    return {"status": "logged", "vital": data}

@app.get("/vitals")
def get_vitals():
    return vitals_db

@app.get("/vitals/patient/{patient_id}")
def get_patient_vitals(patient_id: str):
    return [v for v in vitals_db if v.get('patient_id') == patient_id]


@app.get("/dashboard/stats")
def dashboard_stats():
    total_patients = len(patients_db)
    total_visits = len(visits_db)
    pending_visits = len([v for v in visits_db if v.get('status', 'Pending') == 'Pending'])
    completed_visits = len([v for v in visits_db if v.get('status') == 'Completed'])
    total_predictions = len(predictions_db)
    total_vitals = len(vitals_db)

    high_risk = len([r for r in predictions_db if r.get('risk_score', 0) > 70])
    moderate_risk = len([r for r in predictions_db if 30 < r.get('risk_score', 0) <= 70])
    low_risk = len([r for r in predictions_db if r.get('risk_score', 0) <= 30])

    return {
        "total_patients": total_patients,
        "total_visits": total_visits,
        "pending_visits": pending_visits,
        "completed_visits": completed_visits,
        "total_predictions": total_predictions,
        "total_vitals": total_vitals,
        "risk_distribution": {"high": high_risk, "moderate": moderate_risk, "low": low_risk},
        "recent_patients": patients_db[-5:] if patients_db else [],
        "recent_predictions": predictions_db[-5:] if predictions_db else [],
        "server_status": "Online",
        "ml_model_status": "Loaded" if model else "Not Loaded",
        "excel_status": "Connected" if os.path.exists(EXCEL_PATH) else "Missing",
    }


@app.get("/analytics/summary")
def analytics_summary():
    ages = [p.get('age', 0) for p in patients_db]
    age_ranges = {"20-30": 0, "31-40": 0, "41-50": 0, "51-60": 0, "61-70": 0, "71+": 0}
    for age in ages:
        if age <= 30: age_ranges["20-30"] += 1
        elif age <= 40: age_ranges["31-40"] += 1
        elif age <= 50: age_ranges["41-50"] += 1
        elif age <= 60: age_ranges["51-60"] += 1
        elif age <= 70: age_ranges["61-70"] += 1
        else: age_ranges["71+"] += 1

    males = len([p for p in patients_db if p.get('gender', '').lower() == 'male'])
    females = len([p for p in patients_db if p.get('gender', '').lower() == 'female'])
    others = len(patients_db) - males - females

    risk_timeline = []
    for r in predictions_db:
        risk_timeline.append({
            "patient_name": r.get('patient_name', 'Unknown'),
            "risk_score": r.get('risk_score', 0),
            "timestamp": r.get('timestamp', ''),
        })

    risk_scores = [r.get('risk_score', 0) for r in predictions_db]
    avg_risk = round(sum(risk_scores) / len(risk_scores), 2) if risk_scores else 0

    bp_values, chol_values, hr_values = [], [], []
    for r in predictions_db:
        vitals = r.get('vitals', {})
        if 'trestbps' in vitals: bp_values.append(vitals['trestbps'])
        if 'chol' in vitals: chol_values.append(vitals['chol'])
        if 'thalach' in vitals: hr_values.append(vitals['thalach'])

    avg_bp = round(sum(bp_values) / len(bp_values), 1) if bp_values else 0
    avg_chol = round(sum(chol_values) / len(chol_values), 1) if chol_values else 0
    avg_hr = round(sum(hr_values) / len(hr_values), 1) if hr_values else 0

    return {
        "age_distribution": age_ranges,
        "gender_distribution": {"male": males, "female": females, "other": others},
        "risk_timeline": risk_timeline,
        "average_risk_score": avg_risk,
        "vital_averages": {"bp": avg_bp, "cholesterol": avg_chol, "heart_rate": avg_hr},
        "total_analyzed": len(predictions_db),
        "total_patients": len(patients_db),
    }


@app.post("/assistant/chat")
def chat(req: ChatRequest):
    msg = req.message.lower()
    ExcelDB.write("AI_QUERY", {"message": req.message})

    if "how many" in msg and "patient" in msg:
        reply = f"Currently there are {len(patients_db)} registered patients in the system."
    elif "how many" in msg and "visit" in msg:
        reply = f"There are {len(visits_db)} scheduled visits today."
    elif "risk" in msg and "average" in msg:
        scores = [r.get('risk_score', 0) for r in predictions_db]
        avg = round(sum(scores) / len(scores), 2) if scores else 0
        reply = f"The average risk score across all analyzed patients is {avg}%."
    elif "risk" in msg:
        reply = "Risk scores are computed using a RandomForest ML model trained on 13 cardiovascular biomarkers."
    elif "bp" in msg or "pressure" in msg:
        reply = "Optimal BP is 120/80 mmHg. Above 140/90 is Hypertension Stage 2."
    elif "chol" in msg:
        reply = "Healthy cholesterol is below 200 mg/dL. High LDL increases arterial plaque risk."
    elif "model" in msg or "ml" in msg:
        status = "loaded and ready" if model else "not trained yet"
        reply = f"The ML model is {status}. It uses a RandomForest Classifier with 13 UCI Heart Disease features."
    elif "excel" in msg or "database" in msg:
        exists = "connected and writing" if os.path.exists(EXCEL_PATH) else "not yet created"
        reply = f"The Excel database is {exists}. All actions are saved automatically."
    elif "help" in msg:
        reply = ("I can help with: patient counts, visit stats, risk score explanations, "
                 "blood pressure and cholesterol info, ML model status, and Excel database status.")
    else:
        reply = "CardioGuardian AI here. Ask me about BP, cholesterol, ML risk scores, patient stats, or any cardiac metric."

    ExcelDB.write("AI_REPLY", {"reply": reply})
    return {"reply": reply}


@app.post("/log/action")
def log_action(log: ActionLog):
    ExcelDB.write(log.action_name, {"details": log.details})
    return {"status": "ok"}

@app.post("/log/vital")
def log_vital(data: Dict[str, Any]):
    ExcelDB.write("VITAL_ENTRY", data)
    return {"status": "ok"}


@app.get("/excel/data")
def get_excel_data():
    df = ExcelDB._safe_read()
    if df.empty:
        return {"rows": [], "count": 0}
    records = df.to_dict(orient="records")
    return {"rows": records, "count": len(records)}

@app.get("/excel/actions")
def get_excel_actions():
    df = ExcelDB._safe_read()
    if df.empty or 'Action' not in df.columns:
        return {"actions": []}
    actions = df['Action'].unique().tolist()
    return {"actions": actions, "count": len(actions)}


if __name__ == "__main__":
    ip = get_local_ip()
    print(f"\n{'='*50}")
    print(f"  CardioGuardian AI Backend")
    print(f"  Local  : http://127.0.0.1:8000")
    print(f"  Network: http://{ip}:8000")
    print(f"  Excel  : {EXCEL_PATH}")
    print(f"{'='*50}\n")
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)
