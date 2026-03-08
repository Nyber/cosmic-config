<%*
const noteDate = moment(tp.file.title, "YYYY-MM-DD");
const dayName = noteDate.format("dddd");
const prevCalDate = noteDate.clone().subtract(1, "day").format("YYYY-MM-DD");
const nextCalDate = noteDate.clone().add(1, "day").format("YYYY-MM-DD");

// Find the most recent daily note before this one
const dailyFolder = app.vault.getAbstractFileByPath("1 - Daily");
let prevFile = null;
if (dailyFolder && dailyFolder.children) {
    const files = dailyFolder.children
        .filter(f => f.extension === "md" && f.basename < tp.file.title)
        .sort((a, b) => b.basename.localeCompare(a.basename));
    if (files.length > 0) prevFile = files[0];
}

let carriedTasks = "";
if (prevFile) {
    const content = await app.vault.read(prevFile);
    const planMatch = content.match(/## Plan\s*\n([\s\S]*?)(?=\n## |\n---|$)/);
    if (planMatch) {
        const lines = planMatch[1].split("\n");
        const unchecked = [], kept = [];
        let carrying = false;
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i];
            if (/^- \[ \] /.test(line)) {
                unchecked.push(line);
                carrying = true;
            } else if (carrying && /^\t/.test(line)) {
                unchecked.push(line);
            } else if (/^- \[x\] /.test(line)) {
                // Checked parent: gather any unchecked children and their subtrees
                carrying = false;
                const orphans = [];
                let j = i + 1;
                while (j < lines.length && /^\t/.test(lines[j])) {
                    if (/^\t- \[ \] /.test(lines[j])) {
                        orphans.push(lines[j].replace(/^\t/, ""));
                        let k = j + 1;
                        while (k < lines.length && /^\t\t/.test(lines[k])) {
                            orphans.push(lines[k].replace(/^\t/, ""));
                            k++;
                        }
                        j = k;
                    } else {
                        j++;
                    }
                }
                kept.push(line);
                for (let k = i + 1; k < j; k++) kept.push(lines[k]);
                if (orphans.length > 0) unchecked.push(...orphans);
                i = j - 1;
            } else {
                carrying = false;
                kept.push(line);
            }
        }
        if (unchecked.length > 0) {
            carriedTasks = unchecked.join("\n");
            const count = unchecked.filter(l => /^- \[ \]/.test(l)).length;
            const note = `> *${count} outstanding item${count > 1 ? "s" : ""} moved to [[${tp.file.title}]]*`;
            const newPlan = kept.join("\n").trimEnd() + "\n" + note + "\n";
            const newContent = content.replace(planMatch[1], newPlan);
            await app.vault.modify(prevFile, newContent);
        }
    }

    // Also promote unchecked #followup tasks from non-Plan sections
    const carriedSet = new Set(carriedTasks.split("\n").map(l => l.trim()));
    const allLines = content.split("\n");
    let inPlan = false;
    const followups = [];
    const checkboxFollowups = [];
    for (let i = 0; i < allLines.length; i++) {
        if (/^## Plan/.test(allLines[i])) { inPlan = true; continue; }
        if (/^## /.test(allLines[i])) inPlan = false;
        if (!inPlan && /^- (?:\[ \] )?/.test(allLines[i]) && !/^- \[x\]/.test(allLines[i]) && allLines[i].includes("#followup")) {
            if (!carriedSet.has(allLines[i].trim())) {
                const fLine = /^- \[ \]/.test(allLines[i]) ? allLines[i] : allLines[i].replace(/^- /, "- [ ] ");
                followups.push(fLine);
                if (/^- \[ \] /.test(allLines[i])) checkboxFollowups.push(allLines[i]);
                while (i + 1 < allLines.length && /^\t/.test(allLines[i + 1])) {
                    followups.push(allLines[++i]);
                }
            }
        }
    }
    if (followups.length > 0) {
        carriedTasks = carriedTasks
            ? carriedTasks + "\n" + followups.join("\n")
            : followups.join("\n");

        // Strip checkboxes from promoted followups so Log stays plain bullets
        if (checkboxFollowups.length > 0) {
            let cur = await app.vault.read(prevFile);
            for (const orig of checkboxFollowups) {
                cur = cur.replace(orig, orig.replace(/^- \[ \] /, "- "));
            }
            await app.vault.modify(prevFile, cur);
        }
    }
}
const taskBlock = carriedTasks ? carriedTasks + "\n- [ ] " : "- [ ] ";
const prevLinkDate = prevFile ? prevFile.basename : prevCalDate;
-%>
# <% dayName %>

## Plan
<% taskBlock %>

## Log
-

## Incidents / Issues
-

---
Previous: [[<% prevLinkDate %>]] | Next: [[<% nextCalDate %>]] | [[Follow-ups]]
