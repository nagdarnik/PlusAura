"""Build a self-contained dashboard with reproducible synthetic data (no dependencies)."""
import json
import random
from datetime import date, timedelta
from pathlib import Path

ROOT = Path(__file__).parent
rng = random.Random(20261101)
end = date(2026, 9, 30)
data = {"observed_until": str(end), "source": "synthetic", "users": [], "sessions": [], "workouts": []}
for i in range(600):
    uid = f"demo-{i:04}"
    signup = end - timedelta(days=rng.randrange(0, 91))
    engaged = rng.random() < .38
    data["users"].append({"id": uid, "signup": str(signup), "segment": rng.choice(["Органика", "Рекомендации", "Реклама"])})
    for age in range((end-signup).days+1):
        # Illustrative association is generated, not evidence of causality.
        probability = (.57 if engaged else .27) * (.992 if engaged else .977) ** age
        if age == 0 or rng.random() < probability:
            day = str(signup + timedelta(days=age))
            for _ in range(1 + int(rng.random() < .18)):
                data["sessions"].append({"id": f"s{len(data['sessions'])}", "user_id": uid, "date": day})
            if rng.random() < (.72 if engaged else .29):
                data["workouts"].append({"id": f"w{len(data['workouts'])}", "user_id": uid, "date": day, "duration": rng.choice([20, 30, 40, 45, 60]), "completed": rng.random() < .9})
template = (ROOT / "template.html").read_text()
template = template.replace("/* METRICS_SOURCE */", (ROOT / "metrics.js").read_text())
origin = min(u["signup"] for u in data["users"])
offset = lambda d: (date.fromisoformat(d) - date.fromisoformat(origin)).days
ids = {u["id"]: i for i, u in enumerate(data["users"])}
segments = sorted({u["segment"] for u in data["users"]})
packed = {
    "origin": origin, "end": data["observed_until"], "segments": segments,
    "users": [[offset(u["signup"]), segments.index(u["segment"])] for u in data["users"]],
    "sessions": [[ids[s["user_id"]], offset(s["date"])] for s in data["sessions"]],
    "workouts": [[ids[w["user_id"]], offset(w["date"]), w["duration"], int(w["completed"])] for w in data["workouts"]],
}
template = template.replace("/* DEMO_DATA */", json.dumps(packed, ensure_ascii=False, separators=(",", ":")))
(ROOT / "index.html").write_text(template)
print(f"Built index.html: {len(data['users'])} users, {len(data['sessions'])} sessions; synthetic only")
