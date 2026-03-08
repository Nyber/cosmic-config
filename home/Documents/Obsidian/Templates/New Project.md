<%*
const name = await tp.system.prompt("Project name");
if (!name) {
    await app.vault.trash(tp.config.target_file, true);
    return;
}

const folderPath = `2 - Projects/${name}`;
const filePath = `${folderPath}/${name}.md`;

if (app.vault.getAbstractFileByPath(filePath)) {
    new Notice(`Project "${name}" already exists`);
    await app.vault.trash(tp.config.target_file, true);
    return;
}

if (!app.vault.getAbstractFileByPath(folderPath)) {
    await app.vault.createFolder(folderPath);
}

const today = tp.date.now("YYYY-MM-DD");
const content = `---
status: active
start: ${today}
---

## Tasks

\`\`\`dataviewjs
const { getTasksForEntity } = eval(await app.vault.adapter.read("Scripts/taskUtils.js"));
const { open, done } = getTasksForEntity(dv, dv.current().file.name);
if (open.length) dv.taskList(open, false);
if (done.length) { dv.header(3, "Completed"); dv.taskList(done, false); }
\`\`\`

## Daily Entries

\`\`\`dataviewjs
const name = dv.current().file.name;
const matchLink = l => { const lp = l.path.replace(/\\.md$/, ''); return lp === name || lp.endsWith("/" + name); };
for (const p of dv.pages('"1 - Daily"').sort(p => p.file.name, 'desc')) {
    const matched = new Set();
    for (const item of p.file.lists)
        if (!item.task && item.outlinks && item.outlinks.some(matchLink)) matched.add(item.line);
    if (matched.size > 0) {
        const top = p.file.lists.where(i => matched.has(i.line) && (!i.parent || !matched.has(i.parent)));
        dv.header(4, p.file.link);
        dv.list(top.map(i => i.text));
    }
}
\`\`\`
`;

await app.vault.create(filePath, content);
await app.vault.trash(tp.config.target_file, true);
const created = app.vault.getAbstractFileByPath(filePath);
await app.workspace.getLeaf().openFile(created);
-%>
