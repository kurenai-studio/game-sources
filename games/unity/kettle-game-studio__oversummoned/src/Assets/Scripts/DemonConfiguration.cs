using System;

[Serializable]
public class DamageLevel {
    public bool HornsBlood;
    public bool FaceBlood;
    public bool Brains;
    public bool EyesClosed;

    public static DamageLevel RandomDamage() {
        var damage = new DamageLevel() {
            FaceBlood = true,
            Brains = true,
            HornsBlood = true,
        };
        return damage;
    }
}

[Serializable]
public class DemonConfiguration {
    public int BodyId;
    public int HeadId;
    public int FaceId;
    public int HornsId;
    public int FeatureId;

    public bool MeetsRequest(DemonRequest request, DamageLevel damageLevel) {
        if (damageLevel.Brains || damageLevel.FaceBlood || damageLevel.HornsBlood)
            return false;

        if (request.FeatureId != -1 && request.FeatureId != FeatureId)
            return false;

        return request.HornsId == -1 ||  request.HornsId == HornsId;
    }
}

[Serializable]
public class DemonRequest {
    public int HornsId;
    public int FeatureId;
}