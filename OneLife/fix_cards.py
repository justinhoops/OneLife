import re

with open("ContentView.swift", "r") as f:
    content = f.read()

# Replace:
# PlannerSectionCard(
#     title: "Quick Actions",
#     symbol: "target",
#     status: selectedAction.map(actionLabel) ?? "Take action",
#     tone: selectedAction == nil ? .warning : .neutral
# )
pattern = re.compile(
    r'(PlannerSectionCard\(\s*title: "Quick Actions",\s*symbol: "target"),\s*status:.*?\n\s*tone:.*?\n\s*\)',
    re.MULTILINE
)
content = pattern.sub(r'\1\n            )', content)

# Also fix Crime Action if it has status and tone:
pattern2 = re.compile(
    r'(PlannerSectionCard\(\s*title: "Crime Action",\s*symbol: "eye.slash.fill"),\s*status:.*?\n\s*tone:.*?\n\s*\)',
    re.MULTILINE
)
content = pattern2.sub(r'\1\n            )', content)

with open("ContentView.swift", "w") as f:
    f.write(content)

print("Fixed Quick Actions")
