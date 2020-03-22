"use strict";
(() => {
    class CodeViewer extends HTMLElement {
        constructor() {
            super(...arguments);
            this.editor = null;
            this.editorValue = "";
            this.readOnly = false;
            this.mode = "";
        }
        static get observedAttributes() {
            return ["editor-value", "read-only", "mode"];
        }
        connectedCallback() {
            this.editor = CodeMirror(this, {
                mode: "javascript",
                value: this.editorValue,
                readOnly: this.readOnly
            });
            this.editor.on("changes", () => {
                let event = new CustomEvent("editorChanged", {
                    detail: { value: this.editor.getValue() }
                });
                this.dispatchEvent(event);
            });
        }
        attributeChangedCallback(name, _oldValue, newValue) {
            switch (name) {
                case "editor-value":
                    newValue = newValue || "";
                    if (newValue === this.editorValue)
                        return;
                    this.editorValue = newValue;
                    if (!this.editor)
                        return;
                    if (newValue === this.editor.getValue())
                        return;
                    this.editor.setValue(newValue);
                    break;
                case "read-only":
                    let readOnly = !(newValue === null);
                    if (readOnly === this.readOnly)
                        return;
                    this.readOnly = readOnly;
                    if (!this.editor)
                        return;
                    this.editor.setOption("readOnly", readOnly);
                    break;
                case "mode":
                    newValue = newValue || "";
                    if (newValue === this.mode)
                        return;
                    this.mode = newValue;
                    if (!this.editor)
                        return;
                    if (newValue === this.editor.getOption("mode"))
                        return;
                    this.editor.setOption("mode", newValue);
                    break;
                default:
                    console.warn("Unexpected attribute name:", name);
            }
        }
    }
    customElements.define("code-viewer", CodeViewer);
})();
