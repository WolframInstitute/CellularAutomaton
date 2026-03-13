import re

with open("/Users/swish/src/wolfram/CASearch/Proofs/CA/DoublerTrans.lean", "r") as f:
    text = f.read()

# Fix unmatched ')' from "show " lines
# Lines that have "show " and don't start with "show ¬("
lines = text.split('\n')
out_lines = []
for line in lines:
    if "show " in line and "from by omega" in line:
        if "show ¬(" not in line:
            # It has an unmatched ')' before " from by omega"
            line = line.replace(") from by omega", " from by omega")
    out_lines.append(line)

with open("/Users/swish/src/wolfram/CASearch/Proofs/CA/DoublerTrans.lean", "w") as f:
    f.write('\n'.join(out_lines))
