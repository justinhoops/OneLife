import re

with open("ContentView.swift", "r") as f:
    content = f.read()

properties_to_remove = [
    r'^\s*let selectedAction: ActionChoiceID\?\n',
    r'^\s*let actionChoices: \[ActionChoiceID\]\n',
    r'^\s*let actionLabel: \(ActionChoiceID\) -> String\n',
    r'^\s*let actionPreview: \(ActionChoiceID\) -> \[String\]\n',
    r'^\s*selectedAction: ActionChoiceID\?,\n',
    r'^\s*actionChoices: \[ActionChoiceID\],\n',
    r'^\s*actionLabel: @escaping \(ActionChoiceID\) -> String,\n',
    r'^\s*actionPreview: @escaping \(ActionChoiceID\) -> \[String\],\n',
    r'^\s*self\.selectedAction = selectedAction\n',
    r'^\s*self\.actionChoices = actionChoices\n',
    r'^\s*self\.actionLabel = actionLabel\n',
    r'^\s*self\.actionPreview = actionPreview\n',
    r'^\s*selectedAction: vm\.selectedAction\(for: [^)]+\),\n',
    r'^\s*actionChoices: vm\.actionChoices\(for: [^)]+\),\n',
    r'^\s*actionLabel: vm\.actionLabel\(for:\),\n',
    r'^\s*actionPreview: vm\.actionPreview\(for:\),\n',
    r'^\s*selectedCrimeAction: vm\.selectedAction\(for: \.crime\),\n',
    r'^\s*crimeActionChoices: vm\.actionChoices\(for: \.crime\),\n'
]

# I need to be careful: `actionChoices` is actually USED by `ActionSelectionModule(actionChoices: actionChoices)`!
# Wait! I CANNOT remove `actionChoices` because `ActionSelectionModule` needs it!
# Let me ONLY remove `selectedAction`, `actionLabel`, and `actionPreview`.

safe_properties_to_remove = [
    r'^\s*let selectedAction: ActionChoiceID\?\n',
    r'^\s*let actionLabel: \(ActionChoiceID\) -> String\n',
    r'^\s*let actionPreview: \(ActionChoiceID\) -> \[String\]\n',
    r'^\s*selectedAction: ActionChoiceID\?,\n',
    r'^\s*actionLabel: @escaping \(ActionChoiceID\) -> String,\n',
    r'^\s*actionPreview: @escaping \(ActionChoiceID\) -> \[String\],\n',
    r'^\s*self\.selectedAction = selectedAction\n',
    r'^\s*self\.actionLabel = actionLabel\n',
    r'^\s*self\.actionPreview = actionPreview\n',
    r'^\s*selectedAction: vm\.selectedAction\(for: [^)]+\),\n',
    r'^\s*actionLabel: vm\.actionLabel\(for:\),\n',
    r'^\s*actionPreview: vm\.actionPreview\(for:\),\n',
    r'^\s*selectedCrimeAction: vm\.selectedAction\(for: \.crime\),\n',
]

for p in safe_properties_to_remove:
    content = re.sub(p, '', content, flags=re.MULTILINE)

# Also fix LifePlannerTab which has `selectedCrimeAction`, `actionLabel`, `actionPreview`
content = re.sub(r'^\s*let selectedCrimeAction: ActionChoiceID\?\n', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*selectedCrimeAction: ActionChoiceID\?,\n', '', content, flags=re.MULTILINE)
content = re.sub(r'^\s*self\.selectedCrimeAction = selectedCrimeAction\n', '', content, flags=re.MULTILINE)

with open("ContentView.swift", "w") as f:
    f.write(content)

print("Removed unused properties")
