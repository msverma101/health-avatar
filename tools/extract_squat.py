import numpy as np
import json
import sys

SRC = "mm-fit/w00/w00_pose_3d.npy"
OUT = "/home/techhub/health-avatar-app/data/exercises/squat.json"
START, END = 4040, 4500  # one squat rep (10 reps total in this set; pick first)

d = np.load(SRC)

def ang3(p_joint, p_a, p_b):
    u = p_a - p_joint
    v = p_b - p_joint
    c = np.dot(u, v) / (np.linalg.norm(u) * np.linalg.norm(v) + 1e-9)
    return np.degrees(np.arccos(np.clip(c, -1, 1)))

frames = []
for frame in range(START, END):
    f = d[:, frame, 1:]
    # per-leg joint angles
    hipL = ang3(f[:, 1], f[:, 11], f[:, 2])   # torso->thigh, left
    hipR = ang3(f[:, 4], f[:, 14], f[:, 5])
    kneeL = ang3(f[:, 2], f[:, 1], f[:, 3])   # thigh->shin, left
    kneeR = ang3(f[:, 5], f[:, 4], f[:, 6])
    ankL = ang3(f[:, 3], f[:, 2], f[:, 2] * 0 + f[:, 3])  # placeholder
    # torso lean: angle of spine (hip mid -> shoulder mid) vs vertical(axis2)
    hip_mid = (f[:, 1] + f[:, 4]) / 2
    sho_mid = (f[:, 11] + f[:, 14]) / 2
    vert = np.array([0, 0, 1.0])
    spine = sho_mid - hip_mid
    torso_lean = np.degrees(np.arccos(np.clip(np.dot(spine, vert) / (np.linalg.norm(spine) + 1e-9), -1, 1)))
    frames.append({
        "t": frame - START,
        "hipL": round(hipL, 2), "hipR": round(hipR, 2),
        "kneeL": round(kneeL, 2), "kneeR": round(kneeR, 2),
        "torso": round(torso_lean, 2),
    })

# simple smoothing (moving average window 5)
def smooth(vals, w=5):
    vals = np.array(vals, dtype=float)
    out = np.copy(vals)
    for i in range(len(vals)):
        lo = max(0, i - w // 2)
        hi = min(len(vals), i + w // 2 + 1)
        out[i] = vals[lo:hi].mean()
    return [round(float(x), 2) for x in out]

sm = {"hipL": smooth([x["hipL"] for x in frames]),
      "hipR": smooth([x["hipR"] for x in frames]),
      "kneeL": smooth([x["kneeL"] for x in frames]),
      "kneeR": smooth([x["kneeR"] for x in frames]),
      "torso": smooth([x["torso"] for x in frames])}

out = {"exercise": "Bodyweight squat", "source": "MM-Fit w00 (dev/prototype only)",
       "fps": 30.0, "n_frames": len(frames),
       "joint_angles": sm}
with open(OUT, "w") as fh:
    json.dump(out, fh, indent=1)
print("wrote", OUT, "frames:", len(frames))
print("kneeL range:", min(sm["kneeL"]), "-", max(sm["kneeL"]))
print("hipL range:", min(sm["hipL"]), "-", max(sm["hipL"]))
print("torso range:", min(sm["torso"]), "-", max(sm["torso"]))
