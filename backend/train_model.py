import os
import pandas as pd
import numpy as np
import joblib
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

def train_heart_model():
    """Generates synthetic medical data and trains a RandomForest model."""
    np.random.seed(42)
    data_size = 1000
    
    # Synthetic dataset mimicking the UCI Heart Disease dataset structure
    data = {
        'age': np.random.randint(29, 80, size=data_size),
        'sex': np.random.randint(0, 2, size=data_size),
        'cp': np.random.randint(0, 4, size=data_size),
        'trestbps': np.random.randint(94, 200, size=data_size),
        'chol': np.random.randint(126, 564, size=data_size),
        'fbs': np.random.randint(0, 2, size=data_size),
        'restecg': np.random.randint(0, 3, size=data_size),
        'thalach': np.random.randint(71, 202, size=data_size),
        'exang': np.random.randint(0, 2, size=data_size),
        'oldpeak': np.random.uniform(0, 6.2, size=data_size),
        'slope': np.random.randint(0, 3, size=data_size),
        'ca': np.random.randint(0, 5, size=data_size),
        'thal': np.random.randint(0, 4, size=data_size)
    }
    
    df = pd.DataFrame(data)
    
    # Logical risk heuristic for synthetic target generation
    risk_factor = (
        df['age'] * 0.1 + 
        df['chol'] * 0.05 + 
        df['trestbps'] * 0.05 + 
        df['oldpeak'] * 2.0
    ) 
    df['target'] = (risk_factor > risk_factor.median()).astype(int)

    # Dataset split
    X = df.drop('target', axis=1)
    y = df['target']
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

    # Model initialization and fitting
    print("Initializing RandomForestClassifier...")
    model = RandomForestClassifier(n_estimators=100, max_depth=10, random_state=42)
    model.fit(X_train, y_train)

    # Performance Evaluation
    accuracy = model.score(X_test, y_test)
    print(f"Model Training Complete.")
    print(f"Validation Accuracy: {accuracy * 100:.2f}%")

    # Artifact Export
    model_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'models')
    os.makedirs(model_dir, exist_ok=True)
    
    joblib.dump(model, os.path.join(model_dir, 'heart_disease_model.pkl'))
    joblib.dump(list(X.columns), os.path.join(model_dir, 'feature_names.pkl'))
    
    print(f"Predictive artifacts exported successfully to: {model_dir}")

if __name__ == "__main__":
    train_heart_model()
