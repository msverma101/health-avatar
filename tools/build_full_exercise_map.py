#!/usr/bin/env python3
"""Build the COMPLETE data/exercises.json from ALL Jeff Nippard PDFs.

Each exercise: name, primary (main target muscle group), sub_muscles (specific
muscles within the primary group), muscles (all groups hit), type, url.

Sources (all PDFs in the jeff nippard folder):
  - The Ultimate Exercise Guide (per-muscle anchors)
  - Pure Bodybuilding Push Pull Legs
  - Pure Bodybuilding Upper/Lower
  - Pure Bodybuilding Full Body
  - The Essentials Program
  - The Body Building Transformation System
  - document_compress / document_compress-1
YouTube demo links extracted from each PDF's embedded hyperlinks.
"""
import json, re

CHEST="chest"; SH="shoulders"; BACK="back"; BI="biceps"; TRI="triceps"
FA="forearms"; CORE="core"; QUAD="quadriceps"; HAM="hamstrings"
GLU="glutes"; CALF="calves"; NECK="neck"

# (primary, [sub_muscles within primary], [all groups], type)
EX = {
 # ===== CHEST =====
 "Barbell Bench Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "DB Bench Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Smith Machine Bench Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Incline DB Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "45° Incline DB Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Incline Machine Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "45° Incline Machine Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Low Incline DB Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Low Incline Machine Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Low Incline Smith Machine Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Machine Chest Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Machine Chest Press (Heavy)": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Machine Chest Press (Back off)": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Decline Machine Chest Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Decline Barbell Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Decline Smith Machine Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Smith Machine Incline Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Barbell Incline Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "45° Incline Barbell Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Flat DB Press (Heavy)": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Flat DB Press (Back off)": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Dumbbell Incline Press": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Pec Deck": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Pec Deck (w/ Integrated Partials)": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Low-Incline Dumbbell Flye": (CHEST,["Pectoralis major"],[CHEST,SH],"isolation"),
 "Bottom-Half DB Flye": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Bent-Over Cable Pec Flye": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Bent-Over Cable Pec Flye (w/ Integrated Partials)": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Seated Cable Flye": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Bottom-Half Seated Cable Flye": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Cable Crossover": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Cable Crossover Ladder": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Reverse Cable Crossover": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Cable Flye": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Dumbbell Flye": (CHEST,["Pectoralis major"],[CHEST],"isolation"),
 "Paused Assisted Dip": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Close Grip Dip": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Close-Grip Assisted Dip": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Weighted Dip (Heavy)": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Weighted Dip (Back off)": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Assisted Dip": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Bodyweight Dip": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),
 "Deficit Pushup": (CHEST,["Pectoralis major"],[CHEST,TRI,SH,CORE],"compound"),
 "Close-Grip Push Up": (CHEST,["Pectoralis major"],[CHEST,TRI,SH],"compound"),

 # ===== SHOULDERS =====
 "Machine Shoulder Press": (SH,["Deltoid"],[SH,TRI],"compound"),
 "Cable Shoulder Press": (SH,["Deltoid"],[SH,TRI],"compound"),
 "Seated DB Shoulder Press": (SH,["Deltoid"],[SH,TRI],"compound"),
 "Seated Barbell Shoulder Press": (SH,["Deltoid"],[SH,TRI],"compound"),
 "Seated Smith Machine Shoulder Press": (SH,["Deltoid"],[SH,TRI],"compound"),
 "Standing DB Arnold Press": (SH,["Deltoid"],[SH,TRI],"compound"),
 "Arnold Press": (SH,["Deltoid"],[SH,TRI],"compound"),
 "Cable Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "DB Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Machine Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Dumbbell Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Super-ROM DB Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Lean-In DB Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "High-Cable Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "High-Cable Cuffed Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Cuffed Behind-The-Back Lateral Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Cross-Body Cable Y-Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Cable Y-Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Incline DB Y-Raise": (SH,["Deltoid"],[SH],"isolation"),
 "Cable Reverse Flye (Mechanical Dropset)": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "Rear Delt 45° Cable Flye": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "1-Arm 45° Cable Rear Delt Flye": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "Rear Delt Flye": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "Lying Reverse DB Flye": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "Reverse Flye": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "DB Rear Delt Swing": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "Reverse Pec Deck (w/ Integrated Partials)": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "1-Arm Reverse Pec Deck": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "Bent-Over Reverse DB Flye": (SH,["Deltoid"],[SH,BACK],"isolation"),
 "Lying Paused Rope Face Pull": (SH,["Deltoid","Trapezius"],[SH,BACK],"isolation"),
 "Rope Face Pull": (SH,["Deltoid","Trapezius"],[SH,BACK],"isolation"),
 "Cable Upright Row": (SH,["Trapezius","Deltoid"],[SH,BI],"compound"),
 "Cable Paused Shrug-In": (SH,["Trapezius"],[SH],"isolation"),
 "Cable Shrug-In": (SH,["Trapezius"],[SH],"isolation"),
 "Incline DB Kelso Shrug": (SH,["Trapezius"],[SH,BACK],"isolation"),
 "Seated Cable Kelso Shrug": (SH,["Trapezius"],[SH],"isolation"),
 "Trap-Bar Shrug": (SH,["Trapezius"],[SH],"isolation"),
 "Wide-Grip Barbell Shrug": (SH,["Trapezius"],[SH],"isolation"),
 "Barbell Shrug": (SH,["Trapezius"],[SH],"isolation"),
 "DB Shrug": (SH,["Trapezius"],[SH],"isolation"),
"Neck Curl / Extension": (NECK,["Sternocleidomastoid","Splenius"],[NECK],"isolation"),
"Head Curl": (NECK,["Sternocleidomastoid"],[NECK],"isolation"),
"Plate-Loaded Neck Curls": (NECK,["Sternocleidomastoid","Longus colli & capitis"],[NECK],"isolation"),
"Plate-Loaded Neck Extension": (NECK,["Splenius","Semispinalis","Levator scapulae"],[NECK],"isolation"),
"Head Harness Neck Extension": (NECK,["Splenius","Semispinalis"],[NECK],"isolation"),

 # ===== BACK =====
 "Cross-Body Lat Pull-Around": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Straight-Bar Lat Prayer": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Cable Lat Prayer": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Machine Lat Pullover": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "DB Lat Pullover": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Cable Lat Pullover": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Neutral-Grip Lat Pulldown": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Neutral-Grip Close-Grip Lat Pulldown": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Lean-Back Lat Pulldown": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Close-Grip Lat Pulldown": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Dual-Handle Lat Pulldown": (BACK,["Latissimus dorsi","Rhomboids"],[BACK,BI],"compound"),
 "Dual-Handle Lat Pulldown (Mid-back + Lats)": (BACK,["Latissimus dorsi","Rhomboids"],[BACK,BI],"compound"),
 "Lat Pulldown (Wide Grip)": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "2-Grip Lat Pulldown": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Machine Pulldown": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "1-Arm Cable Pulldown": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "1-Arm Lat Pull-In": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Half-Kneeling 1-Arm Lat Pulldown": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Assisted Pull-Up": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Neutral-Grip Pull-Up": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Wide-Grip Pull-Up": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Close-Grip Pull-Up": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "2-Grip Pull-up": (BACK,["Latissimus dorsi"],[BACK,BI],"compound"),
 "Chest-Supported Machine Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Chest-Supported T-Bar Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Chest-Supported T-Bar Row + Kelso Shrug": (BACK,["Rhomboids","Trapezius","Latissimus dorsi"],[BACK,SH,BI],"compound"),
 "T-Bar Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Pendlay Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH,HAM],"compound"),
 "Deficit Pendlay Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH,HAM],"compound"),
 "Pendlay Deficit Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH,HAM],"compound"),
 "Smith Machine Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Meadows Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Helms DB Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Seated Cable Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Neutral-Grip Seated Cable Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Close-Grip Seated Cable Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Super-ROM Overhand Cable Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Lat-Focused Cable Row": (BACK,["Latissimus dorsi","Rhomboids"],[BACK,BI,SH],"compound"),
 "Dual-Handle Elbows-Out Cable Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Elbows-Out Cable Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Elbows-In 1-Arm DB Row": (BACK,["Latissimus dorsi","Rhomboids"],[BACK,BI,SH],"compound"),
 "Arm-Out Single-Arm DB Row": (BACK,["Latissimus dorsi","Rhomboids"],[BACK,BI,SH],"compound"),
 "Incline Chest-Supported DB Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Supported DB Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Chest-supported DB Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Super-ROM Overhand Cable Row": (BACK,["Rhomboids","Latissimus dorsi"],[BACK,BI,SH],"compound"),
 "Arms-Extended 45° Hyperextension": (BACK,["Erector spinae"],[BACK,HAM,GLU],"compound"),
 "45° Hyperextension": (BACK,["Erector spinae"],[BACK,HAM,GLU],"compound"),

 # ===== BICEPS =====
 "Bayesian Cable Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Slow-Eccentric Bayesian Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Bayesian High Cable Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "DB Bicep Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Barbell Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "EZ Bar Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "EZ-Bar Cable Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Cable EZ Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Cable Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "DB Incline Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Incline DB Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Incline DB Stretch-Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Concentration Cable Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "DB Concentration Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Spider Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Bottom-2/3 Constant Tension Preacher Curl": (BI,["Biceps brachii"],[BI,FA],"isolation"),
 "Hammer Preacher Curl": (BI,["Biceps brachii","Brachialis"],[BI,FA],"isolation"),
 "45-Degree Dumbbell Preacher Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "DB Preacher Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Machine Preacher Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "EZ-Bar Preacher Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Fat-Grip Preacher Curl": (BI,["Biceps brachii","Brachialis"],[BI,FA],"isolation"),
 "N1-Style Short-Head Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Reverse-Grip Cable Curl": (BI,["Biceps brachii","Brachialis"],[BI,FA],"isolation"),
 "Reverse-Grip EZ-Bar Curl": (BI,["Biceps brachii","Brachialis"],[BI,FA],"isolation"),
 "Hammer Curl": (BI,["Brachialis","Biceps brachii"],[BI,FA],"isolation"),
 "DB Hammer Curl": (BI,["Brachialis","Biceps brachii"],[BI,FA],"isolation"),
 "Cable Rope Hammer Curl": (BI,["Brachialis","Biceps brachii"],[BI,FA],"isolation"),
 "Preacher Hammer Curl": (BI,["Brachialis","Biceps brachii"],[BI,FA],"isolation"),
 "Inverse DB Zottman Curl": (BI,["Biceps brachii","Brachioradialis"],[BI,FA],"isolation"),
 "Inverse Zottman Curl": (BI,["Biceps brachii","Brachioradialis"],[BI,FA],"isolation"),
 "Modified Zottman Curl": (BI,["Biceps brachii","Brachioradialis"],[BI,FA],"isolation"),
 "Standing DB Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Alternating DB Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "EZ-Bar Cheat Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "DB Cheat Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Kneeling Overhead Cable Curl": (BI,["Biceps brachii"],[BI],"isolation"),
 "Fat-Grip DB Curl": (BI,["Biceps brachii","Brachialis"],[BI,FA],"isolation"),

 # ===== TRICEPS =====
 "Overhead Cable Triceps Extension": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Overhead Cable Triceps Extension (Bar)": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Single-arm Overhead Cable Triceps Extension": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Overhead DB Triceps Extension": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Katana Triceps Extension": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Dual-Cable Triceps Press": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Triceps Pressdown (Bar)": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Triceps Pressdown (Rope)": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Triceps Pressdown": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Triceps Diverging Pressdown (Long Rope or 2 Ropes)": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Cable Triceps Kickback": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "DB Triceps Kickback": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Skull Crusher": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "EZ-Bar Skull Crusher": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Slow-Eccentric EZ-Bar Skull Crusher": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Cable Skull Crusher": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "DB Skull Crusher": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Floor Skull Crusher": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Seated DB French Press": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "DB French Press": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "French Press": (TRI,["Triceps brachii"],[TRI],"isolation"),
 "Smith Machine JM Press": (TRI,["Triceps brachii"],[TRI,CHEST],"compound"),
 "Barbell JM Press": (TRI,["Triceps brachii"],[TRI,CHEST],"compound"),
 "Close-Grip Bench Press": (TRI,["Triceps brachii"],[TRI,CHEST],"compound"),
 "Bench Dip": (TRI,["Triceps brachii"],[TRI,CHEST],"compound"),
 "Seated Dip Machine": (TRI,["Triceps brachii"],[TRI,CHEST],"compound"),

 # ===== FOREARMS =====
 "Dumbbell Wrist Curl / Reverse Curl": (FA,["Wrist flexors","Wrist extensors"],[FA],"isolation"),
 "DB Wrist Curl": (FA,["Wrist flexors"],[FA],"isolation"),
 "Cable Wrist Curl": (FA,["Wrist flexors"],[FA],"isolation"),
 "DB Wrist Extension": (FA,["Wrist extensors"],[FA],"isolation"),
 "Cable Wrist Extension": (FA,["Wrist extensors"],[FA],"isolation"),
 "Wrist Roller": (FA,["Wrist flexors","Wrist extensors","Finger flexors"],[FA],"isolation"),
 "Stomach Vacuums": (CORE,["Transversus abdominis"],[CORE],"isolation"),

 # ===== CORE =====
 "Cable Crunch": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Weight-Plate Crunch": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Plate-Weighted Crunch": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Weighted Crunch": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Decline Weighted Crunch": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Machine Crunch": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Roman Chair Leg Raise": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Hanging Leg Raise": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Lying Leg Raise": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Ab Wheel Rollout": (CORE,["Rectus abdominis","Transversus abdominis"],[CORE,BACK],"compound"),
 "Medicine Ball Russian Twists": (CORE,["Internal oblique","External oblique","Rectus abdominis"],[CORE],"isolation"),
 "Bicycle Crunch": (CORE,["Rectus abdominis","Internal oblique","External oblique"],[CORE],"isolation"),
 "Dragon Flag": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Bent-Knee Dragon Flag": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Modified Candlestick": (CORE,["Rectus abdominis"],[CORE],"isolation"),
 "Long-Lever Plank": (CORE,["Transversus abdominis","Rectus abdominis"],[CORE],"isolation"),

 # ===== QUADS =====
 "Hack Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU],"compound"),
 "Hack Squat (Heavy)": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU],"compound"),
 "Hack Squat (Back off)": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU],"compound"),
 "Barbell Back Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM,CORE],"compound"),
 "Barbell Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM,CORE],"compound"),
 "Barbell Front Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,CORE],"compound"),
 "Front Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,CORE],"compound"),
 "Smith Machine Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM],"compound"),
 "Machine Squat (Heavy)": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM],"compound"),
 "Machine Squat (Back off)": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM],"compound"),
 "Belt Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM],"compound"),
 "Goblet Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,CORE],"compound"),
 "Sissy Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD],"isolation"),
 "Leg Extension": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD],"isolation"),
 "Single-Leg Leg Extension": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD],"isolation"),
 "Leg Press": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM],"compound"),
 "Single-Leg Leg Press (Heavy)": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU],"compound"),
 "Single-Leg Leg Press (Back off)": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU],"compound"),
 "Reverse Nordic": (QUAD,["Rectus femoris","Vastus lateralis","Vastus medialis","Vastus intermedius"],[QUAD],"isolation"),
 "DB Bulgarian Split Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM],"compound"),
 "Smith Machine Split Squat": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM],"compound"),
 "DB Step-Up": (QUAD,["Vastus lateralis","Vastus medialis","Vastus intermedius","Rectus femoris"],[QUAD,GLU,HAM],"compound"),
 "Machine Hip Adduction": (QUAD,["Vastus medialis","Vastus lateralis"],[QUAD,GLU],"isolation"),

 # ===== GLUTES =====
 "Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "DB Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "DB Static Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "Smith Machine Static Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "Smith Machine Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "Barbell Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "Smith Machine Reverse Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "DB Reverse Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "DB Walking Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "Walking Lunge": (GLU,["Gluteus maximus"],[GLU,QUAD,HAM],"compound"),
 "Hip Thrust": (GLU,["Gluteus maximus"],[GLU,HAM],"compound"),
 "Barbell Hip Thrust": (GLU,["Gluteus maximus"],[GLU,HAM],"compound"),
 "Machine Hip Thrust": (GLU,["Gluteus maximus"],[GLU,HAM],"compound"),
 "Cable Pull-Through": (GLU,["Gluteus maximus","Hamstrings"],[GLU,HAM],"compound"),
 "Glute Kickback": (GLU,["Gluteus maximus"],[GLU],"isolation"),
 "Machine Hip Abduction": (GLU,["Gluteus medius","Gluteus minimus"],[GLU],"isolation"),
 "Cable Hip Abduction": (GLU,["Gluteus medius","Gluteus minimus"],[GLU],"isolation"),
 "Standing Plate Abduction": (GLU,["Gluteus medius","Gluteus minimus"],[GLU],"isolation"),
 "Lateral Band Walk": (GLU,["Gluteus medius","Gluteus minimus"],[GLU],"isolation"),

 # ===== HAMSTRINGS =====
 "Seated Leg Curl": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM],"isolation"),
 "Seated Hamstring Curl": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM],"isolation"),
 "Lying Leg Curl": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM],"isolation"),
 "Nordic Ham Curl": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM],"isolation"),
 "Glute-Ham Raise": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU],"compound"),
 "Romanian Deadlift": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "DB Romanian Deadlift": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "Snatch-Grip RDL": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "Paused Barbell RDL": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "Barbell RDL": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "Slow-Eccentric DB RDL": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "DB RDL": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "Stiff-Leg Deadlift": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "Good Morning": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "Conventional Deadlift": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK,QUAD],"compound"),
 "Sumo Deadlift": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK,QUAD],"compound"),
 "Seated Cable Deadlift": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus"],[HAM,GLU,BACK],"compound"),
 "Cable Pull-Through": (HAM,["Biceps femoris","Semitendinosus","Semimembranosus","Gluteus maximus"],[HAM,GLU],"compound"),

 # ===== CALVES =====
 "Standing Calf Raise": (CALF,["Gastrocnemius","Soleus"],[CALF],"isolation"),
 "Seated Calf Raise": (CALF,["Soleus","Gastrocnemius"],[CALF],"isolation"),
 "Leg Press Calf Press": (CALF,["Gastrocnemius","Soleus"],[CALF],"isolation"),
 "Leg Press Toe Press": (CALF,["Gastrocnemius","Soleus"],[CALF],"isolation"),
 "Donkey Calf Raise": (CALF,["Gastrocnemius","Soleus"],[CALF],"isolation"),
 "DB Calf Jumps": (CALF,["Gastrocnemius","Soleus"],[CALF],"compound"),
}

# ---- Link lookup from all PDFs ----
def norm(s):
    s=s.lower(); s=re.sub(r'[^a-z0-9 ]',' ',s); s=re.sub(r'\s+',' ',s).strip(); return s

lookup={}
for path in ['/tmp/links.json','/tmp/links2.json']:
    for e in json.load(open(path)):
        n=e['name']; u=e['url']
        k=norm(n)
        if not k or len(k)<3: continue
        lookup.setdefault(k, u)

def find_url(name):
    k=norm(name)
    if k in lookup: return lookup[k]
    # try progressively removing parentheticals and short descriptors
    cands=[k]
    m=re.sub(r'\([^)]*\)','',k).strip()
    if m: cands.append(m)
    # try matching any lookup key contained
    for c in cands:
        for lk,lu in lookup.items():
            if c and c in lk and len(c)>=4:
                return lu
    return ""

# Manual URL overrides for exercises whose PDF link is OCR-garbled or under a
# slightly different name, or has no embedded demo.
URL_OVERRIDES = {
 "45-Degree Dumbbell Preacher Curl":"https://youtu.be/WTkQLAethtg",
 "Arms-Extended 45° Hyperextension":"https://youtu.be/PrwC-5NTCCs",
 "Barbell Back Squat":"https://youtu.be/UGwmUJkTIx8",
 "Barbell Front Squat":"https://youtu.be/TRwhJ0TCoqI",
 "Bent-Over Cable Pec Flye (w/ Integrated Partials)":"https://youtu.be/DKaKmnB0BO8",
 "Bottom-2/3 Constant Tension Preacher Curl":"https://youtu.be/vHBedP8oeCA",
 "Cable Lat Prayer":"https://youtu.be/YrcnBlH8XDA",
 "Cable Reverse Flye (Mechanical Dropset)":"https://youtu.be/nN5RV1arpfM",
 "Chest-Supported T-Bar Row + Kelso Shrug":"https://youtu.be/qsmjaYao9pA",
 "Conventional Deadlift":"https://youtu.be/e8U-AM3c0ow",
 "Cuffed Behind-The-Back Lateral Raise":"https://youtu.be/fjiOCmFljDM",
 "Deficit Pendlay Row":"https://youtu.be/MmuyHKYCLps",
 "Dual-Handle Elbows-Out Cable Row":"https://youtu.be/qryIQcx4cTg",
 "Dual-Handle Lat Pulldown (Mid-back + Lats)":"https://youtu.be/NwQ5Ch5t5Vk",
 "Dumbbell Incline Press":"https://youtu.be/YmlMsvNGTKA",
 "Dumbbell Wrist Curl / Reverse Curl":"https://youtu.be/HJx1sIZKDqk",
 "Head Harness Neck Extension":"https://youtu.be/Mp2kp2tVhGQ",
 "Kneeling Overhead Cable Curl":"https://youtu.be/qpzwJd7mr3Y",
 "Neck Curl / Extension":"https://youtu.be/CuIkTLjx6fo",
 "Neutral-Grip Close-Grip Lat Pulldown":"https://youtu.be/7l859qd4E48",
 "Overhead Cable Triceps Extension (Bar)":"https://youtu.be/9_I1PqZAjdA",
 "Pec Deck (w/ Integrated Partials)":"https://youtu.be/NPa8YvUg4CM",
 "Reverse Pec Deck (w/ Integrated Partials)":"https://youtu.be/DKaKmnB0BO8",
 "Single-arm Overhead Cable Triceps Extension":"https://youtu.be/eNHOA90QcAg",
 "Slow-Eccentric EZ-Bar Skull Crusher":"https://youtu.be/oDKGCsTjAk8",
 "Sumo Deadlift":"https://youtu.be/c2go1amvyXs",
 "Super-ROM Overhand Cable Row":"https://youtu.be/WtokJfvWl-I",
 "Trap-Bar Shrug":"https://youtu.be/moFqLlptX7Q",
 "Triceps Diverging Pressdown (Long Rope or 2 Ropes)":"https://youtu.be/o4eazahiXQw",
 "Weight-Plate Crunch":"https://youtu.be/mP99WSRI6Bc",
 "Wide-Grip Barbell Shrug":"https://youtu.be/moFqLlptX7Q",
 "Wrist Roller":"",
}

# ---- Build output ----
exercises=[]
for name,(primary,subs,groups,etype) in EX.items():
    exercises.append({
        "name": name,
        "primary": primary,
        "sub_muscles": subs,
        "muscles": groups,
        "type": etype,
        "url": URL_OVERRIDES.get(name, find_url(name)),
    })
exercises.sort(key=lambda e:e["name"].lower())

# dedupe by lower name
seen={}
for e in exercises:
    seen.setdefault(e["name"].lower(), e)
exercises=list(seen.values())

out={"source":"Jeff Nippard programs (Ultimate Exercise Guide, Pure Bodybuilding PPL/UL/FB, Essentials, Transformation System) + embedded YouTube links",
     "generated":"2026-08-18",
     "groups":["neck","chest","shoulders","back","biceps","triceps","forearms","core","quadriceps","hamstrings","glutes","calves"],
     "exercises":exercises}

path="/home/techhub/health-avatar-app/data/exercises.json"
json.dump(out, open(path,"w"), indent=2)
withurl=sum(1 for e in exercises if e["url"])
print(f"wrote {len(exercises)} exercises, {withurl} with URL")
no=[e["name"] for e in exercises if not e["url"]]
print("missing url:", len(no))
for n in no: print("  -", n)
