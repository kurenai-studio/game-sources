export const InferenceSystem = {
    /**
     * Generates a hypothesis test for a suspicious object.
     * returns: { pValue, isMimic, evidence, threshold: 0.05, h0, h1 }
     */
    generateInvestigation(isActuallyMimic) {
        const threshold = 0.05;
        
        // H0: Safe (Normal chest)
        // H1: Mimic (Hostile)
        
        // Let's use "Temperature" or "Vibration" as evidence.
        // If Safe (H0): N(36.5, 0.5)
        // If Mimic (H1): N(38.0, 0.5)
        
        const h0_mean = 36.5;
        const h0_std = 0.5;
        
        let evidence;
        if (isActuallyMimic) {
            // Sample from H1
            evidence = this._boxMuller(38.0, 0.5);
        } else {
            // Sample from H0
            evidence = this._boxMuller(36.5, 0.5);
        }

        // Calculate Z-score relative to H0
        const z = (evidence - h0_mean) / h0_std;
        
        // Two-tailed p-value (since too hot or too cold might be suspicious)
        // For simplicity, let's do one-tailed: "too hot/active"
        const pValue = 1 - this._normalCDF(z);

        return {
            pValue: parseFloat(pValue.toFixed(4)),
            isMimic: isActuallyMimic,
            evidence: parseFloat(evidence.toFixed(2)),
            threshold,
            h0: "O baú está em repouso térmico (Seguro)",
            h1: "O baú apresenta atividade biológica (Mímico)",
            metric: "Temperatura",
            unit: "°C"
        };
    },

    _boxMuller(mean, stdDev) {
        let u = 0, v = 0;
        while(u === 0) u = Math.random();
        while(v === 0) v = Math.random();
        return (Math.sqrt(-2.0 * Math.log(u)) * Math.cos(2.0 * Math.PI * v)) * stdDev + mean;
    },

    _normalCDF(x) {
        const t = 1 / (1 + 0.2316419 * Math.abs(x));
        const d = 0.3989423 * Math.exp(-x * x / 2);
        const p = d * t * (0.3193815 + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));
        return x > 0 ? 1 - p : p;
    }
};
