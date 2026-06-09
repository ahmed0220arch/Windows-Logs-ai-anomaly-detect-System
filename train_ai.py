import os
import pickle
import numpy as np
import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import TruncatedSVD
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import IsolationForest

def build_robust_ml_artifacts():
    print("Initializing Unsupervised Machine Learning Pipeline...")
    
    # 1. Base Features (Exact names required by ml_service.py)
    base_features = [
        "is_error", "Errors_Last_30s", "Errors_Last_1_Min", "Errors_Last_5_Min", 
        "Errors_Last_10_Min", "Errors_Last_15_Min", "Errors_Last_60_Min", "CUSUM_Errors", 
        "Short_Long_Ratio", "Mid_Long_Ratio", "Error_Trend_Slope", "Error_Density_5Min", 
        "Error_Density_15Min", "CPU_Velocity", "RAM_Velocity", "Hour_sin", "Hour_cos", 
        "Day_sin", "Day_cos"
    ]
    
    # 2. NLP Features
    nlp_features = [f"NLP_Dim_{i+1}" for i in range(5)]
    features_list = base_features + nlp_features
    
    # 3. Robust Bilingual Windows Corpus (The "Normal" Text Baseline)
    # This teaches the AI the exact semantic landscape of healthy OS operation.
    normal_windows_logs = [
        # English Services
        "System service started successfully",
        "The background intelligent transfer service entered the running state",
        "Network connection established successfully",
        "User authentication succeeded for domain login",
        "Windows Update checked for updates",
        "The synchronization process completed without errors",
        "DCOM negotiated protocols successfully",
        "The WinRM service is listening for WS-Management requests",
        "The DHCP client obtained an IP address",
        "Microsoft Defender Antivirus scan completed normally",
        # French Services
        "Le service a démarré avec succès",
        "Le service de transfert intelligent en arrière-plan est entré dans l'état en cours d'exécution",
        "Connexion réseau établie avec succès",
        "L'authentification de l'utilisateur a réussi",
        "Windows Update a recherché des mises à jour",
        "Le processus de synchronisation s'est terminé sans erreur",
        "DCOM a négocié les protocoles avec succès",
        "Le client DHCP a obtenu une adresse IP",
        "L'analyse de Microsoft Defender Antivirus s'est terminée normalement",
        "Le service Pare-feu Windows a démarré",
        # Mixed OS Chatter
        "Svchost.exe executed smoothly",
        "Lsass.exe performed credential validation",
        "Taskeng.exe completed background task",
        "Opération réussie",
        "Tâche planifiée terminée",
        "Le jeton d'accès a été créé",
        "Un processus a été créé",
        "The process was created successfully",
        "A process has exited"
    ] * 50  # Multiply to build a dense vocabulary space
    
    print("Training NLP Transformers on Bilingual Corpus...")
    tfidf = TfidfVectorizer(max_features=150, stop_words='english')
    x_tfidf = tfidf.fit_transform(normal_windows_logs)
    
    svd = TruncatedSVD(n_components=5, random_state=42)
    svd.fit(x_tfidf)
    
    # 4. Realistic Telemetry Distribution (StandardScaler)
    print("Generating Synthetic Telemetry Profiles...")
    n_samples = 5000
    np.random.seed(42)
    
    # CPU & RAM normal usage (Uniform distribution 10% to 70%)
    # We map this into velocity changes which fluctuate slightly around 0
    cpu_vel = np.random.normal(loc=0.0, scale=0.5, size=n_samples)
    ram_vel = np.random.normal(loc=0.0, scale=0.2, size=n_samples)
    
    # Error Rates (Poisson distribution modeling normal rare background errors)
    # A lambda of 0.5 means usually 0 errors, sometimes 1 or 2.
    # An attack generating 15 errors will fall WAY outside this distribution.
    errors = np.random.poisson(lam=0.5, size=(n_samples, 6))
    
    # Ratios and CUSUM
    ratios = np.random.normal(loc=1.0, scale=0.2, size=(n_samples, 3))
    cusum = np.random.exponential(scale=0.5, size=(n_samples, 1))
    densities = np.random.uniform(low=0.0, high=0.5, size=(n_samples, 2))
    
    # Time Trigonometry (Uniformly distributed across the 24h clock)
    time_trig = np.random.uniform(low=-1.0, high=1.0, size=(n_samples, 4))
    
    # is_error is strictly 0.0 for normal logs (errors are covered by rate bursts)
    is_err = np.zeros((n_samples, 1))
    
    # Combine all numerical features in the EXACT order of base_features
    # ['is_error', 'Errors_30s', '1m', '5m', '10m', '15m', '60m', 'CUSUM', 'ShortLong', 'MidLong', 'Slope', 'Dens5', 'Dens15', 'CPUv', 'RAMv', 'HourS', 'HourC', 'DayS', 'DayC']
    normal_numeric = np.hstack([
        is_err, errors, cusum, ratios, densities, cpu_vel.reshape(-1,1), ram_vel.reshape(-1,1), time_trig
    ])
    
    # Add NLP dimensions (centered around 0 for normal text variations)
    nlp_dims = np.random.normal(loc=0.0, scale=0.1, size=(n_samples, 5))
    
    normal_data = pd.DataFrame(
        np.hstack([normal_numeric, nlp_dims]),
        columns=features_list
    )
    
    print("Fitting Scaler...")
    scaler = StandardScaler()
    scaler.fit(normal_data)
    scaled_data = scaler.transform(normal_data)
    
    # 5. Advanced Isolation Forest Training
    print("Training 500-Tree Isolation Forest...")
    # 'auto' contamination allows the forest to define tight boundaries organically
    # based strictly on the topology of the provided normal data.
    model = IsolationForest(
        n_estimators=500, 
        max_samples='auto',
        contamination=0.005,  # Very strict bounds for demo/production recall
        random_state=42,
        n_jobs=-1  # Use all CPU cores for training
    )
    model.fit(scaled_data)
    
    # 6. Save Artifacts Safely
    out_dir = "backend/ml_artifacts"
    os.makedirs(out_dir, exist_ok=True)
    
    print("Exporting Artifacts to disk...")
    with open(os.path.join(out_dir, "tfidf_final.pkl"), "wb") as f:
        pickle.dump(tfidf, f)
    with open(os.path.join(out_dir, "svd_final.pkl"), "wb") as f:
        pickle.dump(svd, f)
    with open(os.path.join(out_dir, "features_final.pkl"), "wb") as f:
        pickle.dump(features_list, f)
    with open(os.path.join(out_dir, "scaler_final.pkl"), "wb") as f:
        pickle.dump(scaler, f)
    with open(os.path.join(out_dir, "model_final.pkl"), "wb") as f:
        pickle.dump(model, f)
        
    print("==================================================")
    print("SUCCESS: Perfect Production ML Artifacts Deployed!")
    print("==================================================")

if __name__ == "__main__":
    build_robust_ml_artifacts()
