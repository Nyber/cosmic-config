<%*
const name = await tp.system.prompt("Resource name");
if (!name) {
    await app.vault.trash(tp.config.target_file, true);
    return;
}

const filePath = `4 - Resources/${name}.md`;

if (app.vault.getAbstractFileByPath(filePath)) {
    new Notice(`Resource "${name}" already exists`);
    await app.vault.trash(tp.config.target_file, true);
    return;
}

const content = `---
category:
url:
---

# ${name}

## Notes


\`\`\`dataviewjs
const { getTasksForEntity } = eval(await app.vault.adapter.read("Scripts/taskUtils.js"));
const { open, done } = getTasksForEntity(dv, dv.current().file.name);
if (open.length) { dv.header(2, "Open Tasks"); dv.taskList(open, false); }
if (done.length) { dv.header(2, "Completed"); dv.taskList(done, false); }
\`\`\`

## Mentions

\`\`\`dataviewjs
const name = dv.current().file.name;
dv.list(dv.pages('"1 - Daily"')
    .where(p => p.file.outlinks.some(l => l.path === name || l.path.endsWith("/" + name)))
    .sort(p => p.file.name, 'desc')
    .map(p => p.file.link));
\`\`\`
`;

await app.vault.create(filePath, content);
await app.vault.trash(tp.config.target_file, true);
const created = app.vault.getAbstractFileByPath(filePath);
await app.workspace.getLeaf().openFile(created);
-%>
