<%*
const projectsFolder = app.vault.getAbstractFileByPath("2 - Projects");
if (!projectsFolder || !projectsFolder.children) {
    new Notice("No projects folder found");
    await app.vault.trash(tp.config.target_file, true);
    return;
}

const projects = projectsFolder.children
    .filter(f => f.children) // only folders
    .map(f => f.name)
    .sort();

if (projects.length === 0) {
    new Notice("No projects found");
    await app.vault.trash(tp.config.target_file, true);
    return;
}

const chosen = await tp.system.suggester(projects, projects, false, "Select project to archive");
if (!chosen) {
    await app.vault.trash(tp.config.target_file, true);
    return;
}

// Check for name collision in Archive
const archivePath = `5 - Archive/${chosen}`;
if (app.vault.getAbstractFileByPath(archivePath)) {
    new Notice(`"${chosen}" already exists in Archive. Rename or remove it first.`);
    await app.vault.trash(tp.config.target_file, true);
    return;
}

// Ensure Archive folder exists
if (!app.vault.getAbstractFileByPath("5 - Archive")) {
    await app.vault.createFolder("5 - Archive");
}

// Update status to done in the project index file
const indexPath = `2 - Projects/${chosen}/${chosen}.md`;
const indexFile = app.vault.getAbstractFileByPath(indexPath);
if (indexFile) {
    let content = await app.vault.read(indexFile);
    content = content.replace(/^status:\s*active/m, "status: done");
    await app.vault.modify(indexFile, content);
}

// Move the project folder to Archive
const sourceFolder = app.vault.getAbstractFileByPath(`2 - Projects/${chosen}`);
if (sourceFolder) {
    await app.fileManager.renameFile(sourceFolder, archivePath);
    new Notice(`Archived: ${chosen}`);
}

await app.vault.trash(tp.config.target_file, true);

// Open the archived project file
const archivedFile = app.vault.getAbstractFileByPath(`${archivePath}/${chosen}.md`);
if (archivedFile) {
    await app.workspace.getLeaf().openFile(archivedFile);
}
-%>
