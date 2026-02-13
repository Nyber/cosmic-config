// badges - Batch query app badge counts via lsappinfo
// Usage: badges 'Safari' 'Mail' 'zoom.us'
// Output: {"Mail":"3","zoom.us":"1"}  (only apps with non-empty badges)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_LINE 512
#define MAX_CMD  512

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("{}\n");
        return 0;
    }

    int first = 1;
    printf("{");

    for (int i = 1; i < argc; i++) {
        const char *app = argv[i];

        char cmd[MAX_CMD];
        // Shell-quote the app name to handle spaces
        snprintf(cmd, sizeof(cmd), "lsappinfo info -only StatusLabel '%s'", app);

        FILE *fp = popen(cmd, "r");
        if (!fp) continue;

        char line[MAX_LINE];
        char label[MAX_LINE] = "";

        while (fgets(line, sizeof(line), fp)) {
            // Parse: "StatusLabel"={ "label"="3" }
            char *p = strstr(line, "\"label\"=\"");
            if (p) {
                p += strlen("\"label\"=\"");
                char *end = strchr(p, '"');
                if (end && end > p) {
                    size_t len = (size_t)(end - p);
                    if (len >= sizeof(label)) len = sizeof(label) - 1;
                    memcpy(label, p, len);
                    label[len] = '\0';
                }
            }
        }
        pclose(fp);

        if (label[0] != '\0') {
            if (!first) printf(",");
            // JSON-escape app name and label (they shouldn't contain quotes, but be safe)
            printf("\"%s\":\"%s\"", app, label);
            first = 0;
        }
    }

    printf("}\n");
    return 0;
}
